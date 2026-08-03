<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Contract;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class ContractController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $contracts = Contract::with(['tenant', 'rentalUnit.property'])
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->when($request->tenant_id, fn ($q) => $q->where('tenant_id', $request->tenant_id))
            ->latest()
            ->paginate(15);

        return response()->json($contracts);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'rental_unit_id' => ['required', 'exists:rental_units,id'],
            'tenant_id' => ['required', 'exists:tenants,id'],
            'start_date' => ['required', 'date'],
            'end_date' => ['nullable', 'date', 'after:start_date'],
            'monthly_rent' => ['required', 'numeric', 'min:0'],
            'deposit_amount' => ['sometimes', 'numeric', 'min:0'],
            'payment_day' => ['sometimes', 'integer', 'min:1', 'max:28'],
            'status' => ['sometimes', 'string', 'in:draft,active,expired,terminated'],
            'terms' => ['nullable', 'string'],
            'contract_number' => ['sometimes', 'string', 'unique:contracts,contract_number'],
        ]);

        $validated['contract_number'] ??= 'CTR-'.strtoupper(Str::random(8));

        $contract = Contract::create($validated);

        return response()->json([
            'message' => 'Contract created successfully.',
            'data' => $contract->load(['tenant', 'rentalUnit']),
        ], 201);
    }

    public function show(Contract $contract): JsonResponse
    {
        $contract->load(['tenant', 'rentalUnit.property', 'payments']);

        return response()->json(['data' => $contract]);
    }

    public function update(Request $request, Contract $contract): JsonResponse
    {
        $validated = $request->validate([
            'rental_unit_id' => ['sometimes', 'exists:rental_units,id'],
            'tenant_id' => ['sometimes', 'exists:tenants,id'],
            'start_date' => ['sometimes', 'date'],
            'end_date' => ['nullable', 'date'],
            'monthly_rent' => ['sometimes', 'numeric', 'min:0'],
            'deposit_amount' => ['sometimes', 'numeric', 'min:0'],
            'payment_day' => ['sometimes', 'integer', 'min:1', 'max:28'],
            'status' => ['sometimes', 'string', 'in:draft,active,expired,terminated'],
            'terms' => ['nullable', 'string'],
        ]);

        $contract->update($validated);

        return response()->json([
            'message' => 'Contract updated successfully.',
            'data' => $contract->fresh(['tenant', 'rentalUnit']),
        ]);
    }

    public function destroy(Contract $contract): JsonResponse
    {
        $contract->delete();

        return response()->json([
            'message' => 'Contract deleted successfully.',
        ]);
    }
}
