<?php

namespace App\Services;

use App\Models\Contract;
use App\Models\Invoice;
use App\Models\MaintenanceRequest;
use App\Models\SupportTicket;
use App\Models\Tenant;
use App\Models\TenantCalendarEvent;
use App\Support\DomainCatalog;

class TenantCalendarService
{
    /**
     * Build a live tenant calendar from invoices, lease milestones,
     * maintenance visits, support tickets, plus any stored custom events.
     *
     * @return list<array<string, mixed>>
     */
    public function eventsFor(Tenant $tenant): array
    {
        $events = collect();

        $stored = TenantCalendarEvent::query()
            ->where('tenant_id', $tenant->id)
            ->orderBy('event_date')
            ->get();

        foreach ($stored as $row) {
            $events->push($this->normalize([
                'id' => 'stored-'.$row->id,
                'title' => $row->title,
                'type' => $row->type,
                'date' => optional($row->event_date)?->toDateString(),
                'all_day' => (bool) $row->all_day,
                'start_time' => $row->start_time,
                'end_time' => $row->end_time,
                'meta' => $row->meta ?: [],
            ]));
        }

        $lease = Contract::query()
            ->with(['rentalUnit.property'])
            ->where('tenant_id', $tenant->id)
            ->whereIn('status', ['active', 'expiring_soon', 'renewed', 'pending_signature', 'notice_given'])
            ->latest()
            ->first();

        if ($lease) {
            Invoice::query()
                ->where('contract_id', $lease->id)
                ->whereIn('status', ['unpaid', 'partially_paid', 'overdue', 'pending', 'draft'])
                ->orderBy('due_date')
                ->get()
                ->each(function (Invoice $invoice) use ($events) {
                    if (! $invoice->due_date) {
                        return;
                    }
                    $events->push($this->normalize([
                        'id' => 'invoice-'.$invoice->id,
                        'title' => 'Rent due · '.$invoice->invoice_number,
                        'type' => 'rent_due',
                        'date' => $invoice->due_date->toDateString(),
                        'all_day' => true,
                        'meta' => [
                            'invoice_id' => $invoice->id,
                            'invoice_number' => $invoice->invoice_number,
                            'amount' => $invoice->remaining_balance,
                            'status' => $invoice->status,
                        ],
                    ]));
                });

            if ($lease->end_date) {
                $events->push($this->normalize([
                    'id' => 'lease-end-'.$lease->id,
                    'title' => 'Lease expiry',
                    'type' => 'lease_expiry',
                    'date' => $lease->end_date->toDateString(),
                    'all_day' => true,
                    'meta' => ['lease_number' => $lease->contract_number],
                ]));

                $renewal = $lease->end_date->copy()->subDays(30);
                if ($renewal->isFuture() || $renewal->isToday()) {
                    $events->push($this->normalize([
                        'id' => 'lease-renewal-'.$lease->id,
                        'title' => 'Renewal deadline',
                        'type' => 'renewal_deadline',
                        'date' => $renewal->toDateString(),
                        'all_day' => true,
                        'meta' => ['lease_number' => $lease->contract_number],
                    ]));
                }
            }
        }

        MaintenanceRequest::query()
            ->where('tenant_id', $tenant->id)
            ->whereNotIn('status', ['closed', 'cancelled', 'resolved'])
            ->whereNotIn('workflow_status', [DomainCatalog::CLOSED, DomainCatalog::COMPLETED])
            ->orderBy('id')
            ->get()
            ->each(function (MaintenanceRequest $ticket) use ($events) {
                $date = $ticket->scheduled_date?->toDateString()
                    ?: optional($ticket->preferred_visit_date)?->toDateString()
                    ?: optional($ticket->reported_at)?->toDateString()
                    ?: optional($ticket->created_at)?->toDateString();
                if (! $date) {
                    return;
                }

                $events->push($this->normalize([
                    'id' => 'maintenance-'.$ticket->id,
                    'title' => 'Maintenance · '.($ticket->ticket_number ?: $ticket->title),
                    'type' => $ticket->scheduled_date || $ticket->preferred_visit_date
                        ? 'maintenance_visit'
                        : 'maintenance_request',
                    'date' => $date,
                    'all_day' => ! $ticket->scheduled_date,
                    'start_time' => $ticket->scheduled_date?->format('H:i'),
                    'meta' => [
                        'ticket' => $ticket->ticket_number,
                        'ticket_id' => $ticket->id,
                        'status' => $ticket->status,
                        'priority' => $ticket->priority,
                    ],
                ]));
            });

        if ($tenant->user_id) {
            SupportTicket::query()
                ->where('user_id', $tenant->user_id)
                ->whereNotIn('status', ['closed', 'resolved', 'cancelled'])
                ->orderByDesc('id')
                ->limit(50)
                ->get()
                ->each(function (SupportTicket $ticket) use ($events) {
                    $date = optional($ticket->created_at)?->toDateString();
                    if (! $date) {
                        return;
                    }
                    $events->push($this->normalize([
                        'id' => 'support-'.$ticket->id,
                        'title' => 'Support · '.($ticket->ticket_number ?: $ticket->subject),
                        'type' => 'support_ticket',
                        'date' => $date,
                        'all_day' => true,
                        'meta' => [
                            'ticket' => $ticket->ticket_number,
                            'ticket_id' => $ticket->id,
                            'status' => $ticket->status,
                            'category' => $ticket->category,
                        ],
                    ]));
                });
        }

        return $events
            ->filter(fn ($row) => ! empty($row['date']))
            ->unique(fn ($row) => $row['id'])
            ->sortBy('date')
            ->values()
            ->all();
    }

    /**
     * Persist a calendar row when a maintenance ticket is scheduled/created.
     */
    public function syncMaintenanceEvent(MaintenanceRequest $ticket): ?TenantCalendarEvent
    {
        if (! $ticket->tenant_id) {
            return null;
        }

        $date = $ticket->scheduled_date?->toDateString()
            ?: optional($ticket->preferred_visit_date)?->toDateString()
            ?: optional($ticket->created_at)?->toDateString();
        if (! $date) {
            return null;
        }

        $existing = TenantCalendarEvent::query()
            ->where('tenant_id', $ticket->tenant_id)
            ->whereIn('type', ['maintenance_visit', 'maintenance_request'])
            ->get()
            ->first(fn (TenantCalendarEvent $row) => (int) data_get($row->meta, 'ticket_id') === (int) $ticket->id);

        $payload = [
            'tenant_id' => $ticket->tenant_id,
            'title' => 'Maintenance · '.($ticket->ticket_number ?: $ticket->title),
            'type' => $ticket->scheduled_date || $ticket->preferred_visit_date
                ? 'maintenance_visit'
                : 'maintenance_request',
            'event_date' => $date,
            'all_day' => ! $ticket->scheduled_date,
            'start_time' => $ticket->scheduled_date?->format('H:i'),
            'end_time' => null,
            'meta' => [
                'ticket' => $ticket->ticket_number,
                'ticket_id' => $ticket->id,
                'status' => $ticket->status,
                'priority' => $ticket->priority,
            ],
        ];

        if ($existing) {
            $existing->fill($payload)->save();

            return $existing;
        }

        return TenantCalendarEvent::query()->create($payload);
    }

    /**
     * Persist a calendar row when a support ticket is opened by a tenant.
     */
    public function syncSupportEvent(SupportTicket $ticket, Tenant $tenant): ?TenantCalendarEvent
    {
        $date = optional($ticket->created_at)?->toDateString() ?: now()->toDateString();
        $existing = TenantCalendarEvent::query()
            ->where('tenant_id', $tenant->id)
            ->where('type', 'support_ticket')
            ->get()
            ->first(fn (TenantCalendarEvent $row) => (int) data_get($row->meta, 'ticket_id') === (int) $ticket->id);

        $payload = [
            'tenant_id' => $tenant->id,
            'title' => 'Support · '.($ticket->ticket_number ?: $ticket->subject),
            'type' => 'support_ticket',
            'event_date' => $date,
            'all_day' => true,
            'start_time' => null,
            'end_time' => null,
            'meta' => [
                'ticket' => $ticket->ticket_number,
                'ticket_id' => $ticket->id,
                'status' => $ticket->status,
                'category' => $ticket->category,
            ],
        ];

        if ($existing) {
            $existing->fill($payload)->save();

            return $existing;
        }

        return TenantCalendarEvent::query()->create($payload);
    }

    /**
     * @param  array<string, mixed>  $row
     * @return array<string, mixed>
     */
    private function normalize(array $row): array
    {
        return [
            'id' => $row['id'],
            'title' => $row['title'],
            'type' => $row['type'],
            'date' => $row['date'],
            'all_day' => (bool) ($row['all_day'] ?? true),
            'start_time' => $row['start_time'] ?? null,
            'end_time' => $row['end_time'] ?? null,
            'meta' => $row['meta'] ?? [],
        ];
    }
}
