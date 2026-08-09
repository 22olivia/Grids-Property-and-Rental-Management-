<?php

namespace App\Services\Notifications\Channels;

use App\Models\AppNotification;
use App\Models\NotificationDelivery;
use App\Services\EmailService;
use Illuminate\Support\Str;

class EmailNotificationChannel
{
    public function __construct(private readonly EmailService $emails) {}

    public function send(AppNotification $notification, NotificationDelivery $delivery): ChannelDeliveryResult
    {
        $recipient = $notification->recipient;
        $email = $recipient?->email;
        if (! $email) {
            return ChannelDeliveryResult::skipped('Recipient has no email address.');
        }

        $actionUrl = $notification->action_url
            ? url($notification->action_url)
            : rtrim((string) config('app.url'), '/').'/notifications';

        $log = $this->emails->queueNotification(
            toEmail: $email,
            toName: $recipient->name,
            subject: $notification->title,
            heading: $notification->title,
            bodyHtml: '<p>'.e($notification->message).'</p><p><a href="'.e($actionUrl).'">Open in GPMS</a></p>',
            user: $recipient,
            related: $notification,
            organizationId: $notification->organization_id,
        );

        $mailer = (string) config('mail.default', 'log');
        $simulated = in_array($mailer, ['log', 'array'], true);

        return ChannelDeliveryResult::sent(
            (string) ($log->provider_message_id ?: 'EMAIL-'.Str::upper(Str::random(10))),
            [
                'ok' => true,
                'channel' => 'email',
                'provider' => $log->provider,
                'email_log_id' => $log->id,
                'simulated' => $simulated,
                'to' => $email,
            ],
        );
    }
}
