# GPMS Payments API

Online rent checkout for tenants: **create order → gateway checkout → webhook/confirm → ledger + receipt**.

## Modes

| `PAYMENT_GATEWAY` | Behaviour |
|-------------------|-----------|
| `demo` (default) | No real money. Returns checkout payload + token. Confirm via API or signed webhook. |
| `paytm` | Builds Paytm initiateTransaction payload. Requires `PAYTM_MERCHANT_ID` + `PAYTM_MERCHANT_KEY`. Capture via Paytm webhook checksum. |

## Env

```env
PAYMENT_GATEWAY=paytm
PAYMENT_CURRENCY=AED
PAYMENT_WEBHOOK_SECRET=demo-verified
PAYTM_MERCHANT_ID=your-staging-mid
PAYTM_MERCHANT_KEY="your-test-key"
PAYTM_WEBSITE=WEBSTAGING
PAYTM_CHANNEL_ID=WEB
PAYTM_INDUSTRY_TYPE=Retail
PAYTM_BASE_URL=https://securegw-stage.paytm.in
```

Use `PAYMENT_GATEWAY=demo` for local demos without a merchant account. Quote `PAYTM_MERCHANT_KEY` when it contains `&` or other special characters.

## Tenant flow (demo)

1. List open invoices: `GET /api/v1/invoices`
2. Create order:

```http
POST /api/v1/payments/orders
Authorization: Bearer {tenant_token}
Content-Type: application/json
Idempotency-Key: optional-unique-key

{
  "invoice_ids": [12],
  "amount": 4500.00,
  "method": "upi"
}
```

Response includes `checkout_token`, `checkout` payload, and `order_number` (`data.id`).

3. Confirm (demo only):

```http
POST /api/v1/payments/orders/{order_number}/confirm
Authorization: Bearer {tenant_token}

{
  "checkout_token": "...",
  "transaction_id": "TXN-OPTIONAL"
}
```

Or send a signed webhook (no auth):

```http
POST /api/v1/payments/webhook
X-Demo-Signature: demo-verified
Content-Type: application/json

{
  "order_id": "ord_...",
  "transaction_id": "TXN-123",
  "amount": 4500.00,
  "status": "successful",
  "method": "upi"
}
```

4. On capture the API atomically:
   - marks the order `paid`
   - creates `payments` + `payment_allocations`
   - recalculates invoice balances / status
   - creates a `receipts` row
   - notifies the tenant (`payment.successful`)

## Paytm

1. Set `PAYMENT_GATEWAY=paytm` and merchant env vars.
2. `POST /payments/orders` returns Paytm `checkout` body + checksum.
3. Frontend calls Paytm `initiateTransaction`, then Checkout JS.
4. Paytm posts to `POST /api/v1/payments/webhook/paytm` — checksum verified, then same capture path.

## Status endpoints

- `GET /api/v1/payments/orders/{order_number}` — order status (tenant)
- `GET /api/v1/tenant/receipts` — persisted receipts (falls back to paid payments if empty)
- `GET /api/v1/transactions` — payments with transaction numbers

## Manual / offline payments

Staff can still use `POST /api/v1/payments` for cash / bank transfer / proof approval (unchanged).
