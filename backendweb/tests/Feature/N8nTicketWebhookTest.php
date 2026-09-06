<?php

namespace Tests\Feature;

use App\Models\User;
use Database\Seeders\DemoRentalSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Support\Facades\Http;
use Tests\TestCase;

class N8nTicketWebhookTest extends TestCase
{
    use RefreshDatabase;

    public function test_support_ticket_create_posts_to_n8n_webhook(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();

        config([
            'services.n8n.enabled' => true,
            'services.n8n.ticket_webhook_url' => 'https://gridsgpms.app.n8n.cloud/webhook/gpms-ticket',
            'services.n8n.webhook_secret' => 'test-secret',
        ]);

        Http::fake([
            'gridsgpms.app.n8n.cloud/*' => Http::response(['ok' => true], 200),
        ]);

        $response = $this->actingAs($tenant, 'sanctum')
            ->postJson('/api/v1/support/tickets', [
                'contact_type' => 'platform',
                'name' => $tenant->name,
                'email' => $tenant->email,
                'phone' => $tenant->phone,
                'subject' => 'n8n webhook test',
                'category' => 'general_query',
                'priority' => 'normal',
                'message' => 'Please confirm n8n received this ticket event.',
                'preferred_contact_method' => 'email',
            ]);

        $response->assertCreated()
            ->assertJsonPath('notifications.n8n.ok', true)
            ->assertJsonPath('notifications.n8n.status', 'sent');

        $ticketId = (string) $response->json('data.id');
        $this->assertNotSame('', $ticketId);

        Http::assertSent(function ($request) use ($ticketId) {
            return $request->url() === 'https://gridsgpms.app.n8n.cloud/webhook/gpms-ticket'
                && $request['event'] === 'support_ticket_created'
                && $request['source'] === 'gpms'
                && ($request['ticket']['id'] ?? null) === $ticketId
                && ! array_key_exists('ping', $request->data())
                && $request->hasHeader('X-GPMS-N8N-Secret', 'test-secret');
        });
    }
}
