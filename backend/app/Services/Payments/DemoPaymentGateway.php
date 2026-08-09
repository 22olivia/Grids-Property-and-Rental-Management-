<?php

namespace App\Services\Payments;

use App\Models\PaymentOrder;
use Illuminate\Support\Str;

class DemoPaymentGateway implements PaymentGatewayInterface
{
    public function name(): string
    {
        return 'demo';
    }

    public function createCheckout(PaymentOrder $order): array
    {
        $gatewayOrderId = 'DEMO-'.strtoupper(Str::random(12));
        $token = hash_hmac(
            'sha256',
            $order->order_number.'|'.$order->amount.'|'.$gatewayOrderId,
            (string) config('payments.webhook_secret')
        );

        return [
            'gateway_order_id' => $gatewayOrderId,
            'checkout_token' => $token,
            'checkout_payload' => [
                'mode' => 'demo',
                'provider' => 'demo',
                'order_id' => $order->order_number,
                'gateway_order_id' => $gatewayOrderId,
                'amount' => (string) $order->amount,
                'currency' => $order->currency,
                'method' => $order->method,
                'emi_months' => $order->emi_months,
                'checkout_url' => rtrim((string) config('app.frontend_url'), '/').'/payments/checkout?order='.$order->order_number,
                'confirm_hint' => 'POST /api/v1/payments/orders/{order}/confirm with checkout_token, or send signed webhook.',
                'instructions' => 'Demo gateway — no real money moves. Confirm the order to capture payment.',
            ],
            'status' => PaymentOrder::STATUS_AWAITING,
        ];
    }

    public function verifyWebhook(string $rawBody, array $headers, array $payload): array
    {
        $secret = (string) config('payments.webhook_secret');
        $signature = $this->header($headers, 'x-demo-signature')
            ?: $this->header($headers, 'x-signature')
            ?: $this->header($headers, 'x-gpms-signature');

        $valid = $signature !== '' && hash_equals($secret, $signature);

        $orderNumber = $payload['order_id'] ?? $payload['order_number'] ?? null;
        $txnId = $payload['transaction_id'] ?? $payload['gateway_txn_id'] ?? null;
        $status = strtolower((string) ($payload['status'] ?? 'successful'));
        $normalized = in_array($status, ['success', 'successful', 'paid', 'captured', 'txn_success'], true)
            ? 'paid'
            : (in_array($status, ['failed', 'failure', 'cancelled', 'canceled'], true) ? 'failed' : $status);

        if (! $valid) {
            return [
                'valid' => false,
                'event_id' => $payload['event_id'] ?? $txnId,
                'order_number' => $orderNumber,
                'gateway_txn_id' => $txnId,
                'amount' => isset($payload['amount']) ? (string) $payload['amount'] : null,
                'status' => $normalized,
                'method' => $payload['method'] ?? null,
                'payload' => $payload,
                'error' => 'Invalid webhook signature.',
            ];
        }

        return [
            'valid' => true,
            'event_id' => $payload['event_id'] ?? ($txnId ? 'demo_'.$txnId : null),
            'order_number' => $orderNumber,
            'gateway_txn_id' => $txnId,
            'amount' => isset($payload['amount']) ? (string) $payload['amount'] : null,
            'status' => $normalized,
            'method' => $payload['method'] ?? null,
            'payload' => $payload,
            'error' => null,
        ];
    }

    public function refund(PaymentOrder $order, float $amount, string $reason): array
    {
        return [
            'success' => true,
            'gateway_refund_id' => 'REF-DEMO-'.strtoupper(Str::random(8)),
            'message' => 'Demo refund recorded locally.',
        ];
    }

    private function header(array $headers, string $name): string
    {
        $lower = strtolower($name);
        foreach ($headers as $key => $value) {
            if (strtolower((string) $key) === $lower) {
                return is_array($value) ? (string) ($value[0] ?? '') : (string) $value;
            }
        }

        return '';
    }
}
