<?php

namespace Database\Seeders;

use App\Models\Contract;
use App\Models\MaintenanceRequest;
use App\Models\Owner;
use App\Models\Payment;
use App\Models\Property;
use App\Models\RentalUnit;
use App\Models\Tenant;
use App\Models\User;
use Illuminate\Database\Seeder;

class DemoRentalSeeder extends Seeder
{
    /**
     * Seed a realistic demo portfolio for automation videos.
     */
    public function run(): void
    {
        User::query()->updateOrCreate(
            ['email' => 'admin@rental.test'],
            [
                'name' => 'Admin User',
                'role' => 'admin',
                'phone' => '+10000000000',
                'password' => 'password',
            ],
        );

        $owner = Owner::query()->updateOrCreate(
            ['email' => 'owner.demo@grids.test'],
            [
                'full_name' => 'Sara Al Nahyan',
                'phone' => '+971500000001',
                'address' => 'Abu Dhabi, UAE',
                'notes' => 'Demo owner portfolio',
            ],
        );

        $property = Property::query()->updateOrCreate(
            [
                'owner_id' => $owner->id,
                'name' => 'Marina Heights',
            ],
            [
                'type' => 'apartment',
                'address_line1' => '12 Corniche Road',
                'city' => 'Abu Dhabi',
                'state' => 'Abu Dhabi',
                'postal_code' => '00000',
                'country' => 'AE',
                'description' => 'Waterfront residences for the GPMS demo.',
                'total_units' => 3,
                'status' => 'active',
            ],
        );

        $unitA = RentalUnit::query()->updateOrCreate(
            ['property_id' => $property->id, 'unit_number' => 'A-101'],
            [
                'floor' => '1',
                'bedrooms' => 2,
                'bathrooms' => 2,
                'square_feet' => 1100,
                'monthly_rent' => 4500,
                'deposit_amount' => 4500,
                'status' => 'occupied',
                'description' => 'Furnished 2BR with balcony',
            ],
        );

        $unitB = RentalUnit::query()->updateOrCreate(
            ['property_id' => $property->id, 'unit_number' => 'A-102'],
            [
                'floor' => '1',
                'bedrooms' => 1,
                'bathrooms' => 1,
                'square_feet' => 750,
                'monthly_rent' => 3200,
                'deposit_amount' => 3200,
                'status' => 'available',
                'description' => 'Bright 1BR city view',
            ],
        );

        RentalUnit::query()->updateOrCreate(
            ['property_id' => $property->id, 'unit_number' => 'B-201'],
            [
                'floor' => '2',
                'bedrooms' => 3,
                'bathrooms' => 2,
                'square_feet' => 1450,
                'monthly_rent' => 6200,
                'deposit_amount' => 6200,
                'status' => 'maintenance',
                'description' => 'Family unit under light renovation',
            ],
        );

        $tenant = Tenant::query()->updateOrCreate(
            ['email' => 'tenant.demo@grids.test'],
            [
                'full_name' => 'Omar Hassan',
                'phone' => '+971500000002',
                'national_id' => 'DEMO-TENANT-001',
                'emergency_contact' => 'Layla Hassan +971500000003',
                'notes' => 'Demo tenant for automation',
            ],
        );

        $contract = Contract::query()->updateOrCreate(
            ['contract_number' => 'CTR-DEMO-001'],
            [
                'rental_unit_id' => $unitA->id,
                'tenant_id' => $tenant->id,
                'start_date' => now()->subMonths(2)->startOfMonth()->toDateString(),
                'end_date' => now()->addMonths(4)->endOfMonth()->toDateString(),
                'monthly_rent' => 4500,
                'deposit_amount' => 4500,
                'payment_day' => 1,
                'status' => 'active',
                'terms' => 'Demo lease for GPMS automation walkthrough.',
            ],
        );

        // Older paid period
        Payment::query()->updateOrCreate(
            ['reference' => 'PAY-DEMO-PAID-01'],
            [
                'contract_id' => $contract->id,
                'amount' => 4500,
                'due_date' => now()->subMonths(2)->startOfMonth()->toDateString(),
                'paid_at' => now()->subMonths(2)->startOfMonth()->addDays(2)->toDateString(),
                'method' => 'bank_transfer',
                'status' => 'paid',
                'period' => now()->subMonths(2)->format('Y-m'),
                'notes' => 'Paid on time',
            ],
        );

        // Pending current-looking payment that is already overdue (for mark-overdue demo)
        Payment::query()->updateOrCreate(
            ['reference' => 'PAY-DEMO-OVERDUE-01'],
            [
                'contract_id' => $contract->id,
                'amount' => 4500,
                'due_date' => now()->subDays(10)->toDateString(),
                'paid_at' => null,
                'method' => null,
                'status' => 'pending',
                'period' => now()->subMonth()->format('Y-m'),
                'notes' => 'Should become overdue when automation runs',
            ],
        );

        MaintenanceRequest::query()->updateOrCreate(
            [
                'rental_unit_id' => $unitA->id,
                'title' => 'AC not cooling',
            ],
            [
                'tenant_id' => $tenant->id,
                'description' => 'Living room AC weak airflow since yesterday.',
                'category' => 'hvac',
                'priority' => 'high',
                'status' => 'open',
                'reported_at' => now()->subDay(),
            ],
        );

        // Ensure available unit stays available for listing-style demo
        $unitB->update(['status' => 'available']);
    }
}
