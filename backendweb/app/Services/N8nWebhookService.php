<?php

namespace App\Services;

use App\Models\SupportTicket;
use App\Models\User;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;

/**
 * Push GPMS events to n8n Cloud webhooks (automation glue).
 * Failures are logged and never block ticket creation.
 */
class N8nWebhookService
{
    /**
     * After a support ticket is persisted, POST its real ID to n8n.
     *
     * @return array{attempted: bool, ok: bool, status: string, message: string, http_status?: int}
     */
    public function ticketCreated(SupportTicket $ticket, ?User $actor = null): array
    {
        $url = (string) config('services.n8n.ticket_webhook_url', '');
        if ($url === '' || ! filter_var($url, FILTER_VALIDATE_URL)) {
            return [
                'attempted' => false,
                'ok' => false,
                'status' => 'skipped',
                'message' => 'N8N_WEBHOOK_TICKET_URL is not configured.',
            ];
        }

        if (! (bool) config('services.n8n.enabled', true)) {
            return [
                'attempted' => false,
                'ok' => false,
                'status' => 'disabled',
                'message' => 'n8n webhooks are disabled.',
            ];
        }

        // UUID primary key from support_tickets.id (HasUuids) — never hardcoded / never "ping".
        $ticketId = (string) $ticket->getKey();
        if ($ticketId === '') {
            return [
                'attempted' => false,
                'ok' => false,
                'status' => 'skipped',
                'message' => 'Ticket has no persisted id; n8n webhook not sent.',
            ];
        }

        $payload = [
            'event' => 'support_ticket_created',
            'source' => 'gpms',
            'ticket' => [
                'id' => $ticketId,
            ],
        ];

        $headers = [
            'Accept' => 'application/json',
            'Content-Type' => 'application/json',
        ];
        $secret = (string) config('services.n8n.webhook_secret', '');
        if ($secret !== '') {
            $headers['X-GPMS-N8N-Secret'] = $secret;
        }

        try {
            $response = Http::timeout(12)
                ->withHeaders($headers)
                ->post($url, $payload);

            if ($response->successful()) {
                return [
                    'attempted' => true,
                    'ok' => true,
                    'status' => 'sent',
                    'message' => 'n8n webhook accepted.',
                    'http_status' => $response->status(),
                ];
            }

            Log::warning('n8n ticket webhook rejected', [
                'status' => $response->status(),
                'body' => $response->body(),
                'ticket_id' => $ticketId,
            ]);

            return [
                'attempted' => true,
                'ok' => false,
                'status' => 'failed',
                'message' => 'n8n webhook HTTP '.$response->status(),
                'http_status' => $response->status(),
            ];
        } catch (\Throwable $e) {
            Log::warning('n8n ticket webhook exception', [
                'message' => $e->getMessage(),
                'ticket_id' => $ticketId,
            ]);

            return [
                'attempted' => true,
                'ok' => false,
                'status' => 'failed',
                'message' => $e->getMessage(),
            ];
        }
    }
}
