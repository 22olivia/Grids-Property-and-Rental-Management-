<?php

namespace App\Services\Payments;

use InvalidArgumentException;

class PaymentGatewayManager
{
    public function driver(?string $name = null): PaymentGatewayInterface
    {
        $name = $name ?: (string) config('payments.default', 'demo');

        return match ($name) {
            'demo', 'demo_gateway' => new DemoPaymentGateway,
            'paytm' => new PaytmPaymentGateway,
            default => throw new InvalidArgumentException("Unsupported payment gateway [{$name}]."),
        };
    }
}
