<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'organization_id',
    'owner_id',
    'name',
    'type',
    'address_line1',
    'address_line2',
    'city',
    'state',
    'postal_code',
    'country',
    'latitude',
    'longitude',
    'description',
    'total_units',
    'status',
])]
class Property extends Model
{
    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(Owner::class);
    }

    public function buildings(): HasMany
    {
        return $this->hasMany(Building::class);
    }

    public function rentalUnits(): HasMany
    {
        return $this->hasMany(RentalUnit::class);
    }

    public function managers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'property_manager')->withTimestamps();
    }
}
