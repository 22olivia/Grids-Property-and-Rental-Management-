<?php

namespace App\Services;

use App\Models\RentalUnit;
use App\Models\SupportAttachment;
use App\Models\SupportCategory;
use App\Models\SupportMessage;
use App\Models\SupportTicket;
use App\Models\User;
use App\Support\Roles;
use App\Support\SupportCatalog;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class SupportTicketService
{
    public function __construct(
        private readonly EmailService $emails,
        private readonly NotificationService $notifications,
        private readonly ActivityLogger $logger,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     * @param  list<UploadedFile>  $files
     */
    public function create(User $user, array $data, array $files = []): SupportTicket
    {
        $categoryKey = (string) $data['category'];
        $contactType = (string) ($data['contact_type'] ?? 'platform');
        $routeTo = $this->resolveRoute($categoryKey, $contactType);
        $assignee = $this->resolveAssignee($user, $routeTo, $data['property_id'] ?? null);

        $ticket = DB::transaction(function () use ($user, $data, $files, $assignee, $contactType) {
            $ticket = SupportTicket::query()->create([
                'ticket_number' => $this->nextTicketNumber(),
                'organization_id' => $user->organization_id,
                'user_id' => $user->id,
                'assigned_to' => $assignee?->id,
                'property_id' => $data['property_id'] ?? null,
                'rental_unit_id' => $data['rental_unit_id'] ?? null,
                'contact_type' => $contactType,
                'category' => $data['category'],
                'priority' => $data['priority'] ?? 'normal',
                'status' => $assignee ? 'assigned' : 'open',
                'subject' => $data['subject'],
                'message' => $data['message'],
                'name' => $data['name'] ?? $user->name,
                'email' => $data['email'] ?? $user->email,
                'phone' => $data['phone'] ?? $user->phone,
                'preferred_contact_method' => $data['preferred_contact_method'] ?? 'email',
                'assigned_at' => $assignee ? now() : null,
                'last_reply_at' => now(),
            ]);

            SupportMessage::query()->create([
                'support_ticket_id' => $ticket->id,
                'user_id' => $user->id,
                'sender_type' => 'user',
                'body' => $ticket->message,
            ]);

            foreach ($files as $file) {
                $this->storeAttachment($ticket, $file, $user);
            }

            return $ticket->fresh(['property', 'rentalUnit', 'assignee', 'attachments', 'messages']);
        });

        $this->dispatchCreatedEmailsAndNotifications($ticket, $user, $assignee, $contactType);

        if ($user->normalizedRole() === Roles::TENANT && $user->tenant) {
            app(TenantCalendarService::class)->syncSupportEvent($ticket, $user->tenant);
        }

        $this->logger->log('support.ticket_created', $ticket, [
            'ticket_number' => $ticket->ticket_number,
            'category' => $ticket->category,
            'priority' => $ticket->priority,
        ]);

        return $ticket;
    }

    /**
     * @param  list<UploadedFile>  $files
     */
    public function reply(SupportTicket $ticket, User $user, string $body, array $files = [], bool $internal = false): SupportMessage
    {
        $isStaff = in_array($user->normalizedRole(), [
            Roles::SUPER_ADMIN, Roles::OWNER, Roles::MANAGER, Roles::ACCOUNTANT,
        ], true);

        $message = DB::transaction(function () use ($ticket, $user, $body, $files, $internal, $isStaff) {
            $message = SupportMessage::query()->create([
                'support_ticket_id' => $ticket->id,
                'user_id' => $user->id,
                'sender_type' => $isStaff ? 'staff' : 'user',
                'body' => $body,
                'is_internal' => $internal && $isStaff,
            ]);

            foreach ($files as $file) {
                $this->storeAttachment($ticket, $file, $user, $message->id);
            }

            $ticket->forceFill([
                'last_reply_at' => now(),
                'status' => match (true) {
                    $ticket->status === 'closed' => 'closed',
                    $isStaff => 'waiting_for_user',
                    default => in_array($ticket->status, ['open', 'assigned'], true) ? 'in_progress' : $ticket->status,
                },
            ])->save();

            return $message;
        });

        if (! $internal) {
            $recipient = $isStaff ? $ticket->user : $ticket->assignee;
            if ($recipient) {
                $this->emails->queue(
                    'support_reply',
                    $recipient->email,
                    [
                        'user_name' => $recipient->name,
                        'ticket_number' => $ticket->ticket_number,
                        'message' => $body,
                        'dashboard_link' => rtrim((string) config('app.url'), '/').'/help-support?ticket='.$ticket->id,
                    ],
                    $recipient->name,
                    $recipient,
                    $ticket,
                    $ticket->organization_id,
                );

                $this->notifications->notify($recipient, 'support.ticket_reply', [
                    'title' => 'New reply on '.$ticket->ticket_number,
                    'message' => Str::limit($body, 140),
                    'priority' => 'normal',
                    'category' => 'system',
                    'module' => 'support',
                    'record_type' => 'support_ticket',
                    'record_id' => $ticket->id,
                    'action_url' => '/help-support?ticket='.$ticket->id,
                    'dedupe_key' => 'support-reply|'.$ticket->id.'|'.$message->id,
                ]);
            }
        }

        $this->logger->log('support.ticket_replied', $ticket, ['message_id' => $message->id]);

        return $message->load('attachments', 'user');
    }

    public function close(SupportTicket $ticket, User $user): SupportTicket
    {
        $ticket->forceFill([
            'status' => 'closed',
            'closed_at' => now(),
            'resolved_at' => $ticket->resolved_at ?: now(),
        ])->save();

        SupportMessage::query()->create([
            'support_ticket_id' => $ticket->id,
            'user_id' => $user->id,
            'sender_type' => 'system',
            'body' => 'Ticket closed by '.$user->name.'.',
        ]);

        $this->notifications->notify($ticket->user, 'support.ticket_closed', [
            'title' => 'Ticket closed '.$ticket->ticket_number,
            'message' => 'Your support ticket was closed.',
            'priority' => 'normal',
            'category' => 'system',
            'module' => 'support',
            'record_type' => 'support_ticket',
            'record_id' => $ticket->id,
            'action_url' => '/help-support?ticket='.$ticket->id,
            'dedupe_key' => 'support-closed|'.$ticket->id,
        ]);

        $this->logger->log('support.ticket_closed', $ticket);

        return $ticket->fresh(['messages', 'attachments', 'rating', 'assignee']);
    }

    public function resolve(SupportTicket $ticket, User $user): SupportTicket
    {
        $ticket->forceFill([
            'status' => 'resolved',
            'resolved_at' => now(),
        ])->save();

        SupportMessage::query()->create([
            'support_ticket_id' => $ticket->id,
            'user_id' => $user->id,
            'sender_type' => 'system',
            'body' => 'Ticket marked resolved by '.$user->name.'.',
        ]);

        $this->notifications->notify($ticket->user, 'support.ticket_resolved', [
            'title' => 'Ticket resolved '.$ticket->ticket_number,
            'message' => 'Your support ticket was marked resolved. You can rate the experience.',
            'priority' => 'normal',
            'category' => 'system',
            'module' => 'support',
            'record_type' => 'support_ticket',
            'record_id' => $ticket->id,
            'action_url' => '/help-support?ticket='.$ticket->id,
            'dedupe_key' => 'support-resolved|'.$ticket->id,
        ]);

        $this->logger->log('support.ticket_resolved', $ticket);

        return $ticket->fresh(['messages', 'attachments', 'rating', 'assignee']);
    }

    public function userCanAccess(User $user, SupportTicket $ticket): bool
    {
        if ($ticket->user_id === $user->id) {
            return true;
        }

        if ($user->isSuperAdmin()) {
            return true;
        }

        if ($ticket->assigned_to === $user->id) {
            return true;
        }

        if (
            $user->organization_id
            && $ticket->organization_id === $user->organization_id
            && in_array($user->normalizedRole(), [Roles::OWNER, Roles::MANAGER], true)
        ) {
            return true;
        }

        return false;
    }

    private function nextTicketNumber(): string
    {
        do {
            $number = 'SUP-'.now()->format('ymd').'-'.Str::upper(Str::random(5));
        } while (SupportTicket::query()->where('ticket_number', $number)->exists());

        return $number;
    }

    private function resolveRoute(string $categoryKey, string $contactType): string
    {
        if ($contactType === 'owner') {
            return 'owner';
        }
        if ($contactType === 'manager') {
            return 'manager';
        }
        if ($contactType === 'platform') {
            return 'platform';
        }

        $category = SupportCategory::query()->where('key', $categoryKey)->first();
        if ($category) {
            return $category->route_to;
        }

        return SupportCatalog::categories()[$categoryKey]['route_to'] ?? 'manager';
    }

    private function resolveAssignee(User $user, string $routeTo, mixed $propertyId): ?User
    {
        $orgId = $user->organization_id;

        return match ($routeTo) {
            'platform' => User::query()->where('role', Roles::SUPER_ADMIN)->orderBy('id')->first(),
            'owner' => User::query()
                ->where('organization_id', $orgId)
                ->where('role', Roles::OWNER)
                ->orderBy('id')
                ->first(),
            'owner_or_manager' => User::query()
                ->where('organization_id', $orgId)
                ->whereIn('role', [Roles::OWNER, Roles::MANAGER])
                ->orderByRaw("case when role = 'owner' then 0 else 1 end")
                ->orderBy('id')
                ->first(),
            default => $this->managerForProperty($orgId, $propertyId)
                ?: User::query()
                    ->where('organization_id', $orgId)
                    ->where('role', Roles::MANAGER)
                    ->orderBy('id')
                    ->first(),
        };
    }

    private function managerForProperty(?int $orgId, mixed $propertyId): ?User
    {
        if (! $propertyId) {
            return null;
        }

        $managerId = RentalUnit::query()
            ->where('property_id', $propertyId)
            ->whereNotNull('assigned_manager_id')
            ->value('assigned_manager_id');

        if (! $managerId) {
            return null;
        }

        return User::query()
            ->where('id', $managerId)
            ->when($orgId, fn ($q) => $q->where('organization_id', $orgId))
            ->first();
    }

    private function storeAttachment(
        SupportTicket $ticket,
        UploadedFile $file,
        User $user,
        ?int $messageId = null,
    ): SupportAttachment {
        $allowed = [
            'image/jpeg', 'image/png', 'image/webp', 'image/gif',
            'application/pdf',
            'application/msword',
            'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
            'text/plain',
        ];

        $mime = (string) ($file->getMimeType() ?: 'application/octet-stream');
        $scanStatus = in_array($mime, $allowed, true) && $file->getSize() <= 5 * 1024 * 1024
            ? 'clean'
            : 'rejected';

        if ($scanStatus === 'rejected') {
            throw new \InvalidArgumentException('Attachment type or size is not allowed.');
        }

        $path = $file->store('support/'.$ticket->id, 'local');

        return SupportAttachment::query()->create([
            'support_ticket_id' => $ticket->id,
            'support_message_id' => $messageId,
            'uploaded_by' => $user->id,
            'original_name' => $file->getClientOriginalName(),
            'path' => $path,
            'mime_type' => $mime,
            'size' => $file->getSize() ?: 0,
            'scan_status' => $scanStatus,
        ]);
    }

    private function dispatchCreatedEmailsAndNotifications(
        SupportTicket $ticket,
        User $user,
        ?User $assignee,
        string $contactType,
    ): void {
        $categoryLabel = SupportCatalog::categories()[$ticket->category]['name'] ?? $ticket->category;
        $propertyName = $ticket->property?->name ?: '—';
        $unitNumber = $ticket->rentalUnit?->unit_number ?: '—';
        $dashboard = rtrim((string) config('app.url'), '/').'/help-support?ticket='.$ticket->id;

        $vars = [
            'user_name' => $ticket->name,
            'recipient_name' => $assignee?->name ?: 'Support Team',
            'ticket_number' => $ticket->ticket_number,
            'property_name' => $propertyName,
            'unit_number' => $unitNumber,
            'category' => $categoryLabel,
            'priority' => ucfirst($ticket->priority),
            'message' => $ticket->message,
            'date' => optional($ticket->created_at)?->toDayDateTimeString() ?: now()->toDayDateTimeString(),
            'dashboard_link' => $dashboard,
        ];

        $this->emails->queue(
            'support_ticket_user',
            $ticket->email,
            $vars,
            $ticket->name,
            $user,
            $ticket,
            $ticket->organization_id,
        );

        $staffTemplate = match ($contactType) {
            'owner' => 'contact_owner',
            'manager' => 'contact_manager',
            'platform' => 'contact_support',
            default => 'support_ticket_staff',
        };

        if ($assignee) {
            $this->emails->queue(
                $staffTemplate,
                $assignee->email,
                $vars,
                $assignee->name,
                $assignee,
                $ticket,
                $ticket->organization_id,
            );

            $this->notifications->notify($assignee, 'support.ticket_assigned', [
                'title' => 'Support ticket assigned '.$ticket->ticket_number,
                'message' => $ticket->subject,
                'priority' => $ticket->priority === 'urgent' ? 'critical' : 'high',
                'category' => 'system',
                'module' => 'support',
                'record_type' => 'support_ticket',
                'record_id' => $ticket->id,
                'action_url' => '/help-support?ticket='.$ticket->id,
                'organization_id' => $ticket->organization_id,
                'variables' => [
                    'property_name' => $propertyName,
                    'unit_number' => $unitNumber,
                ],
                'dedupe_key' => 'support-assigned|'.$ticket->id,
            ]);
        }

        // Technical issues also notify platform even if already assigned to platform.
        if ($ticket->category === 'technical_issue' && $assignee?->normalizedRole() !== Roles::SUPER_ADMIN) {
            $platform = User::query()->where('role', Roles::SUPER_ADMIN)->orderBy('id')->first();
            if ($platform) {
                $this->emails->queue(
                    'contact_support',
                    $platform->email,
                    array_merge($vars, ['recipient_name' => $platform->name]),
                    $platform->name,
                    $platform,
                    $ticket,
                );
            }
        }

        $this->notifications->notify($user, 'support.ticket_created', [
            'title' => 'Support ticket created '.$ticket->ticket_number,
            'message' => 'We received your request: '.$ticket->subject,
            'priority' => 'normal',
            'category' => 'system',
            'module' => 'support',
            'record_type' => 'support_ticket',
            'record_id' => $ticket->id,
            'action_url' => '/help-support?ticket='.$ticket->id,
            'dedupe_key' => 'support-created|'.$ticket->id,
        ]);
    }
}
