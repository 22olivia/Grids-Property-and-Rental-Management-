<?php

namespace App\Services\Notifications\Channels;

class ChannelDeliveryResult
{
    /**
     * @param  array<string, mixed>  $providerResponse
     */
    public function __construct(
        public readonly string $status,
        public readonly ?string $providerMessageId = null,
        public readonly array $providerResponse = [],
        public readonly ?string $errorMessage = null,
    ) {}

    /**
     * @param  array<string, mixed>  $providerResponse
     */
    public static function sent(string $providerMessageId, array $providerResponse = []): self
    {
        return new self('sent', $providerMessageId, $providerResponse);
    }

    /**
     * @param  array<string, mixed>  $providerResponse
     */
    public static function skipped(string $reason, array $providerResponse = []): self
    {
        return new self('skipped', null, $providerResponse, $reason);
    }

    public static function failed(string $error, array $providerResponse = []): self
    {
        return new self('failed', null, $providerResponse + ['ok' => false, 'error' => $error], $error);
    }
}
