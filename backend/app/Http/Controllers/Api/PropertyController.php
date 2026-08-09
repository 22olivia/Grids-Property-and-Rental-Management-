<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Property;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class PropertyController extends Controller
{
    public function mapIndex(): JsonResponse
    {
        $properties = Property::query()
            ->withCount([
                'rentalUnits as available_units_count' => function ($query) {
                    $query->whereIn('status', ['available', 'vacant']);
                },
                'rentalUnits as listed_units_count' => function ($query) {
                    $query->where('is_listed', true);
                },
            ])
            ->where('status', 'active')
            ->orderBy('name')
            ->get()
            ->values()
            ->map(function (Property $property, int $index) {
                $coords = \App\Support\PropertyCoordinates::resolve(
                    $property->latitude !== null ? (float) $property->latitude : null,
                    $property->longitude !== null ? (float) $property->longitude : null,
                    $property->name,
                    $property->city,
                    $property->id ?: $index,
                );

                return [
                    'id' => $property->id,
                    'name' => $property->name,
                    'type' => $property->type,
                    'status' => $property->status,
                    'city' => $property->city,
                    'state' => $property->state,
                    'address_line1' => $property->address_line1,
                    'address_line2' => $property->address_line2,
                    'country' => $property->country,
                    'description' => $property->description,
                    'total_units' => $property->total_units,
                    'available_units' => (int) $property->available_units_count,
                    'listed_units' => (int) $property->listed_units_count,
                    'lat' => $coords['lat'],
                    'lng' => $coords['lng'],
                    'coordinates_source' => $coords['source'],
                ];
            });

        return response()->json([
            'message' => 'Public property map markers.',
            'data' => $properties,
            'total' => $properties->count(),
        ]);
    }

    public function index(): JsonResponse
    {
        $properties = Property::with(['owner', 'rentalUnits'])->latest()->paginate(15);

        return response()->json($properties);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'owner_id' => ['required', 'exists:owners,id'],
            'organization_id' => ['nullable', 'exists:organizations,id'],
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
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
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
            'organization_id' => ['nullable', 'exists:organizations,id'],
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
            'latitude' => ['nullable', 'numeric', 'between:-90,90'],
            'longitude' => ['nullable', 'numeric', 'between:-180,180'],
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
