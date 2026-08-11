<?php

namespace Tests\Feature;

use App\Models\Invoice;
use App\Models\Payment;
use App\Models\PaymentOrder;
use App\Models\Receipt;
use App\Models\User;
use Database\Seeders\DemoRentalSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class PaymentGatewayApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_tenant_can_create_confirm_order_and_get_receipt(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();

        $invoice = Invoice::query()
            ->where('invoice_number', 'INV-SHOW-UNPAID-001')
            ->firstOrFail();

        $create = $this->actingAs($tenant, 'sanctum')
            ->postJson('/api/v1/payments/orders', [
                'invoice_ids' => [$invoice->id],
                'amount' => (float) $invoice->remaining_balance,
                'method' => 'upi',
            ])
            ->assertCreated()
            ->assertJsonPath('data.gateway', 'demo')
            ->assertJsonPath('data.status', 'awaiting_payment');

        $orderNumber = $create->json('data.order_number');
        $token = $create->json('data.checkout_token');
        $this->assertNotEmpty($orderNumber);
        $this->assertNotEmpty($token);

        $this->actingAs($tenant, 'sanctum')
            ->postJson("/api/v1/payments/orders/{$orderNumber}/confirm", [
                'checkout_token' => $token,
                'transaction_id' => 'TXN-TEST-CONFIRM-1',
            ])
            ->assertOk()
            ->assertJsonPath('data.status', 'successful');

        $this->assertDatabaseHas('payment_orders', [
            'order_number' => $orderNumber,
            'status' => 'paid',
            'gateway_txn_id' => 'TXN-TEST-CONFIRM-1',
        ]);

        $this->assertDatabaseHas('payments', [
            'gateway_txn_id' => 'TXN-TEST-CONFIRM-1',
            'status' => 'paid',
            'invoice_id' => $invoice->id,
        ]);

        $this->assertDatabaseHas('receipts', [
            'transaction_reference' => 'TXN-TEST-CONFIRM-1',
        ]);

        $invoice->refresh();
        $this->assertSame('paid', $invoice->status);
        $this->assertEquals(0.0, (float) $invoice->remaining_balance);

        $this->actingAs($tenant, 'sanctum')
            ->getJson('/api/v1/tenant/receipts')
            ->assertOk()
            ->assertJsonFragment(['transaction_reference' => 'TXN-TEST-CONFIRM-1']);
    }

    public function test_multi_invoice_capture_records_only_each_invoice_slice_on_its_payment(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();
        $invoices = Invoice::query()
            ->whereIn('invoice_number', ['INV-SHOW-UNPAID-001', 'INV-DEMO-OPEN-01'])
            ->get();

        $this->assertCount(2, $invoices);
        $expectedByInvoice = $invoices
            ->mapWithKeys(fn (Invoice $invoice) => [$invoice->id => (float) $invoice->remaining_balance]);
        $total = (float) $expectedByInvoice->sum();

        $create = $this->actingAs($tenant, 'sanctum')
            ->postJson('/api/v1/payments/orders', [
                'invoice_ids' => $invoices->pluck('id')->all(),
                'amount' => $total,
                'method' => 'card',
            ])
            ->assertCreated();

        $orderNumber = $create->json('data.order_number');
        $this->actingAs($tenant, 'sanctum')
            ->postJson("/api/v1/payments/orders/{$orderNumber}/confirm", [
                'checkout_token' => $create->json('data.checkout_token'),
                'transaction_id' => 'TXN-TEST-MULTI-1',
            ])
            ->assertOk();

        $order = PaymentOrder::query()->where('order_number', $orderNumber)->firstOrFail();
        $payments = Payment::query()
            ->where('payment_order_id', $order->id)
            ->get()
            ->keyBy('invoice_id');

        $this->assertCount(2, $payments);
        foreach ($expectedByInvoice as $invoiceId => $expectedAmount) {
            $this->assertEquals($expectedAmount, (float) $payments->get($invoiceId)?->amount);
            $this->assertEquals(0.0, (float) Invoice::query()->findOrFail($invoiceId)->remaining_balance);
        }
        $this->assertEquals($total, (float) $payments->sum('amount'));
    }

    public function test_signed_webhook_captures_payment(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();

        $invoice = Invoice::query()
            ->where('invoice_number', 'INV-DEMO-OPEN-01')
            ->firstOrFail();

        $create = $this->actingAs($tenant, 'sanctum')
            ->postJson('/api/v1/payments/orders', [
                'invoice_ids' => [$invoice->id],
                'amount' => (float) $invoice->remaining_balance,
                'method' => 'card',
            ])
            ->assertCreated();

        $orderNumber = $create->json('data.order_number');
        $amount = $create->json('data.amount');

        $this->withHeader('x-demo-signature', 'demo-verified')
            ->postJson('/api/v1/payments/webhook', [
                'order_id' => $orderNumber,
                'transaction_id' => 'TXN-WEBHOOK-99',
                'amount' => $amount,
                'status' => 'successful',
                'method' => 'card',
            ])
            ->assertOk()
            ->assertJsonPath('verified', true)
            ->assertJsonPath('data.status', 'successful');

        $this->assertDatabaseHas('payments', [
            'gateway_txn_id' => 'TXN-WEBHOOK-99',
            'status' => 'paid',
        ]);

        $this->assertSame('paid', $invoice->fresh()->status);
        $this->assertTrue(Receipt::query()->where('transaction_reference', 'TXN-WEBHOOK-99')->exists());
    }

    public function test_webhook_rejects_bad_signature(): void
    {
        $this->seed(DemoRentalSeeder::class);

        $this->postJson('/api/v1/payments/webhook', [
            'order_id' => 'ord_missing',
            'transaction_id' => 'TXN-BAD',
            'amount' => 100,
            'status' => 'successful',
        ])->assertStatus(400)
            ->assertJsonPath('verified', false);
    }

    public function test_order_rejects_amount_above_outstanding(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();
        $invoice = Invoice::query()
            ->where('invoice_number', 'INV-DEMO-OPEN-01')
            ->firstOrFail();

        $this->actingAs($tenant, 'sanctum')
            ->postJson('/api/v1/payments/orders', [
                'invoice_ids' => [$invoice->id],
                'amount' => (float) $invoice->remaining_balance + 500,
                'method' => 'upi',
            ])
            ->assertStatus(422);
    }

    public function test_idempotent_order_creation(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();
        $invoice = Invoice::query()
            ->where('invoice_number', 'INV-DEMO-OPEN-01')
            ->firstOrFail();

        $payload = [
            'invoice_ids' => [$invoice->id],
            'amount' => (float) $invoice->remaining_balance,
            'method' => 'wallet',
            'idempotency_key' => 'idem-test-1',
        ];

        $first = $this->actingAs($tenant, 'sanctum')
            ->postJson('/api/v1/payments/orders', $payload)
            ->assertCreated()
            ->json('data.order_number');

        $second = $this->actingAs($tenant, 'sanctum')
            ->postJson('/api/v1/payments/orders', $payload)
            ->assertCreated()
            ->json('data.order_number');

        $this->assertSame($first, $second);
        $this->assertSame(1, PaymentOrder::query()->where('idempotency_key', 'idem-test-1')->count());
    }

    public function test_duplicate_webhook_does_not_double_charge(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();
        $invoice = Invoice::query()
            ->where('invoice_number', 'INV-SHOW-UNPAID-001')
            ->firstOrFail();

        $create = $this->actingAs($tenant, 'sanctum')
            ->postJson('/api/v1/payments/orders', [
                'invoice_ids' => [$invoice->id],
                'amount' => (float) $invoice->remaining_balance,
                'method' => 'net_banking',
            ])
            ->assertCreated();

        $body = [
            'order_id' => $create->json('data.order_number'),
            'transaction_id' => 'TXN-DUP-1',
            'amount' => $create->json('data.amount'),
            'status' => 'successful',
            'event_id' => 'evt-dup-1',
        ];

        $this->withHeader('x-demo-signature', 'demo-verified')
            ->postJson('/api/v1/payments/webhook', $body)
            ->assertOk();

        $this->withHeader('x-demo-signature', 'demo-verified')
            ->postJson('/api/v1/payments/webhook', $body)
            ->assertOk()
            ->assertJsonPath('duplicate', true);

        $this->assertSame(1, Payment::query()->where('gateway_txn_id', 'TXN-DUP-1')->count());
    }
}
