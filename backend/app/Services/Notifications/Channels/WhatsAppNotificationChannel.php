<?php

namespace App\Services\Notifications\Channels;

use App\Models\AppNotification;
use App\Models\NotificationDelivery;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Str;

class WhatsAppNotificationChannel
{
    public function send(AppNotification $notification, NotificationDelivery $delivery): ChannelDeliveryResult
    {
        $recipient = $notification->recipient;
        $phone = $this->normalizePhone($recipient?->phone);
        if (! $phone) {
            return ChannelDeliveryResult::skipped('Recipient has no phone number for WhatsApp.');
        }

        $sid = (string) config('services.twilio.sid');
        $token = (string) config('services.twilio.token');
        $from = (string) config('services.twilio.whatsapp_from');
        $body = trim($notification->title."\n\n".$notification->message);
        if ($notification->action_url) {
            $body .= "\n\n".url($notification->action_url);
        }

        // Without Twilio credentials, keep an auditable simulated send so demos
        // and local installs still exercise the WhatsApp channel end-to-end.
        if ($sid === '' || $token === '' || $from === '') {
            $messageId = 'WA-SIM-'.Str::upper(Str::random(10));

            return ChannelDeliveryResult::sent($messageId, [
                'ok' => true,
                'channel' => 'whatsapp',
                'provider' => 'twilio_whatsapp',
                'simulated' => true,
                'to' => 'whatsapp:'.$phone,
                'from' => $from ?: 'whatsapp:+14155238886',
                'body_preview' => Str::limit($body, 160),
                'note' => 'Set TWILIO_ACCOUNT_SID, TWILIO_AUTH_TOKEN, and TWILIO_WHATSAPP_FROM to send real WhatsApp messages.',
            ]);
        }

        $to = str_starts_with($phone, 'whatsapp:') ? $phone : 'whatsapp:'.$phone;
        $response = Http::withBasicAuth($sid, $token)
            ->asForm()
            ->post("https://api.twilio.com/2010-04-01/Accounts/{$sid}/Messages.json", [
                'From' => $from,
                'To' => $to,
                'Body' => $body,
            ]);

        if (! $response->successful()) {
            return ChannelDeliveryResult::failed(
                'Twilio WhatsApp send failed: '.$response->body(),
                [
                    'ok' => false,
                    'status' => $response->status(),
                    'body' => $response->json() ?: $response->body(),
                ],
            );
        }

        $payload = $response->json() ?: [];

        return ChannelDeliveryResult::sent(
            (string) ($payload['sid'] ?? ('WA-'.Str::upper(Str::random(10)))),
            [
                'ok' => true,
                'channel' => 'whatsapp',
                'provider' => 'twilio_whatsapp',
                'simulated' => false,
                'to' => $to,
                'from' => $from,
                'twilio' => $payload,
            ],
        );
    }

    private function normalizePhone(?string $phone): ?string
    {
        if (! $phone) {
            return null;
        }

        $trimmed = preg_replace('/\s+/', '', $phone) ?: '';
        if ($trimmed === '') {
            return null;
        }

        if (str_starts_with($trimmed, 'whatsapp:')) {
            return substr($trimmed, strlen('whatsapp:'));
        }

        // Keep leading +, strip other punctuation.
        $normalized = preg_replace('/[^0-9+]/', '', $trimmed) ?: '';

        return $normalized !== '' ? $normalized : null;
    }
}
