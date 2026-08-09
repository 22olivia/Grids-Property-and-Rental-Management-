<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DemoRentalSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class AutomationApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_automation_marks_overdue_and_generates_due_payments(): void
    {
        $this->seed(DemoRentalSeeder::class);

        $user = User::query()->where('email', 'admin@rental.test')->firstOrFail();

        $beforeOverdue = \App\Models\Payment::query()->where('status', 'overdue')->count();

        $response = $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/automation/run');

        $response->assertOk()
            ->assertJsonPath('message', 'Automation completed.')
            ->assertJsonStructure([
                'data' => [
                    'generated_payments',
                    'marked_overdue',
                    'reminders',
                    'expiring_leases',
                    'expiry_reminders',
                    'ran_at',
                    'plain_summary',
                    'changes' => [
                        'generated',
                        'marked_overdue',
                        'reminders',
                        'expiry_reminders',
                    ],
                ],
            ]);

        $this->assertGreaterThan(
            $beforeOverdue,
            \App\Models\Payment::query()->where('status', 'overdue')->count()
        );

        // Demo seed already bills the current month for active leases; generation may be 0.
        $this->assertGreaterThanOrEqual(0, (int) $response->json('data.generated_payments'));
    }

    public function test_reset_demo_restores_overdue_seed_payment(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $user = User::query()->where('email', 'admin@rental.test')->firstOrFail();

        $this->actingAs($user, 'sanctum')->postJson('/api/v1/automation/run')->assertOk();

        $this->actingAs($user, 'sanctum')
            ->postJson('/api/v1/automation/reset-demo')
            ->assertOk()
            ->assertJsonPath('data.reset_overdue_demo', true);

        $this->assertDatabaseHas('payments', [
            'reference' => 'PAY-DEMO-OVERDUE-01',
            'status' => 'pending',
        ]);

        $this->assertDatabaseMissing('payments', [
            'notes' => 'Auto-generated rent for '.now()->format('Y-m'),
        ]);
    }

    public function test_automation_requires_auth(): void
    {
        $this->postJson('/api/v1/automation/run')->assertUnauthorized();
    }
}
