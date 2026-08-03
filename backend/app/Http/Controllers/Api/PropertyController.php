<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Property;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PropertyController extends Controller
{
    public function index(): JsonResponse
    {
        $properties = Property::with(['owner', 'rentalUnits'])->latest()->paginate(15);

        return response()->json($properties);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'owner_id' => ['required', 'exists:owners,id'],
            'name' => ['required', 'string', 'max:255'],
            'type' => ['sometimes', 'string', 'in:apartment,house,commercial,villa'],
            'address_line1' => ['required', 'string', 'max:255'],
            'address_line2' => ['nullable', 'string', 'max:255'],
            'city' => ['required', 'string', 'max:100'],
            'state' => ['nullable', 'string', 'max:100'],
            'postal_code' => ['nullable', 'string', 'max:20'],
            'country' => ['sometimes', 'string', 'max:100'],
            'description' => ['nullable', 'string'],
            'total_units' => ['sometimes', 'integer', 'min:1'],
            'status' => ['sometimes', 'string', 'in:active,inactive,under_maintenance'],
        ]);

        $property = Property::create($validated);

        return response()->json([
            'message' => 'Property created successfully.',
            'data' => $property->load('owner'),
        ], 201);
    }

    public function show(Property $property): JsonResponse
    {
        $property->load(['owner', 'rentalUnits']);

        return response()->json(['data' => $property]);
    }

    public function update(Request $request, Property $property): JsonResponse
    {
        $validated = $request->validate([
            'owner_id' => ['sometimes', 'exists:owners,id'],
            'name' => ['sometimes', 'string', 'max:255'],
            'type' => ['sometimes', 'string', 'in:apartment,house,commercial,villa'],
            'address_line1' => ['sometimes', 'string', 'max:255'],
            'address_line2' => ['nullable', 'string', 'max:255'],
            'city' => ['sometimes', 'string', 'max:100'],
            'state' => ['nullable', 'string', 'max:100'],
            'postal_code' => ['nullable', 'string', 'max:20'],
            'country' => ['sometimes', 'string', 'max:100'],
            'description' => ['nullable', 'string'],
            'total_units' => ['sometimes', 'integer', 'min:1'],
            'status' => ['sometimes', 'string', 'in:active,inactive,under_maintenance'],
        ]);

        $property->update($validated);

        return response()->json([
            'message' => 'Property updated successfully.',
            'data' => $property->fresh('owner'),
        ]);
    }

    public function destroy(Property $property): JsonResponse
    {
        $property->delete();

        return response()->json([
            'message' => 'Property deleted successfully.',
        ]);
    }
}
