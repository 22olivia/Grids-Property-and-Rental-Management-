<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('tenants', function (Blueprint $table) {
            if (! Schema::hasColumn('tenants', 'alternate_phone')) {
                $table->string('alternate_phone')->nullable()->after('phone');
            }
            if (! Schema::hasColumn('tenants', 'occupation')) {
                $table->string('occupation')->nullable();
            }
            if (! Schema::hasColumn('tenants', 'employer')) {
                $table->string('employer')->nullable();
            }
            if (! Schema::hasColumn('tenants', 'communication_address')) {
                $table->text('communication_address')->nullable();
            }
            if (! Schema::hasColumn('tenants', 'preferred_language')) {
                $table->string('preferred_language', 10)->default('en');
            }
            if (! Schema::hasColumn('tenants', 'profile_completion')) {
                $table->unsignedTinyInteger('profile_completion')->default(0);
            }
            if (! Schema::hasColumn('tenants', 'identity_type')) {
                $table->string('identity_type')->nullable();
            }
            if (! Schema::hasColumn('tenants', 'identity_number_encrypted')) {
                $table->text('identity_number_encrypted')->nullable();
            }
            if (! Schema::hasColumn('tenants', 'identity_verification_status')) {
                $table->string('identity_verification_status', 30)->default('unverified');
            }
            if (! Schema::hasColumn('tenants', 'identity_expiry_date')) {
                $table->date('identity_expiry_date')->nullable();
            }
            if (! Schema::hasColumn('tenants', 'settings')) {
                $table->json('settings')->nullable();
            }
        });

        Schema::create('tenant_documents', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('uploaded_by')->nullable()->constrained('users')->nullOnDelete();
            $table->string('title');
            $table->string('category', 80);
            $table->string('disk')->default('private');
            $table->string('path');
            $table->string('file_type', 40)->nullable();
            $table->unsignedBigInteger('file_size')->default(0);
            $table->string('verification_status', 30)->default('pending');
            $table->date('expiry_date')->nullable();
            $table->boolean('tenant_owned')->default(false);
            $table->unsignedInteger('version')->default(1);
            $table->timestamps();
            $table->index(['tenant_id', 'category']);
        });

        Schema::create('receipts', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('payment_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('invoice_id')->nullable()->constrained()->nullOnDelete();
            $table->string('receipt_number')->unique();
            $table->date('payment_date');
            $table->string('tenant_name');
            $table->string('property_name')->nullable();
            $table->string('unit_number')->nullable();
            $table->string('billing_period', 20)->nullable();
            $table->decimal('amount_paid', 12, 2);
            $table->string('payment_method', 40)->nullable();
            $table->string('transaction_reference')->nullable();
            $table->string('invoice_number')->nullable();
            $table->timestamps();
        });

        Schema::create('payment_allocations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('payment_id')->constrained()->cascadeOnDelete();
            $table->foreignId('invoice_id')->constrained()->cascadeOnDelete();
            $table->decimal('amount', 12, 2);
            $table->timestamps();
        });

        Schema::create('lease_amendments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('contract_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->text('summary')->nullable();
            $table->date('effective_date')->nullable();
            $table->string('status', 30)->default('active');
            $table->timestamps();
        });

        Schema::create('conversations', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('subject');
            $table->string('participant_type', 40); // manager|support|vendor
            $table->foreignId('participant_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('related_type')->nullable();
            $table->string('related_label')->nullable();
            $table->unsignedInteger('tenant_unread_count')->default(0);
            $table->timestamp('last_message_at')->nullable();
            $table->timestamps();
        });

        Schema::create('messages', function (Blueprint $table) {
            $table->id();
            $table->foreignId('conversation_id')->constrained()->cascadeOnDelete();
            $table->foreignId('sender_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->string('sender_role', 40)->default('tenant');
            $table->text('body');
            $table->string('attachment_path')->nullable();
            $table->timestamp('read_at')->nullable();
            $table->timestamps();
        });

        Schema::create('support_requests', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('subject');
            $table->text('body');
            $table->string('status', 30)->default('open');
            $table->timestamps();
        });

        Schema::create('tenant_calendar_events', function (Blueprint $table) {
            $table->id();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->string('title');
            $table->string('type', 40);
            $table->date('event_date');
            $table->boolean('all_day')->default(true);
            $table->string('start_time', 10)->nullable();
            $table->string('end_time', 10)->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('tenant_calendar_events');
        Schema::dropIfExists('support_requests');
        Schema::dropIfExists('messages');
        Schema::dropIfExists('conversations');
        Schema::dropIfExists('lease_amendments');
        Schema::dropIfExists('payment_allocations');
        Schema::dropIfExists('receipts');
        Schema::dropIfExists('tenant_documents');
    }
};
