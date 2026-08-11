<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'organization_id',
    'property_id',
    'building_id',
    'floor_id',
    'unit_number',
    'unit_type',
    'floor',
    'bedrooms',
    'bathrooms',
    'square_feet',
    'area',
    'furnishing_status',
    'monthly_rent',
    'maintenance_charge',
    'deposit_amount',
    'availability_date',
    'tenant_capacity',
    'status',
    'description',
    'amenities',
    'inventory',
    'meter_numbers',
    'images',
    'documents',
    'assigned_manager_id',
    'is_listed',
    'listing_title',
    'listing_description',
])]
class RentalUnit extends Model
{
    protected function casts(): array
    {
        return [
            'square_feet' => 'decimal:2',
            'area' => 'decimal:2',
            'monthly_rent' => 'decimal:2',
            'maintenance_charge' => 'decimal:2',
            'deposit_amount' => 'decimal:2',
            'availability_date' => 'date',
            'amenities' => 'array',
            'inventory' => 'array',
            'meter_numbers' => 'array',
            'images' => 'array',
            'documents' => 'array',
            'is_listed' => 'boolean',
        ];
    }

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function property(): BelongsTo
    {
        return $this->belongsTo(Property::class);
    }

    public function building(): BelongsTo
    {
        return $this->belongsTo(Building::class);
    }

    public function floorLevel(): BelongsTo
    {
        return $this->belongsTo(Floor::class, 'floor_id');
    }

    public function assignedManager(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_manager_id');
    }

    public function contracts(): HasMany
    {
        return $this->hasMany(Contract::class);
    }

    public function maintenanceRequests(): HasMany
    {
        return $this->hasMany(MaintenanceRequest::class);
    }
}
