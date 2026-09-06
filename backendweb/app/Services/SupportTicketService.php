<?php

namespace App\Services;

use App\Models\ActivityLog;
use App\Models\RentalUnit;
use App\Models\SupportAttachment;
use App\Models\SupportCategory;
use App\Models\SupportMessage;
use App\Models\SupportTicket;
use App\Models\User;
use App\Support\Roles;
use App\Support\DomainCatalog;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Str;

class SupportTicketService
{
    public function __construct(
        private readonly EmailService $emails,
        private readonly NotificationService $notifications,
        private readonly N8nWebhookService $n8n,
    ) {}

    /** @var array<string, mixed>|null */
    private ?array $lastN8nResult = null;

    /**
     * @return array<string, mixed>|null
     */
    public function lastN8nResult(): ?array
    {
        return $this->lastN8nResult;
    }

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

        // Never fail the HTTP create because email/WhatsApp/queue/broadcast broke.
        // Those side-effects were returning Laravel's opaque "Server Error" to the UI.
        try {
            $this->dispatchCreatedEmailsAndNotifications($ticket, $user, $assignee, $contactType);
        } catch (\Throwable $e) {
            report($e);
        }

        try {
            if ($user->normalizedRole() === Roles::TENANT && $user->tenant) {
                app(TenantCalendarService::class)->syncSupportEvent($ticket, $user->tenant);
            }
        } catch (\Throwable $e) {
            report($e);
        }

        try {
            ActivityLog::record('support.ticket_created', $ticket, [
                'ticket_number' => $ticket->ticket_number,
                'category' => $ticket->category,
                'priority' => $ticket->priority,
            ]);
        } catch (\Throwable $e) {
            report($e);
        }

        try {
            $this->lastN8nResult = $this->n8n->ticketCreated($ticket, $user);
        } catch (\Throwable $e) {
            report($e);
            $this->lastN8nResult = [
                'attempted' => true,
                'ok' => false,
                'status' => 'failed',
                'message' => $e->getMessage(),
            ];
        }

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

        ActivityLog::record('support.ticket_replied', $ticket, ['message_id' => $message->id]);

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

        ActivityLog::record('support.ticket_closed', $ticket);

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

        ActivityLog::record('support.ticket_resolved', $ticket);

        return $ticket->fresh(['messages', 'attachments', 'rating', 'assignee']);
    }

    /**
     * Assign a maintainer (role=manager) to a support ticket.
     * Used by staff UI and by n8n HTTP callbacks with a login Bearer token.
     */
    public function assignMaintainer(SupportTicket $ticket, User $actor, User $maintainer): SupportTicket
    {
        if ($maintainer->normalizedRole() !== Roles::MANAGER) {
            throw new \InvalidArgumentException('Assignee must be a maintainer (manager role).');
        }

        if ($maintainer->status !== 'active') {
            throw new \InvalidArgumentException('Maintainer account is not active.');
        }

        if (
            ! $actor->isSuperAdmin()
            && $ticket->organization_id
            && (int) $maintainer->organization_id !== (int) $ticket->organization_id
        ) {
            throw new \InvalidArgumentException('Maintainer must belong to the ticket organization.');
        }

        $previousId = $ticket->assigned_to;

        $ticket->forceFill([
            'assigned_to' => $maintainer->id,
            'assigned_at' => now(),
            'status' => in_array($ticket->status, ['closed', 'resolved'], true)
                ? $ticket->status
                : 'assigned',
        ])->save();

        SupportMessage::query()->create([
            'support_ticket_id' => $ticket->id,
            'user_id' => $actor->id,
            'sender_type' => 'system',
            'body' => 'Ticket assigned to maintainer '.$maintainer->name.' by '.$actor->name.'.',
        ]);

        if ((int) $previousId !== (int) $maintainer->id) {
            try {
                $this->notifications->notify($maintainer, 'support.ticket_assigned', [
                    'title' => 'Support ticket assigned '.$ticket->ticket_number,
                    'message' => $ticket->subject,
                    'priority' => $ticket->priority === 'urgent' ? 'critical' : 'high',
                    'category' => 'system',
                    'module' => 'support',
                    'record_type' => 'support_ticket',
                    'record_id' => $ticket->id,
                    'action_url' => '/help-support?ticket='.$ticket->id,
                    'organization_id' => $ticket->organization_id,
                    'dedupe_key' => 'support-assigned|'.$ticket->id.'|'.$maintainer->id,
                    'channels' => ['in_app', 'email', 'whatsapp'],
                ]);
            } catch (\Throwable $e) {
                report($e);
            }
        }

        try {
            ActivityLog::record('support.ticket_assigned', $ticket, [
                'assigned_to' => $maintainer->id,
                'previous_assigned_to' => $previousId,
                'by' => $actor->id,
            ]);
        } catch (\Throwable $e) {
            report($e);
        }

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

        return DomainCatalog::supportCategories()[$categoryKey]['route_to'] ?? 'manager';
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
        $categoryLabel = DomainCatalog::supportCategories()[$ticket->category]['name'] ?? $ticket->category;
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
            $assigneeEmail = $this->preferredNotifyEmail($assignee);
            $this->emails->queue(
                $staffTemplate,
                $assigneeEmail,
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
                // Email already queued above — avoid a second SMTP send.
                'channels' => ['in_app', 'whatsapp'],
            ]);
        }

        // Technical issues also notify platform even if already assigned to platform.
        if ($ticket->category === 'technical_issue' && $assignee?->normalizedRole() !== Roles::SUPER_ADMIN) {
            $platform = User::query()->where('role', Roles::SUPER_ADMIN)->orderBy('id')->first();
            if ($platform) {
                $platformEmail = $this->preferredNotifyEmail($platform);
                $this->emails->queue(
                    'contact_support',
                    $platformEmail,
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
            // Email already queued to ticket.email — avoid a second SMTP send.
            'channels' => ['in_app'],
        ]);
    }

    private function preferredNotifyEmail(User $user): string
    {
        // notify_email may be missing until migration 2026_08_12_140000 runs.
        $notify = $user->getAttribute('notify_email');
        if (filled($notify)) {
            return (string) $notify;
        }

        return (string) $user->email;
    }
}
