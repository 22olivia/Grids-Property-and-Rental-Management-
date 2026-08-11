<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\MorphTo;

class EmailLog extends Model
{
    protected $fillable = [
        'organization_id',
        'user_id',
        'related_type',
        'related_id',
        'template_key',
        'to_email',
        'to_name',
        'subject',
        'payload',
        'provider',
        'provider_message_id',
        'status',
        'attempts',
        'next_retry_at',
        'error_message',
        'provider_response',
        'sent_at',
    ];

    protected function casts(): array
    {
        return [
            'payload' => 'array',
            'provider_response' => 'array',
            'next_retry_at' => 'datetime',
            'sent_at' => 'datetime',
        ];
    }

    public function related(): MorphTo
    {
        return $this->morphTo();
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
    }

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }
}
