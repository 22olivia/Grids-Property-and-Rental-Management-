<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;

class NotificationPreference extends Model
{
    protected $fillable = [
        'user_id',
        'in_app',
        'email',
        'sms',
        'whatsapp',
        'push',
        'categories',
        'preferred_language',
        'digest_frequency',
        'quiet_hours_start',
        'quiet_hours_end',
        'emergency_override',
        'channel_by_category',
    ];

    protected function casts(): array
    {
        return [
            'in_app' => 'boolean',
            'email' => 'boolean',
            'sms' => 'boolean',
            'whatsapp' => 'boolean',
            'push' => 'boolean',
            'categories' => 'array',
            'emergency_override' => 'boolean',
            'channel_by_category' => 'array',
        ];
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }
}
