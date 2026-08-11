<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Concerns\HasUuids;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;

class AppNotification extends Model
{
    use HasUuids;

    public $incrementing = false;

    protected $keyType = 'string';

    protected $fillable = [
        'organization_id',
        'recipient_user_id',
        'recipient_role',
        'category',
        'title',
        'message',
        'priority',
        'module',
        'record_type',
        'record_id',
        'action_url',
        'action_label',
        'template_key',
        'dedupe_key',
        'channels',
        'payload',
        'group_key',
        'scheduled_at',
        'sent_at',
        'read_at',
        'archived_at',
        'delivery_status',
        'is_emergency',
    ];

    protected function casts(): array
    {
        return [
            'channels' => 'array',
            'payload' => 'array',
            'scheduled_at' => 'datetime',
            'sent_at' => 'datetime',
            'read_at' => 'datetime',
            'archived_at' => 'datetime',
            'is_emergency' => 'boolean',
        ];
    }

    public function recipient(): BelongsTo
    {
        return $this->belongsTo(User::class, 'recipient_user_id');
    }

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function deliveries(): HasMany
    {
        return $this->hasMany(NotificationDelivery::class, 'app_notification_id');
    }

    public function markRead(): void
    {
        if ($this->read_at) {
            return;
        }
        $this->forceFill(['read_at' => now()])->save();
    }

    public function archive(): void
    {
        $this->forceFill(['archived_at' => now()])->save();
    }
}
