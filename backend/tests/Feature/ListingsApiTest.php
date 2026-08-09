<?php

namespace Tests\Feature;

use Database\Seeders\DemoRentalSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class ListingsApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_public_listings_returns_available_units_only(): void
    {
        $this->seed(DemoRentalSeeder::class);

        $response = $this->getJson('/api/v1/listings');

        $response->assertOk()
            ->assertJsonPath('message', 'Available rental listings.')
            ->assertJsonStructure([
                'data' => [
                    '*' => [
                        'id',
                        'unit_number',
                        'monthly_rent',
                        'property' => ['name', 'city'],
                    ],
                ],
            ]);

        $units = collect($response->json('data'))->pluck('unit_number');
        $this->assertTrue($units->contains('C-302') || $units->contains('R-101'));
        $this->assertFalse($units->contains('A-101'));
    }
}
