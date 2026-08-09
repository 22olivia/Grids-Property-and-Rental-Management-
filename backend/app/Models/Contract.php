<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'contract_number',
    'rental_unit_id',
    'tenant_id',
    'start_date',
    'end_date',
    'monthly_rent',
    'deposit_amount',
    'payment_day',
    'grace_period_days',
    'late_fee_amount',
    'payment_frequency',
    'status',
    'terms',
    'agreement_path',
    'move_in_date',
    'move_out_date',
    'created_by',
    'notes',
])]
class Contract extends Model
{
    public const STATUSES = [
        'draft',
        'pending_approval',
        'pending_signature',
        'active',
        'expiring_soon',
        'notice_given',
        'expired',
        'terminated',
        'renewed',
    ];

    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
            'move_in_date' => 'date',
            'move_out_date' => 'date',
            'monthly_rent' => 'decimal:2',
            'deposit_amount' => 'decimal:2',
            'late_fee_amount' => 'decimal:2',
        ];
    }

    public function rentalUnit(): BelongsTo
    {
        return $this->belongsTo(RentalUnit::class);
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function payments(): HasMany
    {
        return $this->hasMany(Payment::class);
    }

    public function invoices(): HasMany
    {
        return $this->hasMany(Invoice::class);
    }

    public function amendments(): HasMany
    {
        return $this->hasMany(LeaseAmendment::class);
    }

    public function creator(): BelongsTo
    {
        return $this->belongsTo(User::class, 'created_by');
    }
}
