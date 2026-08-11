<?php

namespace App\Services\Payments;

use App\Models\Contract;
use App\Models\Invoice;
use App\Models\Payment;
use App\Models\PaymentAllocation;
use App\Models\PaymentOrder;
use App\Models\PaymentWebhookEvent;
use App\Models\Receipt;
use App\Models\Tenant;
use App\Models\User;
use App\Services\ActivityLogger;
use App\Services\NotificationService;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Str;
use Illuminate\Validation\ValidationException;
use RuntimeException;
use Throwable;

class PaymentOrderService
{
    public function __construct(
        private readonly PaymentGatewayManager $gateways,
        private readonly ActivityLogger $logger,
        private readonly NotificationService $notifications,
    ) {}

    /**
     * @param  list<int>  $invoiceIds
     */
    public function createOrder(
        Tenant $tenant,
        array $invoiceIds,
        float $amount,
        string $method,
        ?int $emiMonths = null,
        ?string $idempotencyKey = null,
        ?User $actor = null,
    ): PaymentOrder {
        if ($idempotencyKey) {
            $existing = PaymentOrder::query()
                ->where('idempotency_key', $idempotencyKey)
                ->where('tenant_id', $tenant->id)
                ->first();
            if ($existing) {
                return $existing;
            }
        }

        return DB::transaction(function () use ($tenant, $invoiceIds, $amount, $method, $emiMonths, $idempotencyKey, $actor) {
            $leaseIds = Contract::query()->where('tenant_id', $tenant->id)->pluck('id');
            $invoiceIds = array_values(array_unique(array_map('intval', $invoiceIds)));

            $invoices = Invoice::query()
                ->whereIn('contract_id', $leaseIds)
                ->whereIn('id', $invoiceIds)
                ->lockForUpdate()
                ->get();

            if ($invoices->count() !== count($invoiceIds)) {
                throw ValidationException::withMessages([
                    'invoice_ids' => ['One or more invoices are not owned by this tenant.'],
                ]);
            }

            foreach ($invoices as $invoice) {
                if (in_array($invoice->status, ['paid', 'cancelled', 'draft'], true)) {
                    throw ValidationException::withMessages([
                        'invoice_ids' => ["Invoice {$invoice->invoice_number} is not payable."],
                    ]);
                }
            }

            $outstanding = round((float) $invoices->sum('remaining_balance'), 2);
            $amount = round($amount, 2);

            if ($amount > $outstanding + 0.009) {
                throw ValidationException::withMessages([
                    'amount' => ["Amount exceeds outstanding balance of {$outstanding}."],
                ]);
            }

            if (count($invoiceIds) > 1 && abs($amount - $outstanding) > 0.009) {
                throw ValidationException::withMessages([
                    'amount' => ['Multi-invoice orders must match the full outstanding total.'],
                ]);
            }

            $contractId = (int) $invoices->first()->contract_id;
            $orgId = $actor?->organization_id
                ?? $tenant->user?->organization_id
                ?? null;

            $order = PaymentOrder::query()->create([
                'order_number' => 'ord_'.Str::uuid()->toString(),
                'tenant_id' => $tenant->id,
                'contract_id' => $contractId,
                'organization_id' => $orgId,
                'invoice_ids' => $invoiceIds,
                'amount' => number_format($amount, 2, '.', ''),
                'currency' => (string) config('payments.currency', 'AED'),
                'method' => $method,
                'emi_months' => $method === 'emi' ? ($emiMonths ?: 3) : null,
                'status' => PaymentOrder::STATUS_PENDING,
                'gateway' => (string) config('payments.default', 'demo'),
                'idempotency_key' => $idempotencyKey,
                'expires_at' => now()->addHour(),
                'meta' => [],
            ]);

            $gateway = $this->gateways->driver($order->gateway);
            $checkout = $gateway->createCheckout($order);

            $order->update([
                'gateway_order_id' => $checkout['gateway_order_id'],
                'checkout_token' => $checkout['checkout_token'],
                'checkout_payload' => $checkout['checkout_payload'],
                'status' => $checkout['status'] ?? PaymentOrder::STATUS_AWAITING,
            ]);

            $this->logger->log('payment.order_created', $order, [
                'order_number' => $order->order_number,
                'amount' => $order->amount,
                'gateway' => $order->gateway,
            ]);

            return $order->fresh();
        });
    }

    public function confirmDemoOrder(PaymentOrder $order, string $checkoutToken, ?string $transactionId = null): PaymentOrder
    {
        if (! in_array($order->gateway, ['demo', 'demo_gateway'], true)) {
            throw ValidationException::withMessages([
                'order' => ['Only demo gateway orders can be confirmed here. Use the Paytm webhook for live payments.'],
            ]);
        }

        if ($order->status === PaymentOrder::STATUS_PAID) {
            return $order;
        }

        if (! $order->isOpen()) {
            throw ValidationException::withMessages([
                'order' => ['Order is not open for confirmation.'],
            ]);
        }

        if (! hash_equals((string) $order->checkout_token, $checkoutToken)) {
            throw ValidationException::withMessages([
                'checkout_token' => ['Invalid checkout token.'],
            ]);
        }

        return $this->capture(
            $order,
            $transactionId ?: 'TXN-DEMO-'.strtoupper(Str::random(10)),
            (string) $order->amount,
            $order->method,
        );
    }

    /**
     * @param  array<string, mixed>  $headers
     * @param  array<string, mixed>  $payload
     * @return array<string, mixed>
     */
    public function handleWebhook(string $provider, string $rawBody, array $headers, array $payload): array
    {
        $driverName = $provider === 'paytm' ? 'paytm' : ($provider ?: (string) config('payments.default', 'demo'));
        $gateway = $this->gateways->driver($driverName);
        $verified = $gateway->verifyWebhook($rawBody, $headers, $payload);

        $eventId = $verified['event_id'] ?? ('evt_'.Str::uuid()->toString());

        $prior = PaymentWebhookEvent::query()
            ->where('provider', $gateway->name())
            ->where('event_id', $eventId)
            ->where('status', 'processed')
            ->first();

        if ($prior) {
            return [
                'ok' => true,
                'message' => 'Event already processed.',
                'verified' => true,
                'duplicate' => true,
                'event_id' => $prior->id,
            ];
        }

        if (! empty($verified['gateway_txn_id'])
            && Payment::query()->where('gateway_txn_id', $verified['gateway_txn_id'])->exists()) {
            PaymentWebhookEvent::query()->create([
                'provider' => $gateway->name(),
                'event_id' => $eventId,
                'order_number' => $verified['order_number'] ?? null,
                'gateway_txn_id' => $verified['gateway_txn_id'] ?? null,
                'status' => 'ignored',
                'signature_valid' => (bool) $verified['valid'],
                'payload' => $verified['payload'] ?? $payload,
                'raw_body' => $rawBody,
                'processed_at' => now(),
            ]);

            return [
                'ok' => true,
                'message' => 'Transaction already captured.',
                'verified' => true,
                'duplicate' => true,
            ];
        }

        $event = PaymentWebhookEvent::query()->create([
            'provider' => $gateway->name(),
            'event_id' => $eventId,
            'order_number' => $verified['order_number'] ?? null,
            'gateway_txn_id' => $verified['gateway_txn_id'] ?? null,
            'status' => 'received',
            'signature_valid' => (bool) $verified['valid'],
            'payload' => $verified['payload'] ?? $payload,
            'raw_body' => $rawBody,
        ]);

        if (! $verified['valid']) {
            $event->update([
                'status' => 'failed',
                'processing_error' => $verified['error'] ?? 'Invalid signature',
                'processed_at' => now(),
            ]);

            return [
                'ok' => false,
                'message' => $verified['error'] ?? 'Webhook signature invalid.',
                'verified' => false,
                'event_id' => $event->id,
            ];
        }

        if (($verified['status'] ?? '') !== 'paid') {
            if (! empty($verified['order_number'])) {
                PaymentOrder::query()
                    ->where(function ($q) use ($verified) {
                        $q->where('order_number', $verified['order_number'])
                            ->orWhere('gateway_order_id', $verified['order_number']);
                    })
                    ->whereIn('status', [PaymentOrder::STATUS_PENDING, PaymentOrder::STATUS_AWAITING])
                    ->update([
                        'status' => PaymentOrder::STATUS_FAILED,
                        'failure_reason' => 'Gateway reported status: '.($verified['status'] ?? 'unknown'),
                    ]);
            }

            $event->update(['status' => 'processed', 'processed_at' => now()]);

            return [
                'ok' => true,
                'message' => 'Non-success status recorded.',
                'verified' => true,
                'data' => ['status' => $verified['status']],
                'event_id' => $event->id,
            ];
        }

        try {
            $result = DB::transaction(function () use ($verified, $event) {
                $orderNumber = (string) ($verified['order_number'] ?? '');
                $order = PaymentOrder::query()
                    ->where(function ($q) use ($orderNumber) {
                        $q->where('order_number', $orderNumber)
                            ->orWhere('gateway_order_id', $orderNumber);
                    })
                    ->lockForUpdate()
                    ->first();

                if (! $order) {
                    $event->update([
                        'status' => 'failed',
                        'processing_error' => 'Order not found',
                        'processed_at' => now(),
                    ]);

                    return [
                        'ok' => false,
                        'message' => 'Payment order not found.',
                        'verified' => true,
                        'event_id' => $event->id,
                    ];
                }

                if ($verified['amount'] !== null
                    && abs((float) $verified['amount'] - (float) $order->amount) > 0.009) {
                    $event->update([
                        'status' => 'failed',
                        'processing_error' => 'Amount mismatch',
                        'processed_at' => now(),
                    ]);

                    return [
                        'ok' => false,
                        'message' => 'Webhook amount does not match order.',
                        'verified' => true,
                        'event_id' => $event->id,
                    ];
                }

                $order = $this->capture(
                    $order,
                    (string) ($verified['gateway_txn_id'] ?: 'TXN-'.strtoupper(Str::random(12))),
                    (string) $order->amount,
                    $verified['method'] ?? $order->method,
                );

                $event->update(['status' => 'processed', 'processed_at' => now()]);

                return [
                    'ok' => true,
                    'message' => 'Payment verified and captured.',
                    'verified' => true,
                    'data' => [
                        'status' => 'successful',
                        'order_number' => $order->order_number,
                        'payment_id' => $order->payment_id,
                        'transaction_id' => $order->gateway_txn_id,
                        'receipt_number' => Receipt::query()
                            ->where('payment_id', $order->payment_id)
                            ->value('receipt_number'),
                    ],
                    'event_id' => $event->id,
                ];
            });
        } catch (Throwable $e) {
            $event->update([
                'status' => 'failed',
                'processing_error' => $e->getMessage(),
                'processed_at' => now(),
            ]);

            throw $e;
        }

        return $result;
    }

    public function capture(
        PaymentOrder $order,
        string $gatewayTxnId,
        string $amount,
        ?string $method = null,
    ): PaymentOrder {
        return DB::transaction(function () use ($order, $gatewayTxnId, $amount, $method) {
            $order = PaymentOrder::query()->whereKey($order->id)->lockForUpdate()->firstOrFail();

            if ($order->status === PaymentOrder::STATUS_PAID) {
                return $order;
            }

            if (! $order->isOpen() && $order->status !== PaymentOrder::STATUS_PENDING) {
                throw new RuntimeException('Order cannot be captured in status '.$order->status);
            }

            if (Payment::query()->where('gateway_txn_id', $gatewayTxnId)->exists()) {
                return $order->fresh();
            }

            $invoiceIds = array_map('intval', $order->invoice_ids ?: []);
            $invoices = Invoice::query()
                ->whereIn('id', $invoiceIds)
                ->orderBy('due_date')
                ->lockForUpdate()
                ->get();

            if ($invoices->isEmpty()) {
                throw new RuntimeException('No invoices found for payment order.');
            }

            $remainingAmount = round((float) $amount, 2);
            $allocations = [];
            foreach ($invoices as $invoice) {
                if ($remainingAmount <= 0) {
                    break;
                }
                $due = round((float) $invoice->remaining_balance, 2);
                if ($due <= 0) {
                    continue;
                }
                $slice = min($due, $remainingAmount);
                $allocations[] = ['invoice' => $invoice, 'amount' => $slice];
                $remainingAmount = round($remainingAmount - $slice, 2);
            }

            if ($allocations === []) {
                throw new RuntimeException('Nothing left to allocate — invoices already paid.');
            }

            $primary = $allocations[0];
            $totalAllocated = round(array_sum(array_column($allocations, 'amount')), 2);
            $payMethod = $method ?: $order->method;

            $payment = Payment::query()->create([
                'contract_id' => $order->contract_id,
                'invoice_id' => $primary['invoice']->id,
                'payment_order_id' => $order->id,
                'reference' => 'PAY-'.strtoupper(Str::random(10)),
                'transaction_number' => $gatewayTxnId,
                'gateway_txn_id' => $gatewayTxnId,
                'gateway' => $order->gateway,
                'amount' => number_format($primary['amount'], 2, '.', ''),
                'currency' => $order->currency,
                'due_date' => optional($primary['invoice']->due_date)->toDateString(),
                'paid_at' => now()->toDateString(),
                'method' => $payMethod,
                'status' => 'paid',
                'period' => $primary['invoice']->billing_month,
                'approval_status' => 'approved',
                'notes' => 'Captured via '.$order->gateway.' order '.$order->order_number,
            ]);

            foreach ($allocations as $row) {
                PaymentAllocation::query()->create([
                    'payment_id' => $payment->id,
                    'invoice_id' => $row['invoice']->id,
                    'amount' => number_format($row['amount'], 2, '.', ''),
                ]);

                if ($row['invoice']->id !== $primary['invoice']->id) {
                    Payment::query()->create([
                        'contract_id' => $order->contract_id,
                        'invoice_id' => $row['invoice']->id,
                        'payment_order_id' => $order->id,
                        'reference' => 'PAY-'.strtoupper(Str::random(10)),
                        'transaction_number' => $gatewayTxnId.'-'.$row['invoice']->id,
                        'gateway_txn_id' => $gatewayTxnId.'-INV'.$row['invoice']->id,
                        'gateway' => $order->gateway,
                        'amount' => number_format($row['amount'], 2, '.', ''),
                        'currency' => $order->currency,
                        'due_date' => optional($row['invoice']->due_date)->toDateString(),
                        'paid_at' => now()->toDateString(),
                        'method' => $payMethod,
                        'status' => 'paid',
                        'period' => $row['invoice']->billing_month,
                        'approval_status' => 'approved',
                        'notes' => 'Allocation from order '.$order->order_number,
                    ]);
                }

                $row['invoice']->recalculateBalances();
            }

            $tenant = $order->tenant ?: Tenant::query()->find($order->tenant_id);
            $contract = $order->contract
                ?: Contract::query()->with('rentalUnit.property')->find($order->contract_id);
            $unit = $contract?->rentalUnit;
            $property = $unit?->property;

            $receipt = Receipt::query()->create([
                'organization_id' => $order->organization_id,
                'tenant_id' => $order->tenant_id,
                'payment_id' => $payment->id,
                'invoice_id' => $primary['invoice']->id,
                'receipt_number' => 'RCP-'.strtoupper(Str::random(8)),
                'payment_date' => now()->toDateString(),
                'tenant_name' => $tenant?->full_name ?: 'Tenant',
                'property_name' => $property?->name,
                'unit_number' => $unit?->unit_number,
                'billing_period' => $primary['invoice']->billing_month,
                'amount_paid' => number_format($totalAllocated, 2, '.', ''),
                'payment_method' => $payMethod,
                'transaction_reference' => $gatewayTxnId,
                'invoice_number' => $invoices->pluck('invoice_number')->implode(', '),
            ]);

            $order->update([
                'status' => PaymentOrder::STATUS_PAID,
                'gateway_txn_id' => $gatewayTxnId,
                'payment_id' => $payment->id,
                'paid_at' => now(),
                'meta' => array_merge($order->meta ?? [], [
                    'receipt_number' => $receipt->receipt_number,
                    'allocated' => collect($allocations)->map(fn ($a) => [
                        'invoice_id' => $a['invoice']->id,
                        'amount' => $a['amount'],
                    ])->all(),
                ]),
            ]);

            $this->logger->log('payment.captured', $payment, [
                'order_number' => $order->order_number,
                'gateway_txn_id' => $gatewayTxnId,
                'receipt_number' => $receipt->receipt_number,
            ]);

            if ($tenant?->user) {
                try {
                    $this->notifications->notify($tenant->user, 'payment.successful', [
                        'title' => 'Payment successful',
                        'body' => 'Payment of '.$order->currency.' '.$order->amount.' was successful.',
                        'module' => 'payments',
                        'action_url' => '/tenant/receipts',
                        'record_type' => Payment::class,
                        'record_id' => $payment->id,
                        'variables' => [
                            'amount' => $order->currency.' '.$order->amount,
                            'invoice_number' => $receipt->invoice_number,
                            'receipt_number' => $receipt->receipt_number,
                        ],
                    ]);
                } catch (Throwable) {
                    // Capture must succeed even if notification delivery fails.
                }
            }

            return $order->fresh(['payment']);
        });
    }
}
