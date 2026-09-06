<?php

namespace Tests\Feature;

use App\Models\AppNotification;
use App\Models\NotificationTemplate;
use App\Models\User;
use App\Services\NotificationService;
use Database\Seeders\DemoRentalSeeder;
use Illuminate\Foundation\Testing\RefreshDatabase;
use Tests\TestCase;

class NotificationCentreApiTest extends TestCase
{
    use RefreshDatabase;

    public function test_role_users_receive_seeded_notifications_and_can_manage_centre(): void
    {
        $this->seed(DemoRentalSeeder::class);

        $manager = User::query()->where('email', 'manager@grids.test')->firstOrFail();

        $list = $this->actingAs($manager, 'sanctum')
            ->getJson('/api/v1/notifications')
            ->assertOk()
            ->assertJsonStructure(['data', 'unread_count', 'meta']);

        $this->assertGreaterThan(0, $list->json('unread_count'));
        $this->assertNotEmpty($list->json('data'));

        $id = $list->json('data.0.id');

        $this->actingAs($manager, 'sanctum')
            ->postJson("/api/v1/notifications/{$id}/read")
            ->assertOk();

        $this->actingAs($manager, 'sanctum')
            ->getJson('/api/v1/notifications/unread-count')
            ->assertOk()
            ->assertJsonPath('unread_count', fn ($v) => $v < $list->json('unread_count'));

        $this->actingAs($manager, 'sanctum')
            ->postJson('/api/v1/notifications/read-all')
            ->assertOk()
            ->assertJsonPath('unread_count', 0);

        $this->actingAs($manager, 'sanctum')
            ->putJson('/api/v1/notification-preferences', [
                'email' => true,
                'sms' => false,
                'digest_frequency' => 'daily',
                'preferred_language' => 'en',
                'quiet_hours_start' => '22:00',
                'quiet_hours_end' => '07:00',
                'categories' => [
                    'maintenance' => true,
                    'rent_payment' => true,
                ],
            ])
            ->assertOk()
            ->assertJsonPath('data.emergency_override', true)
            ->assertJsonPath('data.digest_frequency', 'daily');
    }

    public function test_notification_service_dedupes_and_delivers_channels(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();
        $service = app(NotificationService::class);

        $first = $service->notify($tenant, 'rent.due', [
            'dedupe_key' => 'test-dedupe-rent-due',
            'title' => 'Rent due',
            'message' => 'Pay now',
            'action_url' => '/payments',
            'variables' => ['amount' => 'AED 100', 'unit_number' => 'A-101', 'due_date' => '2026-08-10'],
        ]);
        $second = $service->notify($tenant, 'rent.due', [
            'dedupe_key' => 'test-dedupe-rent-due',
            'title' => 'Rent due again',
            'message' => 'Should not create',
        ]);

        $this->assertNotNull($first);
        $this->assertSame($first->id, $second?->id);
        $this->assertTrue($first->deliveries()->where('status', 'sent')->exists());
    }

    public function test_super_admin_can_manage_templates_and_channels(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $admin = User::query()->where('email', 'admin@rental.test')->firstOrFail();

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/notifications/catalog')
            ->assertOk()
            ->assertJsonStructure(['data' => ['categories', 'channels', 'priorities', 'events_by_role']]);

        $this->actingAs($admin, 'sanctum')
            ->postJson('/api/v1/notification-templates', [
                'key' => 'system.custom_alert',
                'name' => 'Custom alert',
                'category' => 'system',
                'channel' => 'email',
                'priority' => 'high',
                'body' => 'Hello {{user_name}} — {{action_link}}',
                'variables' => ['user_name', 'action_link'],
            ])
            ->assertCreated();

        $this->assertDatabaseHas('notification_templates', ['key' => 'system.custom_alert']);

        $this->actingAs($admin, 'sanctum')
            ->putJson('/api/v1/notification-channels', [
                'channel' => 'whatsapp',
                'enabled' => true,
                'provider' => 'twilio',
            ])
            ->assertOk();

        $this->actingAs($admin, 'sanctum')
            ->getJson('/api/v1/notification-delivery-logs')
            ->assertOk()
            ->assertJsonStructure(['data', 'meta']);
    }

    public function test_owner_can_customize_org_template_without_changing_global(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $owner = User::query()->where('email', 'owner@grids.test')->firstOrFail();
        $global = NotificationTemplate::query()->whereNull('organization_id')->where('key', 'lease.expiring')->firstOrFail();

        $this->actingAs($owner, 'sanctum')
            ->putJson('/api/v1/notification-templates/'.$global->id, [
                'body' => 'Org custom: lease for {{unit_number}} at {{property_name}} expires soon.',
            ])
            ->assertOk();

        $this->assertSame(
            'Lease for {{unit_number}} at {{property_name}} expires on {{due_date}}.',
            $global->fresh()->body
        );
        $this->assertDatabaseHas('notification_templates', [
            'organization_id' => $owner->organization_id,
            'key' => 'lease.expiring',
        ]);
    }

    public function test_tenant_cannot_access_delivery_logs(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();

        $this->actingAs($tenant, 'sanctum')
            ->getJson('/api/v1/notification-delivery-logs')
            ->assertForbidden();
    }

    public function test_filters_and_archive_work(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $manager = User::query()->where('email', 'manager@grids.test')->firstOrFail();
        $row = AppNotification::query()->where('recipient_user_id', $manager->id)->firstOrFail();

        $this->actingAs($manager, 'sanctum')
            ->getJson('/api/v1/notifications?category=maintenance&priority=critical&status=unread')
            ->assertOk();

        $this->actingAs($manager, 'sanctum')
            ->postJson("/api/v1/notifications/{$row->id}/archive")
            ->assertOk();

        $this->assertNotNull($row->fresh()->archived_at);
    }

    public function test_notify_delivers_email_and_whatsapp_channels(): void
    {
        $this->seed(DemoRentalSeeder::class);
        $tenant = User::query()->where('email', 'tenant@grids.test')->firstOrFail();

        /** @var NotificationService $service */
        $service = app(NotificationService::class);
        $notification = $service->notify($tenant, 'maintenance.created', [
            'title' => 'Maintenance request received',
            'message' => 'Ticket MT-TEST: Kitchen sink leak',
            'action_url' => '/maintenance',
            'channels' => ['in_app', 'email', 'whatsapp'],
            'dedupe_key' => 'test-email-whatsapp-'.uniqid(),
        ]);

        $this->assertNotNull($notification);
        $statuses = $notification->fresh()->deliveries()->pluck('status', 'channel');
        $this->assertSame('sent', $statuses['in_app'] ?? null);
        $this->assertSame('sent', $statuses['email'] ?? null);
        $this->assertSame('sent', $statuses['whatsapp'] ?? null);

        $whatsapp = $notification->deliveries()->where('channel', 'whatsapp')->first();
        $this->assertTrue((bool) data_get($whatsapp?->provider_response, 'simulated'));
        $this->assertDatabaseHas('email_logs', [
            'user_id' => $tenant->id,
            'template_key' => 'notification_centre',
            'status' => 'sent',
        ]);
    }
}
