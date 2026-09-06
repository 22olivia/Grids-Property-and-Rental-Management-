<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\ActivityLog;
use App\Services\InvoiceService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class InvoiceController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $invoices = Invoice::with(['contract.tenant', 'contract.rentalUnit.property'])
            ->when($request->status, function ($q) use ($request) {
                $status = strtolower((string) $request->status);
                // "unpaid" / "payable" = bills that still need payment (matches demo API + Pay rent).
                if (in_array($status, ['unpaid', 'payable', 'open'], true)) {
                    $q->whereIn('status', ['unpaid', 'partially_paid', 'overdue', 'pending']);
                } else {
                    $q->where('status', $request->status);
                }
            })
            ->when($request->billing_month, fn ($q) => $q->where('billing_month', $request->billing_month))
            ->when($request->search, function ($q) use ($request) {
                $term = '%'.$request->search.'%';
                $q->where(function ($inner) use ($term) {
                    $inner->where('invoice_number', 'like', $term)
                        ->orWhereHas('contract.tenant', fn ($t) => $t->where('full_name', 'like', $term));
                });
            })
            ->when($user->isTenant(), function ($q) use ($user) {
                $tenantId = $user->tenant?->id;
                $q->whereHas('contract', fn ($c) => $c->where('tenant_id', $tenantId ?: 0));
            })
            ->latest()
            ->paginate((int) $request->get('per_page', 15));

        return response()->json($invoices);
    }

    public function show(Invoice $invoice): JsonResponse
    {
        $invoice->load([
            'contract.tenant',
            'contract.rentalUnit.property',
            'payments' => fn ($q) => $q->latest(),
        ]);

        return response()->json(['data' => $invoice]);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'contract_id' => ['required', 'exists:contracts,id'],
            'billing_month' => ['required', 'string', 'max:7'],
            'rent_amount' => ['required', 'numeric', 'min:0'],
            'additional_charges' => ['sometimes', 'numeric', 'min:0'],
            'discounts' => ['sometimes', 'numeric', 'min:0'],
            'late_fee' => ['sometimes', 'numeric', 'min:0'],
            'previous_balance' => ['sometimes', 'numeric', 'min:0'],
            'due_date' => ['required', 'date'],
            'status' => ['sometimes', Rule::in(['draft', 'unpaid', 'partially_paid', 'paid', 'overdue', 'cancelled'])],
            'notes' => ['nullable', 'string'],
            'invoice_number' => ['sometimes', 'string', 'unique:invoices,invoice_number'],
        ]);

        $rent = (float) $validated['rent_amount'];
        $extra = (float) ($validated['additional_charges'] ?? 0);
        $discount = (float) ($validated['discounts'] ?? 0);
        $late = (float) ($validated['late_fee'] ?? 0);
        $previous = (float) ($validated['previous_balance'] ?? 0);
        $total = round($rent + $extra + $late + $previous - $discount, 2);

        $invoice = Invoice::create([
            ...$validated,
            'invoice_number' => $validated['invoice_number'] ?? ('INV-'.strtoupper(Str::random(10))),
            'additional_charges' => $extra,
            'discounts' => $discount,
            'late_fee' => $late,
            'previous_balance' => $previous,
            'total_amount' => $total,
            'paid_amount' => 0,
            'remaining_balance' => $total,
            'status' => $validated['status'] ?? 'unpaid',
        ]);

        ActivityLog::record('invoice.created', $invoice, $validated, $request);

        return response()->json([
            'message' => 'Invoice created.',
            'data' => $invoice->load(['contract.tenant', 'contract.rentalUnit.property']),
        ], 201);
    }

    public function generate(InvoiceService $invoices): JsonResponse
    {
        $count = $invoices->generateForActiveLeases();
        ActivityLog::record('invoice.generated_batch', null, ['count' => $count]);

        $message = $count > 0
            ? "Generated {$count} invoice(s) for active leases."
            : 'No new invoices needed — every active lease already has bills for the current, previous, and next month.';

        return response()->json([
            'message' => $message,
            'data' => [
                'generated' => $count,
                'billing_month' => now()->format('Y-m'),
            ],
        ]);
    }

    public function cancel(Invoice $invoice): JsonResponse
    {
        $invoice->update([
            'status' => 'cancelled',
            'remaining_balance' => 0,
        ]);
        ActivityLog::record('invoice.cancelled', $invoice);

        return response()->json([
            'message' => 'Invoice cancelled.',
            'data' => $invoice,
        ]);
    }

    public function destroy(Invoice $invoice): JsonResponse
    {
        ActivityLog::record('invoice.deleted', $invoice, [
            'invoice_number' => $invoice->invoice_number,
            'billing_month' => $invoice->billing_month,
            'status' => $invoice->status,
        ]);

        // Clear payment links first so delete succeeds even when DB foreign keys
        // are strict / cascade is unavailable (e.g. some SQLite setups).
        $invoice->allocations()->delete();
        $invoice->payments()->update(['invoice_id' => null]);
        $invoice->delete();

        return response()->json(['message' => 'Invoice deleted.']);
    }
}
