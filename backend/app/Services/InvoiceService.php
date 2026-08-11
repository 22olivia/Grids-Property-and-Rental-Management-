<?php

namespace App\Services;

use App\Models\Contract;
use App\Models\Invoice;
use Illuminate\Support\Carbon;
use Illuminate\Support\Str;

class InvoiceService
{
    /**
     * Create missing rent invoices for active leases.
     * Fills the current month first, then any gaps in the previous month,
     * then the next month — so the demo "Generate" button still creates
     * invoices even when the current period was already seeded.
     */
    public function generateForActiveLeases(?Carbon $asOf = null): int
    {
        $asOf ??= now();
        $created = 0;

        $periods = [
            $asOf->copy()->startOfMonth(),
            $asOf->copy()->subMonth()->startOfMonth(),
            $asOf->copy()->addMonth()->startOfMonth(),
        ];

        foreach ($periods as $periodDate) {
            Contract::query()
                ->whereIn('status', ['active', 'expiring_soon', 'renewed'])
                ->orderBy('id')
                ->each(function (Contract $contract) use ($periodDate, &$created) {
                    if ($this->ensurePeriodInvoice($contract, $periodDate)) {
                        $created++;
                    }
                });
        }

        return $created;
    }

    public function ensurePeriodInvoice(Contract $contract, ?Carbon $asOf = null): ?Invoice
    {
        $asOf ??= now();
        $period = $asOf->copy()->startOfMonth();
        $periodKey = $period->format('Y-m');

        $existing = Invoice::query()
            ->where('contract_id', $contract->id)
            ->where('billing_month', $periodKey)
            ->where('status', '!=', 'cancelled')
            ->first();

        if ($existing) {
            return null;
        }

        $day = min(max((int) $contract->payment_day, 1), 28);
        $dueDate = $period->copy()->day($day);
        $previous = (float) Invoice::query()
            ->where('contract_id', $contract->id)
            ->whereIn('status', ['unpaid', 'partially_paid', 'overdue'])
            ->sum('remaining_balance');

        $rent = (float) $contract->monthly_rent;
        $lateFee = 0.0;
        if ($dueDate->copy()->addDays((int) ($contract->grace_period_days ?: 0))->isPast()) {
            $lateFee = (float) ($contract->late_fee_amount ?: 0);
        }

        $total = round($rent + $previous + $lateFee, 2);

        return Invoice::query()->create([
            'contract_id' => $contract->id,
            'invoice_number' => 'INV-'.strtoupper(Str::random(10)),
            'billing_month' => $periodKey,
            'rent_amount' => $rent,
            'additional_charges' => 0,
            'discounts' => 0,
            'late_fee' => $lateFee,
            'previous_balance' => $previous,
            'total_amount' => $total,
            'paid_amount' => 0,
            'remaining_balance' => $total,
            'due_date' => $dueDate->toDateString(),
            'status' => $dueDate->isPast() ? 'overdue' : 'unpaid',
            'notes' => 'Auto-generated rent invoice for '.$periodKey,
        ]);
    }
}
