<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\ActivityLog;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;
use Illuminate\Validation\ValidationException;

class PaymentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $payments = Payment::with(['contract.tenant', 'invoice'])
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->when($request->contract_id, fn ($q) => $q->where('contract_id', $request->contract_id))
            ->when($request->invoice_id, fn ($q) => $q->where('invoice_id', $request->invoice_id))
            ->when($user->isTenant(), function ($q) use ($user) {
                $tenantId = $user->tenant?->id;
                $q->whereHas('contract', fn ($c) => $c->where('tenant_id', $tenantId ?: 0));
            })
            ->latest()
            ->paginate((int) $request->get('per_page', 15));

        return response()->json($payments);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'contract_id' => ['required', 'exists:contracts,id'],
            'invoice_id' => ['nullable', 'exists:invoices,id'],
            'amount' => ['required', 'numeric', 'min:0.01'],
            'due_date' => ['nullable', 'date'],
            'paid_at' => ['nullable', 'date'],
            'method' => ['required', Rule::in(Payment::METHODS)],
            'status' => ['sometimes', Rule::in(['pending', 'paid', 'overdue', 'cancelled', 'refunded'])],
            'period' => ['nullable', 'string', 'max:20'],
            'notes' => ['nullable', 'string'],
            'proof_path' => ['nullable', 'string', 'max:255'],
            'approval_status' => ['nullable', Rule::in(['pending', 'approved', 'rejected'])],
            'reference' => ['sometimes', 'string', 'unique:payments,reference'],
        ]);

        $invoice = null;
        if (! empty($validated['invoice_id'])) {
            $invoice = Invoice::query()->findOrFail($validated['invoice_id']);
            $amount = (float) $validated['amount'];
            if ($amount > (float) $invoice->remaining_balance) {
                throw ValidationException::withMessages([
                    'amount' => ['Payment exceeds outstanding balance. Record advance credit separately if needed.'],
                ]);
            }
            $validated['contract_id'] = $invoice->contract_id;
            $validated['period'] ??= $invoice->billing_month;
            $validated['due_date'] ??= optional($invoice->due_date)->toDateString();
        }

        $isManual = in_array($validated['method'], ['cash', 'bank_transfer', 'upi', 'check'], true)
            && ! empty($validated['proof_path']);

        $validated['reference'] ??= 'PAY-'.strtoupper(Str::random(10));
        $validated['transaction_number'] = 'TXN-'.strtoupper(Str::random(12));
        $validated['status'] ??= 'paid';
        $validated['paid_at'] ??= now()->toDateString();
        $validated['approval_status'] = $isManual
            ? ($validated['approval_status'] ?? 'pending')
            : 'approved';

        if ($validated['approval_status'] === 'pending') {
            $validated['status'] = 'pending';
        }

        $payment = Payment::create($validated);

        if ($invoice && $payment->approval_status === 'approved' && $payment->status === 'paid') {
            $invoice->recalculateBalances();
        }

        ActivityLog::record('payment.recorded', $payment, $validated, $request);

        return response()->json([
            'message' => 'Payment recorded successfully.',
            'data' => $payment->load(['contract.tenant', 'invoice']),
        ], 201);
    }

    public function show(Payment $payment): JsonResponse
    {
        $payment->load(['contract.tenant', 'contract.rentalUnit.property', 'invoice']);

        return response()->json(['data' => $payment]);
    }

    public function update(Request $request, Payment $payment): JsonResponse
    {
        $validated = $request->validate([
            'amount' => ['sometimes', 'numeric', 'min:0'],
            'due_date' => ['sometimes', 'date'],
            'paid_at' => ['nullable', 'date'],
            'method' => ['nullable', Rule::in(Payment::METHODS)],
            'status' => ['sometimes', Rule::in(['pending', 'paid', 'overdue', 'cancelled', 'refunded'])],
            'period' => ['nullable', 'string', 'max:20'],
            'notes' => ['nullable', 'string'],
            'proof_path' => ['nullable', 'string', 'max:255'],
            'approval_status' => ['nullable', Rule::in(['pending', 'approved', 'rejected'])],
        ]);

        if (($validated['status'] ?? null) === 'paid') {
            $validated['paid_at'] ??= now()->toDateString();
            $validated['method'] ??= 'bank_transfer';
            $validated['approval_status'] ??= 'approved';
        }

        $payment->update($validated);

        if ($payment->invoice_id) {
            $payment->invoice?->recalculateBalances();
        }

        return response()->json([
            'message' => 'Payment updated successfully.',
            'data' => $payment->fresh(['contract.tenant', 'invoice']),
        ]);
    }

    public function approve(Payment $payment): JsonResponse
    {
        $payment->update([
            'approval_status' => 'approved',
            'status' => 'paid',
            'paid_at' => $payment->paid_at ?: now()->toDateString(),
        ]);

        $payment->invoice?->recalculateBalances();
        ActivityLog::record('payment.approved', $payment);

        return response()->json([
            'message' => 'Payment approved.',
            'data' => $payment->fresh(['invoice', 'contract.tenant']),
        ]);
    }

    public function reject(Request $request, Payment $payment): JsonResponse
    {
        $validated = $request->validate([
            'notes' => ['nullable', 'string'],
        ]);

        $payment->update([
            'approval_status' => 'rejected',
            'status' => 'cancelled',
            'notes' => trim(($payment->notes ? $payment->notes."\n" : '').($validated['notes'] ?? 'Rejected')),
        ]);

        $payment->invoice?->recalculateBalances();
        ActivityLog::record('payment.rejected', $payment, $validated, $request);

        return response()->json([
            'message' => 'Payment rejected.',
            'data' => $payment->fresh(['invoice', 'contract.tenant']),
        ]);
    }

    public function refund(Request $request, Payment $payment): JsonResponse
    {
        $validated = $request->validate([
            'amount' => ['required', 'numeric', 'min:0.01'],
            'reason' => ['required', 'string'],
        ]);

        $amount = (float) $validated['amount'];
        $max = (float) $payment->amount - (float) $payment->refunded_amount;

        if ($amount > $max) {
            throw ValidationException::withMessages([
                'amount' => ['Refund exceeds available payment amount.'],
            ]);
        }

        $payment->update([
            'refunded_amount' => (float) $payment->refunded_amount + $amount,
            'refund_reason' => $validated['reason'],
            'status' => $amount >= (float) $payment->amount ? 'refunded' : $payment->status,
        ]);

        $payment->invoice?->recalculateBalances();
        ActivityLog::record('payment.refunded', $payment, $validated, $request);

        return response()->json([
            'message' => 'Refund recorded.',
            'data' => $payment->fresh(['invoice', 'contract.tenant']),
        ]);
    }

    public function destroy(Payment $payment): JsonResponse
    {
        $invoice = $payment->invoice;
        $payment->delete();
        $invoice?->recalculateBalances();

        return response()->json([
            'message' => 'Payment deleted successfully.',
        ]);
    }

    public function transactions(Request $request): JsonResponse
    {
        $user = $request->user();

        $rows = Payment::with(['contract.tenant', 'invoice'])
            ->whereNotNull('transaction_number')
            ->when($user->isTenant(), function ($q) use ($user) {
                $tenantId = $user->tenant?->id;
                $q->whereHas('contract', fn ($c) => $c->where('tenant_id', $tenantId ?: 0));
            })
            ->latest()
            ->paginate((int) $request->get('per_page', 20));

        return response()->json($rows);
    }
}
