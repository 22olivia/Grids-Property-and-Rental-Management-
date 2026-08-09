<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationTemplate extends Model
{
    protected $fillable = [
        'organization_id',
        'key',
        'name',
        'category',
        'roles',
        'channel',
        'channels',
        'priority',
        'is_emergency',
        'subject',
        'body',
        'variables',
        'is_active',
    ];

    protected function casts(): array
    {
        return [
            'roles' => 'array',
            'channels' => 'array',
            'variables' => 'array',
            'is_active' => 'boolean',
            'is_emergency' => 'boolean',
        ];
    }

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }
}
