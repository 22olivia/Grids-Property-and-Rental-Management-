<?php

namespace App\Services;

use App\Models\Contract;
use App\Models\Payment;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

class RentalAutomationService
{
    /**
     * Run the demo automation bundle and return a summary.
     *
     * @return array{
     *     generated_payments: int,
     *     marked_overdue: int,
     *     reminders: int,
     *     expiring_leases: int,
     *     ran_at: string
     * }
     */
    public function run(): array
    {
        $generated = $this->generateDuePayments();
        $overdue = $this->markOverduePayments();
        $reminders = $this->sendPaymentReminders();
        $expiring = $this->countExpiringLeases();

        return [
            'generated_payments' => $generated,
            'marked_overdue' => $overdue,
            'reminders' => $reminders,
            'expiring_leases' => $expiring,
            'ran_at' => now()->toIso8601String(),
        ];
    }

    /**
     * Create the current-period rent payment for each active contract if missing.
     */
    public function generateDuePayments(?Carbon $asOf = null): int
    {
        $asOf ??= now();
        $period = $asOf->format('Y-m');
        $created = 0;

        Contract::query()
            ->where('status', 'active')
            ->with('tenant')
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
     * Log/send simple reminders for pending and overdue payments.
     */
    public function sendPaymentReminders(): int
    {
        $count = 0;

        Payment::query()
            ->whereIn('status', ['pending', 'overdue'])
            ->with('contract.tenant')
            ->each(function (Payment $payment) use (&$count): void {
                $tenant = $payment->contract?->tenant;
                $email = $tenant?->email ?? 'unknown';

                Log::info('Rent reminder', [
                    'payment_id' => $payment->id,
                    'reference' => $payment->reference,
                    'status' => $payment->status,
                    'amount' => $payment->amount,
                    'due_date' => optional($payment->due_date)->toDateString(),
                    'tenant_email' => $email,
                ]);

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
            ->whereBetween('end_date', [$asOf->toDateString(), $asOf->copy()->addDays(30)->toDateString()])
            ->count();
    }
}
