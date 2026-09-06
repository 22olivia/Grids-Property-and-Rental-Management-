<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\EmailLog;
use App\Models\SupportCategory;
use App\Models\SupportRating;
use App\Models\SupportTicket;
use App\Models\ActivityLog;
use App\Models\User;
use App\Services\SupportTicketService;
use App\Support\Roles;
use App\Support\DomainCatalog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\RateLimiter;
use Illuminate\Validation\Rule;

class SupportController extends Controller
{
    public function meta(): JsonResponse
    {
        $categories = SupportCategory::query()
            ->where('is_active', true)
            ->orderBy('sort_order')
            ->get(['key', 'name', 'route_to', 'description']);

        if ($categories->isEmpty()) {
            $categories = collect(DomainCatalog::supportCategories())->map(fn ($row, $key) => [
                'key' => $key,
                'name' => $row['name'],
                'route_to' => $row['route_to'],
                'description' => $row['description'],
            ])->values();
        }

        return response()->json([
            'data' => [
                'support_email' => config('support.email', 'support@gpms.test'),
                'helpline' => config('support.helpline', '+971 4 000 1234'),
                'hours' => config('support.hours', 'Sunday–Thursday, 9:00–18:00 GST'),
                'contact_types' => DomainCatalog::SUPPORT_CONTACT_TYPES,
                'categories' => $categories,
                'priorities' => DomainCatalog::SUPPORT_PRIORITIES,
                'statuses' => DomainCatalog::SUPPORT_STATUSES,
                'faqs' => DomainCatalog::supportFaqs(),
                'preferred_contact_methods' => ['email', 'phone'],
            ],
        ]);
    }

    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $query = SupportTicket::query()
            ->with(['property:id,name', 'rentalUnit:id,unit_number', 'assignee:id,name,email,role'])
            ->latest();

        if ($user->isSuperAdmin()) {
            // platform sees all
        } elseif (in_array($user->normalizedRole(), [Roles::OWNER, Roles::MANAGER], true)) {
            $query->where(function ($q) use ($user) {
                $q->where('user_id', $user->id)
                    ->orWhere('assigned_to', $user->id)
                    ->orWhere('organization_id', $user->organization_id);
            });
        } else {
            $query->where('user_id', $user->id);
        }

        if ($request->filled('status')) {
            $query->where('status', $request->string('status'));
        }
        if ($request->filled('contact_type')) {
            $query->where('contact_type', $request->string('contact_type'));
        }

        $page = $query->paginate(min(50, max(1, (int) $request->integer('per_page', 20))));

        return response()->json([
            'data' => $page->items(),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page' => $page->lastPage(),
                'total' => $page->total(),
            ],
        ]);
    }

    public function store(Request $request, SupportTicketService $support): JsonResponse
    {
        $user = $request->user();
        $key = 'support-submit:'.$user->id;
        if (RateLimiter::tooManyAttempts($key, 5)) {
            return response()->json([
                'message' => 'Too many support submissions. Please wait a minute and try again.',
            ], 429);
        }
        RateLimiter::hit($key, 60);

        $validated = $request->validate([
            'contact_type' => ['required', Rule::in(array_keys(DomainCatalog::SUPPORT_CONTACT_TYPES))],
            'name' => ['required', 'string', 'max:120'],
            'email' => ['required', 'email', 'max:255'],
            'phone' => ['nullable', 'string', 'max:40'],
            'subject' => ['required', 'string', 'max:200'],
            'category' => ['required', Rule::in(array_keys(DomainCatalog::supportCategories()))],
            'priority' => ['required', Rule::in(DomainCatalog::SUPPORT_PRIORITIES)],
            'property_id' => ['nullable', 'integer', 'exists:properties,id'],
            'rental_unit_id' => ['nullable', 'integer', 'exists:rental_units,id'],
            'message' => ['required', 'string', 'max:5000'],
            'preferred_contact_method' => ['required', Rule::in(['email', 'phone'])],
            'attachments' => ['sometimes', 'array', 'max:5'],
            'attachments.*' => ['file', 'max:5120'],
        ]);

        $files = $request->file('attachments', []);
        if (! is_array($files)) {
            $files = $files ? [$files] : [];
        }

        try {
            $ticket = $support->create($user, $validated, array_values($files));
        } catch (\InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        } catch (\Throwable $e) {
            report($e);

            return response()->json([
                'message' => 'Could not create the support ticket. Check Railway MySQL migrations and queue, then try again.',
            ], 500);
        }

        return response()->json([
            'message' => 'Support request submitted. Confirmation email sent.',
            'data' => $this->serialize($ticket->load(['messages.user', 'attachments', 'rating', 'assignee', 'property', 'rentalUnit'])),
            'notifications' => array_merge(
                $this->notificationSummary($ticket),
                ['n8n' => $support->lastN8nResult()],
            ),
        ], 201);
    }

    public function show(Request $request, string $id, SupportTicketService $support): JsonResponse
    {
        $ticket = SupportTicket::query()
            ->with([
                'messages' => fn ($q) => $q->with(['user:id,name,role', 'attachments'])->orderBy('created_at'),
                'attachments',
                'rating',
                'assignee:id,name,email,role',
                'property:id,name',
                'rentalUnit:id,unit_number',
            ])
            ->findOrFail($id);

        abort_unless($support->userCanAccess($request->user(), $ticket), 403);

        $messages = $ticket->messages
            ->filter(fn ($m) => ! $m->is_internal || $this->isStaff($request->user()))
            ->values();

        return response()->json([
            'data' => array_merge($this->serialize($ticket), [
                'messages' => $messages,
            ]),
        ]);
    }

    public function reply(Request $request, string $id, SupportTicketService $support): JsonResponse
    {
        $ticket = SupportTicket::query()->findOrFail($id);
        abort_unless($support->userCanAccess($request->user(), $ticket), 403);
        abort_if($ticket->status === 'closed', 422, 'Ticket is closed.');

        $validated = $request->validate([
            'body' => ['required', 'string', 'max:5000'],
            'is_internal' => ['sometimes', 'boolean'],
            'attachments' => ['sometimes', 'array', 'max:5'],
            'attachments.*' => ['file', 'max:5120'],
        ]);

        $files = $request->file('attachments', []);
        if (! is_array($files)) {
            $files = $files ? [$files] : [];
        }

        try {
            $message = $support->reply(
                $ticket,
                $request->user(),
                $validated['body'],
                array_values($files),
                (bool) ($validated['is_internal'] ?? false),
            );
        } catch (\InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'message' => 'Reply added.',
            'data' => $message,
        ]);
    }

    public function close(Request $request, string $id, SupportTicketService $support): JsonResponse
    {
        $ticket = SupportTicket::query()->findOrFail($id);
        abort_unless($support->userCanAccess($request->user(), $ticket), 403);

        $ticket = $support->close($ticket, $request->user());

        return response()->json([
            'message' => 'Ticket closed.',
            'data' => $this->serialize($ticket),
        ]);
    }

    public function resolve(Request $request, string $id, SupportTicketService $support): JsonResponse
    {
        abort_unless($this->isStaff($request->user()), 403);
        $ticket = SupportTicket::query()->findOrFail($id);
        abort_unless($support->userCanAccess($request->user(), $ticket), 403);

        $ticket = $support->resolve($ticket, $request->user());

        return response()->json([
            'message' => 'Ticket resolved.',
            'data' => $this->serialize($ticket),
        ]);
    }

    /**
     * List maintainers (manager-role users) for n8n / staff assignment.
     */
    public function maintainers(Request $request): JsonResponse
    {
        abort_unless($this->isStaff($request->user()), 403);

        $user = $request->user();
        $query = User::query()
            ->where('role', Roles::MANAGER)
            ->where('status', 'active')
            ->orderBy('name');

        if (! $user->isSuperAdmin()) {
            $query->where('organization_id', $user->organization_id);
        } elseif ($request->filled('organization_id')) {
            $query->where('organization_id', (int) $request->integer('organization_id'));
        }

        $rows = $query->get(['id', 'name', 'email', 'phone', 'role', 'organization_id', 'status']);

        return response()->json([
            'data' => $rows,
            'meta' => ['total' => $rows->count()],
        ]);
    }

    /**
     * Assign a maintainer to a ticket (staff + n8n HTTP with login Bearer token).
     */
    public function assign(Request $request, string $id, SupportTicketService $support): JsonResponse
    {
        abort_unless($this->isStaff($request->user()), 403);
        $ticket = SupportTicket::query()->findOrFail($id);
        abort_unless($support->userCanAccess($request->user(), $ticket), 403);
        abort_if($ticket->status === 'closed', 422, 'Ticket is closed.');

        $validated = $request->validate([
            'maintainer_id' => ['nullable', 'integer', 'exists:users,id'],
            'maintainer_email' => ['nullable', 'email', 'max:255'],
            'assigned_to' => ['nullable', 'integer', 'exists:users,id'],
        ]);

        $maintainerId = $validated['maintainer_id'] ?? $validated['assigned_to'] ?? null;
        $maintainer = null;
        if ($maintainerId) {
            $maintainer = User::query()->find($maintainerId);
        } elseif (! empty($validated['maintainer_email'])) {
            $maintainer = User::query()
                ->where('email', $validated['maintainer_email'])
                ->first();
        }

        if (! $maintainer) {
            return response()->json([
                'message' => 'Provide maintainer_id, assigned_to, or maintainer_email.',
            ], 422);
        }

        try {
            $ticket = $support->assignMaintainer($ticket, $request->user(), $maintainer);
        } catch (\InvalidArgumentException $e) {
            return response()->json(['message' => $e->getMessage()], 422);
        }

        return response()->json([
            'message' => 'Maintainer assigned.',
            'data' => $this->serialize($ticket->load(['assignee', 'messages', 'attachments', 'rating'])),
        ]);
    }

    public function rate(Request $request, string $id, SupportTicketService $support): JsonResponse
    {
        $ticket = SupportTicket::query()->findOrFail($id);
        abort_unless($ticket->user_id === $request->user()->id, 403);
        abort_unless(in_array($ticket->status, ['resolved', 'closed'], true), 422, 'Rate after the ticket is resolved.');

        $validated = $request->validate([
            'rating' => ['required', 'integer', 'min:1', 'max:5'],
            'comment' => ['nullable', 'string', 'max:1000'],
        ]);

        $rating = SupportRating::query()->updateOrCreate(
            [
                'support_ticket_id' => $ticket->id,
                'user_id' => $request->user()->id,
            ],
            $validated,
        );

        ActivityLog::record('support.ticket_rated', $ticket, $validated, $request);

        return response()->json([
            'message' => 'Thanks for your feedback.',
            'data' => $rating,
        ]);
    }

    private function isStaff($user): bool
    {
        return in_array($user->normalizedRole(), [
            Roles::SUPER_ADMIN, Roles::OWNER, Roles::MANAGER, Roles::ACCOUNTANT,
        ], true);
    }

    /**
     * @return array{email: string, whatsapp: string}
     */
    private function notificationSummary(SupportTicket $ticket): array
    {
        $logs = EmailLog::query()
            ->where('related_type', SupportTicket::class)
            ->where('related_id', $ticket->id)
            ->latest('id')
            ->limit(5)
            ->get();

        $email = 'failed';
        if ($logs->contains(fn (EmailLog $row) => $row->status === 'sent'
            && ! in_array((string) data_get($row->provider_response, 'provider', $row->provider), ['log', 'array'], true)
            && ! data_get($row->provider_response, 'simulated'))) {
            $email = 'sent';
        } elseif ($logs->contains(fn (EmailLog $row) => $row->status === 'sent')) {
            // log/array mailer — not a real inbox delivery
            $email = 'simulated';
        } elseif ($logs->contains(fn (EmailLog $row) => in_array($row->status, ['queued', 'retrying'], true))) {
            $email = 'queued';
        } elseif ($logs->isEmpty()) {
            // No log yet — let the Vercel UI SMTP fallback send.
            $email = 'missing';
        }

        return [
            // Frontend only skips its SMTP fallback when email is a known status string.
            // Use "missing" so UI still sends via /api/mail/send when Laravel did not deliver.
            'email' => $email === 'missing' ? null : $email,
            'whatsapp' => 'backend',
        ];
    }

    /**
     * @return array<string, mixed>
     */
    private function serialize(SupportTicket $ticket): array
    {
        return [
            'id' => $ticket->id,
            'ticket_number' => $ticket->ticket_number,
            'organization_id' => $ticket->organization_id,
            'user_id' => $ticket->user_id,
            'assigned_to' => $ticket->assigned_to,
            'assignee' => $ticket->assignee,
            'contact_type' => $ticket->contact_type,
            'contact_type_label' => DomainCatalog::SUPPORT_CONTACT_TYPES[$ticket->contact_type] ?? $ticket->contact_type,
            'category' => $ticket->category,
            'category_label' => DomainCatalog::supportCategories()[$ticket->category]['name'] ?? $ticket->category,
            'priority' => $ticket->priority,
            'status' => $ticket->status,
            'subject' => $ticket->subject,
            'message' => $ticket->message,
            'name' => $ticket->name,
            'email' => $ticket->email,
            'phone' => $ticket->phone,
            'preferred_contact_method' => $ticket->preferred_contact_method,
            'property_id' => $ticket->property_id,
            'property' => $ticket->property,
            'rental_unit_id' => $ticket->rental_unit_id,
            'rental_unit' => $ticket->rentalUnit,
            'attachments' => $ticket->attachments,
            'rating' => $ticket->rating,
            'assigned_at' => $ticket->assigned_at,
            'resolved_at' => $ticket->resolved_at,
            'closed_at' => $ticket->closed_at,
            'last_reply_at' => $ticket->last_reply_at,
            'created_at' => $ticket->created_at,
            'updated_at' => $ticket->updated_at,
        ];
    }
}
