<?php

namespace App\Models;

use App\Support\Roles;
use Database\Factories\UserFactory;
use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Attributes\Hidden;
use Illuminate\Database\Eloquent\Factories\HasFactory;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;
use Illuminate\Database\Eloquent\Relations\HasOne;
use Illuminate\Foundation\Auth\User as Authenticatable;
use Illuminate\Notifications\Notifiable;
use Illuminate\Support\Facades\Storage;
use Laravel\Sanctum\HasApiTokens;

#[Fillable([
    'organization_id',
    'name',
    'email',
    'notify_email',
    'password',
    'role',
    'phone',
    'whatsapp_phone',
    'photo_path',
    'address',
    'status',
    'verification_status',
    'assigned_property_ids',
    'assigned_unit_ids',
    'last_login_at',
])]
#[Hidden(['password', 'remember_token'])]
class User extends Authenticatable
{
    /** @use HasFactory<UserFactory> */
    use HasApiTokens, HasFactory, Notifiable;

    /**
     * @var list<string>
     */
    protected $appends = ['photo_url'];

    protected function casts(): array
    {
        return [
            'email_verified_at' => 'datetime',
            'password' => 'hashed',
            'last_login_at' => 'datetime',
            'assigned_property_ids' => 'array',
            'assigned_unit_ids' => 'array',
        ];
    }

    public function getPhotoUrlAttribute(): ?string
    {
        $path = $this->photo_path;
        if (! $path) {
            return null;
        }

        if (
            str_starts_with($path, 'http://')
            || str_starts_with($path, 'https://')
            || str_starts_with($path, 'data:')
            || str_starts_with($path, '/')
        ) {
            return $path;
        }

        return Storage::disk('public')->url($path);
    }

    public function normalizedRole(): string
    {
        return Roles::normalize($this->role);
    }

    public function isSuperAdmin(): bool
    {
        return $this->normalizedRole() === Roles::SUPER_ADMIN;
    }

    public function isOwner(): bool
    {
        return $this->normalizedRole() === Roles::OWNER;
    }

    public function isManager(): bool
    {
        return $this->normalizedRole() === Roles::MANAGER;
    }

    public function isTenant(): bool
    {
        return $this->normalizedRole() === Roles::TENANT;
    }

    public function isVendor(): bool
    {
        return $this->normalizedRole() === Roles::VENDOR;
    }

    public function isTechnician(): bool
    {
        return $this->normalizedRole() === Roles::TECHNICIAN;
    }

    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function organizations(): BelongsToMany
    {
        return $this->belongsToMany(Organization::class)
            ->withPivot(['role', 'status', 'permissions'])
            ->withTimestamps();
    }

    public function owner(): HasOne
    {
        return $this->hasOne(Owner::class);
    }

    public function tenant(): HasOne
    {
        return $this->hasOne(Tenant::class);
    }

    public function vendor(): HasOne
    {
        return $this->hasOne(Vendor::class);
    }

    public function managedProperties(): BelongsToMany
    {
        return $this->belongsToMany(Property::class, 'property_manager')->withTimestamps();
    }

    public function notificationPreference(): HasOne
    {
        return $this->hasOne(NotificationPreference::class);
    }

    public function loginHistories(): HasMany
    {
        return $this->hasMany(LoginHistory::class);
    }

    public function activityLogs(): HasMany
    {
        return $this->hasMany(ActivityLog::class);
    }
}
