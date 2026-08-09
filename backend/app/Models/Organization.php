<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'name', 'slug', 'legal_name', 'email', 'phone', 'country', 'city', 'address',
    'plan', 'status', 'maintenance_approval_limit', 'owner_user_id', 'settings',
])]
class Organization extends Model
{
    protected function casts(): array
    {
        return [
            'maintenance_approval_limit' => 'decimal:2',
            'settings' => 'array',
        ];
    }

    public function ownerUser(): BelongsTo
    {
        return $this->belongsTo(User::class, 'owner_user_id');
    }

    public function users(): BelongsToMany
    {
        return $this->belongsToMany(User::class)
            ->withPivot(['role', 'status', 'permissions'])
            ->withTimestamps();
    }

    public function properties(): HasMany
    {
        return $this->hasMany(Property::class);
    }

    public function buildings(): HasMany
    {
        return $this->hasMany(Building::class);
    }

    public function vendors(): HasMany
    {
        return $this->hasMany(Vendor::class);
    }
}
