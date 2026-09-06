<?php

namespace App\Models;

use Illuminate\Database\Eloquent\Attributes\Fillable;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Database\Eloquent\Relations\BelongsTo;
use Illuminate\Database\Eloquent\Relations\BelongsToMany;
use Illuminate\Database\Eloquent\Relations\HasMany;

#[Fillable([
    'organization_id',
    'owner_id',
    'name',
    'type',
    'address_line1',
    'address_line2',
    'city',
    'state',
    'postal_code',
    'country',
    'latitude',
    'longitude',
    'description',
    'total_units',
    'status',
])]
class Property extends Model
{
    public function organization(): BelongsTo
    {
        return $this->belongsTo(Organization::class);
    }

    public function owner(): BelongsTo
    {
        return $this->belongsTo(Owner::class);
    }

    public function buildings(): HasMany
    {
        return $this->hasMany(Building::class);
    }

    public function rentalUnits(): HasMany
    {
        return $this->hasMany(RentalUnit::class);
    }

    public function managers(): BelongsToMany
    {
        return $this->belongsToMany(User::class, 'property_manager')->withTimestamps();
    }

    /**
     * Resolve map coordinates from stored lat/lng, known landmarks, or city fallback.
     *
     * @return array{lat: float, lng: float, source: string}
     */
    public function resolveCoordinates(int $jitterSeed = 0): array
    {
        $lat = $this->latitude !== null ? (float) $this->latitude : null;
        $lng = $this->longitude !== null ? (float) $this->longitude : null;

        if ($lat !== null && $lng !== null) {
            return ['lat' => $lat, 'lng' => $lng, 'source' => 'stored'];
        }

        $named = [
            'marina heights' => ['lat' => 24.47685, 'lng' => 54.32195],
            'corniche towers' => ['lat' => 24.48210, 'lng' => 54.35420],
            'reem gate residences' => ['lat' => 24.49380, 'lng' => 54.40760],
            'saadiyat dunes' => ['lat' => 24.54120, 'lng' => 54.43380],
        ];
        $landmark = $named[strtolower(trim((string) $this->name))] ?? null;
        if ($landmark) {
            return ['lat' => $landmark['lat'], 'lng' => $landmark['lng'], 'source' => 'landmark'];
        }

        $cities = [
            'abu dhabi' => ['lat' => 24.45390, 'lng' => 54.37730],
            'dubai' => ['lat' => 25.20480, 'lng' => 55.27080],
            'sharjah' => ['lat' => 25.34630, 'lng' => 55.42090],
        ];
        $seed = $jitterSeed ?: (int) $this->id;
        $cityKey = strtolower(trim((string) $this->city));
        $base = $cities[$cityKey] ?? $cities['abu dhabi'];
        $offset = ($seed % 7) * 0.004;
        $latOffset = (($seed % 2) === 0 ? 1 : -1) * $offset;
        $lngOffset = (($seed % 3) - 1) * 0.003;

        return [
            'lat' => $base['lat'] + $latOffset,
            'lng' => $base['lng'] + $lngOffset,
            'source' => 'fallback',
        ];
    }
}
