<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DemoRentalSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AdminSearchApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_staff_can_search_platform_records(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $admin = User::query()->where('email', 'admin@rental.test')->firstOrFail();

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/admin/search?q=Marina')
            ->assertOk()
            ->assertJsonFragment([
                'type' => 'Property',
                'title' => 'Marina Heights',
                'href' => '/properties',
            ]);
    }

    public function test_tenants_cannot_use_staff_search(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();

        $this->actingAs($tenant, 'sanctum')
            ->getJson('/api/v1/admin/search?q=Marina')
            ->assertForbidden();
    }
}
