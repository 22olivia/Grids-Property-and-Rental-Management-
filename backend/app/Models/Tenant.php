<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Notifications\Notifiable;

#[Fillable([
    'user_id',
    'full_name',
    'email',
    'phone',
    'alternate_phone',
    'national_id',
    'date_of_birth',
    'occupation',
    'employer',
    'emergency_contact',
    'communication_address',
    'preferred_language',
    'profile_completion',
    'identity_type',
    'identity_number_encrypted',
    'identity_verification_status',
    'identity_expiry_date',
    'settings',
    'notes',
])]
class Tenant extends Model
{
    use Notifiable;

    protected function casts(): array
    {
        return [
            'date_of_birth' => 'date',
            'identity_expiry_date' => 'date',
            'settings' => 'array',
        ];
    }

    /**
     * Route mail notifications to the tenant email address.
     */
    public function routeNotificationForMail(): string
    {
        return $this->email;
    }

    public function user(): BelongsTo
    {
        return $this->belongsTo(User::class);
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
