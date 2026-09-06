<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\SupportTicket;
use Illuminate\Http\JsonResponse;

/**
 * Super-admin visibility into outbound n8n ticket webhooks.
 * Config remains env-based (N8N_*); this endpoint never exposes secrets.
 */
class N8nController extends Controller
{
    public function status(): JsonResponse
    {
        $url = (string) config('services.n8n.ticket_webhook_url', '');
        $enabled = (bool) config('services.n8n.enabled', true);
        $secret = (string) config('services.n8n.webhook_secret', '');
        $validUrl = $url !== '' && filter_var($url, FILTER_VALIDATE_URL);

        $host = null;
        $path = null;
        if ($validUrl) {
            $parts = parse_url($url);
            $host = $parts['host'] ?? null;
            $path = $parts['path'] ?? null;
        }

        $recent = SupportTicket::query()
            ->with(['assignee:id,name,email,role', 'user:id,name,email'])
            ->latest()
            ->limit(25)
            ->get()
            ->map(fn (SupportTicket $ticket) => [
                'id' => $ticket->id,
                'ticket_number' => $ticket->ticket_number,
                'subject' => $ticket->subject,
                'status' => $ticket->status,
                'assigned_to' => $ticket->assigned_to,
                'assignee' => $ticket->assignee
                    ? [
                        'id' => $ticket->assignee->id,
                        'name' => $ticket->assignee->name,
                        'email' => $ticket->assignee->email,
                        'role' => $ticket->assignee->role,
                    ]
                    : null,
                'requester' => $ticket->user
                    ? [
                        'id' => $ticket->user->id,
                        'name' => $ticket->user->name,
                        'email' => $ticket->user->email,
                    ]
                    : null,
                'created_at' => optional($ticket->created_at)?->toIso8601String(),
                'assigned_at' => optional($ticket->assigned_at)?->toIso8601String(),
            ])
            ->values();

        return response()->json([
            'data' => [
                'enabled' => $enabled,
                'webhook_configured' => $validUrl,
                'webhook_host' => $host,
                'webhook_path' => $path,
                'secret_configured' => $secret !== '',
                'event' => 'support_ticket_created',
                'payload_shape' => [
                    'event' => 'support_ticket_created',
                    'source' => 'gpms',
                    'ticket' => ['id' => '<uuid>'],
                ],
                'assign_path' => '/api/v1/support/tickets/{id}/assign',
                'recent_tickets' => $recent,
            ],
        ]);
    }
}
