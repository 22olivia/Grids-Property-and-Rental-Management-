<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'contract_id',
    'invoice_number',
    'billing_month',
    'rent_amount',
    'additional_charges',
    'discounts',
    'late_fee',
    'previous_balance',
    'total_amount',
    'paid_amount',
    'remaining_balance',
    'due_date',
    'status',
    'notes',
])]
class Invoice extends Model
{
    protected function casts(): array
    {
        return [
            'rent_amount' => 'decimal:2',
            'additional_charges' => 'decimal:2',
            'discounts' => 'decimal:2',
            'late_fee' => 'decimal:2',
            'previous_balance' => 'decimal:2',
            'total_amount' => 'decimal:2',
            'paid_amount' => 'decimal:2',
            'remaining_balance' => 'decimal:2',
            'due_date' => 'date',
        ];
    }

    public function contract(): BelongsTo
    {
        return $this->belongsTo(Contract::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function allocations(): HasMany
    {
        return $this->hasMany(PaymentAllocation::class);
    }

    public function recalculateBalances(): void
    {
        $paid = (float) $this->payments()
            ->whereIn('status', ['paid'])
            ->where(function ($q) {
                $q->whereNull('approval_status')
                    ->orWhere('approval_status', 'approved');
            })
            ->sum('amount');

        $refunded = (float) $this->payments()->sum('refunded_amount');
        $netPaid = max(0, $paid - $refunded);
        $total = (float) $this->total_amount;
        $remaining = max(0, round($total - $netPaid, 2));

        $status = $this->status;
        if ($status !== 'cancelled' && $status !== 'draft') {
            if ($remaining <= 0) {
                $status = 'paid';
            } elseif ($netPaid > 0) {
                $status = 'partially_paid';
            } elseif ($this->due_date && $this->due_date->isPast()) {
                $status = 'overdue';
            } else {
                $status = 'unpaid';
            }
        }

        $this->update([
            'paid_amount' => $netPaid,
            'remaining_balance' => $remaining,
            'status' => $status,
        ]);
    }
}
