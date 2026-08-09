<?php

namespace Tests\Feature;

use App\Models\EmailLog;
use App\Models\SupportTicket;
use App\Models\User;
use Database\Seeders\DemoRentalSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\Storage;
use Tests\TestCase;

class SupportApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_tenant_can_create_and_track_support_ticket(): void
    {
        Storage::fake('local');
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();

        $response = $this->actingAs($tenant, 'sanctum')
            ->post('/api/v1/support/tickets', [
                'contact_type' => 'owner',
                'name' => $tenant->name,
                'email' => $tenant->email,
                'phone' => $tenant->phone,
                'subject' => 'Question about deposit',
                'category' => 'lease',
                'priority' => 'normal',
                'message' => 'When will my deposit be refunded after move-out?',
                'preferred_contact_method' => 'email',
                'attachments' => [
                    UploadedFile::fake()->create('note.pdf', 100, 'application/pdf'),
                ],
            ]);

        $response->assertCreated()
            ->assertJsonPath('data.category', 'lease')
            ->assertJsonPath('data.status', 'assigned');

        $ticketId = $response->json('data.id');
        $this->assertDatabaseHas('support_tickets', ['id' => $ticketId]);
        $this->assertTrue(EmailLog::query()->where('template_key', 'support_ticket_user')->exists());
        $this->assertTrue(EmailLog::query()->whereIn('template_key', ['contact_owner', 'support_ticket_staff'])->exists());

        $this->actingAs($tenant, 'sanctum')
            ->getJson('/api/v1/support/tickets/'.$ticketId)
            ->assertOk()
            ->assertJsonPath('data.ticket_number', fn ($v) => is_string($v) && str_starts_with($v, 'SUP-'));

        $this->actingAs($tenant, 'sanctum')
            ->postJson('/api/v1/support/tickets/'.$ticketId.'/reply', [
                'body' => 'Adding more details about the move-out date.',
            ])
            ->assertOk();
    }

    public function test_support_meta_and_faq_available(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();

        $this->actingAs($tenant, 'sanctum')
            ->getJson('/api/v1/support/meta')
            ->assertOk()
            ->assertJsonStructure([
                'data' => ['support_email', 'helpline', 'hours', 'categories', 'faqs', 'priorities', 'contact_types'],
            ]);
    }

    public function test_ticket_visibility_is_restricted(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();
        $agent = User::query()->where('email', 'agent@grids.test')->firstOrFail();
        $ticket = SupportTicket::query()->where('user_id', $tenant->id)->firstOrFail();

        $this->actingAs($agent, 'sanctum')
            ->getJson('/api/v1/support/tickets/'.$ticket->id)
            ->assertForbidden();
    }

    public function test_user_can_close_and_rate_ticket(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();
        $ticket = SupportTicket::query()->where('user_id', $tenant->id)->firstOrFail();

        $this->actingAs($tenant, 'sanctum')
            ->postJson('/api/v1/support/tickets/'.$ticket->id.'/close')
            ->assertOk()
            ->assertJsonPath('data.status', 'closed');

        $this->actingAs($tenant, 'sanctum')
            ->postJson('/api/v1/support/tickets/'.$ticket->id.'/rate', [
                'rating' => 5,
                'comment' => 'Helpful and quick.',
            ])
            ->assertOk();
    }
}
