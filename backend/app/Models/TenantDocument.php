<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TenantDocument extends Model
{
    protected $fillable = [
        'organization_id',
        'tenant_id',
        'uploaded_by',
        'title',
        'category',
        'disk',
        'path',
        'file_type',
        'file_size',
        'verification_status',
        'expiry_date',
        'tenant_owned',
        'version',
    ];

    protected function casts(): array
    {
        return [
            'expiry_date' => 'date',
            'tenant_owned' => 'boolean',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }
}
