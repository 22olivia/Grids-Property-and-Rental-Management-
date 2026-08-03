<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MaintenanceRequest;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class MaintenanceRequestController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $requests = MaintenanceRequest::with(['rentalUnit.property', 'tenant'])
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->when($request->priority, fn ($q) => $q->where('priority', $request->priority))
            ->latest()
            ->paginate(15);

        return response()->json($requests);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'rental_unit_id' => ['required', 'exists:rental_units,id'],
            'tenant_id' => ['nullable', 'exists:tenants,id'],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
            'category' => ['sometimes', 'string', 'in:plumbing,electrical,hvac,appliance,general'],
            'priority' => ['sometimes', 'string', 'in:low,medium,high,urgent'],
            'status' => ['sometimes', 'string', 'in:open,in_progress,resolved,closed,cancelled'],
            'reported_at' => ['sometimes', 'date'],
        ]);

        $maintenanceRequest = MaintenanceRequest::create($validated);

        return response()->json([
            'message' => 'Maintenance request created successfully.',
            'data' => $maintenanceRequest->load(['rentalUnit', 'tenant']),
        ], 201);
    }

    public function show(MaintenanceRequest $maintenanceRequest): JsonResponse
    {
        $maintenanceRequest->load(['rentalUnit.property', 'tenant']);

        return response()->json(['data' => $maintenanceRequest]);
    }

    public function update(Request $request, MaintenanceRequest $maintenanceRequest): JsonResponse
    {
        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'description' => ['sometimes', 'string'],
            'category' => ['sometimes', 'string', 'in:plumbing,electrical,hvac,appliance,general'],
            'priority' => ['sometimes', 'string', 'in:low,medium,high,urgent'],
            'status' => ['sometimes', 'string', 'in:open,in_progress,resolved,closed,cancelled'],
            'resolved_at' => ['nullable', 'date'],
            'resolution_notes' => ['nullable', 'string'],
        ]);

        $maintenanceRequest->update($validated);

        return response()->json([
            'message' => 'Maintenance request updated successfully.',
            'data' => $maintenanceRequest->fresh(['rentalUnit', 'tenant']),
        ]);
    }

    public function destroy(MaintenanceRequest $maintenanceRequest): JsonResponse
    {
        $maintenanceRequest->delete();

        return response()->json([
            'message' => 'Maintenance request deleted successfully.',
        ]);
    }
}
