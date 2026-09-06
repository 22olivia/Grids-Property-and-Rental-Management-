<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DemoRentalSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class DashboardApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_each_role_receives_a_scoped_dashboard_payload(): void
    {
        $this->seed(DemoRentalSeeder::class);

        $admin = User::query()->where('email', 'admin@rental.test')->firstOrFail();
        $owner = User::query()->where('email', 'owner@grids.test')->firstOrFail();
        $manager = User::query()->where('email', 'manager@grids.test')->firstOrFail();
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/dashboard')
            ->assertOk()
            ->assertJsonPath('data.dashboard_variant', 'super_admin')
            ->assertJsonStructure([
                'data' => [
                    'total_properties',
                    'monthly_revenue_series',
                    'lease_status_distribution',
                    'payment_status_distribution',
                    'recent_payments',
                    'expiring_leases',
                    'dashboard_alerts',
                    'recent_users',
                ],
            ]);

        $this->actingAs($owner, 'sanctum')
            ->getJson('/api/v1/dashboard')
            ->assertOk()
            ->assertJsonPath('data.dashboard_variant', 'owner')
            ->assertJsonStructure([
                'data' => [
                    'my_properties',
                    'outstanding_payments',
                    'lease_expiry',
                    'dashboard_alerts',
                ],
            ]);

        $this->actingAs($manager, 'sanctum')
            ->getJson('/api/v1/dashboard')
            ->assertOk()
            ->assertJsonPath('data.dashboard_variant', 'manager')
            ->assertJsonStructure([
                'data' => [
                    'assigned_properties',
                    'pending_approvals',
                    'assigned_maintenance',
                    'dashboard_alerts',
                ],
            ]);

        $this->actingAs($tenant, 'sanctum')
            ->getJson('/api/v1/dashboard')
            ->assertOk()
            ->assertJsonPath('data.dashboard_variant', 'tenant')
            ->assertJsonStructure([
                'data' => [
                    'my_lease',
                    'upcoming_payment',
                    'recent_invoices',
                    'payment_history',
                    'dashboard_alerts',
                ],
            ]);
    }

    public function test_demo_seed_creates_invoices_payments_and_notifications(): void
    {
        $this->seed(DemoRentalSeeder::class);

        $this->assertDatabaseHas('invoices', ['invoice_number' => 'INV-NORA-'.now()->format('Y-m')]);
        $this->assertDatabaseHas('payments', ['reference' => 'PAY-DEMO-PENDING-APPROVAL']);
        $this->assertDatabaseHas('contracts', ['contract_number' => 'CTR-DEMO-DRAFT']);

        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();
        $this->assertGreaterThan(
            0,
            \App\Models\AppNotification::query()->where('recipient_user_id', $tenant->id)->count()
        );
    }
}
