<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\Payment;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;

class PaymentController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $payments = Payment::with('contract.tenant')
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->when($request->contract_id, fn ($q) => $q->where('contract_id', $request->contract_id))
            ->latest()
            ->paginate(15);

        return response()->json($payments);
    }

    public function store(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'contract_id' => ['required', 'exists:contracts,id'],
            'amount' => ['required', 'numeric', 'min:0'],
            'due_date' => ['required', 'date'],
            'paid_at' => ['nullable', 'date'],
            'method' => ['nullable', 'string', 'in:cash,bank_transfer,card,check'],
            'status' => ['sometimes', 'string', 'in:pending,paid,overdue,cancelled,refunded'],
            'period' => ['nullable', 'string', 'max:20'],
            'notes' => ['nullable', 'string'],
            'reference' => ['sometimes', 'string', 'unique:payments,reference'],
        ]);

        $validated['reference'] ??= 'PAY-'.strtoupper(Str::random(10));

        $payment = Payment::create($validated);

        return response()->json([
            'message' => 'Payment created successfully.',
            'data' => $payment->load('contract'),
        ], 201);
    }

    public function show(Payment $payment): JsonResponse
    {
        $payment->load('contract.tenant');

        return response()->json(['data' => $payment]);
    }

    public function update(Request $request, Payment $payment): JsonResponse
    {
        $validated = $request->validate([
            'amount' => ['sometimes', 'numeric', 'min:0'],
            'due_date' => ['sometimes', 'date'],
            'paid_at' => ['nullable', 'date'],
            'method' => ['nullable', 'string', 'in:cash,bank_transfer,card,check'],
            'status' => ['sometimes', 'string', 'in:pending,paid,overdue,cancelled,refunded'],
            'period' => ['nullable', 'string', 'max:20'],
            'notes' => ['nullable', 'string'],
        ]);

        $payment->update($validated);

        return response()->json([
            'message' => 'Payment updated successfully.',
            'data' => $payment->fresh('contract'),
        ]);
    }

    public function destroy(Payment $payment): JsonResponse
    {
        $payment->delete();

        return response()->json([
            'message' => 'Payment deleted successfully.',
        ]);
    }
}
