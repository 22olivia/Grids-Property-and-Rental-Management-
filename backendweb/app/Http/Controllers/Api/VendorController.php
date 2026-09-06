<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Vendor;
use App\Models\ActivityLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class VendorController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $vendors = Vendor::query()
            ->with('user:id,name,email,role')
            ->when($request->organization_id, fn ($q) => $q->where('organization_id', $request->organization_id))
            ->when(
                ! $request->user()->isSuperAdmin() && $request->user()->organization_id,
                fn ($q) => $q->where('organization_id', $request->user()->organization_id)
            )
            ->latest()
            ->paginate(20);

        return response()->json($vendors);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'organization_id' => ['nullable', 'exists:organizations,id'],
            'user_id' => ['nullable', 'exists:users,id'],
            'company_name' => ['required', 'string', 'max:255'],
            'contact_name' => ['nullable', 'string', 'max:255'],
            'email' => ['nullable', 'email'],
            'phone' => ['nullable', 'string', 'max:50'],
            'categories' => ['sometimes', 'array'],
            'status' => ['sometimes', 'string', 'max:30'],
        ]);

        $vendor = Vendor::create([
            ...$validated,
            'organization_id' => $validated['organization_id'] ?? $request->user()->organization_id,
            'status' => $validated['status'] ?? 'active',
        ]);

        ActivityLog::record('vendor.created', $vendor, $validated, $request);

        return response()->json([
            'message' => 'Vendor created.',
            'data' => $vendor,
        ], 201);
    }

    public function show(Vendor $vendor): JsonResponse
    {
        return response()->json([
            'data' => $vendor->load(['user', 'maintenanceRequests']),
        ]);
    }

    public function update(Request $request, Vendor $vendor): JsonResponse
    {
        $validated = $request->validate([
            'company_name' => ['sometimes', 'string', 'max:255'],
            'contact_name' => ['nullable', 'string', 'max:255'],
            'email' => ['nullable', 'email'],
            'phone' => ['nullable', 'string', 'max:50'],
            'categories' => ['sometimes', 'array'],
            'status' => ['sometimes', 'string', 'max:30'],
            'user_id' => ['nullable', 'exists:users,id'],
        ]);

        $vendor->update($validated);
        ActivityLog::record('vendor.updated', $vendor, $validated, $request);

        return response()->json([
            'message' => 'Vendor updated.',
            'data' => $vendor->fresh(),
        ]);
    }

    public function destroy(Vendor $vendor): JsonResponse
    {
        ActivityLog::record('vendor.deleted', $vendor, ['company_name' => $vendor->company_name]);
        $vendor->delete();

        return response()->json(['message' => 'Vendor deleted.']);
    }
}
