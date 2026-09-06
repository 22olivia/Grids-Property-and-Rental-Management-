<?php

namespace App\Services;

use App\Models\Contract;
use App\Models\Payment;
use App\Notifications\TenantReminderNotification;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class RentalAutomationService
{
    /**
     * Run the automation bundle synchronously and return a summary.
     * Used by demo button and artisan command.
     *
     * @return array{
     *     generated_payments: int,
     *     marked_overdue: int,
     *     reminders: int,
     *     expiring_leases: int,
     *     expiry_reminders: int,
     *     ran_at: string,
     *     changes: array{
     *         generated: list<array{id:int,reference:?string,period:?string,status:string,amount:string}>,
     *         marked_overdue: list<array{id:int,reference:?string,period:?string,status:string,amount:string}>,
     *         reminders: list<array{payment_id:int,tenant:?string}>,
     *         expiry_reminders: list<array{contract_id:int,tenant:?string,end_date:?string}>
     *     },
     *     plain_summary: string
     * }
     */
    public function run(): array
    {
        $leaseService = app(LeaseService::class);
        $invoiceService = app(InvoiceService::class);

        $expired = $leaseService->markExpired();
        $expiringMarked = $leaseService->markExpiringSoon();
        $generatedInvoices = $invoiceService->generateForActiveLeases();
        $generatedItems = $this->generateDuePayments();
        $overdueItems = $this->markOverduePayments();
        $reminderItems = $this->sendPaymentReminders();
        $expiryItems = $this->sendLeaseExpiryReminders();
        $expiring = $this->countExpiringLeases();

        $summary = [
            'generated_payments' => count($generatedItems),
            'generated_invoices' => $generatedInvoices,
            'marked_overdue' => count($overdueItems),
            'reminders' => count($reminderItems),
            'expiring_leases' => $expiring,
            'expiry_reminders' => count($expiryItems),
            'leases_marked_expiring' => $expiringMarked,
            'leases_marked_expired' => $expired,
            'ran_at' => now()->toIso8601String(),
            'changes' => [
                'generated' => $generatedItems,
                'marked_overdue' => $overdueItems,
                'reminders' => $reminderItems,
                'expiry_reminders' => $expiryItems,
            ],
        ];

        $summary['plain_summary'] = $this->buildPlainSummary($summary);

        return $summary;
    }

    /**
     * Reset demo payments so "Run Automation" can be shown again.
     *
     * @return array{reset_overdue_demo: bool, removed_auto_payments: int, message: string}
     */
    public function resetDemo(): array
    {
        $reset = Payment::query()
            ->where('reference', 'PAY-DEMO-OVERDUE-01')
            ->update([
                'status' => 'pending',
                'paid_at' => null,
                'method' => null,
                'notes' => 'Should become overdue when automation runs',
            ]) > 0;

        $removed = Payment::query()
            ->where('notes', 'like', 'Auto-generated rent for %')
            ->delete();

        return [
            'reset_overdue_demo' => $reset,
            'removed_auto_payments' => $removed,
            'message' => 'Demo reset. Open Payments, then click Run rent jobs again.',
        ];
    }

    /**
     * Create the current-period rent payment for each active contract if missing.
     * SRS: GPMS-FR-LSE-003 / FIN-001 recurring billing.
     *
     * @return list<array{id:int,reference:?string,period:?string,status:string,amount:string}>
     */
    public function generateDuePayments(?Carbon $asOf = null): array
    {
        $asOf ??= now();
        $period = $asOf->format('Y-m');
        $created = [];

        Contract::query()
            ->where('status', 'active')
            ->each(function (Contract $contract) use ($asOf, $period, &$created): void {
                $exists = Payment::query()
                    ->where('contract_id', $contract->id)
                    ->where('period', $period)
                    ->exists();

                if ($exists) {
                    return;
                }

                $day = min(max((int) $contract->payment_day, 1), 28);
                $dueDate = $asOf->copy()->day($day);

                $payment = Payment::query()->create([
                    'contract_id' => $contract->id,
                    'reference' => 'PAY-'.strtoupper(Str::random(10)),
                    'amount' => $contract->monthly_rent,
                    'due_date' => $dueDate->toDateString(),
                    'status' => $dueDate->isPast() ? 'overdue' : 'pending',
                    'period' => $period,
                    'notes' => 'Auto-generated rent for '.$period,
                ]);

                $created[] = $this->paymentSnippet($payment);
            });

        return $created;
    }

    /**
     * Mark pending payments past due date as overdue.
     * SRS: collections / aging workflow.
     *
     * @return list<array{id:int,reference:?string,period:?string,status:string,amount:string}>
     */
    public function markOverduePayments(?Carbon $asOf = null): array
    {
        $asOf ??= now();

        $pending = Payment::query()
            ->where('status', 'pending')
            ->whereDate('due_date', '<', $asOf->toDateString())
            ->get();

        if ($pending->isEmpty()) {
            return [];
        }

        Payment::query()
            ->whereIn('id', $pending->pluck('id'))
            ->update(['status' => 'overdue']);

        return $pending->map(function (Payment $payment) {
            $payment->status = 'overdue';

            return $this->paymentSnippet($payment);
        })->all();
    }

    /**
     * Send rent/overdue reminders (email via notification + queue when enabled).
     * SRS: GPMS-FR-NOT-005
     *
     * @return list<array{payment_id:int,tenant:?string}>
     */
    public function sendPaymentReminders(): array
    {
        $sent = [];

        Payment::query()
            ->whereIn('status', ['pending', 'overdue'])
            ->with('contract.tenant')
            ->each(function (Payment $payment) use (&$sent): void {
                $tenant = $payment->contract?->tenant;

                if (! $tenant || blank($tenant->email)) {
                    Log::warning('Skipped rent reminder: missing tenant email', [
                        'payment_id' => $payment->id,
                    ]);

                    return;
                }

                $tenant->notify(TenantReminderNotification::rent($payment));
                $sent[] = [
                    'payment_id' => $payment->id,
                    'tenant' => $tenant->full_name,
                ];
            });

        return $sent;
    }

    /**
     * Notify tenants of leases expiring within 30 days.
     * SRS: GPMS-FR-LSE-005 / NOT-005
     *
     * @return list<array{contract_id:int,tenant:?string,end_date:?string}>
     */
    public function sendLeaseExpiryReminders(?Carbon $asOf = null): array
    {
        $asOf ??= now();
        $sent = [];

        Contract::query()
            ->where('status', 'active')
            ->whereNotNull('end_date')
            ->whereBetween('end_date', [
                $asOf->toDateString(),
                $asOf->copy()->addDays(30)->toDateString(),
            ])
            ->with('tenant')
            ->each(function (Contract $contract) use (&$sent): void {
                $tenant = $contract->tenant;

                if (! $tenant || blank($tenant->email)) {
                    return;
                }

                $tenant->notify(TenantReminderNotification::leaseExpiry($contract));
                $sent[] = [
                    'contract_id' => $contract->id,
                    'tenant' => $tenant->full_name,
                    'end_date' => optional($contract->end_date)->toDateString()
                        ?? (string) $contract->end_date,
                ];
            });

        return $sent;
    }

    /**
     * Count active leases expiring within 30 days.
     */
    public function countExpiringLeases(?Carbon $asOf = null): int
    {
        $asOf ??= now();

        return Contract::query()
            ->where('status', 'active')
            ->whereNotNull('end_date')
            ->whereBetween('end_date', [
                $asOf->toDateString(),
                $asOf->copy()->addDays(30)->toDateString(),
            ])
            ->count();
    }

    /**
     * @return array{id:int,reference:?string,period:?string,status:string,amount:string}
     */
    private function paymentSnippet(Payment $payment): array
    {
        return [
            'id' => $payment->id,
            'reference' => $payment->reference,
            'period' => $payment->period,
            'status' => $payment->status,
            'amount' => (string) $payment->amount,
        ];
    }

    /**
     * @param  array<string, mixed>  $summary
     */
    private function buildPlainSummary(array $summary): string
    {
        $parts = [];

        if ($summary['generated_payments'] > 0) {
            $parts[] = "Created {$summary['generated_payments']} new rent bill(s) for this month";
        } else {
            $parts[] = 'No new rent bills needed (already created for this month)';
        }

        if ($summary['marked_overdue'] > 0) {
            $parts[] = "Marked {$summary['marked_overdue']} late payment(s) as overdue";
        } else {
            $parts[] = 'No payments needed to mark overdue';
        }

        $parts[] = "Queued {$summary['reminders']} rent reminder email(s)";
        $parts[] = "Queued {$summary['expiry_reminders']} lease-expiry reminder(s)";

        return implode('. ', $parts).'.';
    }
}
