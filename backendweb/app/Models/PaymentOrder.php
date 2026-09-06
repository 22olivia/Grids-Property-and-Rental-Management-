<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class PaymentOrder extends Model
{
    public const STATUS_PENDING = 'pending';

    public const STATUS_AWAITING = 'awaiting_payment';

    public const STATUS_PAID = 'paid';

    public const STATUS_FAILED = 'failed';

    public const STATUS_EXPIRED = 'expired';

    public const STATUS_CANCELLED = 'cancelled';

    public const STATUS_REFUNDED = 'refunded';

    protected $fillable = [
        'order_number',
        'tenant_id',
        'contract_id',
        'organization_id',
        'invoice_ids',
        'amount',
        'currency',
        'method',
        'emi_months',
        'status',
        'gateway',
        'gateway_order_id',
        'gateway_txn_id',
        'checkout_token',
        'checkout_payload',
        'idempotency_key',
        'payment_id',
        'failure_reason',
        'expires_at',
        'paid_at',
        'meta',
    ];

    protected function casts(): array
    {
        return [
            'invoice_ids' => 'array',
            'checkout_payload' => 'array',
            'meta' => 'array',
            'amount' => 'decimal:2',
            'expires_at' => 'datetime',
            'paid_at' => 'datetime',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function contract(): BelongsTo
    {
        return $this->belongsTo(Contract::class);
    }

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class);
    }

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function isOpen(): bool
    {
        return in_array($this->status, [self::STATUS_PENDING, self::STATUS_AWAITING], true)
            && (! $this->expires_at || $this->expires_at->isFuture());
    }

    public function toApiArray(): array
    {
        return [
            'id' => $this->order_number,
            'order_number' => $this->order_number,
            'invoice_ids' => $this->invoice_ids,
            'amount' => (string) $this->amount,
            'currency' => $this->currency,
            'method' => $this->method,
            'emi_months' => $this->emi_months,
            'status' => $this->status,
            'gateway' => $this->gateway,
            'gateway_order_id' => $this->gateway_order_id,
            'checkout_token' => $this->checkout_token,
            'checkout' => $this->checkout_payload,
            'expires_at' => optional($this->expires_at)?->toIso8601String(),
            'paid_at' => optional($this->paid_at)?->toIso8601String(),
            'payment_id' => $this->payment_id,
            'created_at' => optional($this->created_at)?->toIso8601String(),
        ];
    }
}
