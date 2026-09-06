<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AppNotification;
use App\Models\NotificationChannelSetting;
use App\Models\NotificationDelivery;
use App\Models\NotificationPreference;
use App\Models\NotificationTemplate;
use App\Models\ActivityLog;
use App\Services\NotificationService;
use App\Support\NotificationCatalog;
use App\Support\Roles;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class NotificationCentreController extends Controller
{
    public function catalog(): JsonResponse
    {
        return response()->json([
            'data' => [
                'categories' => NotificationCatalog::CATEGORIES,
                'channels' => NotificationCatalog::CHANNELS,
                'priorities' => NotificationCatalog::PRIORITIES,
                'template_variables' => NotificationCatalog::templateVariables(),
                'events_by_role' => NotificationCatalog::eventsByRole(),
                'rules' => NotificationCatalog::deliveryRules(),
                'role_map' => [
                    Roles::SUPER_ADMIN => 'Super Admin',
                    Roles::OWNER => 'Tenant (Company) / Property Owner',
                    Roles::MANAGER => 'Manager',
                    Roles::TENANT => 'Residential Tenant',
                ],
            ],
        ]);
    }

    public function index(Request $request, NotificationService $notifications): JsonResponse
    {
        $user = $request->user();
        $perPage = min(100, max(1, (int) $request->integer('per_page', 20)));

        $query = AppNotification::query()
            ->where('recipient_user_id', $user->id)
            ->when(! $request->boolean('include_archived'), fn ($q) => $q->whereNull('archived_at'))
            ->when($request->filled('category'), fn ($q) => $q->where('category', $request->string('category')))
            ->when($request->filled('priority'), fn ($q) => $q->where('priority', $request->string('priority')))
            ->when($request->filled('status'), function ($q) use ($request) {
                match ((string) $request->string('status')) {
                    'unread' => $q->whereNull('read_at'),
                    'read' => $q->whereNotNull('read_at'),
                    'archived' => $q->whereNotNull('archived_at'),
                    default => $q,
                };
            })
            ->when($request->boolean('unread_only'), fn ($q) => $q->whereNull('read_at'))
            ->when($request->filled('from'), fn ($q) => $q->whereDate('created_at', '>=', $request->date('from')))
            ->when($request->filled('to'), fn ($q) => $q->whereDate('created_at', '<=', $request->date('to')))
            ->when($request->filled('search'), function ($q) use ($request) {
                $term = '%'.strtolower((string) $request->string('search')).'%';
                $q->where(function ($inner) use ($term) {
                    $inner->whereRaw('LOWER(title) like ?', [$term])
                        ->orWhereRaw('LOWER(message) like ?', [$term])
                        ->orWhereRaw('LOWER(COALESCE(template_key, "")) like ?', [$term])
                        ->orWhereRaw('LOWER(category) like ?', [$term]);
                });
            })
            ->latest();

        if ($request->boolean('grouped')) {
            $groups = (clone $query)
                ->get()
                ->groupBy(fn (AppNotification $n) => $n->group_key ?: $n->category)
                ->map(function ($items, $key) use ($notifications) {
                    /** @var \Illuminate\Support\Collection<int, AppNotification> $items */
                    $latest = $items->sortByDesc('created_at')->first();

                    return [
                        'group_key' => $key,
                        'count' => $items->count(),
                        'unread_count' => $items->whereNull('read_at')->count(),
                        'latest' => $this->serialize($latest, $notifications),
                        'items' => $items->sortByDesc('created_at')->take(5)->map(
                            fn (AppNotification $n) => $this->serialize($n, $notifications)
                        )->values(),
                    ];
                })
                ->values();

            return response()->json([
                'data' => $groups,
                'unread_count' => $this->unreadCountFor($user->id),
                'meta' => ['grouped' => true],
            ]);
        }

        $page = $query->paginate($perPage);

        return response()->json([
            'data' => collect($page->items())->map(
                fn (AppNotification $n) => $this->serialize($n, $notifications)
            )->values(),
            'unread_count' => $this->unreadCountFor($user->id),
            'meta' => [
                'current_page' => $page->currentPage(),
                'last_page' => $page->lastPage(),
                'per_page' => $page->perPage(),
                'total' => $page->total(),
            ],
        ]);
    }

    public function unreadCount(Request $request): JsonResponse
    {
        return response()->json([
            'unread_count' => $this->unreadCountFor($request->user()->id),
        ]);
    }

    public function markRead(Request $request, string $id): JsonResponse
    {
        $notification = AppNotification::query()
            ->where('recipient_user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();
        $notification->markRead();

        return response()->json([
            'message' => 'Notification marked as read.',
            'unread_count' => $this->unreadCountFor($request->user()->id),
        ]);
    }

    public function markAllRead(Request $request): JsonResponse
    {
        AppNotification::query()
            ->where('recipient_user_id', $request->user()->id)
            ->whereNull('read_at')
            ->update(['read_at' => now()]);

        return response()->json([
            'message' => 'All notifications marked as read.',
            'unread_count' => 0,
        ]);
    }

    public function archive(Request $request, string $id): JsonResponse
    {
        $notification = AppNotification::query()
            ->where('recipient_user_id', $request->user()->id)
            ->where('id', $id)
            ->firstOrFail();
        $notification->archive();
        $notification->markRead();

        return response()->json(['message' => 'Notification archived.']);
    }

    public function destroy(Request $request, string $id): JsonResponse
    {
        AppNotification::query()
            ->where('recipient_user_id', $request->user()->id)
            ->where('id', $id)
            ->delete();

        return response()->json(['message' => 'Notification deleted.']);
    }

    public function preferences(Request $request): JsonResponse
    {
        $prefs = NotificationPreference::query()->firstOrCreate(
            ['user_id' => $request->user()->id],
            [
                'in_app' => true,
                'email' => true,
                'whatsapp' => true,
                'categories' => array_fill_keys(array_keys(NotificationCatalog::CATEGORIES), true),
                'preferred_language' => 'en',
                'digest_frequency' => 'none',
                'emergency_override' => true,
            ]
        );

        return response()->json([
            'data' => $prefs,
            'meta' => [
                'emergency_alerts_cannot_be_disabled' => true,
                'channels' => NotificationCatalog::CHANNELS,
                'categories' => NotificationCatalog::CATEGORIES,
            ],
        ]);
    }

    public function updatePreferences(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'in_app' => ['sometimes', 'boolean'],
            'email' => ['sometimes', 'boolean'],
            'whatsapp' => ['sometimes', 'boolean'],
            'categories' => ['sometimes', 'array'],
            'preferred_language' => ['sometimes', 'string', 'max:10'],
            'digest_frequency' => ['sometimes', Rule::in(['none', 'daily', 'weekly'])],
            'quiet_hours_start' => ['nullable', 'date_format:H:i'],
            'quiet_hours_end' => ['nullable', 'date_format:H:i'],
            'emergency_override' => ['sometimes', 'boolean'],
            'channel_by_category' => ['sometimes', 'array'],
        ]);

        // Emergency alerts cannot be disabled.
        $validated['emergency_override'] = true;

        $prefs = NotificationPreference::query()->updateOrCreate(
            ['user_id' => $request->user()->id],
            $validated
        );

        ActivityLog::record('notification.preferences_updated', $prefs, $validated, $request);

        return response()->json([
            'message' => 'Notification preferences saved.',
            'data' => $prefs,
        ]);
    }

    public function templates(Request $request): JsonResponse
    {
        $user = $request->user();
        $templates = NotificationTemplate::query()
            ->when(
                ! $user->isSuperAdmin(),
                fn ($q) => $q->where(function ($inner) use ($user) {
                    $inner->whereNull('organization_id')
                        ->orWhere('organization_id', $user->organization_id);
                })
            )
            ->when($request->filled('category'), fn ($q) => $q->where('category', $request->string('category')))
            ->orderBy('key')
            ->get();

        return response()->json(['data' => $templates]);
    }

    public function storeTemplate(Request $request): JsonResponse
    {
        $user = $request->user();
        abort_unless($user->isSuperAdmin() || $user->isOwner(), 403);

        $validated = $request->validate([
            'key' => ['required', 'string', 'max:100'],
            'name' => ['required', 'string', 'max:255'],
            'category' => ['nullable', Rule::in(array_keys(NotificationCatalog::CATEGORIES))],
            'roles' => ['sometimes', 'array'],
            'channel' => ['required', Rule::in(NotificationCatalog::CHANNELS)],
            'channels' => ['sometimes', 'array'],
            'priority' => ['sometimes', Rule::in(NotificationCatalog::PRIORITIES)],
            'is_emergency' => ['sometimes', 'boolean'],
            'subject' => ['nullable', 'string', 'max:255'],
            'body' => ['required', 'string'],
            'variables' => ['sometimes', 'array'],
            'organization_id' => ['nullable', 'exists:organizations,id'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        if ($user->isOwner()) {
            $validated['organization_id'] = $user->organization_id;
        }

        $template = NotificationTemplate::query()->updateOrCreate(
            [
                'organization_id' => $validated['organization_id'] ?? null,
                'key' => $validated['key'],
            ],
            $validated
        );

        ActivityLog::record('notification.template_saved', $template, $validated, $request);

        return response()->json([
            'message' => 'Notification template saved.',
            'data' => $template,
        ], 201);
    }

    public function updateTemplate(Request $request, NotificationTemplate $template): JsonResponse
    {
        $user = $request->user();
        $canEditOrgCopy = $user->isOwner()
            && $template->organization_id !== null
            && (int) $template->organization_id === (int) $user->organization_id;
        $canCloneGlobal = $user->isOwner() && $template->organization_id === null;
        abort_unless($user->isSuperAdmin() || $canEditOrgCopy || $canCloneGlobal, 403);

        if ($canCloneGlobal) {
            // Org owners customize by cloning global templates into org scope.
            $existing = NotificationTemplate::query()
                ->where('organization_id', $user->organization_id)
                ->where('key', $template->key)
                ->first();

            if ($existing) {
                $template = $existing;
            } else {
                $template = $template->replicate();
                $template->organization_id = $user->organization_id;
                $template->save();
            }
        }

        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'category' => ['nullable', Rule::in(array_keys(NotificationCatalog::CATEGORIES))],
            'roles' => ['sometimes', 'array'],
            'channel' => ['sometimes', Rule::in(NotificationCatalog::CHANNELS)],
            'channels' => ['sometimes', 'array'],
            'priority' => ['sometimes', Rule::in(NotificationCatalog::PRIORITIES)],
            'is_emergency' => ['sometimes', 'boolean'],
            'subject' => ['nullable', 'string', 'max:255'],
            'body' => ['sometimes', 'string'],
            'variables' => ['sometimes', 'array'],
            'is_active' => ['sometimes', 'boolean'],
        ]);

        $template->update($validated);
        ActivityLog::record('notification.template_updated', $template, $validated, $request);

        return response()->json([
            'message' => 'Notification template updated.',
            'data' => $template->fresh(),
        ]);
    }

    public function channels(Request $request): JsonResponse
    {
        abort_unless($request->user()->isSuperAdmin() || $request->user()->isOwner(), 403);

        $rows = NotificationChannelSetting::query()
            ->when(
                $request->user()->isOwner(),
                fn ($q) => $q->where(function ($inner) use ($request) {
                    $inner->whereNull('organization_id')
                        ->orWhere('organization_id', $request->user()->organization_id);
                })
            )
            ->whereIn('channel', NotificationCatalog::CHANNELS)
            ->orderBy('channel')
            ->get();

        if ($rows->isEmpty()) {
            $rows = collect(NotificationCatalog::CHANNELS)->map(fn (string $channel) => [
                'channel' => $channel,
                'enabled' => true,
                'provider' => match ($channel) {
                    'email' => 'smtp',
                    'whatsapp' => 'twilio_whatsapp',
                    default => 'in_app',
                },
                'organization_id' => null,
            ]);
        }

        return response()->json(['data' => $rows]);
    }

    public function updateChannel(Request $request): JsonResponse
    {
        abort_unless($request->user()->isSuperAdmin(), 403);

        $validated = $request->validate([
            'channel' => ['required', Rule::in(NotificationCatalog::CHANNELS)],
            'enabled' => ['required', 'boolean'],
            'provider' => ['nullable', 'string', 'max:80'],
            'config' => ['sometimes', 'array'],
            'organization_id' => ['nullable', 'exists:organizations,id'],
        ]);

        $setting = NotificationChannelSetting::query()->updateOrCreate(
            [
                'organization_id' => $validated['organization_id'] ?? null,
                'channel' => $validated['channel'],
            ],
            $validated
        );

        ActivityLog::record('notification.channel_updated', $setting, $validated, $request);

        return response()->json([
            'message' => 'Channel settings saved.',
            'data' => $setting,
        ]);
    }

    public function deliveryLogs(Request $request): JsonResponse
    {
        abort_unless($request->user()->isSuperAdmin(), 403);

        $perPage = min(100, max(1, (int) $request->integer('per_page', 25)));
        $logs = NotificationDelivery::query()
            ->with(['notification:id,title,recipient_user_id,organization_id,category,priority'])
            ->when($request->filled('status'), fn ($q) => $q->where('status', $request->string('status')))
            ->when($request->filled('channel'), fn ($q) => $q->where('channel', $request->string('channel')))
            ->latest()
            ->paginate($perPage);

        return response()->json([
            'data' => $logs->items(),
            'meta' => [
                'current_page' => $logs->currentPage(),
                'last_page' => $logs->lastPage(),
                'total' => $logs->total(),
            ],
        ]);
    }

    public function globalSettings(Request $request): JsonResponse
    {
        abort_unless($request->user()->isSuperAdmin(), 403);

        return response()->json([
            'data' => [
                'retry_max_attempts' => 5,
                'quiet_hours_honoured' => true,
                'emergency_alerts_forced' => true,
                'dedupe_window' => 'hourly',
                'realtime' => [
                    'driver' => config('broadcasting.default'),
                    'channel_pattern' => 'private-users.{userId}',
                    'event' => 'notification.created',
                ],
                'digest_frequencies' => ['none', 'daily', 'weekly'],
                'roles' => Roles::all(),
            ],
        ]);
    }

    private function unreadCountFor(int $userId): int
    {
        return AppNotification::query()
            ->where('recipient_user_id', $userId)
            ->whereNull('read_at')
            ->whereNull('archived_at')
            ->count();
    }

    /**
     * @return array<string, mixed>
     */
    private function serialize(AppNotification $notification, NotificationService $notifications): array
    {
        return [
            'id' => $notification->id,
            'organization_id' => $notification->organization_id,
            'recipient_user_id' => $notification->recipient_user_id,
            'recipient_role' => $notification->recipient_role,
            'category' => $notification->category,
            'category_label' => NotificationCatalog::label($notification->category),
            'title' => $notification->title,
            'message' => $notification->message,
            'body' => $notification->message,
            'priority' => $notification->priority,
            'module' => $notification->module,
            'record_type' => $notification->record_type,
            'record_id' => $notification->record_id,
            'action_url' => $notifications->secureActionUrl($notification) ?? $notification->action_url,
            'action_label' => $notification->action_label ?: 'Open',
            'channels' => $notification->channels,
            'scheduled_at' => $notification->scheduled_at,
            'sent_at' => $notification->sent_at,
            'delivery_status' => $notification->delivery_status,
            'read_at' => $notification->read_at,
            'archived_at' => $notification->archived_at,
            'is_emergency' => $notification->is_emergency,
            'group_key' => $notification->group_key,
            'template_key' => $notification->template_key,
            'created_at' => $notification->created_at,
            'property_name' => data_get($notification->payload, 'property_name')
                ?? data_get($notification->payload, 'variables.property_name'),
            'unit_number' => data_get($notification->payload, 'unit_number')
                ?? data_get($notification->payload, 'variables.unit_number'),
            'organisation_name' => data_get($notification->payload, 'organisation_name')
                ?? data_get($notification->payload, 'variables.organisation_name')
                ?? data_get($notification->payload, 'organization_name'),
        ];
    }
}
