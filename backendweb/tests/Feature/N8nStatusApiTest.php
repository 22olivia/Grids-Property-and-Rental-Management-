<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DemoRentalSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class N8nStatusApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_super_admin_can_view_n8n_status_and_ticket_assignees(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $admin = User::query()->where('role', 'super_admin')->orderBy('id')->firstOrFail();

        config([
            'services.n8n.enabled' => true,
            'services.n8n.ticket_webhook_url' => 'https://gridsgpms.app.n8n.cloud/webhook/gpms-ticket',
            'services.n8n.webhook_secret' => 'secret',
        ]);

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/n8n/status')
            ->assertOk()
            ->assertJsonPath('data.enabled', true)
            ->assertJsonPath('data.webhook_configured', true)
            ->assertJsonPath('data.webhook_host', 'gridsgpms.app.n8n.cloud')
            ->assertJsonPath('data.secret_configured', true)
            ->assertJsonPath('data.event', 'support_ticket_created')
            ->assertJsonStructure([
                'data' => [
                    'recent_tickets' => [
                        ['id', 'ticket_number', 'subject', 'status', 'assigned_to', 'assignee'],
                    ],
                ],
            ]);
    }

    public function test_non_admin_cannot_view_n8n_status(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $owner = User::query()->where('email', 'owner@grids.test')->firstOrFail();

        $this->actingAs($owner, 'sanctum')
            ->getJson('/api/v1/n8n/status')
            ->assertForbidden();
    }
}
