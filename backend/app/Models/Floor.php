<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable(['building_id', 'name', 'level'])]
class Floor extends Model
{
    public function building(): BelongsTo
    {
        return $this->belongsTo(Building::class);
    }

    public function rentalUnits(): HasMany
    {
        return $this->hasMany(RentalUnit::class);
    }
}
