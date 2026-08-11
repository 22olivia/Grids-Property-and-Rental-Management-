<?php

namespace App\Support;

class PropertyCoordinates
{
    /**
     * Known demo / Abu Dhabi landmarks used when a property has no stored coordinates.
     *
     * @var array<string, array{lat: float, lng: float}>
     */
    private const NAMED = [
        'marina heights' => ['lat' => 24.47685, 'lng' => 54.32195],
        'corniche towers' => ['lat' => 24.48210, 'lng' => 54.35420],
        'reem gate residences' => ['lat' => 24.49380, 'lng' => 54.40760],
        'saadiyat dunes' => ['lat' => 24.54120, 'lng' => 54.43380],
    ];

    /**
     * City centroids for rough map placement.
     *
     * @var array<string, array{lat: float, lng: float}>
     */
    private const CITIES = [
        'abu dhabi' => ['lat' => 24.45390, 'lng' => 54.37730],
        'dubai' => ['lat' => 25.20480, 'lng' => 55.27080],
        'sharjah' => ['lat' => 25.34630, 'lng' => 55.42090],
    ];

    /**
     * @return array{lat: float, lng: float, source: string}
     */
    public static function resolve(?float $lat, ?float $lng, ?string $name = null, ?string $city = null, int $jitterSeed = 0): array
    {
        if ($lat !== null && $lng !== null) {
            return ['lat' => $lat, 'lng' => $lng, 'source' => 'stored'];
        }

        $named = self::NAMED[strtolower(trim((string) $name))] ?? null;
        if ($named) {
            return ['lat' => $named['lat'], 'lng' => $named['lng'], 'source' => 'landmark'];
        }

        $cityKey = strtolower(trim((string) $city));
        $base = self::CITIES[$cityKey] ?? self::CITIES['abu dhabi'];
        // Small deterministic offset so multiple properties in one city don't stack.
        $offset = ($jitterSeed % 7) * 0.004;
        $latOffset = (($jitterSeed % 2) === 0 ? 1 : -1) * $offset;
        $lngOffset = (($jitterSeed % 3) - 1) * 0.003;

        return [
            'lat' => $base['lat'] + $latOffset,
            'lng' => $base['lng'] + $lngOffset,
            'source' => 'fallback',
        ];
    }
}
