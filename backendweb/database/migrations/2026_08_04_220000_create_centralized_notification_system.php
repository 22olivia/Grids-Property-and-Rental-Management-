<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('app_notifications', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('recipient_user_id')->constrained('users')->cascadeOnDelete();
            $table->string('recipient_role', 40);
            $table->string('category', 60);
            $table->string('title');
            $table->text('message');
            $table->string('priority', 20)->default('normal'); // critical|high|normal|low
            $table->string('module', 60)->nullable();
            $table->string('record_type')->nullable();
            $table->string('record_id')->nullable();
            $table->string('action_url')->nullable();
            $table->string('action_label')->nullable();
            $table->string('template_key')->nullable();
            $table->string('dedupe_key')->nullable();
            $table->json('channels')->nullable(); // requested channels
            $table->json('payload')->nullable();
            $table->string('group_key')->nullable();
            $table->timestamp('scheduled_at')->nullable();
            $table->timestamp('sent_at')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamp('archived_at')->nullable();
            $table->string('delivery_status', 30)->default('pending'); // pending|queued|sent|partial|failed|cancelled
            $table->boolean('is_emergency')->default(false);
            $table->timestamps();

            $table->index(['recipient_user_id', 'read_at']);
            $table->index(['organization_id', 'category']);
            $table->index(['priority', 'created_at']);
            $table->index(['group_key']);
            $table->unique(['dedupe_key']);
        });

        Schema::create('notification_deliveries', function (Blueprint $table) {
            $table->id();
            $table->uuid('app_notification_id');
            $table->foreign('app_notification_id')->references('id')->on('app_notifications')->cascadeOnDelete();
            $table->string('channel', 30); // in_app|email|sms|whatsapp|push
            $table->string('status', 30)->default('pending'); // pending|sent|failed|retrying|skipped
            $table->unsignedTinyInteger('attempts')->default(0);
            $table->timestamp('next_retry_at')->nullable();
            $table->string('provider')->nullable();
            $table->string('provider_message_id')->nullable();
            $table->json('provider_response')->nullable();
            $table->text('error_message')->nullable();
            $table->timestamp('sent_at')->nullable();
            $table->timestamps();

            $table->index(['app_notification_id', 'channel']);
            $table->index(['status', 'next_retry_at']);
        });

        Schema::create('notification_channel_settings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->string('channel', 30);
            $table->boolean('enabled')->default(true);
            $table->string('provider')->nullable();
            $table->json('config')->nullable();
            $table->timestamps();
            $table->unique(['organization_id', 'channel']);
        });

        Schema::table('notification_preferences', function (Blueprint $table) {
            $table->string('preferred_language', 10)->default('en')->after('categories');
            $table->string('digest_frequency', 20)->default('none')->after('preferred_language'); // none|daily|weekly
            $table->time('quiet_hours_start')->nullable()->after('digest_frequency');
            $table->time('quiet_hours_end')->nullable()->after('quiet_hours_start');
            $table->boolean('emergency_override')->default(true)->after('quiet_hours_end');
            $table->json('channel_by_category')->nullable()->after('emergency_override');
        });

        Schema::table('notification_templates', function (Blueprint $table) {
            $table->dropUnique(['key']);
            $table->unique(['organization_id', 'key']);
            $table->string('category', 60)->nullable()->after('name');
            $table->json('roles')->nullable()->after('category');
            $table->json('channels')->nullable()->after('channel');
            $table->string('priority', 20)->default('normal')->after('channels');
            $table->boolean('is_emergency')->default(false)->after('priority');
        });
    }

    public function down(): void
    {
        Schema::table('notification_templates', function (Blueprint $table) {
            $table->dropUnique(['organization_id', 'key']);
            $table->unique(['key']);
            $table->dropColumn(['category', 'roles', 'channels', 'priority', 'is_emergency']);
        });

        Schema::table('notification_preferences', function (Blueprint $table) {
            $table->dropColumn([
                'preferred_language',
                'digest_frequency',
                'quiet_hours_start',
                'quiet_hours_end',
                'emergency_override',
                'channel_by_category',
            ]);
        });

        Schema::dropIfExists('notification_channel_settings');
        Schema::dropIfExists('notification_deliveries');
        Schema::dropIfExists('app_notifications');
    }
};
