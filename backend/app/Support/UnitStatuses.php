<?php

namespace App\Support;

class UnitStatuses
{
    public const VACANT = 'vacant';

    public const RESERVED = 'reserved';

    public const APPLICATION_PENDING = 'application_pending';

    public const OCCUPIED = 'occupied';

    public const NOTICE_PERIOD = 'notice_period';

    public const UNDER_MAINTENANCE = 'under_maintenance';

    public const BLOCKED = 'blocked';

    /** Legacy aliases kept for backward compatibility. */
    public const AVAILABLE = 'available';

    public const MAINTENANCE = 'maintenance';

    /** @return list<string> */
    public static function all(): array
    {
        return [
            self::VACANT,
            self::RESERVED,
            self::APPLICATION_PENDING,
            self::OCCUPIED,
            self::NOTICE_PERIOD,
            self::UNDER_MAINTENANCE,
            self::BLOCKED,
            // legacy
            self::AVAILABLE,
            self::MAINTENANCE,
        ];
    }

    public static function normalize(?string $status): string
    {
        return match ($status) {
            'available' => self::VACANT,
            'maintenance' => self::UNDER_MAINTENANCE,
            default => $status ?: self::VACANT,
        };
    }
}
