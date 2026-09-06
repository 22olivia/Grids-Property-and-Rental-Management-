<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DemoRentalSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TenantPortalApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_tenant_can_access_scoped_portal_endpoints(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();

        $this->actingAs($tenant, 'sanctum')
            ->getJson('/api/v1/tenant/lease')
            ->assertOk()
            ->assertJsonPath('data.lease_number', fn ($v) => is_string($v) && $v !== '');

        $this->actingAs($tenant, 'sanctum')
            ->getJson('/api/v1/tenant/receipts')
            ->assertOk()
            ->assertJsonStructure(['data']);

        $this->actingAs($tenant, 'sanctum')
            ->getJson('/api/v1/tenant/documents')
            ->assertOk();

        $this->actingAs($tenant, 'sanctum')
            ->getJson('/api/v1/tenant/calendar')
            ->assertOk()
            ->assertJsonStructure(['data']);

        $this->actingAs($tenant, 'sanctum')
            ->getJson('/api/v1/tenant/profile')
            ->assertOk()
            ->assertJsonPath('data.email', 'tenant@grids.test');

        $this->actingAs($tenant, 'sanctum')
            ->getJson('/api/v1/payments/summary')
            ->assertOk()
            ->assertJsonStructure(['data' => ['total_paid', 'outstanding_amount']]);
    }

    public function test_payment_webhook_requires_signature(): void
    {
        $this->seed(DemoRentalSeeder::class);

        $this->postJson('/api/v1/payments/webhook', [
            'order_id' => 'ord_missing',
            'transaction_id' => 'TXN-TEST',
            'amount' => 100,
            'status' => 'successful',
        ])
            ->assertStatus(400)
            ->assertJsonPath('verified', false);
    }

    public function test_staff_cannot_use_tenant_lease_endpoint(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $manager = User::query()->where('email', 'manager@grids.test')->firstOrFail();

        $this->actingAs($manager, 'sanctum')
            ->getJson('/api/v1/tenant/lease')
            ->assertForbidden();
    }

    public function test_tenant_calendar_includes_maintenance_and_support_tickets(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenantUser = User::query()->where('email', 'tenant@grids.test')->firstOrFail();
        $tenant = $tenantUser->tenant;
        $this->assertNotNull($tenant);

        $unitId = \App\Models\RentalUnit::query()->value('id');
        $this->assertNotNull($unitId);

        $created = $this->actingAs($tenantUser, 'sanctum')
            ->postJson('/api/v1/maintenance-requests', [
                'rental_unit_id' => $unitId,
                'title' => 'AC not cooling',
                'description' => 'Living room AC blows warm air.',
                'preferred_visit_date' => now()->addDays(2)->toDateString(),
            ])
            ->assertCreated()
            ->json('data');

        $calendar = $this->actingAs($tenantUser, 'sanctum')
            ->getJson('/api/v1/tenant/calendar')
            ->assertOk()
            ->json('data');

        $this->assertTrue(collect($calendar)->contains(
            fn ($row) => ($row['type'] ?? null) === 'maintenance_visit'
                && (int) data_get($row, 'meta.ticket_id') === (int) $created['id']
        ));
        $this->assertTrue(collect($calendar)->contains(
            fn ($row) => ($row['type'] ?? null) === 'rent_due'
        ));
    }

    public function test_tenant_ai_assist_is_recommendation_only(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();

        $this->actingAs($tenant, 'sanctum')
            ->postJson('/api/v1/ai/tenant-assist', ['prompt' => 'Explain my open invoice'])
            ->assertOk()
            ->assertJsonPath('data.recommendation_only', true);
    }
}
