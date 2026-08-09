<?php

return [

    /*
    |--------------------------------------------------------------------------
    | Default payment gateway
    |--------------------------------------------------------------------------
    |
    | demo  — full local checkout + confirm/webhook capture (no real money)
    | paytm — Paytm-shaped checkout payload (requires merchant credentials)
    |
    */

    'default' => env('PAYMENT_GATEWAY', 'demo'),

    'currency' => env('PAYMENT_CURRENCY', 'AED'),

    'webhook_secret' => env('PAYMENT_WEBHOOK_SECRET', 'demo-verified'),

    'paytm' => [
        'merchant_id' => env('PAYTM_MERCHANT_ID'),
        'merchant_key' => env('PAYTM_MERCHANT_KEY'),
        'website' => env('PAYTM_WEBSITE', 'WEBSTAGING'),
        'channel_id' => env('PAYTM_CHANNEL_ID', 'WEB'),
        'industry_type' => env('PAYTM_INDUSTRY_TYPE', 'Retail'),
        'base_url' => env('PAYTM_BASE_URL', 'https://securegw-stage.paytm.in'),
    ],

];
