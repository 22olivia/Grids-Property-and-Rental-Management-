<?php

namespace App\Services\Payments;

use App\Models\PaymentOrder;

interface PaymentGatewayInterface
{
    public function name(): string;

    /**
     * Create a provider-side checkout session for the order.
     *
     * @return array{gateway_order_id: string, checkout_token: ?string, checkout_payload: array, status: string}
     */
    public function createCheckout(PaymentOrder $order): array;

    /**
     * Verify an inbound webhook / callback.
     *
     * @return array{
     *   valid: bool,
     *   event_id: ?string,
     *   order_number: ?string,
     *   gateway_txn_id: ?string,
     *   amount: ?string,
     *   status: string,
     *   method: ?string,
     *   payload: array,
     *   error: ?string
     * }
     */
    public function verifyWebhook(string $rawBody, array $headers, array $payload): array;

    /**
     * Optional provider refund. Demo gateway records locally only.
     *
     * @return array{success: bool, gateway_refund_id: ?string, message: string}
     */
    public function refund(PaymentOrder $order, float $amount, string $reason): array;
}
