<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Owner;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class OwnerController extends Controller
{
    public function index(): JsonResponse
    {
        $owners = Owner::with('properties')->latest()->paginate(15);

        return response()->json($owners);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'user_id' => ['nullable', 'exists:users,id'],
            'full_name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:owners,email'],
            'phone' => ['nullable', 'string', 'max:50'],
            'national_id' => ['nullable', 'string', 'max:100', 'unique:owners,national_id'],
            'address' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
        ]);

        $owner = Owner::create($validated);

        return response()->json([
            'message' => 'Owner created successfully.',
            'data' => $owner,
        ], 201);
    }

    public function show(Owner $owner): JsonResponse
    {
        $owner->load('properties.rentalUnits');

        return response()->json(['data' => $owner]);
    }

    public function update(Request $request, Owner $owner): JsonResponse
    {
        $validated = $request->validate([
            'user_id' => ['nullable', 'exists:users,id'],
            'full_name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', 'unique:owners,email,'.$owner->id],
            'phone' => ['nullable', 'string', 'max:50'],
            'national_id' => ['nullable', 'string', 'max:100', 'unique:owners,national_id,'.$owner->id],
            'address' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
        ]);

        $owner->update($validated);

        return response()->json([
            'message' => 'Owner updated successfully.',
            'data' => $owner,
        ]);
    }

    public function destroy(Owner $owner): JsonResponse
    {
        $owner->delete();

        return response()->json([
            'message' => 'Owner deleted successfully.',
        ]);
    }
}
