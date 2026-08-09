<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Tenant;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class TenantController extends Controller
{
    public function index(): JsonResponse
    {
        $tenants = Tenant::with('contracts')->latest()->paginate(15);

        return response()->json($tenants);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'user_id' => ['nullable', 'exists:users,id'],
            'full_name' => ['required', 'string', 'max:255'],
            'email' => ['required', 'email', 'unique:tenants,email'],
            'phone' => ['nullable', 'string', 'max:50'],
            'national_id' => ['nullable', 'string', 'max:100', 'unique:tenants,national_id'],
            'date_of_birth' => ['nullable', 'date'],
            'emergency_contact' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
        ]);

        $tenant = Tenant::create($validated);

        return response()->json([
            'message' => 'Tenant created successfully.',
            'data' => $tenant,
        ], 201);
    }

    public function show(Tenant $tenant): JsonResponse
    {
        $tenant->load([
            'contracts' => fn ($query) => $query->latest('start_date'),
            'contracts.rentalUnit.property',
            'contracts.payments' => fn ($query) => $query->latest('due_date'),
            'maintenanceRequests' => fn ($query) => $query->latest(),
            'maintenanceRequests.rentalUnit',
        ]);

        $payments = $tenant->contracts
            ->flatMap(function ($contract) {
                return $contract->payments->map(fn ($payment) => [
                    'id' => $payment->id,
                    'reference' => $payment->reference,
                    'amount' => $payment->amount,
                    'due_date' => optional($payment->due_date)->toDateString(),
                    'paid_at' => optional($payment->paid_at)->toDateString(),
                    'method' => $payment->method,
                    'status' => $payment->status,
                    'period' => $payment->period,
                    'contract_number' => $contract->contract_number,
                ]);
            })
            ->sortByDesc(fn ($payment) => $payment['due_date'] ?? '')
            ->values();

        $payload = $tenant->toArray();
        $payload['payment_history'] = $payments->all();
        $payload['receipts'] = $payments->where('status', 'paid')->values()->all();

        return response()->json([
            'data' => $payload,
        ]);
    }

    public function update(Request $request, Tenant $tenant): JsonResponse
    {
        $validated = $request->validate([
            'user_id' => ['nullable', 'exists:users,id'],
            'full_name' => ['sometimes', 'string', 'max:255'],
            'email' => ['sometimes', 'email', 'unique:tenants,email,'.$tenant->id],
            'phone' => ['nullable', 'string', 'max:50'],
            'national_id' => ['nullable', 'string', 'max:100', 'unique:tenants,national_id,'.$tenant->id],
            'date_of_birth' => ['nullable', 'date'],
            'emergency_contact' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
        ]);

        $tenant->update($validated);

        return response()->json([
            'message' => 'Tenant updated successfully.',
            'data' => $tenant,
        ]);
    }

    public function destroy(Tenant $tenant): JsonResponse
    {
        $tenant->delete();

        return response()->json([
            'message' => 'Tenant deleted successfully.',
        ]);
    }
}
