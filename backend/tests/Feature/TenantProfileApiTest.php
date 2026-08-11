<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DemoRentalSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class TenantProfileApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_tenant_profile_includes_payment_and_receipt_history(): void
    {
        $this->seed(DemoRentalSeeder::class);

        $user = User::query()->where('email', 'admin@rental.test')->firstOrFail();
        $tenantId = \App\Models\Tenant::query()
            ->where('email', 'tenant@grids.test')
            ->value('id');

        $response = $this->actingAs($user, 'sanctum')
            ->getJson('/api/v1/tenants/'.$tenantId);

        $response->assertOk()
            ->assertJsonPath('data.email', 'tenant@grids.test')
            ->assertJsonStructure([
                'data' => [
                    'full_name',
                    'email',
                    'phone',
                    'contracts',
                    'maintenance_requests',
                    'payment_history',
                    'receipts',
                ],
            ]);

        $this->assertNotEmpty($response->json('data.payment_history'));
        $this->assertNotEmpty($response->json('data.receipts'));
    }
}
