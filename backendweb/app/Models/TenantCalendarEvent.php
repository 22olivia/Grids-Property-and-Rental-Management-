<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class TenantCalendarEvent extends Model
{
    protected $fillable = [
        'tenant_id',
        'title',
        'type',
        'event_date',
        'all_day',
        'start_time',
        'end_time',
        'meta',
    ];

    protected function casts(): array
    {
        return [
            'event_date' => 'date',
            'all_day' => 'boolean',
            'meta' => 'array',
        ];
    }

    public function tenant(): BelongsTo
    {
        return $this->belongsTo(Tenant::class);
    }
}
