<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationChannelSetting extends Model
{
    protected $fillable = [
        'organization_id',
        'channel',
        'enabled',
        'provider',
        'config',
    ];

    protected function casts(): array
    {
        return [
            'enabled' => 'boolean',
            'config' => 'array',
        ];
    }

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }
}
