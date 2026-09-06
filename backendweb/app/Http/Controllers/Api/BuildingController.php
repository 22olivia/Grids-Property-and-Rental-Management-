<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Building;
use App\Models\Floor;
use App\Models\ActivityLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class BuildingController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $buildings = Building::query()
            ->with(['property:id,name', 'floors', 'rentalUnits:id,building_id,unit_number,status'])
            ->when($request->property_id, fn ($q) => $q->where('property_id', $request->property_id))
            ->when($request->organization_id, fn ($q) => $q->where('organization_id', $request->organization_id))
            ->latest()
            ->paginate((int) $request->get('per_page', 20));

        return response()->json($buildings);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'property_id' => ['required', 'exists:properties,id'],
            'organization_id' => ['nullable', 'exists:organizations,id'],
            'name' => ['required', 'string', 'max:255'],
            'code' => ['nullable', 'string', 'max:50'],
            'total_floors' => ['sometimes', 'integer', 'min:1', 'max:200'],
            'status' => ['sometimes', 'string', 'max:30'],
            'floors' => ['sometimes', 'array'],
            'floors.*.name' => ['required_with:floors', 'string', 'max:100'],
            'floors.*.level' => ['required_with:floors', 'integer'],
        ]);

        $building = Building::create([
            'property_id' => $validated['property_id'],
            'organization_id' => $validated['organization_id'] ?? null,
            'name' => $validated['name'],
            'code' => $validated['code'] ?? null,
            'total_floors' => $validated['total_floors'] ?? 1,
            'status' => $validated['status'] ?? 'active',
        ]);

        foreach ($validated['floors'] ?? [] as $floor) {
            Floor::create([
                'building_id' => $building->id,
                'name' => $floor['name'],
                'level' => $floor['level'],
            ]);
        }

        ActivityLog::record('building.created', $building, $validated, $request);

        return response()->json([
            'message' => 'Building created.',
            'data' => $building->load('floors', 'property'),
        ], 201);
    }

    public function show(Building $building): JsonResponse
    {
        return response()->json([
            'data' => $building->load(['property', 'floors.rentalUnits', 'rentalUnits']),
        ]);
    }

    public function update(Request $request, Building $building): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['sometimes', 'string', 'max:255'],
            'code' => ['nullable', 'string', 'max:50'],
            'total_floors' => ['sometimes', 'integer', 'min:1', 'max:200'],
            'status' => ['sometimes', 'string', 'max:30'],
        ]);

        $building->update($validated);
        ActivityLog::record('building.updated', $building, $validated, $request);

        return response()->json([
            'message' => 'Building updated.',
            'data' => $building->fresh('floors'),
        ]);
    }

    public function destroy(Building $building): JsonResponse
    {
        ActivityLog::record('building.deleted', $building, ['name' => $building->name]);
        $building->delete();

        return response()->json(['message' => 'Building deleted.']);
    }

    public function storeFloor(Request $request, Building $building): JsonResponse
    {
        $validated = $request->validate([
            'name' => ['required', 'string', 'max:100'],
            'level' => ['required', 'integer'],
        ]);

        $floor = Floor::create([
            'building_id' => $building->id,
            ...$validated,
        ]);

        ActivityLog::record('floor.created', $floor, $validated, $request);

        return response()->json([
            'message' => 'Floor created.',
            'data' => $floor,
        ], 201);
    }
}
