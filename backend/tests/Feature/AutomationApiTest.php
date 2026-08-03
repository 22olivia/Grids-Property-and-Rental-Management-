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
                    'ran_at',
                ],
            ]);

        $this->assertGreaterThan(
            $beforeOverdue,
            \App\Models\Payment::query()->where('status', 'overdue')->count()
        );

        $this->assertDatabaseHas('payments', [
            'period' => now()->format('Y-m'),
            'notes' => 'Auto-generated rent for '.now()->format('Y-m'),
        ]);
    }

    public function test_automation_requires_auth(): void
    {
        $this->postJson('/api/v1/automation/run')->assertUnauthorized();
    }
}
