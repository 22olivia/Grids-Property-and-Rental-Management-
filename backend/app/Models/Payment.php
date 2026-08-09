<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'contract_id',
    'invoice_id',
    'payment_order_id',
    'reference',
    'transaction_number',
    'amount',
    'currency',
    'due_date',
    'paid_at',
    'method',
    'gateway',
    'gateway_txn_id',
    'status',
    'period',
    'notes',
    'proof_path',
    'approval_status',
    'refund_reason',
    'refunded_amount',
])]
class Payment extends Model
{
    public const METHODS = [
        'upi',
        'card',
        'emi',
        'net_banking',
        'bank_transfer',
        'wallet',
        'cash',
        'cheque',
        'check',
        'apple_pay',
        'google_pay',
        'payment_gateway',
    ];

    protected function casts(): array
    {
        return [
            'amount' => 'decimal:2',
            'refunded_amount' => 'decimal:2',
            'due_date' => 'date',
            'paid_at' => 'date',
        ];
    }

    public function contract(): BelongsTo
    {
        return $this->belongsTo(Contract::class);
    }

    public function invoice(): BelongsTo
    {
        return $this->belongsTo(Invoice::class);
    }

    public function paymentOrder(): BelongsTo
    {
        return $this->belongsTo(PaymentOrder::class);
    }

    public function allocations(): \Illuminate\Database\Eloquent\Relations\HasMany
    {
        return $this->hasMany(PaymentAllocation::class);
    }
}
