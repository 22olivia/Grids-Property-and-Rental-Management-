<?php

namespace Tests\Feature;

use App\Models\Contract;
use App\Models\User;
use App\Support\Roles;
use Database\Seeders\DemoRentalSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class GpmsUsersLeasesTest extends TestCase
{
    use RefreshDatabase;

    public function test_super_admin_can_list_users_and_see_stats(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $admin = User::query()->where('email', 'admin@rental.test')->firstOrFail();

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/users')
            ->assertOk()
            ->assertJsonStructure(['data']);

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/users/stats')
            ->assertOk()
            ->assertJsonPath('data.total_users', 9);
    }

    public function test_tenant_cannot_access_user_admin_routes(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();

        $this->actingAs($tenant, 'sanctum')
            ->getJson('/api/v1/users')
            ->assertForbidden();
    }

    public function test_lease_overlap_is_rejected(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $admin = User::query()->where('email', 'admin@rental.test')->firstOrFail();
        $lease = Contract::query()->where('contract_number', 'CTR-DEMO-001')->firstOrFail();

        $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/leases', [
                'rental_unit_id' => $lease->rental_unit_id,
                'tenant_id' => $lease->tenant_id,
                'start_date' => now()->toDateString(),
                'end_date' => now()->addMonths(6)->toDateString(),
                'monthly_rent' => 4500,
                'status' => 'active',
            ])
            ->assertUnprocessable()
            ->assertJsonValidationErrors(['rental_unit_id']);
    }

    public function test_staff_can_generate_invoices_and_record_payment(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $admin = User::query()->where('email', 'admin@rental.test')->firstOrFail();
        $lease = Contract::query()->where('contract_number', 'CTR-DEMO-001')->firstOrFail();

        $generate = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/invoices/generate')
            ->assertOk()
            ->json('data.generated');

        $this->assertGreaterThanOrEqual(0, $generate);

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/invoices?per_page=50')
            ->assertOk()
            ->assertJsonFragment(['invoice_number' => 'INV-SHOW-UNPAID-001'])
            ->assertJsonFragment(['invoice_number' => 'INV-SHOW-OVERDUE-001'])
            ->assertJsonFragment(['invoice_number' => 'INV-SHOW-PAID-001']);

        $invoiceId = $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/invoices?status=unpaid')
            ->assertOk()
            ->json('data.0.id');

        $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/payments', [
                'contract_id' => $lease->id,
                'invoice_id' => $invoiceId,
                'amount' => 1000,
                'method' => 'card',
            ])
            ->assertCreated()
            ->assertJsonPath('data.approval_status', 'approved');

        $this->assertSame(Roles::SUPER_ADMIN, $admin->fresh()->role);
    }

    public function test_generate_creates_missing_next_month_invoices_when_current_exists(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $admin = User::query()->where('email', 'admin@rental.test')->firstOrFail();

        // Showcase already planted Omar's next-month bill; remove other leases' next-month rows.
        \App\Models\Invoice::query()
            ->where('billing_month', now()->addMonth()->format('Y-m'))
            ->where('invoice_number', '!=', 'INV-SHOW-UNPAID-001')
            ->delete();

        $before = \App\Models\Invoice::query()->count();

        $generated = $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/invoices/generate')
            ->assertOk()
            ->json('data.generated');

        $this->assertGreaterThan(0, $generated);
        $this->assertSame($before + $generated, \App\Models\Invoice::query()->count());
    }

    public function test_staff_can_delete_invoice_and_tenant_cannot(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $admin = User::query()->where('email', 'admin@rental.test')->firstOrFail();
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();
        $invoice = \App\Models\Invoice::query()
            ->where('invoice_number', 'INV-SHOW-UNPAID-001')
            ->firstOrFail();

        $this->actingAs($tenant, 'sanctum')
            ->deleteJson('/api/v1/invoices/'.$invoice->id)
            ->assertForbidden();

        $this->actingAs($admin, 'sanctum')
            ->deleteJson('/api/v1/invoices/'.$invoice->id)
            ->assertOk()
            ->assertJsonPath('message', 'Invoice deleted.');

        $this->assertDatabaseMissing('invoices', ['id' => $invoice->id]);
    }
}
