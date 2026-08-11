<?php

namespace App\Services\Payments;

use App\Models\PaymentOrder;
use Illuminate\Support\Str;
use RuntimeException;

/**
 * Paytm-shaped gateway driver.
 *
 * When PAYTM_MERCHANT_ID / PAYTM_MERCHANT_KEY are unset, checkout creation fails
 * with a clear configuration error. Checksum helpers follow Paytm's classic
 * HMAC-SHA256 + base64 pattern so real keys can be wired without redesign.
 */
class PaytmPaymentGateway implements PaymentGatewayInterface
{
    public function name(): string
    {
        return 'paytm';
    }

    public function createCheckout(PaymentOrder $order): array
    {
        $mid = (string) config('payments.paytm.merchant_id');
        $key = (string) config('payments.paytm.merchant_key');
        $website = (string) config('payments.paytm.website', 'WEBSTAGING');
        $channel = (string) config('payments.paytm.channel_id', 'WEB');
        $industry = (string) config('payments.paytm.industry_type', 'Retail');
        $baseUrl = rtrim((string) config('payments.paytm.base_url', 'https://securegw-stage.paytm.in'), '/');

        if ($mid === '' || $key === '') {
            throw new RuntimeException(
                'Paytm is not configured. Set PAYTM_MERCHANT_ID and PAYTM_MERCHANT_KEY, or use PAYMENT_GATEWAY=demo.'
            );
        }

        $gatewayOrderId = $order->order_number;
        $callback = url('/api/v1/payments/webhook/paytm');

        $body = [
            'requestType' => 'Payment',
            'mid' => $mid,
            'websiteName' => $website,
            'orderId' => $gatewayOrderId,
            'callbackUrl' => $callback,
            'txnAmount' => [
                'value' => number_format((float) $order->amount, 2, '.', ''),
                'currency' => $order->currency === 'INR' ? 'INR' : 'INR',
            ],
            'userInfo' => [
                'custId' => 'TENANT_'.$order->tenant_id,
            ],
        ];

        if ($order->method === 'emi' && $order->emi_months) {
            $body['extendInfo'] = [
                'emiMonths' => (string) $order->emi_months,
            ];
        }

        $checksum = $this->checksum(json_encode($body, JSON_UNESCAPED_SLASHES), $key);
        $token = 'paytm_'.Str::lower(Str::random(24));

        return [
            'gateway_order_id' => $gatewayOrderId,
            'checkout_token' => $token,
            'checkout_payload' => [
                'mode' => 'paytm',
                'provider' => 'paytm',
                'mid' => $mid,
                'order_id' => $gatewayOrderId,
                'amount' => number_format((float) $order->amount, 2, '.', ''),
                'currency' => 'INR',
                'website' => $website,
                'channel_id' => $channel,
                'industry_type' => $industry,
                'callback_url' => $callback,
                'initiate_url' => $baseUrl.'/theia/api/v1/initiateTransaction?mid='.$mid.'&orderId='.$gatewayOrderId,
                'checksum' => $checksum,
                'body' => $body,
                'note' => 'Frontend should call Paytm initiateTransaction with this payload, then open Checkout JS.',
            ],
            'status' => PaymentOrder::STATUS_AWAITING,
        ];
    }

    public function verifyWebhook(string $rawBody, array $headers, array $payload): array
    {
        $key = (string) config('payments.paytm.merchant_key');
        $checksum = $payload['CHECKSUMHASH']
            ?? $payload['checksum']
            ?? $this->header($headers, 'x-paytm-checksum')
            ?: '';

        $orderNumber = $payload['ORDERID'] ?? $payload['orderId'] ?? $payload['order_id'] ?? null;
        $txnId = $payload['TXNID'] ?? $payload['txnId'] ?? $payload['transaction_id'] ?? null;
        $amount = $payload['TXNAMOUNT'] ?? $payload['txnAmount'] ?? $payload['amount'] ?? null;
        $statusRaw = strtoupper((string) ($payload['STATUS'] ?? $payload['status'] ?? ''));
        $status = in_array($statusRaw, ['TXN_SUCCESS', 'SUCCESS', 'PAID'], true) ? 'paid' : 'failed';

        $valid = false;
        $error = null;

        if ($key === '') {
            $error = 'Paytm merchant key not configured.';
        } elseif ($checksum === '') {
            $error = 'Missing Paytm checksum.';
        } else {
            $checkPayload = $payload;
            unset($checkPayload['CHECKSUMHASH'], $checkPayload['checksum']);
            $valid = $this->verifyChecksum($checkPayload, $checksum, $key);
            if (! $valid) {
                $error = 'Invalid Paytm checksum.';
            }
        }

        return [
            'valid' => $valid,
            'event_id' => $txnId ? 'paytm_'.$txnId : ($orderNumber ? 'paytm_order_'.$orderNumber : null),
            'order_number' => $orderNumber,
            'gateway_txn_id' => $txnId,
            'amount' => $amount !== null ? (string) $amount : null,
            'status' => $status,
            'method' => $payload['PAYMENTMODE'] ?? $payload['method'] ?? null,
            'payload' => $payload,
            'error' => $error,
        ];
    }

    public function refund(PaymentOrder $order, float $amount, string $reason): array
    {
        $mid = (string) config('payments.paytm.merchant_id');
        $key = (string) config('payments.paytm.merchant_key');

        if ($mid === '' || $key === '') {
            return [
                'success' => false,
                'gateway_refund_id' => null,
                'message' => 'Paytm not configured for refunds.',
            ];
        }

        // Real Paytm refund API call would go here when credentials + network are available.
        return [
            'success' => false,
            'gateway_refund_id' => null,
            'message' => 'Paytm refund API call is not executed in this environment. Record ledger refund after provider confirmation.',
        ];
    }

    public function checksum(string $bodyJson, string $key): string
    {
        return base64_encode(hash_hmac('sha256', $bodyJson, $key, true));
    }

    public function verifyChecksum(array $params, string $checksum, string $key): bool
    {
        ksort($params);
        $string = '';
        foreach ($params as $k => $v) {
            if (is_array($v)) {
                $v = json_encode($v, JSON_UNESCAPED_SLASHES);
            }
            $string .= $k.'='.$v.'&';
        }
        $string = rtrim($string, '&');
        $expected = $this->checksum($string, $key);

        return hash_equals($expected, $checksum);
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
