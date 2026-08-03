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
    'status',
    'terms',
])]
class Contract extends Model
{
    protected function casts(): array
    {
        return [
            'start_date' => 'date',
            'end_date' => 'date',
            'monthly_rent' => 'decimal:2',
            'deposit_amount' => 'decimal:2',
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
}
