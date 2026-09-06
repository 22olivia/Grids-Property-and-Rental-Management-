<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Contract;
use App\Models\ActivityLog;
use App\Services\InvoiceService;
use App\Services\LeaseService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class LeaseController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $leases = Contract::with(['tenant', 'rentalUnit.property'])
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->when($request->tenant_id, fn ($q) => $q->where('tenant_id', $request->tenant_id))
            ->when($request->search, function ($q) use ($request) {
                $term = '%'.$request->search.'%';
                $q->where(function ($inner) use ($term) {
                    $inner->where('contract_number', 'like', $term)
                        ->orWhereHas('tenant', fn ($t) => $t->where('full_name', 'like', $term));
                });
            })
            ->when($user->isTenant(), function ($q) use ($user) {
                $tenantId = $user->tenant?->id;
                $q->where('tenant_id', $tenantId ?: 0);
            })
            ->latest()
            ->paginate((int) $request->get('per_page', 15));

        return response()->json($leases);
    }

    public function store(Request $request, LeaseService $leases): JsonResponse
    {
        $validated = $this->validatedPayload($request);
        $leases->assertNoOverlap(
            (int) $validated['rental_unit_id'],
            $validated['start_date'],
            $validated['end_date'] ?? null,
        );

        $validated['contract_number'] ??= 'CTR-'.strtoupper(Str::random(8));
        $validated['status'] ??= 'draft';
        $validated['created_by'] = $request->user()->id;
        $validated['grace_period_days'] ??= 3;
        $validated['payment_frequency'] ??= 'monthly';
        $validated['late_fee_amount'] ??= 0;

        $lease = Contract::create($validated);
        $leases->syncUnitOccupancy($lease);
        ActivityLog::record('lease.created', $lease, $validated, $request);

        return response()->json([
            'message' => 'Lease created successfully.',
            'data' => $lease->load(['tenant', 'rentalUnit.property']),
        ], 201);
    }

    public function show(Contract $lease): JsonResponse
    {
        $lease->load([
            'tenant',
            'rentalUnit.property',
            'payments' => fn ($q) => $q->latest(),
            'invoices' => fn ($q) => $q->latest(),
            'creator',
        ]);

        return response()->json(['data' => $lease]);
    }

    public function update(Request $request, Contract $lease, LeaseService $leases): JsonResponse
    {
        $validated = $this->validatedPayload($request, partial: true);

        $unitId = $validated['rental_unit_id'] ?? $lease->rental_unit_id;
        $start = $validated['start_date'] ?? $lease->start_date?->toDateString();
        $end = array_key_exists('end_date', $validated)
            ? $validated['end_date']
            : $lease->end_date?->toDateString();

        if ($start) {
            $leases->assertNoOverlap((int) $unitId, $start, $end, $lease->id);
        }

        $lease->update($validated);
        $leases->syncUnitOccupancy($lease->fresh());
        ActivityLog::record('lease.updated', $lease, $validated, $request);

        return response()->json([
            'message' => 'Lease updated successfully.',
            'data' => $lease->fresh(['tenant', 'rentalUnit.property']),
        ]);
    }

    public function activate(Contract $lease, LeaseService $leases, InvoiceService $invoices): JsonResponse
    {
        $leases->assertNoOverlap(
            $lease->rental_unit_id,
            $lease->start_date->toDateString(),
            $lease->end_date?->toDateString(),
            $lease->id,
        );

        $lease->update([
            'status' => 'active',
            'move_in_date' => $lease->move_in_date ?: now()->toDateString(),
        ]);
        $leases->syncUnitOccupancy($lease);
        $invoices->ensurePeriodInvoice($lease);
        ActivityLog::record('lease.activated', $lease);

        return response()->json([
            'message' => 'Lease activated.',
            'data' => $lease->fresh(['tenant', 'rentalUnit.property', 'invoices']),
        ]);
    }

    public function terminate(Request $request, Contract $lease): JsonResponse
    {
        $validated = $request->validate([
            'move_out_date' => ['nullable', 'date'],
            'notes' => ['nullable', 'string'],
        ]);

        $lease->update([
            'status' => 'terminated',
            'move_out_date' => $validated['move_out_date'] ?? now()->toDateString(),
            'notes' => trim(($lease->notes ? $lease->notes."\n" : '').($validated['notes'] ?? '')),
        ]);

        $lease->rentalUnit()->update(['status' => 'vacant']);
        ActivityLog::record('lease.terminated', $lease, $validated, $request);

        return response()->json([
            'message' => 'Lease terminated.',
            'data' => $lease->fresh(['tenant', 'rentalUnit.property']),
        ]);
    }

    public function renew(Request $request, Contract $lease, LeaseService $leases): JsonResponse
    {
        $validated = $request->validate([
            'start_date' => ['required', 'date'],
            'end_date' => ['nullable', 'date', 'after:start_date'],
            'monthly_rent' => ['sometimes', 'numeric', 'min:0'],
            'deposit_amount' => ['sometimes', 'numeric', 'min:0'],
            'terms' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
        ]);

        $leases->assertNoOverlap(
            $lease->rental_unit_id,
            $validated['start_date'],
            $validated['end_date'] ?? null,
            $lease->id,
        );

        $lease->update(['status' => 'renewed']);

        $renewal = Contract::create([
            'contract_number' => 'CTR-'.strtoupper(Str::random(8)),
            'rental_unit_id' => $lease->rental_unit_id,
            'tenant_id' => $lease->tenant_id,
            'start_date' => $validated['start_date'],
            'end_date' => $validated['end_date'] ?? null,
            'monthly_rent' => $validated['monthly_rent'] ?? $lease->monthly_rent,
            'deposit_amount' => $validated['deposit_amount'] ?? $lease->deposit_amount,
            'payment_day' => $lease->payment_day,
            'grace_period_days' => $lease->grace_period_days,
            'late_fee_amount' => $lease->late_fee_amount,
            'payment_frequency' => $lease->payment_frequency,
            'status' => 'active',
            'terms' => $validated['terms'] ?? $lease->terms,
            'notes' => $validated['notes'] ?? 'Renewed from '.$lease->contract_number,
            'created_by' => $request->user()->id,
            'move_in_date' => $validated['start_date'],
        ]);

        $leases->syncUnitOccupancy($renewal);
        ActivityLog::record('lease.renewed', $renewal, ['from' => $lease->id], $request);

        return response()->json([
            'message' => 'Lease renewed successfully.',
            'data' => $renewal->load(['tenant', 'rentalUnit.property']),
            'previous' => $lease,
        ], 201);
    }

    public function timeline(Contract $lease): JsonResponse
    {
        $logs = \App\Models\ActivityLog::query()
            ->where('subject_type', Contract::class)
            ->where('subject_id', $lease->id)
            ->latest()
            ->limit(50)
            ->get();

        return response()->json(['data' => $logs]);
    }

    /**
     * @return array<string, mixed>
     */
    private function validatedPayload(Request $request, bool $partial = false): array
    {
        $required = $partial ? 'sometimes' : 'required';

        return $request->validate([
            'rental_unit_id' => [$required, 'exists:rental_units,id'],
            'tenant_id' => [$required, 'exists:tenants,id'],
            'start_date' => [$required, 'date'],
            'end_date' => ['nullable', 'date', 'after:start_date'],
            'monthly_rent' => [$required, 'numeric', 'min:0'],
            'deposit_amount' => ['sometimes', 'numeric', 'min:0'],
            'payment_day' => ['sometimes', 'integer', 'min:1', 'max:28'],
            'grace_period_days' => ['sometimes', 'integer', 'min:0', 'max:60'],
            'late_fee_amount' => ['sometimes', 'numeric', 'min:0'],
            'payment_frequency' => ['sometimes', Rule::in(['monthly', 'quarterly', 'yearly'])],
            'status' => ['sometimes', Rule::in(Contract::STATUSES)],
            'terms' => ['nullable', 'string'],
            'notes' => ['nullable', 'string'],
            'agreement_path' => ['nullable', 'string', 'max:255'],
            'move_in_date' => ['nullable', 'date'],
            'move_out_date' => ['nullable', 'date'],
            'contract_number' => ['sometimes', 'string', 'unique:contracts,contract_number'],
        ]);
    }
}
