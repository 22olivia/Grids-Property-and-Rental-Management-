<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Contract;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\RentalUnit;
use App\Services\ActivityLogger;
use App\Support\UnitStatuses;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Validation\Rule;

class RentalUnitController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();
        $units = RentalUnit::with(['property', 'building', 'floorLevel', 'assignedManager:id,name,email'])
            ->when($request->property_id, fn ($q) => $q->where('property_id', $request->property_id))
            ->when($request->building_id, fn ($q) => $q->where('building_id', $request->building_id))
            ->when($request->floor_id, fn ($q) => $q->where('floor_id', $request->floor_id))
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->when($request->organization_id, fn ($q) => $q->where('organization_id', $request->organization_id))
            ->when($request->boolean('listed_only'), fn ($q) => $q->where('is_listed', true))
            ->when($user->isTenant(), function ($q) use ($user) {
                $tenantId = $user->tenant?->id;
                $q->whereHas('contracts', fn ($contracts) => $contracts->where('tenant_id', $tenantId ?: 0));
            })
            ->when(
                ! $user->isSuperAdmin() && ! $user->isTenant() && $user->organization_id,
                fn ($q) => $q->where('organization_id', $user->organization_id)
            )
            ->latest()
            ->paginate((int) $request->get('per_page', 20));

        return response()->json($units);
    }

    public function store(Request $request, ActivityLogger $logger): JsonResponse
    {
        $validated = $this->validatedPayload($request);
        $validated['status'] = UnitStatuses::normalize($validated['status'] ?? UnitStatuses::VACANT);
        $validated['organization_id'] = $validated['organization_id'] ?? $request->user()->organization_id;

        $unit = RentalUnit::create($validated);
        $logger->log('unit.created', $unit, $validated, $request);

        return response()->json([
            'message' => 'Rental unit created successfully.',
            'data' => $unit->load(['property', 'building', 'floorLevel', 'assignedManager:id,name,email']),
        ], 201);
    }

    public function show(RentalUnit $rentalUnit): JsonResponse
    {
        $rentalUnit->load([
            'property.owner',
            'building',
            'floorLevel',
            'assignedManager:id,name,email',
            'contracts.tenant',
            'maintenanceRequests',
        ]);

        $contractIds = $rentalUnit->contracts()->pluck('id');

        return response()->json([
            'data' => $rentalUnit,
            'meta' => [
                'lease_history' => Contract::query()->where('rental_unit_id', $rentalUnit->id)->latest()->limit(20)->get(),
                'rent_history' => Invoice::query()->whereIn('contract_id', $contractIds)->latest()->limit(20)->get(),
                'maintenance_history' => $rentalUnit->maintenanceRequests()->latest()->limit(20)->get(),
                'income_total' => (float) Payment::query()
                    ->whereIn('contract_id', $contractIds)
                    ->where('status', 'paid')
                    ->sum('amount'),
            ],
        ]);
    }

    public function update(Request $request, RentalUnit $rentalUnit, ActivityLogger $logger): JsonResponse
    {
        $validated = $this->validatedPayload($request, partial: true);
        if (isset($validated['status'])) {
            $validated['status'] = UnitStatuses::normalize($validated['status']);
        }

        $rentalUnit->update($validated);
        $logger->log('unit.updated', $rentalUnit, $validated, $request);

        return response()->json([
            'message' => 'Rental unit updated successfully.',
            'data' => $rentalUnit->fresh(['property', 'building', 'floorLevel', 'assignedManager:id,name,email']),
        ]);
    }

    public function destroy(RentalUnit $rentalUnit, ActivityLogger $logger): JsonResponse
    {
        $logger->log('unit.deleted', $rentalUnit, ['unit_number' => $rentalUnit->unit_number]);
        $rentalUnit->delete();

        return response()->json([
            'message' => 'Rental unit deleted successfully.',
        ]);
    }

    public function publishListing(Request $request, RentalUnit $rentalUnit, ActivityLogger $logger): JsonResponse
    {
        $validated = $request->validate([
            'listing_title' => ['nullable', 'string', 'max:255'],
            'listing_description' => ['nullable', 'string'],
            'is_listed' => ['sometimes', 'boolean'],
        ]);

        $rentalUnit->update([
            'is_listed' => $validated['is_listed'] ?? true,
            'listing_title' => $validated['listing_title'] ?? $rentalUnit->listing_title,
            'listing_description' => $validated['listing_description'] ?? $rentalUnit->listing_description,
        ]);

        $logger->log('unit.listing_published', $rentalUnit, $validated, $request);

        return response()->json([
            'message' => 'Unit listing updated.',
            'data' => $rentalUnit->fresh(),
        ]);
    }

    /**
     * @return array<string, mixed>
     */
    private function validatedPayload(Request $request, bool $partial = false): array
    {
        $required = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'organization_id' => ['nullable', 'exists:organizations,id'],
            'property_id' => [$required, 'exists:properties,id'],
            'building_id' => ['nullable', 'exists:buildings,id'],
            'floor_id' => ['nullable', 'exists:floors,id'],
            'unit_number' => [$required, 'string', 'max:50'],
            'unit_type' => ['nullable', 'string', 'max:50'],
            'floor' => ['nullable', 'string', 'max:50'],
            'bedrooms' => ['sometimes', 'integer', 'min:0'],
            'bathrooms' => ['sometimes', 'integer', 'min:0'],
            'square_feet' => ['nullable', 'numeric', 'min:0'],
            'area' => ['nullable', 'numeric', 'min:0'],
            'furnishing_status' => ['nullable', 'string', 'max:40'],
            'monthly_rent' => [$required, 'numeric', 'min:0'],
            'maintenance_charge' => ['nullable', 'numeric', 'min:0'],
            'deposit_amount' => ['nullable', 'numeric', 'min:0'],
            'availability_date' => ['nullable', 'date'],
            'tenant_capacity' => ['sometimes', 'integer', 'min:1'],
            'status' => ['sometimes', Rule::in(UnitStatuses::all())],
            'description' => ['nullable', 'string'],
            'amenities' => ['sometimes', 'array'],
            'inventory' => ['sometimes', 'array'],
            'meter_numbers' => ['sometimes', 'array'],
            'images' => ['sometimes', 'array'],
            'documents' => ['sometimes', 'array'],
            'assigned_manager_id' => ['nullable', 'exists:users,id'],
            'is_listed' => ['sometimes', 'boolean'],
            'listing_title' => ['nullable', 'string', 'max:255'],
            'listing_description' => ['nullable', 'string'],
        ]);
    }
}
