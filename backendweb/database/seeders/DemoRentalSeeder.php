<?php

namespace Database\Seeders;

use App\Models\Building;
use App\Models\Contract;
use App\Models\Floor;
use App\Models\Invoice;
use App\Models\MaintenanceRequest;
use App\Models\NotificationChannelSetting;
use App\Models\NotificationPreference;
use App\Models\NotificationTemplate;
use App\Models\Organization;
use App\Models\Owner;
use App\Models\Payment;
use App\Models\Property;
use App\Models\RentalUnit;
use App\Models\SupportCategory;
use App\Models\SupportTicket;
use App\Models\Tenant;
use App\Models\User;
use App\Models\Vendor;
use App\Services\NotificationService;
use App\Services\SupportTicketService;
use App\Support\NotificationCatalog;
use App\Support\Roles;
use App\Support\DomainCatalog;
use Illuminate\Database\Seeder;
use Illuminate\Support\Facades\App;

class DemoRentalSeeder extends Seeder
{
    public function run(): void
    {
        $superAdmin = User::query()->updateOrCreate(
            ['email' => 'admin@rental.test'],
            [
                'name' => 'GPMS Super Admin',
                'role' => Roles::SUPER_ADMIN,
                'phone' => '+971500000000',
                'notify_email' => 'admin@rental.test',
                'whatsapp_phone' => null,
                'address' => 'Grids HQ, Abu Dhabi',
                'status' => 'active',
                'password' => 'password',
                'email_verified_at' => now(),
            ],
        );

        User::query()->where('email', 'admin@rental.test')->update(['role' => Roles::SUPER_ADMIN]);

        $ownerUser = User::query()->updateOrCreate(
            ['email' => 'owner@grids.test'],
            [
                'name' => 'Sara Al Nahyan',
                'role' => Roles::OWNER,
                'phone' => '+971500000001',
                'notify_email' => 'owner@grids.test',
                'whatsapp_phone' => null,
                'address' => 'Abu Dhabi, UAE',
                'status' => 'active',
                'password' => 'password',
                'email_verified_at' => now(),
            ],
        );

        $managerUser = User::query()->updateOrCreate(
            ['email' => 'manager@grids.test'],
            [
                'name' => 'James Carter',
                'role' => Roles::MANAGER,
                'phone' => '+971500000004',
                'notify_email' => 'manager@grids.test',
                'whatsapp_phone' => null,
                'address' => 'Abu Dhabi Marina',
                'status' => 'active',
                'password' => 'password',
                'email_verified_at' => now(),
            ],
        );

        $tenantUser = User::query()->updateOrCreate(
            ['email' => 'tenant@grids.test'],
            [
                'name' => 'Omar Hassan',
                'role' => Roles::TENANT,
                'phone' => '+971500000002',
                'notify_email' => 'tenant@grids.test',
                'whatsapp_phone' => null,
                'address' => 'Marina Heights A-101',
                'status' => 'active',
                'password' => 'password',
                'email_verified_at' => now(),
            ],
        );

        User::query()->updateOrCreate(
            ['email' => 'inactive.staff@grids.test'],
            [
                'name' => 'Inactive Demo Staff',
                'role' => Roles::MANAGER,
                'phone' => '+971500000099',
                'address' => 'Abu Dhabi',
                'status' => 'inactive',
                'password' => 'password',
                'email_verified_at' => now(),
            ],
        );

        $owner = Owner::query()->updateOrCreate(
            ['email' => 'owner@grids.test'],
            [
                'user_id' => $ownerUser->id,
                'full_name' => $ownerUser->name,
                'phone' => $ownerUser->phone,
                'address' => $ownerUser->address,
                'notes' => 'GPMS demo owner portfolio',
            ],
        );

        Owner::query()->updateOrCreate(
            ['email' => 'owner.demo@grids.test'],
            [
                'user_id' => $ownerUser->id,
                'full_name' => $ownerUser->name,
                'phone' => $ownerUser->phone,
                'address' => $ownerUser->address,
            ],
        );

        $ownerTwo = Owner::query()->updateOrCreate(
            ['email' => 'owner.yasmin@grids.test'],
            [
                'user_id' => null,
                'full_name' => 'Yasmin Al Ketbi',
                'phone' => '+971500000010',
                'address' => 'Al Reem Island, Abu Dhabi',
                'notes' => 'Second demo owner (no login user)',
            ],
        );

        $marina = Property::query()->updateOrCreate(
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
                'description' => 'Waterfront residences for Grids Property Management System – GPMS.',
                'total_units' => 3,
                'status' => 'active',
                'latitude' => 24.47685,
                'longitude' => 54.32195,
            ],
        );

        $corniche = Property::query()->updateOrCreate(
            [
                'owner_id' => $owner->id,
                'name' => 'Corniche Towers',
            ],
            [
                'type' => 'apartment',
                'address_line1' => '88 Corniche Avenue',
                'city' => 'Abu Dhabi',
                'state' => 'Abu Dhabi',
                'postal_code' => '00001',
                'country' => 'AE',
                'description' => 'Second portfolio building with mixed occupancy.',
                'total_units' => 2,
                'status' => 'active',
                'latitude' => 24.48210,
                'longitude' => 54.35420,
            ],
        );

        $reem = Property::query()->updateOrCreate(
            [
                'owner_id' => $ownerTwo->id,
                'name' => 'Reem Gate Residences',
            ],
            [
                'type' => 'apartment',
                'address_line1' => '5 Gate Boulevard',
                'city' => 'Abu Dhabi',
                'state' => 'Abu Dhabi',
                'postal_code' => '00002',
                'country' => 'AE',
                'description' => 'Owned by Yasmin — useful for multi-owner dashboards.',
                'total_units' => 2,
                'status' => 'active',
                'latitude' => 24.49380,
                'longitude' => 54.40760,
            ],
        );

        $managerUser->managedProperties()->syncWithoutDetaching([$marina->id, $corniche->id]);

        $unitA = RentalUnit::query()->updateOrCreate(
            ['property_id' => $marina->id, 'unit_number' => 'A-101'],
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
            ['property_id' => $marina->id, 'unit_number' => 'A-102'],
            [
                'floor' => '1',
                'bedrooms' => 1,
                'bathrooms' => 1,
                'square_feet' => 750,
                'monthly_rent' => 3200,
                'deposit_amount' => 3200,
                'status' => 'occupied',
                'description' => 'Bright 1BR city view',
            ],
        );

        $unitC = RentalUnit::query()->updateOrCreate(
            ['property_id' => $marina->id, 'unit_number' => 'B-201'],
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

        $unitD = RentalUnit::query()->updateOrCreate(
            ['property_id' => $corniche->id, 'unit_number' => 'C-301'],
            [
                'floor' => '3',
                'bedrooms' => 2,
                'bathrooms' => 2,
                'square_feet' => 980,
                'monthly_rent' => 5100,
                'deposit_amount' => 5100,
                'status' => 'occupied',
                'description' => 'Corner unit with marina view',
            ],
        );

        $unitE = RentalUnit::query()->updateOrCreate(
            ['property_id' => $corniche->id, 'unit_number' => 'C-302'],
            [
                'floor' => '3',
                'bedrooms' => 1,
                'bathrooms' => 1,
                'square_feet' => 700,
                'monthly_rent' => 2900,
                'deposit_amount' => 2900,
                'status' => 'available',
                'description' => 'Vacant unit ready to lease',
            ],
        );

        RentalUnit::query()->updateOrCreate(
            ['property_id' => $reem->id, 'unit_number' => 'R-101'],
            [
                'floor' => '1',
                'bedrooms' => 2,
                'bathrooms' => 2,
                'square_feet' => 1050,
                'monthly_rent' => 4800,
                'deposit_amount' => 4800,
                'status' => 'available',
                'description' => 'Open listing on Reem Island',
            ],
        );

        RentalUnit::query()->updateOrCreate(
            ['property_id' => $reem->id, 'unit_number' => 'R-202'],
            [
                'floor' => '2',
                'bedrooms' => 3,
                'bathrooms' => 2,
                'square_feet' => 1400,
                'monthly_rent' => 6500,
                'deposit_amount' => 6500,
                'status' => 'occupied',
                'description' => 'Family suite',
            ],
        );

        $tenantOmar = Tenant::query()->updateOrCreate(
            ['email' => 'tenant@grids.test'],
            [
                'user_id' => $tenantUser->id,
                'full_name' => $tenantUser->name,
                'phone' => $tenantUser->phone,
                'national_id' => 'DEMO-TENANT-001',
                'emergency_contact' => 'Layla Hassan +971500000003',
                'notes' => 'Linked GPMS tenant user',
            ],
        );

        $tenantFatima = Tenant::query()->updateOrCreate(
            ['email' => 'fatima.tenant@grids.test'],
            [
                'user_id' => null,
                'full_name' => 'Fatima Al Mazrouei',
                'phone' => '+971500000020',
                'national_id' => 'DEMO-TENANT-002',
                'emergency_contact' => 'Ahmed Al Mazrouei +971500000021',
                'notes' => 'Demo tenant without portal login',
            ],
        );

        $tenantKhalid = Tenant::query()->updateOrCreate(
            ['email' => 'khalid.tenant@grids.test'],
            [
                'user_id' => null,
                'full_name' => 'Khalid Rahman',
                'phone' => '+971500000022',
                'national_id' => 'DEMO-TENANT-003',
                'emergency_contact' => 'Noor Rahman +971500000023',
                'notes' => 'Lease expiring soon demo',
            ],
        );

        $tenantNora = Tenant::query()->updateOrCreate(
            ['email' => 'nora.tenant@grids.test'],
            [
                'user_id' => null,
                'full_name' => 'Nora Saeed',
                'phone' => '+971500000024',
                'national_id' => 'DEMO-TENANT-004',
                'emergency_contact' => 'Saeed family office',
                'notes' => 'Reem Gate resident',
            ],
        );

        $leaseOmar = Contract::query()->updateOrCreate(
            ['contract_number' => 'CTR-DEMO-001'],
            [
                'rental_unit_id' => $unitA->id,
                'tenant_id' => $tenantOmar->id,
                'start_date' => now()->subMonths(5)->startOfMonth()->toDateString(),
                'end_date' => now()->addMonths(7)->endOfMonth()->toDateString(),
                'monthly_rent' => 4500,
                'deposit_amount' => 4500,
                'payment_day' => 1,
                'grace_period_days' => 3,
                'late_fee_amount' => 150,
                'payment_frequency' => 'monthly',
                'status' => 'active',
                'terms' => 'Standard GPMS residential lease terms.',
                'notes' => 'Seeded active lease for Omar',
                'move_in_date' => now()->subMonths(5)->startOfMonth()->toDateString(),
                'created_by' => $superAdmin->id,
            ],
        );

        $leaseFatima = Contract::query()->updateOrCreate(
            ['contract_number' => 'CTR-DEMO-002'],
            [
                'rental_unit_id' => $unitB->id,
                'tenant_id' => $tenantFatima->id,
                'start_date' => now()->subMonths(3)->startOfMonth()->toDateString(),
                'end_date' => now()->addMonths(9)->endOfMonth()->toDateString(),
                'monthly_rent' => 3200,
                'deposit_amount' => 3200,
                'payment_day' => 5,
                'grace_period_days' => 3,
                'late_fee_amount' => 100,
                'payment_frequency' => 'monthly',
                'status' => 'active',
                'terms' => 'Standard GPMS residential lease terms.',
                'notes' => 'Seeded active lease for Fatima',
                'move_in_date' => now()->subMonths(3)->startOfMonth()->toDateString(),
                'created_by' => $managerUser->id,
            ],
        );

        $leaseKhalid = Contract::query()->updateOrCreate(
            ['contract_number' => 'CTR-DEMO-003'],
            [
                'rental_unit_id' => $unitD->id,
                'tenant_id' => $tenantKhalid->id,
                'start_date' => now()->subMonths(11)->startOfMonth()->toDateString(),
                'end_date' => now()->addDays(18)->toDateString(),
                'monthly_rent' => 5100,
                'deposit_amount' => 5100,
                'payment_day' => 1,
                'grace_period_days' => 2,
                'late_fee_amount' => 200,
                'payment_frequency' => 'monthly',
                'status' => 'expiring_soon',
                'terms' => 'Renewal discussion pending.',
                'notes' => 'Expiring lease for dashboard tables',
                'move_in_date' => now()->subMonths(11)->startOfMonth()->toDateString(),
                'created_by' => $managerUser->id,
            ],
        );

        $unitReem202 = RentalUnit::query()
            ->where('property_id', $reem->id)
            ->where('unit_number', 'R-202')
            ->firstOrFail();

        $leaseNora = Contract::query()->updateOrCreate(
            ['contract_number' => 'CTR-DEMO-004'],
            [
                'rental_unit_id' => $unitReem202->id,
                'tenant_id' => $tenantNora->id,
                'start_date' => now()->subMonths(2)->startOfMonth()->toDateString(),
                'end_date' => now()->addMonths(10)->endOfMonth()->toDateString(),
                'monthly_rent' => 6500,
                'deposit_amount' => 6500,
                'payment_day' => 1,
                'grace_period_days' => 3,
                'late_fee_amount' => 180,
                'payment_frequency' => 'monthly',
                'status' => 'active',
                'terms' => 'Reem Gate residential lease.',
                'notes' => 'Second-owner portfolio lease',
                'move_in_date' => now()->subMonths(2)->startOfMonth()->toDateString(),
                'created_by' => $superAdmin->id,
            ],
        );

        Contract::query()->updateOrCreate(
            ['contract_number' => 'CTR-DEMO-DRAFT'],
            [
                'rental_unit_id' => $unitE->id,
                'tenant_id' => $tenantFatima->id,
                'start_date' => now()->addMonth()->startOfMonth()->toDateString(),
                'end_date' => now()->addMonths(13)->endOfMonth()->toDateString(),
                'monthly_rent' => 2900,
                'deposit_amount' => 2900,
                'payment_day' => 1,
                'grace_period_days' => 3,
                'late_fee_amount' => 100,
                'payment_frequency' => 'monthly',
                'status' => 'draft',
                'terms' => 'Draft lease for vacant Corniche unit C-302.',
                'notes' => 'Pending activation — useful for lease status charts',
                'move_in_date' => null,
                'created_by' => $managerUser->id,
            ],
        );

        $this->seedLeaseBilling($leaseOmar, [
            ['ago' => 4, 'status' => 'paid', 'paid' => 4500],
            ['ago' => 3, 'status' => 'paid', 'paid' => 4500],
            ['ago' => 2, 'status' => 'paid', 'paid' => 4500],
            ['ago' => 1, 'status' => 'unpaid', 'paid' => 0, 'overdue' => true],
            ['ago' => 0, 'status' => 'unpaid', 'paid' => 0],
        ], 'OMAR');

        $this->seedLeaseBilling($leaseFatima, [
            ['ago' => 3, 'status' => 'paid', 'paid' => 3200],
            ['ago' => 2, 'status' => 'paid', 'paid' => 3200],
            ['ago' => 1, 'status' => 'partially_paid', 'paid' => 1600],
            ['ago' => 0, 'status' => 'unpaid', 'paid' => 0],
        ], 'FATIMA');

        $this->seedLeaseBilling($leaseKhalid, [
            ['ago' => 2, 'status' => 'paid', 'paid' => 5100],
            ['ago' => 1, 'status' => 'paid', 'paid' => 5100],
            ['ago' => 0, 'status' => 'overdue', 'paid' => 0, 'overdue' => true],
        ], 'KHALID');

        $this->seedLeaseBilling($leaseNora, [
            ['ago' => 1, 'status' => 'paid', 'paid' => 6500],
            ['ago' => 0, 'status' => 'unpaid', 'paid' => 0],
        ], 'NORA');

        // Always-visible showcase invoices for demos / screenshots.
        Invoice::query()->updateOrCreate(
            ['invoice_number' => 'INV-SHOW-UNPAID-001'],
            [
                'contract_id' => $leaseOmar->id,
                'billing_month' => now()->addMonth()->format('Y-m'),
                'rent_amount' => 4500,
                'additional_charges' => 100,
                'discounts' => 0,
                'late_fee' => 0,
                'previous_balance' => 0,
                'total_amount' => 4600,
                'paid_amount' => 0,
                'remaining_balance' => 4600,
                'due_date' => now()->addMonth()->startOfMonth()->addDays(4)->toDateString(),
                'status' => 'unpaid',
                'notes' => 'Showcase unpaid invoice for demos',
            ],
        );

        Invoice::query()->updateOrCreate(
            ['invoice_number' => 'INV-SHOW-OVERDUE-001'],
            [
                'contract_id' => $leaseKhalid->id,
                'billing_month' => now()->subMonths(3)->format('Y-m'),
                'rent_amount' => 5100,
                'additional_charges' => 0,
                'discounts' => 0,
                'late_fee' => 200,
                'previous_balance' => 0,
                'total_amount' => 5300,
                'paid_amount' => 0,
                'remaining_balance' => 5300,
                'due_date' => now()->subMonths(3)->startOfMonth()->addDays(12)->toDateString(),
                'status' => 'overdue',
                'notes' => 'Showcase overdue invoice for demos',
            ],
        );

        Invoice::query()->updateOrCreate(
            ['invoice_number' => 'INV-SHOW-PAID-001'],
            [
                'contract_id' => $leaseFatima->id,
                'billing_month' => now()->subMonths(4)->format('Y-m'),
                'rent_amount' => 3200,
                'additional_charges' => 0,
                'discounts' => 0,
                'late_fee' => 0,
                'previous_balance' => 0,
                'total_amount' => 3200,
                'paid_amount' => 3200,
                'remaining_balance' => 0,
                'due_date' => now()->subMonths(4)->startOfMonth()->addDays(4)->toDateString(),
                'status' => 'paid',
                'notes' => 'Showcase paid invoice for demos',
            ],
        );

        Payment::query()->updateOrCreate(
            ['reference' => 'PAY-SHOW-PAID-001'],
            [
                'contract_id' => $leaseFatima->id,
                'invoice_id' => Invoice::query()->where('invoice_number', 'INV-SHOW-PAID-001')->value('id'),
                'transaction_number' => 'TXN-SHOW-PAID-001',
                'amount' => 3200,
                'due_date' => now()->subMonths(4)->startOfMonth()->addDays(4)->toDateString(),
                'paid_at' => now()->subMonths(4)->startOfMonth()->addDays(5)->toDateString(),
                'method' => 'card',
                'status' => 'paid',
                'approval_status' => 'approved',
                'period' => now()->subMonths(4)->format('Y-m'),
                'notes' => 'Showcase paid receipt',
            ],
        );

        // Keep legacy invoice/payment keys used by older docs/tests.
        Invoice::query()->updateOrCreate(
            ['invoice_number' => 'INV-DEMO-PAID-01'],
            [
                'contract_id' => $leaseOmar->id,
                'billing_month' => now()->subMonths(2)->format('Y-m'),
                'rent_amount' => 4500,
                'additional_charges' => 0,
                'discounts' => 0,
                'late_fee' => 0,
                'previous_balance' => 0,
                'total_amount' => 4500,
                'paid_amount' => 4500,
                'remaining_balance' => 0,
                'due_date' => now()->subMonths(2)->startOfMonth()->toDateString(),
                'status' => 'paid',
                'notes' => 'Legacy paid invoice key',
            ],
        );

        $legacyOpenInvoice = Invoice::query()->updateOrCreate(
            ['invoice_number' => 'INV-DEMO-OPEN-01'],
            [
                'contract_id' => $leaseOmar->id,
                'billing_month' => now()->subMonth()->format('Y-m'),
                'rent_amount' => 4500,
                'additional_charges' => 0,
                'discounts' => 0,
                'late_fee' => 0,
                'previous_balance' => 0,
                'total_amount' => 4500,
                'paid_amount' => 0,
                'remaining_balance' => 4500,
                'due_date' => now()->subDays(10)->toDateString(),
                'status' => 'overdue',
                'notes' => 'Legacy open invoice key (overdue for demo)',
            ],
        );

        Payment::query()->updateOrCreate(
            ['reference' => 'PAY-DEMO-PAID-01'],
            [
                'contract_id' => $leaseOmar->id,
                'invoice_id' => Invoice::query()->where('invoice_number', 'INV-DEMO-PAID-01')->value('id'),
                'transaction_number' => 'TXN-DEMO-PAID-01',
                'amount' => 4500,
                'due_date' => now()->subMonths(2)->startOfMonth()->toDateString(),
                'paid_at' => now()->subMonths(2)->startOfMonth()->addDays(2)->toDateString(),
                'method' => 'bank_transfer',
                'status' => 'paid',
                'approval_status' => 'approved',
                'period' => now()->subMonths(2)->format('Y-m'),
                'notes' => 'Paid on time',
            ],
        );

        Payment::query()->updateOrCreate(
            ['reference' => 'PAY-DEMO-OVERDUE-01'],
            [
                'contract_id' => $leaseOmar->id,
                'invoice_id' => $legacyOpenInvoice->id,
                'transaction_number' => 'TXN-DEMO-OPEN-01',
                'amount' => 4500,
                'due_date' => now()->subDays(10)->toDateString(),
                'paid_at' => null,
                'method' => null,
                'status' => 'pending',
                'approval_status' => null,
                'period' => now()->subMonth()->format('Y-m'),
                'notes' => 'Should become overdue when automation runs',
            ],
        );

        $fatimaOpenInvoice = Invoice::query()
            ->where('invoice_number', 'INV-FATIMA-'.now()->format('Y-m'))
            ->first();

        if ($fatimaOpenInvoice) {
            Payment::query()->updateOrCreate(
                ['reference' => 'PAY-DEMO-PENDING-APPROVAL'],
                [
                    'contract_id' => $leaseFatima->id,
                    'invoice_id' => $fatimaOpenInvoice->id,
                    'transaction_number' => 'TXN-DEMO-PENDING-01',
                    'amount' => 1600,
                    'due_date' => now()->startOfMonth()->toDateString(),
                    'paid_at' => now()->subHours(6)->toDateString(),
                    'method' => 'bank_transfer',
                    'status' => 'pending',
                    'approval_status' => 'pending',
                    'period' => now()->format('Y-m'),
                    'notes' => 'Manual bank transfer awaiting manager/owner approval',
                    'proof_path' => 'demo/proof-fatima-transfer.pdf',
                ],
            );
        }

        MaintenanceRequest::query()->updateOrCreate(
            [
                'rental_unit_id' => $unitA->id,
                'title' => 'AC not cooling',
            ],
            [
                'tenant_id' => $tenantOmar->id,
                'description' => 'Living room AC weak airflow since yesterday.',
                'category' => 'hvac',
                'priority' => 'high',
                'status' => 'open',
                'reported_at' => now()->subDay(),
            ],
        );

        MaintenanceRequest::query()->updateOrCreate(
            [
                'rental_unit_id' => $unitB->id,
                'title' => 'Kitchen sink leak',
            ],
            [
                'tenant_id' => $tenantFatima->id,
                'description' => 'Slow drip under the sink cabinet.',
                'category' => 'plumbing',
                'priority' => 'medium',
                'status' => 'in_progress',
                'reported_at' => now()->subDays(3),
            ],
        );

        MaintenanceRequest::query()->updateOrCreate(
            [
                'rental_unit_id' => $unitD->id,
                'title' => 'Broken hallway light',
            ],
            [
                'tenant_id' => $tenantKhalid->id,
                'description' => 'Common-area fixture outside unit C-301.',
                'category' => 'electrical',
                'priority' => 'low',
                'status' => 'resolved',
                'reported_at' => now()->subDays(10),
                'resolved_at' => now()->subDays(7),
                'resolution_notes' => 'Bulb and ballast replaced.',
            ],
        );

        MaintenanceRequest::query()->updateOrCreate(
            [
                'rental_unit_id' => $unitC->id,
                'title' => 'Bathroomovation punch list',
            ],
            [
                'tenant_id' => null,
                'description' => 'Paint touch-ups before re-listing B-201.',
                'category' => 'general',
                'priority' => 'urgent',
                'status' => 'open',
                'reported_at' => now()->subHours(8),
            ],
        );

        MaintenanceRequest::query()->updateOrCreate(
            [
                'rental_unit_id' => $unitA->id,
                'title' => 'Washing machine noise',
            ],
            [
                'tenant_id' => $tenantOmar->id,
                'description' => 'Spin cycle vibrates loudly.',
                'category' => 'appliance',
                'priority' => 'medium',
                'status' => 'closed',
                'reported_at' => now()->subDays(20),
                'resolved_at' => now()->subDays(16),
                'resolution_notes' => 'Drum balance adjusted.',
            ],
        );

        $unitB->update(['status' => 'occupied']);
        $unitE->update(['status' => 'available']);

        $this->seedSaaSFoundation(
            $superAdmin,
            $ownerUser,
            $managerUser,
            $tenantUser,
            $marina,
            $corniche,
            $unitA,
            $unitE,
            $tenantOmar,
        );

        $this->seedDemoNotifications($superAdmin, $ownerUser, $managerUser, $tenantUser);
        $this->seedSupportCatalogueAndTickets($tenantUser, $marina, $unitA);
    }

    private function seedSaaSFoundation(
        User $superAdmin,
        User $ownerUser,
        User $managerUser,
        User $tenantUser,
        Property $marina,
        Property $corniche,
        RentalUnit $unitA,
        RentalUnit $unitE,
        Tenant $tenantOmar,
    ): void {
        $org = Organization::query()->updateOrCreate(
            ['slug' => 'grids-abu-dhabi'],
            [
                'name' => 'Grids Abu Dhabi',
                'legal_name' => 'Grids Property Management LLC',
                'email' => 'ops@grids.test',
                'phone' => '+971500000100',
                'country' => 'AE',
                'city' => 'Abu Dhabi',
                'address' => 'Al Maryah Island',
                'plan' => 'growth',
                'status' => 'active',
                'maintenance_approval_limit' => 1500,
                'owner_user_id' => $ownerUser->id,
                'settings' => ['timezone' => 'Asia/Dubai', 'currency' => 'AED'],
            ],
        );

        foreach ([
            [$superAdmin, Roles::SUPER_ADMIN],
            [$ownerUser, Roles::OWNER],
            [$managerUser, Roles::MANAGER],
            [$tenantUser, Roles::TENANT],
        ] as [$user, $role]) {
            $user->update([
                'organization_id' => $org->id,
                'verification_status' => 'verified',
            ]);
            $org->users()->syncWithoutDetaching([
                $user->id => [
                    'role' => $role,
                    'status' => 'active',
                    'permissions' => json_encode(Roles::permissions()[$role] ?? []),
                ],
            ]);
        }

        $accountant = User::query()->updateOrCreate(
            ['email' => 'accountant@grids.test'],
            [
                'name' => 'Nora Finance',
                'role' => Roles::ACCOUNTANT,
                'phone' => '+971500000201',
                'organization_id' => $org->id,
                'status' => 'active',
                'verification_status' => 'verified',
                'password' => 'password',
                'email_verified_at' => now(),
            ],
        );
        $agent = User::query()->updateOrCreate(
            ['email' => 'agent@grids.test'],
            [
                'name' => 'Rami Agent',
                'role' => Roles::AGENT,
                'phone' => '+971500000202',
                'organization_id' => $org->id,
                'status' => 'active',
                'verification_status' => 'verified',
                'password' => 'password',
                'email_verified_at' => now(),
            ],
        );
        $vendorUser = User::query()->updateOrCreate(
            ['email' => 'vendor@grids.test'],
            [
                'name' => 'Gulf Fix Vendor',
                'role' => Roles::VENDOR,
                'phone' => '+971500000203',
                'organization_id' => $org->id,
                'status' => 'active',
                'verification_status' => 'verified',
                'password' => 'password',
                'email_verified_at' => now(),
            ],
        );
        $techUser = User::query()->updateOrCreate(
            ['email' => 'technician@grids.test'],
            [
                'name' => 'Hassan Technician',
                'role' => Roles::TECHNICIAN,
                'phone' => '+971500000204',
                'organization_id' => $org->id,
                'status' => 'active',
                'verification_status' => 'verified',
                'password' => 'password',
                'email_verified_at' => now(),
            ],
        );

        foreach ([$accountant, $agent, $vendorUser, $techUser] as $user) {
            $org->users()->syncWithoutDetaching([
                $user->id => [
                    'role' => $user->role,
                    'status' => 'active',
                    'permissions' => json_encode(Roles::permissions()[$user->role] ?? []),
                ],
            ]);
            NotificationPreference::query()->firstOrCreate(
                ['user_id' => $user->id],
                ['in_app' => true, 'email' => true, 'whatsapp' => true],
            );
        }

        $marina->update(['organization_id' => $org->id]);
        $corniche->update(['organization_id' => $org->id]);

        $building = Building::query()->updateOrCreate(
            ['property_id' => $marina->id, 'name' => 'Tower A'],
            [
                'organization_id' => $org->id,
                'code' => 'MH-A',
                'total_floors' => 20,
                'status' => 'active',
            ],
        );
        $floor1 = Floor::query()->updateOrCreate(
            ['building_id' => $building->id, 'level' => 1],
            ['name' => 'Level 1'],
        );
        $floor2 = Floor::query()->updateOrCreate(
            ['building_id' => $building->id, 'level' => 2],
            ['name' => 'Level 2'],
        );

        $unitA->update([
            'organization_id' => $org->id,
            'building_id' => $building->id,
            'floor_id' => $floor1->id,
            'unit_type' => 'apartment',
            'area' => $unitA->square_feet,
            'furnishing_status' => 'semi_furnished',
            'maintenance_charge' => 150,
            'tenant_capacity' => 3,
            'amenities' => ['parking', 'gym', 'pool'],
            'meter_numbers' => ['electric' => 'E-1001', 'water' => 'W-1001'],
            'assigned_manager_id' => $managerUser->id,
            'is_listed' => false,
            'status' => 'occupied',
        ]);
        $unitE->update([
            'organization_id' => $org->id,
            'unit_type' => 'apartment',
            'area' => $unitE->square_feet,
            'furnishing_status' => 'unfurnished',
            'is_listed' => false,
            'status' => 'vacant',
            'assigned_manager_id' => $managerUser->id,
        ]);

        $vendor = Vendor::query()->updateOrCreate(
            ['email' => 'vendor@grids.test'],
            [
                'organization_id' => $org->id,
                'user_id' => $vendorUser->id,
                'company_name' => 'Gulf Fix Services',
                'contact_name' => $vendorUser->name,
                'phone' => $vendorUser->phone,
                'categories' => ['plumbing', 'electrical', 'hvac'],
                'status' => 'active',
            ],
        );

        MaintenanceRequest::query()->updateOrCreate(
            ['ticket_number' => 'MT-DEMO-AC01'],
            [
                'organization_id' => $org->id,
                'rental_unit_id' => $unitA->id,
                'property_id' => $marina->id,
                'tenant_id' => $tenantOmar->id,
                'title' => 'AC not cooling',
                'description' => 'Bedroom AC blows warm air since yesterday evening.',
                'category' => 'hvac',
                'priority' => 'high',
                'status' => 'open',
                'workflow_status' => 'ai_triaged',
                'permission_to_enter' => true,
                'preferred_visit_date' => now()->addDay()->toDateString(),
                'assigned_vendor_id' => $vendor->id,
                'assigned_technician_id' => $techUser->id,
                'estimated_cost' => 450,
                'ai_triage' => [
                    'recommendation_only' => true,
                    'category' => 'hvac',
                    'priority' => 'high',
                    'vendor_type' => 'HVAC technician',
                    'manager_summary' => 'Likely HVAC issue. Schedule licensed technician.',
                ],
                'sla_due_at' => now()->addHours(24),
                'reported_at' => now()->subHours(5),
            ],
        );

        $this->seedNotificationTemplates($org->id);

        foreach (NotificationCatalog::CHANNELS as $channel) {
            NotificationChannelSetting::query()->firstOrCreate(
                ['organization_id' => null, 'channel' => $channel],
                [
                    'enabled' => true,
                    'provider' => match ($channel) {
                        'email' => 'smtp',
                        'whatsapp' => 'twilio_whatsapp',
                        default => 'in_app',
                    },
                ],
            );
        }

        foreach ([$superAdmin, $ownerUser, $managerUser, $tenantUser, $accountant, $agent] as $user) {
            NotificationPreference::query()->firstOrCreate(
                ['user_id' => $user->id],
                ['in_app' => true, 'email' => true, 'whatsapp' => true],
            );
        }

        $unitA->update(['floor' => (string) $floor1->level]);
        RentalUnit::query()->where('unit_number', 'B-201')->update([
            'organization_id' => $org->id,
            'building_id' => $building->id,
            'floor_id' => $floor2->id,
            'status' => 'under_maintenance',
        ]);
    }

    private function seedNotificationTemplates(?int $organizationId): void
    {
        $defaults = [
            ['key' => 'org.registered', 'name' => 'Organisation registered', 'category' => 'system', 'roles' => [Roles::SUPER_ADMIN], 'priority' => 'high', 'body' => 'New organisation {{organisation_name}} registered.'],
            ['key' => 'subscription.payment_failed', 'name' => 'Subscription payment failed', 'category' => 'subscription_billing', 'roles' => [Roles::SUPER_ADMIN], 'priority' => 'critical', 'is_emergency' => true, 'body' => 'Subscription payment failed for {{organisation_name}}.'],
            ['key' => 'security.suspicious_login', 'name' => 'Suspicious login', 'category' => 'account_security', 'roles' => [Roles::SUPER_ADMIN], 'priority' => 'critical', 'is_emergency' => true, 'body' => 'Suspicious login detected for {{user_name}}.'],
            ['key' => 'property.added', 'name' => 'Property added', 'category' => 'property_unit', 'roles' => [Roles::OWNER], 'priority' => 'normal', 'body' => 'Property {{property_name}} was added to your portfolio.'],
            ['key' => 'lease.expiring', 'name' => 'Lease expiring', 'category' => 'lease', 'roles' => [Roles::OWNER, Roles::MANAGER, Roles::TENANT], 'priority' => 'high', 'body' => 'Lease for {{unit_number}} at {{property_name}} expires on {{due_date}}.'],
            ['key' => 'rent.overdue', 'name' => 'Rent overdue', 'category' => 'rent_payment', 'roles' => [Roles::OWNER, Roles::MANAGER, Roles::TENANT, Roles::ACCOUNTANT], 'priority' => 'high', 'body' => 'Rent of {{amount}} for {{unit_number}} is overdue. Tenant: {{tenant_name}}.'],
            ['key' => 'maintenance.quotation_awaiting_approval', 'name' => 'Quotation awaiting approval', 'category' => 'approval', 'roles' => [Roles::OWNER], 'priority' => 'high', 'body' => 'Quotation of {{amount}} for ticket {{ticket_number}} awaits approval.'],
            ['key' => 'maintenance.submitted', 'name' => 'Maintenance submitted', 'category' => 'maintenance', 'roles' => [Roles::MANAGER], 'priority' => 'high', 'body' => 'Maintenance {{ticket_number}} submitted for {{property_name}} {{unit_number}}.'],
            ['key' => 'maintenance.sla_breached', 'name' => 'SLA breached', 'category' => 'maintenance', 'roles' => [Roles::MANAGER], 'priority' => 'critical', 'is_emergency' => true, 'body' => 'SLA breached for ticket {{ticket_number}} at {{property_name}}.'],
            ['key' => 'invoice.generated', 'name' => 'Invoice generated', 'category' => 'rent_payment', 'roles' => [Roles::ACCOUNTANT, Roles::TENANT], 'priority' => 'normal', 'body' => 'Invoice {{invoice_number}} for {{amount}} is ready. Due {{due_date}}.'],
            ['key' => 'payment.received', 'name' => 'Payment received', 'category' => 'rent_payment', 'roles' => [Roles::ACCOUNTANT], 'priority' => 'normal', 'body' => 'Payment of {{amount}} received for invoice {{invoice_number}}.'],
            ['key' => 'payment.failed', 'name' => 'Payment failed', 'category' => 'rent_payment', 'roles' => [Roles::ACCOUNTANT, Roles::TENANT], 'priority' => 'critical', 'is_emergency' => true, 'body' => 'Payment of {{amount}} failed for invoice {{invoice_number}}.'],
            ['key' => 'lead.created', 'name' => 'New lead', 'category' => 'listing_lead', 'roles' => [Roles::AGENT], 'priority' => 'high', 'body' => 'New lead for {{property_name}} {{unit_number}}. Follow up via {{action_link}}.'],
            ['key' => 'visit.scheduled', 'name' => 'Visit scheduled', 'category' => 'listing_lead', 'roles' => [Roles::AGENT, Roles::TENANT, Roles::MANAGER], 'priority' => 'normal', 'body' => 'Visit scheduled on {{scheduled_date}} for {{property_name}} {{unit_number}}.'],
            ['key' => 'rent.due', 'name' => 'Rent due', 'category' => 'rent_payment', 'roles' => [Roles::TENANT], 'priority' => 'high', 'body' => 'Hi {{user_name}}, rent of {{amount}} for {{unit_number}} is due on {{due_date}}.'],
            ['key' => 'maintenance.status_updated', 'name' => 'Maintenance status updated', 'category' => 'maintenance', 'roles' => [Roles::TENANT], 'priority' => 'normal', 'body' => 'Ticket {{ticket_number}} status was updated. Open {{action_link}}.'],
            ['key' => 'maintenance.job_assigned', 'name' => 'Job assigned', 'category' => 'maintenance', 'roles' => [Roles::VENDOR, Roles::TECHNICIAN], 'priority' => 'high', 'body' => 'Job {{ticket_number}} assigned at {{property_name}} {{unit_number}}. Visit {{scheduled_date}}.'],
            ['key' => 'quotation.approved', 'name' => 'Quotation approved', 'category' => 'approval', 'roles' => [Roles::VENDOR], 'priority' => 'high', 'body' => 'Quotation of {{amount}} for {{ticket_number}} was approved.'],
            ['key' => 'announcement.published', 'name' => 'Announcement', 'category' => 'announcement', 'roles' => [Roles::TENANT], 'priority' => 'low', 'body' => 'New announcement for {{property_name}}: open {{action_link}}.'],
        ];

        foreach ($defaults as $template) {
            NotificationTemplate::query()->updateOrCreate(
                ['organization_id' => null, 'key' => $template['key']],
                [
                    'name' => $template['name'],
                    'category' => $template['category'],
                    'roles' => $template['roles'],
                    'channel' => 'in_app',
                    'channels' => ['in_app', 'email', 'whatsapp'],
                    'priority' => $template['priority'],
                    'is_emergency' => $template['is_emergency'] ?? false,
                    'subject' => $template['name'],
                    'body' => $template['body'],
                    'variables' => NotificationCatalog::templateVariables(),
                    'is_active' => true,
                ],
            );
        }

        // Organisation-level customization sample (does not affect other orgs).
        if ($organizationId) {
            NotificationTemplate::query()->updateOrCreate(
                ['organization_id' => $organizationId, 'key' => 'rent.due'],
                [
                    'name' => 'Rent due (Grids branding)',
                    'category' => 'rent_payment',
                    'roles' => [Roles::TENANT],
                    'channel' => 'in_app',
                    'channels' => ['in_app', 'email', 'whatsapp'],
                    'priority' => 'high',
                    'is_emergency' => false,
                    'subject' => 'Grids rent reminder',
                    'body' => 'Hi {{user_name}}, Grids reminder: {{amount}} for {{unit_number}} at {{property_name}} is due on {{due_date}}. Pay: {{action_link}}',
                    'variables' => NotificationCatalog::templateVariables(),
                    'is_active' => true,
                ],
            );
        }
    }

    private function seedDemoNotifications(
        User $superAdmin,
        User $ownerUser,
        User $managerUser,
        User $tenantUser,
    ): void {
        /** @var NotificationService $service */
        $service = App::make(NotificationService::class);

        $accountant = User::query()->where('email', 'accountant@grids.test')->first();
        $agent = User::query()->where('email', 'agent@grids.test')->first();
        $vendor = User::query()->where('email', 'vendor@grids.test')->first();
        $technician = User::query()->where('email', 'technician@grids.test')->first();

        $samples = [
            [$superAdmin, 'org.registered', [
                'title' => 'New organisation registered',
                'message' => 'Grids Abu Dhabi completed onboarding and awaits verification.',
                'priority' => 'high',
                'module' => 'organizations',
                'action_url' => '/organizations',
                'channels' => ['in_app', 'email'],
                'variables' => ['organisation_name' => 'Grids Abu Dhabi'],
            ]],
            [$superAdmin, 'org.verification_requested', [
                'title' => 'Tenant verification requested',
                'message' => 'KYC documents uploaded for Grids Abu Dhabi — approval required.',
                'priority' => 'high',
                'module' => 'organizations',
                'category' => 'approval',
                'action_url' => '/organizations',
                'channels' => ['in_app', 'email', 'whatsapp'],
                'variables' => ['organisation_name' => 'Grids Abu Dhabi'],
            ]],
            [$superAdmin, 'subscription.payment_failed', [
                'title' => 'Subscription payment failed',
                'message' => 'Card decline on Growth plan renewal.',
                'priority' => 'critical',
                'is_emergency' => true,
                'module' => 'billing',
                'action_url' => '/organizations',
                'channels' => ['in_app', 'email', 'whatsapp'],
            ]],
            [$superAdmin, 'security.alert', [
                'title' => 'Security alert',
                'message' => 'Multiple failed Super Admin login attempts from a new IP.',
                'priority' => 'critical',
                'is_emergency' => true,
                'module' => 'security',
                'category' => 'account_security',
                'action_url' => '/settings',
                'channels' => ['in_app', 'email', 'whatsapp'],
            ]],
            [$superAdmin, 'integration.failure', [
                'title' => 'Paytm integration failure',
                'message' => 'Staging webhook returned 500 for 12 minutes.',
                'priority' => 'critical',
                'is_emergency' => true,
                'module' => 'system',
                'action_url' => '/notifications/admin',
                'channels' => ['in_app', 'email'],
            ]],
            [$superAdmin, 'delivery.whatsapp_failed', [
                'title' => 'WhatsApp delivery failure',
                'message' => '12 rent-due templates failed — Twilio rate limit.',
                'priority' => 'high',
                'module' => 'system',
                'action_url' => '/notifications/admin',
                'channels' => ['in_app', 'email'],
            ]],
            [$superAdmin, 'support.high_priority', [
                'title' => 'High-priority support ticket',
                'message' => 'Urgent complaint from tenant Omar Hassan needs escalation.',
                'priority' => 'high',
                'module' => 'support',
                'category' => 'support',
                'action_url' => '/help-support',
                'channels' => ['in_app', 'email', 'whatsapp'],
            ]],
            [$superAdmin, 'report.daily', [
                'title' => 'Daily platform report',
                'message' => 'Collections AED 128k · 4 open critical alerts · 2 orgs pending verification.',
                'priority' => 'low',
                'module' => 'reports',
                'action_url' => '/dashboard',
                'channels' => ['in_app', 'email'],
            ]],
            [$ownerUser, 'org.approved', [
                'title' => 'Organisation approved',
                'message' => 'Your Grids Abu Dhabi account is verified and active.',
                'priority' => 'high',
                'module' => 'organizations',
                'category' => 'account_security',
                'action_url' => '/dashboard',
                'channels' => ['in_app', 'email', 'whatsapp'],
            ]],
            [$ownerUser, 'subscription.renewal_reminder', [
                'title' => 'Subscription renewal reminder',
                'message' => 'Growth plan renews in 5 days. Update billing if needed.',
                'priority' => 'high',
                'module' => 'billing',
                'category' => 'subscription_billing',
                'action_url' => '/settings',
                'channels' => ['in_app', 'email', 'whatsapp'],
            ]],
            [$ownerUser, 'property.added', [
                'title' => 'Property submitted',
                'message' => 'Marina Heights was added to your portfolio.',
                'module' => 'properties',
                'record_type' => 'property',
                'action_url' => '/properties',
                'channels' => ['in_app', 'email'],
                'variables' => ['property_name' => 'Marina Heights'],
            ]],
            [$ownerUser, 'manager.added', [
                'title' => 'Manager added',
                'message' => 'James Carter was assigned as Property Manager.',
                'module' => 'users',
                'category' => 'account_security',
                'action_url' => '/users',
                'channels' => ['in_app', 'email'],
            ]],
            [$ownerUser, 'lease.expiring', [
                'title' => 'Lease expiring',
                'message' => 'Corniche Towers C-301 lease expires within 30 days.',
                'priority' => 'high',
                'module' => 'leases',
                'action_url' => '/leases',
                'channels' => ['in_app', 'email', 'whatsapp'],
                'variables' => [
                    'property_name' => 'Corniche Towers',
                    'unit_number' => 'C-301',
                    'due_date' => now()->addDays(28)->toDateString(),
                ],
            ]],
            [$ownerUser, 'rent.overdue', [
                'title' => 'Overdue rent',
                'message' => 'Omar Hassan has an overdue balance on A-101.',
                'priority' => 'high',
                'module' => 'payments',
                'action_url' => '/payments',
                'channels' => ['in_app', 'email', 'whatsapp'],
                'variables' => [
                    'tenant_name' => 'Omar Hassan',
                    'unit_number' => 'A-101',
                    'amount' => 'AED 4,500',
                    'property_name' => 'Marina Heights',
                ],
            ]],
            [$ownerUser, 'maintenance.quotation_awaiting_approval', [
                'title' => 'Quotation awaiting approval',
                'message' => 'AED 450 quote for MT-DEMO-AC01 needs approval.',
                'priority' => 'high',
                'module' => 'maintenance',
                'action_url' => '/maintenance',
                'channels' => ['in_app', 'email', 'whatsapp'],
                'variables' => ['ticket_number' => 'MT-DEMO-AC01', 'amount' => 'AED 450'],
            ]],
            [$ownerUser, 'announcement.from_super_admin', [
                'title' => 'Platform maintenance notice',
                'message' => 'Scheduled platform maintenance this Sunday 02:00–04:00 GST.',
                'priority' => 'normal',
                'module' => 'announcements',
                'category' => 'announcement',
                'action_url' => '/notifications',
                'channels' => ['in_app', 'email'],
            ]],
            [$managerUser, 'property.assigned', [
                'title' => 'New property assigned',
                'message' => 'You are now managing Marina Heights and Corniche Towers.',
                'priority' => 'high',
                'module' => 'properties',
                'action_url' => '/properties',
                'channels' => ['in_app', 'email'],
            ]],
            [$managerUser, 'property.requires_review', [
                'title' => 'Property requires review',
                'message' => 'Owner submitted listing changes for Reem Gate Residences.',
                'priority' => 'high',
                'module' => 'properties',
                'category' => 'approval',
                'action_url' => '/properties',
                'channels' => ['in_app', 'email', 'whatsapp'],
                'variables' => ['property_name' => 'Reem Gate Residences'],
            ]],
            [$managerUser, 'maintenance.submitted', [
                'title' => 'Maintenance request submitted',
                'message' => 'AC not cooling reported at Marina Heights A-101.',
                'priority' => 'high',
                'module' => 'maintenance',
                'action_url' => '/maintenance',
                'channels' => ['in_app', 'email', 'whatsapp'],
                'variables' => [
                    'ticket_number' => 'MT-DEMO-AC01',
                    'property_name' => 'Marina Heights',
                    'unit_number' => 'A-101',
                ],
            ]],
            [$managerUser, 'maintenance.sla_breached', [
                'title' => 'SLA breached',
                'message' => 'Ticket MT-DEMO-AC01 exceeded response SLA.',
                'priority' => 'critical',
                'is_emergency' => true,
                'module' => 'maintenance',
                'action_url' => '/maintenance',
                'channels' => ['in_app', 'email', 'whatsapp'],
                'variables' => ['ticket_number' => 'MT-DEMO-AC01', 'property_name' => 'Marina Heights'],
            ]],
            [$managerUser, 'tenant.application_received', [
                'title' => 'New tenant application',
                'message' => 'Application received for Corniche Towers C-302.',
                'priority' => 'high',
                'module' => 'tenants',
                'action_url' => '/tenants',
                'category' => 'listing_lead',
                'channels' => ['in_app', 'email'],
                'variables' => ['property_name' => 'Corniche Towers', 'unit_number' => 'C-302'],
            ]],
            [$managerUser, 'task.reminder', [
                'title' => 'Task reminder',
                'message' => 'Site visit at Marina Heights scheduled for tomorrow 10:00.',
                'priority' => 'normal',
                'module' => 'calendar',
                'action_url' => '/calendar',
                'channels' => ['in_app', 'whatsapp'],
            ]],
            [$tenantUser, 'rent.due', [
                'title' => 'Rent due reminder',
                'message' => 'Your rent of AED 4,500 is due soon.',
                'priority' => 'high',
                'module' => 'invoices',
                'action_url' => '/payments',
                'channels' => ['in_app', 'email', 'whatsapp'],
                'variables' => [
                    'amount' => 'AED 4,500',
                    'unit_number' => 'A-101',
                    'property_name' => 'Marina Heights',
                    'due_date' => now()->addDays(3)->toDateString(),
                ],
            ]],
            [$tenantUser, 'invoice.generated', [
                'title' => 'Rent invoice generated',
                'message' => 'Invoice INV-SHOW-UNPAID-001 for AED 4,650 is ready.',
                'priority' => 'high',
                'module' => 'invoices',
                'action_url' => '/invoices',
                'channels' => ['in_app', 'email', 'whatsapp'],
                'variables' => [
                    'invoice_number' => 'INV-SHOW-UNPAID-001',
                    'amount' => 'AED 4,650',
                ],
            ]],
            [$tenantUser, 'maintenance.status_updated', [
                'title' => 'Maintenance status updated',
                'message' => 'Your AC request is being scheduled.',
                'module' => 'maintenance',
                'action_url' => '/maintenance',
                'channels' => ['in_app', 'email'],
                'variables' => ['ticket_number' => 'MT-DEMO-AC01'],
            ]],
            [$tenantUser, 'maintenance.visit_scheduled', [
                'title' => 'Maintenance visit scheduled',
                'message' => 'Technician visit for AC repair tomorrow between 10:00–12:00.',
                'priority' => 'high',
                'module' => 'maintenance',
                'action_url' => '/maintenance',
                'channels' => ['in_app', 'email', 'whatsapp'],
            ]],
            [$tenantUser, 'announcement.published', [
                'title' => 'Building announcement',
                'message' => 'Water maintenance scheduled for Tower A this Friday.',
                'priority' => 'low',
                'module' => 'announcements',
                'action_url' => '/documents',
                'channels' => ['in_app', 'email'],
                'variables' => ['property_name' => 'Marina Heights'],
            ]],
        ];

        if ($accountant) {
            $samples[] = [$accountant, 'invoice.generated', [
                'title' => 'Invoice generated',
                'message' => 'INV-OMAR-2026-08 generated for Omar Hassan.',
                'module' => 'invoices',
                'action_url' => '/invoices',
                'variables' => ['invoice_number' => 'INV-OMAR-2026-08', 'amount' => 'AED 4,500', 'due_date' => now()->addDays(5)->toDateString()],
            ]];
            $samples[] = [$accountant, 'payment.failed', [
                'title' => 'Payment failed',
                'message' => 'Card payment failed for INV-OMAR-2026-07.',
                'priority' => 'critical',
                'is_emergency' => true,
                'module' => 'payments',
                'action_url' => '/payments',
                'variables' => ['invoice_number' => 'INV-OMAR-2026-07', 'amount' => 'AED 4,500'],
            ]];
            $samples[] = [$accountant, 'owner.payout_due', [
                'title' => 'Owner payout due',
                'message' => 'Monthly owner payout is ready for review.',
                'priority' => 'high',
                'module' => 'payments',
                'category' => 'rent_payment',
                'action_url' => '/transactions',
            ]];
        }

        if ($agent) {
            $samples[] = [$agent, 'lead.created', [
                'title' => 'New lead',
                'message' => 'Lead interested in Corniche Towers C-302.',
                'priority' => 'high',
                'module' => 'listings',
                'action_url' => '/listings',
                'variables' => ['property_name' => 'Corniche Towers', 'unit_number' => 'C-302'],
            ]];
            $samples[] = [$agent, 'visit.scheduled', [
                'title' => 'Property visit scheduled',
                'message' => 'Visit booked for C-302 tomorrow at 11:00.',
                'module' => 'listings',
                'action_url' => '/calendar',
                'variables' => [
                    'property_name' => 'Corniche Towers',
                    'unit_number' => 'C-302',
                    'scheduled_date' => now()->addDay()->format('Y-m-d H:i'),
                ],
            ]];
        }

        if ($vendor) {
            $samples[] = [$vendor, 'maintenance.job_assigned', [
                'title' => 'Maintenance job assigned',
                'message' => 'Job MT-DEMO-AC01 assigned to your team.',
                'priority' => 'high',
                'module' => 'maintenance',
                'action_url' => '/maintenance',
                'variables' => [
                    'ticket_number' => 'MT-DEMO-AC01',
                    'property_name' => 'Marina Heights',
                    'unit_number' => 'A-101',
                    'scheduled_date' => now()->addDay()->format('Y-m-d H:i'),
                ],
            ]];
            $samples[] = [$vendor, 'quotation.approved', [
                'title' => 'Quotation approved',
                'message' => 'Your AED 450 quote for MT-DEMO-AC01 was approved.',
                'priority' => 'high',
                'module' => 'maintenance',
                'action_url' => '/maintenance',
                'variables' => ['ticket_number' => 'MT-DEMO-AC01', 'amount' => 'AED 450'],
            ]];
        }

        if ($technician) {
            $samples[] = [$technician, 'maintenance.job_assigned', [
                'title' => 'Job assigned',
                'message' => 'You were assigned to MT-DEMO-AC01.',
                'priority' => 'high',
                'module' => 'maintenance',
                'action_url' => '/maintenance',
                'variables' => [
                    'ticket_number' => 'MT-DEMO-AC01',
                    'property_name' => 'Marina Heights',
                    'unit_number' => 'A-101',
                    'scheduled_date' => now()->addDay()->format('Y-m-d H:i'),
                ],
            ]];
            $samples[] = [$technician, 'maintenance.deadline_approaching', [
                'title' => 'Work deadline approaching',
                'message' => 'Complete MT-DEMO-AC01 before SLA expires.',
                'priority' => 'high',
                'module' => 'maintenance',
                'category' => 'maintenance',
                'action_url' => '/maintenance',
                'variables' => ['ticket_number' => 'MT-DEMO-AC01'],
            ]];
        }

        foreach ($samples as [$recipient, $event, $data]) {
            $data['dedupe_key'] = 'seed|'.$recipient->id.'|'.$event.'|'.md5(json_encode($data));
            $service->notify($recipient, $event, $data);
        }
    }

    private function seedSupportCatalogueAndTickets(
        User $tenantUser,
        Property $marina,
        RentalUnit $unitA,
    ): void {
        $sort = 0;
        foreach (DomainCatalog::supportCategories() as $key => $row) {
            SupportCategory::query()->updateOrCreate(
                ['key' => $key],
                [
                    'name' => $row['name'],
                    'route_to' => $row['route_to'],
                    'description' => $row['description'],
                    'is_active' => true,
                    'sort_order' => $sort++,
                ],
            );
        }

        /** @var SupportTicketService $support */
        $support = App::make(SupportTicketService::class);

        // Keep Help & Support demo data small. Repeated SEED_ON_BOOT used to append
        // two tickets every run and balloon the list (e.g. 30+).
        SupportTicket::query()
            ->where(function ($query) use ($tenantUser) {
                $query->where('user_id', $tenantUser->id)
                    ->orWhereIn('email', [
                        'tenant@grids.test',
                        'nancy2005nov+tenant@gmail.com',
                    ]);
            })
            ->delete();

        $support->create($tenantUser, [
            'contact_type' => 'manager',
            'name' => $tenantUser->name,
            'email' => $tenantUser->email,
            'phone' => $tenantUser->phone,
            'subject' => 'AC still warm after last visit',
            'category' => 'maintenance',
            'priority' => 'high',
            'property_id' => $marina->id,
            'rental_unit_id' => $unitA->id,
            'message' => 'Bedroom AC is still blowing warm air. Please advise on next visit.',
            'preferred_contact_method' => 'email',
        ]);
        $support->create($tenantUser, [
            'contact_type' => 'platform',
            'name' => $tenantUser->name,
            'email' => $tenantUser->email,
            'phone' => $tenantUser->phone,
            'subject' => 'Cannot open receipt PDF on mobile',
            'category' => 'technical_issue',
            'priority' => 'normal',
            'property_id' => $marina->id,
            'rental_unit_id' => $unitA->id,
            'message' => 'Receipt download fails on Safari. Looking for a workaround.',
            'preferred_contact_method' => 'email',
        ]);
    }

    /**
     * @param  array<int, array{ago:int,status:string,paid:float|int,overdue?:bool}>  $months
     */
    private function seedLeaseBilling(Contract $lease, array $months, string $tag): void
    {
        foreach ($months as $row) {
            $period = now()->subMonths($row['ago'])->format('Y-m');
            $total = (float) $lease->monthly_rent;
            $paid = (float) $row['paid'];
            $remaining = max($total - $paid, 0);
            $due = now()->subMonths($row['ago'])->startOfMonth()->addDays(max(0, ((int) $lease->payment_day) - 1));
            if (! empty($row['overdue'])) {
                $due = now()->subDays(12);
            }

            $invoice = Invoice::query()->updateOrCreate(
                ['invoice_number' => "INV-{$tag}-{$period}"],
                [
                    'contract_id' => $lease->id,
                    'billing_month' => $period,
                    'rent_amount' => $total,
                    'additional_charges' => 0,
                    'discounts' => 0,
                    'late_fee' => ! empty($row['overdue']) ? (float) $lease->late_fee_amount : 0,
                    'previous_balance' => 0,
                    'total_amount' => $total + (! empty($row['overdue']) ? (float) $lease->late_fee_amount : 0),
                    'paid_amount' => $paid,
                    'remaining_balance' => max(($total + (! empty($row['overdue']) ? (float) $lease->late_fee_amount : 0)) - $paid, 0),
                    'due_date' => $due->toDateString(),
                    'status' => $row['status'],
                    'notes' => "Demo {$tag} invoice for {$period}",
                ],
            );

            if ($paid > 0) {
                Payment::query()->updateOrCreate(
                    ['reference' => "PAY-{$tag}-{$period}"],
                    [
                        'contract_id' => $lease->id,
                        'invoice_id' => $invoice->id,
                        'transaction_number' => "TXN-{$tag}-{$period}",
                        'amount' => $paid,
                        'due_date' => $due->toDateString(),
                        'paid_at' => $due->copy()->addDays(2)->toDateString(),
                        'method' => 'bank_transfer',
                        'status' => 'paid',
                        'approval_status' => 'approved',
                        'period' => $period,
                        'notes' => "Demo payment {$tag} {$period}",
                    ],
                );
            } else {
                Payment::query()->updateOrCreate(
                    ['reference' => "PAY-{$tag}-{$period}"],
                    [
                        'contract_id' => $lease->id,
                        'invoice_id' => $invoice->id,
                        'transaction_number' => "TXN-{$tag}-{$period}",
                        'amount' => $invoice->total_amount,
                        'due_date' => $due->toDateString(),
                        'paid_at' => null,
                        'method' => null,
                        'status' => ! empty($row['overdue']) || $row['status'] === 'overdue' ? 'overdue' : 'pending',
                        'approval_status' => null,
                        'period' => $period,
                        'notes' => "Open payment {$tag} {$period}",
                    ],
                );
            }
        }
    }
}
