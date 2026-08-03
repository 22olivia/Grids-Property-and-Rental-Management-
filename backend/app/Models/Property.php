<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'owner_id',
    'name',
    'type',
    'address_line1',
    'address_line2',
    'city',
    'state',
    'postal_code',
    'country',
    'description',
    'total_units',
    'status',
])]
class Property extends Model
{
    public function owner(): BelongsTo
    {
        return $this->belongsTo(Owner::class);
    }

    public function rentalUnits(): HasMany
    {
        return $this->hasMany(RentalUnit::class);
    }
}
