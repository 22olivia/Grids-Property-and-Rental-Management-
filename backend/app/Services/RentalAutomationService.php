<?php

namespace App\Services;

use App\Models\Contract;
use App\Models\Payment;
use App\Notifications\LeaseExpiryReminderNotification;
use App\Notifications\RentPaymentReminderNotification;
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
     *     ran_at: string
     * }
     */
    public function run(): array
    {
        $generated = $this->generateDuePayments();
        $overdue = $this->markOverduePayments();
        $reminders = $this->sendPaymentReminders();
        $expiryReminders = $this->sendLeaseExpiryReminders();
        $expiring = $this->countExpiringLeases();

        return [
            'generated_payments' => $generated,
            'marked_overdue' => $overdue,
            'reminders' => $reminders,
            'expiring_leases' => $expiring,
            'expiry_reminders' => $expiryReminders,
            'ran_at' => now()->toIso8601String(),
        ];
    }

    /**
     * Create the current-period rent payment for each active contract if missing.
     * SRS: GPMS-FR-LSE-003 / FIN-001 recurring billing.
     */
    public function generateDuePayments(?Carbon $asOf = null): int
    {
        $asOf ??= now();
        $period = $asOf->format('Y-m');
        $created = 0;

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

                Payment::query()->create([
                    'contract_id' => $contract->id,
                    'reference' => 'PAY-'.strtoupper(Str::random(10)),
                    'amount' => $contract->monthly_rent,
                    'due_date' => $dueDate->toDateString(),
                    'status' => $dueDate->isPast() ? 'overdue' : 'pending',
                    'period' => $period,
                    'notes' => 'Auto-generated rent for '.$period,
                ]);

                $created++;
            });

        return $created;
    }

    /**
     * Mark pending payments past due date as overdue.
     * SRS: collections / aging workflow.
     */
    public function markOverduePayments(?Carbon $asOf = null): int
    {
        $asOf ??= now();

        return Payment::query()
            ->where('status', 'pending')
            ->whereDate('due_date', '<', $asOf->toDateString())
            ->update(['status' => 'overdue']);
    }

    /**
     * Send rent/overdue reminders (email via notification + queue when enabled).
     * SRS: GPMS-FR-NOT-005
     */
    public function sendPaymentReminders(): int
    {
        $count = 0;

        Payment::query()
            ->whereIn('status', ['pending', 'overdue'])
            ->with('contract.tenant')
            ->each(function (Payment $payment) use (&$count): void {
                $tenant = $payment->contract?->tenant;

                if (! $tenant || blank($tenant->email)) {
                    Log::warning('Skipped rent reminder: missing tenant email', [
                        'payment_id' => $payment->id,
                    ]);

                    return;
                }

                $tenant->notify(new RentPaymentReminderNotification($payment));
                $count++;
            });

        return $count;
    }

    /**
     * Notify tenants of leases expiring within 30 days.
     * SRS: GPMS-FR-LSE-005 / NOT-005
     */
    public function sendLeaseExpiryReminders(?Carbon $asOf = null): int
    {
        $asOf ??= now();
        $count = 0;

        Contract::query()
            ->where('status', 'active')
            ->whereNotNull('end_date')
            ->whereBetween('end_date', [
                $asOf->toDateString(),
                $asOf->copy()->addDays(30)->toDateString(),
            ])
            ->with('tenant')
            ->each(function (Contract $contract) use (&$count): void {
                $tenant = $contract->tenant;

                if (! $tenant || blank($tenant->email)) {
                    return;
                }

                $tenant->notify(new LeaseExpiryReminderNotification($contract));
                $count++;
            });

        return $count;
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
}
