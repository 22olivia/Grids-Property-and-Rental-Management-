<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('support_categories', function (Blueprint $table) {
            $table->id();
            $table->string('key')->unique();
            $table->string('name');
            $table->string('route_to', 40)->default('manager'); // owner|manager|platform|owner_or_manager
            $table->text('description')->nullable();
            $table->boolean('is_active')->default(true);
            $table->unsignedSmallInteger('sort_order')->default(0);
            $table->timestamps();
        });

        Schema::create('support_tickets', function (Blueprint $table) {
            $table->uuid('id')->primary();
            $table->string('ticket_number')->unique();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->foreignId('assigned_to')->nullable()->constrained('users')->nullOnDelete();
            $table->foreignId('property_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('rental_unit_id')->nullable()->constrained('rental_units')->nullOnDelete();
            $table->string('contact_type', 40)->default('platform'); // owner|manager|platform|problem|feedback
            $table->string('category', 60);
            $table->string('priority', 20)->default('normal'); // low|normal|high|urgent
            $table->string('status', 30)->default('open'); // open|assigned|in_progress|waiting_for_user|resolved|closed
            $table->string('subject');
            $table->text('message');
            $table->string('name');
            $table->string('email');
            $table->string('phone')->nullable();
            $table->string('preferred_contact_method', 20)->default('email'); // email|phone
            $table->timestamp('assigned_at')->nullable();
            $table->timestamp('resolved_at')->nullable();
            $table->timestamp('closed_at')->nullable();
            $table->timestamp('last_reply_at')->nullable();
            $table->timestamps();

            $table->index(['user_id', 'status']);
            $table->index(['organization_id', 'category']);
            $table->index(['assigned_to', 'status']);
        });

        Schema::create('support_messages', function (Blueprint $table) {
            $table->id();
            $table->uuid('support_ticket_id');
            $table->foreign('support_ticket_id')->references('id')->on('support_tickets')->cascadeOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('sender_type', 20)->default('user'); // user|staff|system
            $table->text('body');
            $table->boolean('is_internal')->default(false);
            $table->timestamps();

            $table->index(['support_ticket_id', 'created_at']);
        });

        Schema::create('support_attachments', function (Blueprint $table) {
            $table->id();
            $table->uuid('support_ticket_id');
            $table->foreign('support_ticket_id')->references('id')->on('support_tickets')->cascadeOnDelete();
            $table->foreignId('support_message_id')->nullable()->constrained('support_messages')->nullOnDelete();
            $table->foreignId('uploaded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('original_name');
            $table->string('path');
            $table->string('mime_type', 120)->nullable();
            $table->unsignedBigInteger('size')->default(0);
            $table->string('scan_status', 30)->default('clean'); // pending|clean|rejected
            $table->timestamps();
        });

        Schema::create('support_ratings', function (Blueprint $table) {
            $table->id();
            $table->uuid('support_ticket_id');
            $table->foreign('support_ticket_id')->references('id')->on('support_tickets')->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->unsignedTinyInteger('rating'); // 1-5
            $table->text('comment')->nullable();
            $table->timestamps();
            $table->unique(['support_ticket_id', 'user_id']);
        });

        Schema::create('email_logs', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->nullableUuidMorphs('related');
            $table->string('template_key', 80);
            $table->string('to_email');
            $table->string('to_name')->nullable();
            $table->string('subject');
            $table->json('payload')->nullable();
            $table->string('provider', 40)->default('log'); // resend|brevo|smtp|log|array
            $table->string('provider_message_id')->nullable();
            $table->string('status', 30)->default('queued'); // queued|sent|failed|retrying
            $table->unsignedTinyInteger('attempts')->default(0);
            $table->timestamp('next_retry_at')->nullable();
            $table->text('error_message')->nullable();
            $table->json('provider_response')->nullable();
            $table->timestamp('sent_at')->nullable();
            $table->timestamps();

            $table->index(['status', 'next_retry_at']);
            $table->index(['template_key', 'created_at']);
        });

        Schema::create('email_otps', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->nullable()->constrained()->cascadeOnDelete();
            $table->string('email');
            $table->string('purpose', 40); // email_verify|phone_verify|login|password_reset|support
            $table->string('code_hash');
            $table->timestamp('expires_at');
            $table->timestamp('consumed_at')->nullable();
            $table->unsignedTinyInteger('attempts')->default(0);
            $table->string('ip_address', 45)->nullable();
            $table->timestamps();

            $table->index(['email', 'purpose', 'expires_at']);
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('email_otps');
        Schema::dropIfExists('email_logs');
        Schema::dropIfExists('support_ratings');
        Schema::dropIfExists('support_attachments');
        Schema::dropIfExists('support_messages');
        Schema::dropIfExists('support_tickets');
        Schema::dropIfExists('support_categories');
    }
};
