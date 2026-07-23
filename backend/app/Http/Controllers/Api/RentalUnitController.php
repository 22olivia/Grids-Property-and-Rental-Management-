<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\RentalUnit;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class RentalUnitController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $units = RentalUnit::with('property')
            ->when($request->property_id, fn ($q) => $q->where('property_id', $request->property_id))
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->latest()
            ->paginate(15);

        return response()->json($units);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'property_id' => ['required', 'exists:properties,id'],
            'unit_number' => ['required', 'string', 'max:50'],
            'floor' => ['nullable', 'string', 'max:50'],
            'bedrooms' => ['sometimes', 'integer', 'min:0'],
            'bathrooms' => ['sometimes', 'integer', 'min:0'],
            'square_feet' => ['nullable', 'numeric', 'min:0'],
            'monthly_rent' => ['required', 'numeric', 'min:0'],
            'deposit_amount' => ['nullable', 'numeric', 'min:0'],
            'status' => ['sometimes', 'string', 'in:available,occupied,maintenance,reserved'],
            'description' => ['nullable', 'string'],
        ]);

        $unit = RentalUnit::create($validated);

        return response()->json([
            'message' => 'Rental unit created successfully.',
            'data' => $unit->load('property'),
        ], 201);
    }

    public function show(RentalUnit $rentalUnit): JsonResponse
    {
        $rentalUnit->load(['property.owner', 'contracts.tenant', 'maintenanceRequests']);

        return response()->json(['data' => $rentalUnit]);
    }

    public function update(Request $request, RentalUnit $rentalUnit): JsonResponse
    {
        $validated = $request->validate([
            'property_id' => ['sometimes', 'exists:properties,id'],
            'unit_number' => ['sometimes', 'string', 'max:50'],
            'floor' => ['nullable', 'string', 'max:50'],
            'bedrooms' => ['sometimes', 'integer', 'min:0'],
            'bathrooms' => ['sometimes', 'integer', 'min:0'],
            'square_feet' => ['nullable', 'numeric', 'min:0'],
            'monthly_rent' => ['sometimes', 'numeric', 'min:0'],
            'deposit_amount' => ['nullable', 'numeric', 'min:0'],
            'status' => ['sometimes', 'string', 'in:available,occupied,maintenance,reserved'],
            'description' => ['nullable', 'string'],
        ]);

        $rentalUnit->update($validated);

        return response()->json([
            'message' => 'Rental unit updated successfully.',
            'data' => $rentalUnit->fresh('property'),
        ]);
    }

    public function destroy(RentalUnit $rentalUnit): JsonResponse
    {
        $rentalUnit->delete();

        return response()->json([
            'message' => 'Rental unit deleted successfully.',
        ]);
    }
}
