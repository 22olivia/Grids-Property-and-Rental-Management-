<?php

namespace App\Services;

use App\Models\Contract;
use App\Models\RentalUnit;
use Illuminate\Support\Carbon;
use Illuminate\Validation\ValidationException;

class LeaseService
{
    public function assertNoOverlap(
        int $rentalUnitId,
        string $startDate,
        ?string $endDate,
        ?int $ignoreContractId = null,
    ): void {
        $start = Carbon::parse($startDate)->toDateString();
        $end = $endDate ? Carbon::parse($endDate)->toDateString() : '9999-12-31';

        $overlap = Contract::query()
            ->where('rental_unit_id', $rentalUnitId)
            ->whereIn('status', ['pending_approval', 'active', 'expiring_soon', 'renewed'])
            ->when($ignoreContractId, fn ($q) => $q->where('id', '!=', $ignoreContractId))
            ->whereDate('start_date', '<=', $end)
            ->where(function ($q) use ($start) {
                $q->whereNull('end_date')
                    ->orWhereDate('end_date', '>=', $start);
            })
            ->exists();

        if ($overlap) {
            throw ValidationException::withMessages([
                'rental_unit_id' => ['This unit already has an active/pending lease overlapping these dates.'],
            ]);
        }
    }

    public function markExpiringSoon(?Carbon $asOf = null): int
    {
        $asOf ??= now();

        return Contract::query()
            ->where('status', 'active')
            ->whereNotNull('end_date')
            ->whereBetween('end_date', [
                $asOf->toDateString(),
                $asOf->copy()->addDays(30)->toDateString(),
            ])
            ->update(['status' => 'expiring_soon']);
    }

    public function markExpired(?Carbon $asOf = null): int
    {
        $asOf ??= now();

        return Contract::query()
            ->whereIn('status', ['active', 'expiring_soon'])
            ->whereNotNull('end_date')
            ->whereDate('end_date', '<', $asOf->toDateString())
            ->update(['status' => 'expired']);
    }

    public function syncUnitOccupancy(Contract $contract): void
    {
        if (in_array($contract->status, ['active', 'renewed'], true)) {
            RentalUnit::query()->whereKey($contract->rental_unit_id)->update(['status' => 'occupied']);
        }

        if ($contract->status === 'expiring_soon') {
            RentalUnit::query()->whereKey($contract->rental_unit_id)->update(['status' => 'notice_period']);
        }

        if (in_array($contract->status, ['terminated', 'expired'], true)) {
            RentalUnit::query()->whereKey($contract->rental_unit_id)->update(['status' => 'vacant']);
        }
    }
}
