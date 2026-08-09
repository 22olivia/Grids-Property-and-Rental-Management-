<?php

namespace App\Services;

use App\Events\NotificationCreated;
use App\Jobs\DeliverNotificationJob;
use App\Models\AppNotification;
use App\Models\NotificationChannelSetting;
use App\Models\NotificationDelivery;
use App\Models\NotificationPreference;
use App\Models\NotificationTemplate;
use App\Models\User;
use App\Services\Notifications\Channels\ChannelDeliveryResult;
use App\Services\Notifications\Channels\EmailNotificationChannel;
use App\Services\Notifications\Channels\WhatsAppNotificationChannel;
use App\Support\NotificationCatalog;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;

class NotificationService
{
    public function __construct(
        private readonly EmailNotificationChannel $emailChannel,
        private readonly WhatsAppNotificationChannel $whatsappChannel,
    ) {}

    /**
     * @param  array<string, mixed>  $data
     */
    public function notify(User $recipient, string $eventKey, array $data = []): ?AppNotification
    {
        $role = $recipient->normalizedRole();
        $variables = $this->baseVariables($recipient, $data);
        $template = $this->resolveTemplate($eventKey, $recipient->organization_id, $role);
        $rendered = $this->renderTemplate($template, $variables, $data);

        $priority = $data['priority']
            ?? $template?->priority
            ?? ($data['is_emergency'] ?? false ? 'critical' : 'normal');
        $isEmergency = (bool) ($data['is_emergency'] ?? $template?->is_emergency ?? false)
            || $priority === 'critical';

        $category = $data['category']
            ?? $template?->category
            ?? $this->inferCategory($eventKey);

        $channels = $this->resolveChannels($recipient, $category, $isEmergency, $data['channels'] ?? null);
        if ($channels === []) {
            return null;
        }

        $dedupeKey = $data['dedupe_key']
            ?? hash('sha256', implode('|', [
                $recipient->id,
                $eventKey,
                (string) ($data['record_type'] ?? ''),
                (string) ($data['record_id'] ?? ''),
                (string) ($data['group_key'] ?? ''),
                Carbon::now()->format('Y-m-d-H'),
            ]));

        if (AppNotification::query()->where('dedupe_key', $dedupeKey)->exists()) {
            return AppNotification::query()->where('dedupe_key', $dedupeKey)->first();
        }

        $scheduledAt = isset($data['scheduled_at'])
            ? Carbon::parse($data['scheduled_at'])
            : null;

        $notification = DB::transaction(function () use (
            $recipient,
            $role,
            $category,
            $rendered,
            $priority,
            $isEmergency,
            $channels,
            $dedupeKey,
            $scheduledAt,
            $eventKey,
            $data,
        ) {
            $notification = AppNotification::query()->create([
                'organization_id' => $data['organization_id'] ?? $recipient->organization_id,
                'recipient_user_id' => $recipient->id,
                'recipient_role' => $role,
                'category' => $category,
                'title' => $rendered['title'],
                'message' => $rendered['message'],
                'priority' => $priority,
                'module' => $data['module'] ?? explode('.', $eventKey)[0] ?? null,
                'record_type' => $data['record_type'] ?? null,
                'record_id' => isset($data['record_id']) ? (string) $data['record_id'] : null,
                'action_url' => $rendered['action_url'],
                'action_label' => $data['action_label'] ?? 'Open',
                'template_key' => $eventKey,
                'dedupe_key' => $dedupeKey,
                'channels' => $channels,
                'payload' => $data['payload'] ?? $data,
                'group_key' => $data['group_key'] ?? ($category.'|'.$eventKey),
                'scheduled_at' => $scheduledAt,
                'delivery_status' => $scheduledAt && $scheduledAt->isFuture() ? 'pending' : 'queued',
                'is_emergency' => $isEmergency,
            ]);

            foreach ($channels as $channel) {
                NotificationDelivery::query()->create([
                    'app_notification_id' => $notification->id,
                    'channel' => $channel,
                    'status' => 'pending',
                    'provider' => $this->providerFor($channel, $notification->organization_id),
                ]);
            }

            return $notification;
        });

        if (! $scheduledAt || $scheduledAt->isPast()) {
            DeliverNotificationJob::dispatch($notification->id);
        }

        event(new NotificationCreated($notification));

        return $notification;
    }

    public function secureActionUrl(AppNotification $notification): ?string
    {
        if (! $notification->action_url) {
            return null;
        }

        $signature = hash_hmac(
            'sha256',
            $notification->id.'|'.$notification->recipient_user_id.'|'.$notification->action_url,
            (string) config('app.key'),
        );

        $separator = str_contains($notification->action_url, '?') ? '&' : '?';

        return $notification->action_url.$separator.'nid='.$notification->id.'&nsig='.substr($signature, 0, 32);
    }

    /**
     * @param  iterable<int, User>  $recipients
     * @param  array<string, mixed>  $data
     * @return list<AppNotification>
     */
    public function notifyMany(iterable $recipients, string $eventKey, array $data = []): array
    {
        $created = [];
        foreach ($recipients as $recipient) {
            $notification = $this->notify($recipient, $eventKey, $data);
            if ($notification) {
                $created[] = $notification;
            }
        }

        return $created;
    }

    public function deliver(AppNotification $notification): void
    {
        if ($notification->scheduled_at && $notification->scheduled_at->isFuture()) {
            return;
        }

        $notification->loadMissing('deliveries', 'recipient');
        foreach ($notification->deliveries as $delivery) {
            if (in_array($delivery->status, ['sent', 'skipped'], true)) {
                continue;
            }

            if ($delivery->next_retry_at && $delivery->next_retry_at->isFuture()) {
                continue;
            }

            $this->deliverChannel($notification, $delivery);
        }

        $statuses = $notification->deliveries()->pluck('status');
        $notification->forceFill([
            'sent_at' => now(),
            'delivery_status' => $statuses->every(fn ($s) => $s === 'sent')
                ? 'sent'
                : ($statuses->contains('sent') ? 'partial' : 'failed'),
        ])->save();
    }

    public function retryFailed(): int
    {
        $rows = NotificationDelivery::query()
            ->whereIn('status', ['failed', 'retrying'])
            ->where(function ($q) {
                $q->whereNull('next_retry_at')->orWhere('next_retry_at', '<=', now());
            })
            ->where('attempts', '<', 5)
            ->limit(100)
            ->get();

        foreach ($rows as $delivery) {
            DeliverNotificationJob::dispatch($delivery->app_notification_id);
        }

        return $rows->count();
    }

    public function dispatchDueScheduled(): int
    {
        $rows = AppNotification::query()
            ->where('delivery_status', 'pending')
            ->whereNotNull('scheduled_at')
            ->where('scheduled_at', '<=', now())
            ->limit(100)
            ->get();

        foreach ($rows as $notification) {
            $notification->update(['delivery_status' => 'queued']);
            DeliverNotificationJob::dispatch($notification->id);
        }

        return $rows->count();
    }

    /**
     * @param  array<string, mixed>  $variables
     */
    public function render(string $body, array $variables): string
    {
        return preg_replace_callback('/\{\{\s*([a-zA-Z0-9_]+)\s*\}\}/', function ($matches) use ($variables) {
            $key = $matches[1];

            return (string) ($variables[$key] ?? '');
        }, $body) ?? $body;
    }

    private function deliverChannel(AppNotification $notification, NotificationDelivery $delivery): void
    {
        $delivery->attempts++;
        try {
            if (! $this->channelEnabled($delivery->channel, $notification->organization_id)) {
                $delivery->forceFill([
                    'status' => 'skipped',
                    'error_message' => 'Channel disabled for organisation.',
                ])->save();

                return;
            }

            $result = $this->dispatchToChannel($notification, $delivery);
            if ($result->status === 'failed') {
                throw new \RuntimeException($result->errorMessage ?: 'Channel delivery failed.');
            }

            $delivery->forceFill([
                'status' => $result->status,
                'provider_message_id' => $result->providerMessageId,
                'provider_response' => $result->providerResponse + [
                    'recipient_user_id' => $notification->recipient_user_id,
                ],
                'sent_at' => $result->status === 'sent' ? now() : $delivery->sent_at,
                'error_message' => $result->errorMessage,
                'next_retry_at' => null,
            ])->save();
        } catch (\Throwable $e) {
            $attempts = $delivery->attempts;
            $delivery->forceFill([
                'status' => $attempts >= 5 ? 'failed' : 'retrying',
                'error_message' => $e->getMessage(),
                'next_retry_at' => now()->addMinutes(min(60, 2 ** $attempts)),
                'provider_response' => ['ok' => false, 'error' => $e->getMessage()],
            ])->save();
        }
    }

    private function dispatchToChannel(
        AppNotification $notification,
        NotificationDelivery $delivery,
    ): ChannelDeliveryResult {
        return match ($delivery->channel) {
            'email' => $this->emailChannel->send($notification, $delivery),
            'whatsapp' => $this->whatsappChannel->send($notification, $delivery),
            'in_app' => ChannelDeliveryResult::sent(
                'INAPP-'.Str::upper(Str::random(8)),
                ['ok' => true, 'channel' => 'in_app', 'simulated' => false],
            ),
            default => ChannelDeliveryResult::skipped('Unsupported channel: '.$delivery->channel),
        };
    }

    private function resolveTemplate(string $eventKey, ?int $organizationId, string $role): ?NotificationTemplate
    {
        return NotificationTemplate::query()
            ->where('key', $eventKey)
            ->where('is_active', true)
            ->where(function ($q) use ($organizationId) {
                $q->whereNull('organization_id');
                if ($organizationId) {
                    $q->orWhere('organization_id', $organizationId);
                }
            })
            ->orderByRaw('organization_id is null') // org-specific first when present
            ->get()
            ->first(function (NotificationTemplate $template) use ($role) {
                $roles = $template->roles ?: [];

                return $roles === [] || in_array($role, $roles, true);
            });
    }

    /**
     * @param  array<string, mixed>  $variables
     * @param  array<string, mixed>  $data
     * @return array{title: string, message: string, action_url: ?string}
     */
    private function renderTemplate(?NotificationTemplate $template, array $variables, array $data): array
    {
        $title = $data['title'] ?? $template?->subject ?? $template?->name ?? 'Notification';
        $message = $data['message'] ?? $data['body'] ?? $template?->body ?? 'You have a new notification.';
        $action = $data['action_url'] ?? $variables['action_link'] ?? null;

        return [
            'title' => $this->render($title, $variables),
            'message' => $this->render($message, $variables),
            'action_url' => $action ? $this->render($action, $variables) : null,
        ];
    }

    /**
     * @param  array<string, mixed>  $data
     * @return array<string, mixed>
     */
    private function baseVariables(User $recipient, array $data): array
    {
        return array_merge([
            'user_name' => $recipient->name,
            'organisation_name' => $recipient->organization?->name,
            'action_link' => $data['action_url'] ?? '/notifications',
        ], $data['variables'] ?? [], collect($data)->only(NotificationCatalog::templateVariables())->all());
    }

    /**
     * @param  list<string>|null  $requested
     * @return list<string>
     */
    private function resolveChannels(User $recipient, string $category, bool $isEmergency, ?array $requested): array
    {
        $prefs = NotificationPreference::query()->firstOrCreate(
            ['user_id' => $recipient->id],
            [
                'in_app' => true,
                'email' => true,
                'whatsapp' => true,
                'categories' => array_fill_keys(array_keys(NotificationCatalog::CATEGORIES), true),
                'preferred_language' => 'en',
                'digest_frequency' => 'none',
                'emergency_override' => true,
            ],
        );

        $categoryEnabled = data_get($prefs->categories, $category, true);
        if (! $categoryEnabled && ! ($isEmergency && $prefs->emergency_override)) {
            return [];
        }

        if ($this->inQuietHours($prefs) && ! ($isEmergency && $prefs->emergency_override)) {
            $requested = ['in_app'];
        }

        $byCategory = $prefs->channel_by_category[$category] ?? null;
        $channels = $requested
            ?? $byCategory
            ?? array_values(array_filter(NotificationCatalog::CHANNELS, function (string $channel) use ($prefs) {
                return (bool) data_get($prefs, $channel, false);
            }));

        if ($isEmergency && $prefs->emergency_override) {
            $channels = array_values(array_unique(array_merge($channels, ['in_app', 'email', 'whatsapp'])));
        }

        return array_values(array_intersect(NotificationCatalog::CHANNELS, $channels));
    }

    private function inQuietHours(NotificationPreference $prefs): bool
    {
        if (! $prefs->quiet_hours_start || ! $prefs->quiet_hours_end) {
            return false;
        }

        $now = now()->format('H:i:s');
        $start = (string) $prefs->quiet_hours_start;
        $end = (string) $prefs->quiet_hours_end;

        if ($start <= $end) {
            return $now >= $start && $now <= $end;
        }

        return $now >= $start || $now <= $end;
    }

    private function channelEnabled(string $channel, ?int $organizationId): bool
    {
        $setting = NotificationChannelSetting::query()
            ->where('channel', $channel)
            ->where(function ($q) use ($organizationId) {
                $q->whereNull('organization_id');
                if ($organizationId) {
                    $q->orWhere('organization_id', $organizationId);
                }
            })
            ->orderByRaw('organization_id is null')
            ->first();

        return $setting?->enabled ?? true;
    }

    private function providerFor(string $channel, ?int $organizationId): string
    {
        $setting = NotificationChannelSetting::query()
            ->where('channel', $channel)
            ->where(function ($q) use ($organizationId) {
                $q->whereNull('organization_id');
                if ($organizationId) {
                    $q->orWhere('organization_id', $organizationId);
                }
            })
            ->orderByRaw('organization_id is null')
            ->first();

        return $setting?->provider ?: match ($channel) {
            'email' => 'smtp',
            'whatsapp' => 'twilio_whatsapp',
            default => 'in_app',
        };
    }

    private function inferCategory(string $eventKey): string
    {
        return match (true) {
            str_starts_with($eventKey, 'subscription') => 'subscription_billing',
            str_starts_with($eventKey, 'security') || str_starts_with($eventKey, 'account') => 'account_security',
            str_starts_with($eventKey, 'property') || str_starts_with($eventKey, 'unit') => 'property_unit',
            str_starts_with($eventKey, 'listing') || str_starts_with($eventKey, 'lead') || str_starts_with($eventKey, 'enquiry') || str_starts_with($eventKey, 'offer') || str_starts_with($eventKey, 'visit') => 'listing_lead',
            str_starts_with($eventKey, 'lease') => 'lease',
            str_starts_with($eventKey, 'invoice') || str_starts_with($eventKey, 'payment') || str_starts_with($eventKey, 'rent') || str_starts_with($eventKey, 'receipt') || str_starts_with($eventKey, 'refund') || str_starts_with($eventKey, 'deposit') || str_starts_with($eventKey, 'balance') || str_starts_with($eventKey, 'owner') => 'rent_payment',
            str_starts_with($eventKey, 'maintenance') || str_starts_with($eventKey, 'quotation') => 'maintenance',
            str_starts_with($eventKey, 'document') => 'documents',
            str_starts_with($eventKey, 'announcement') => 'announcement',
            str_contains($eventKey, 'approval') || str_contains($eventKey, 'approved') || str_contains($eventKey, 'rejected') => 'approval',
            default => 'system',
        };
    }
}
