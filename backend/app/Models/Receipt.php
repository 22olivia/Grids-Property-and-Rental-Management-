<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class Receipt extends Model
{
    protected $fillable = [
        'organization_id',
        'tenant_id',
        'payment_id',
        'invoice_id',
        'receipt_number',
        'payment_date',
        'tenant_name',
        'property_name',
        'unit_number',
        'billing_period',
        'amount_paid',
        'payment_method',
        'transaction_reference',
        'invoice_number',
    ];

    protected function casts(): array
    {
        return [
            'payment_date' => 'date',
            'amount_paid' => 'decimal:2',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function payment(): BelongsTo
    {
        return $this->belongsTo(Payment::class);
    }
}
