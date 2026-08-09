<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

#[Fillable([
    'organization_id',
    'ticket_number',
    'rental_unit_id',
    'property_id',
    'tenant_id',
    'title',
    'description',
    'category',
    'priority',
    'status',
    'workflow_status',
    'permission_to_enter',
    'preferred_visit_date',
    'assigned_vendor_id',
    'assigned_technician_id',
    'estimated_cost',
    'approved_cost',
    'actual_cost',
    'scheduled_date',
    'media',
    'before_after_images',
    'quotation',
    'ai_triage',
    'sla_due_at',
    'reported_at',
    'resolved_at',
    'resolution_notes',
])]
class MaintenanceRequest extends Model
{
    protected function casts(): array
    {
        return [
            'reported_at' => 'datetime',
            'resolved_at' => 'datetime',
            'preferred_visit_date' => 'date',
            'scheduled_date' => 'datetime',
            'sla_due_at' => 'datetime',
            'permission_to_enter' => 'boolean',
            'estimated_cost' => 'decimal:2',
            'approved_cost' => 'decimal:2',
            'actual_cost' => 'decimal:2',
            'media' => 'array',
            'before_after_images' => 'array',
            'quotation' => 'array',
            'ai_triage' => 'array',
        ];
    }

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function rentalUnit(): BelongsTo
    {
        return $this->belongsTo(RentalUnit::class);
    }

    public function property(): BelongsTo
    {
        return $this->belongsTo(Property::class);
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }

    public function assignedVendor(): BelongsTo
    {
        return $this->belongsTo(Vendor::class, 'assigned_vendor_id');
    }

    public function assignedTechnician(): BelongsTo
    {
        return $this->belongsTo(User::class, 'assigned_technician_id');
    }
}
