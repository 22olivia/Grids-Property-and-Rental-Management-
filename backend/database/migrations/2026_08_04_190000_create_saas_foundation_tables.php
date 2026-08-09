<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('organizations', function (Blueprint $table) {
            $table->id();
            $table->string('name');
            $table->string('slug')->unique();
            $table->string('legal_name')->nullable();
            $table->string('email')->nullable();
            $table->string('phone')->nullable();
            $table->string('country')->nullable();
            $table->string('city')->nullable();
            $table->string('address')->nullable();
            $table->string('plan', 50)->default('starter');
            $table->string('status', 30)->default('active');
            $table->decimal('maintenance_approval_limit', 12, 2)->default(1000);
            $table->foreignId('owner_user_id')->nullable()->constrained('users')->nullOnDelete();
            $table->json('settings')->nullable();
            $table->timestamps();
        });

        Schema::create('organization_user', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->constrained()->cascadeOnDelete();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->string('role', 40);
            $table->string('status', 30)->default('active');
            $table->json('permissions')->nullable();
            $table->timestamps();
            $table->unique(['organization_id', 'user_id']);
        });

        Schema::table('users', function (Blueprint $table) {
            $table->foreignId('organization_id')->nullable()->after('id')->constrained()->nullOnDelete();
            $table->string('verification_status', 30)->default('unverified')->after('status');
            $table->json('assigned_property_ids')->nullable()->after('address');
            $table->json('assigned_unit_ids')->nullable()->after('assigned_property_ids');
        });

        Schema::table('properties', function (Blueprint $table) {
            $table->foreignId('organization_id')->nullable()->after('id')->constrained()->nullOnDelete();
        });

        Schema::create('buildings', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('property_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->string('code')->nullable();
            $table->unsignedInteger('total_floors')->default(1);
            $table->string('status', 30)->default('active');
            $table->timestamps();
        });

        Schema::create('floors', function (Blueprint $table) {
            $table->id();
            $table->foreignId('building_id')->constrained()->cascadeOnDelete();
            $table->string('name');
            $table->integer('level')->default(0);
            $table->timestamps();
            $table->unique(['building_id', 'level']);
        });

        Schema::table('rental_units', function (Blueprint $table) {
            $table->foreignId('organization_id')->nullable()->after('id')->constrained()->nullOnDelete();
            $table->foreignId('building_id')->nullable()->after('property_id')->constrained()->nullOnDelete();
            $table->foreignId('floor_id')->nullable()->after('building_id')->constrained()->nullOnDelete();
            $table->string('unit_type', 50)->nullable()->after('unit_number');
            $table->decimal('area', 12, 2)->nullable()->after('square_feet');
            $table->string('furnishing_status', 40)->nullable()->after('area');
            $table->decimal('maintenance_charge', 12, 2)->default(0)->after('monthly_rent');
            $table->date('availability_date')->nullable()->after('deposit_amount');
            $table->unsignedTinyInteger('tenant_capacity')->default(2)->after('availability_date');
            $table->json('amenities')->nullable()->after('description');
            $table->json('inventory')->nullable();
            $table->json('meter_numbers')->nullable();
            $table->json('images')->nullable();
            $table->json('documents')->nullable();
            $table->foreignId('assigned_manager_id')->nullable()->constrained('users')->nullOnDelete();
            $table->boolean('is_listed')->default(false);
            $table->string('listing_title')->nullable();
            $table->text('listing_description')->nullable();
        });

        Schema::create('vendors', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('company_name');
            $table->string('contact_name')->nullable();
            $table->string('email')->nullable();
            $table->string('phone')->nullable();
            $table->json('categories')->nullable();
            $table->string('status', 30)->default('active');
            $table->timestamps();
        });

        Schema::table('maintenance_requests', function (Blueprint $table) {
            $table->foreignId('organization_id')->nullable()->after('id')->constrained()->nullOnDelete();
            $table->string('ticket_number')->nullable()->unique()->after('organization_id');
            $table->foreignId('property_id')->nullable()->after('rental_unit_id')->constrained()->nullOnDelete();
            $table->boolean('permission_to_enter')->default(false);
            $table->date('preferred_visit_date')->nullable();
            $table->foreignId('assigned_vendor_id')->nullable()->constrained('vendors')->nullOnDelete();
            $table->foreignId('assigned_technician_id')->nullable()->constrained('users')->nullOnDelete();
            $table->decimal('estimated_cost', 12, 2)->nullable();
            $table->decimal('approved_cost', 12, 2)->nullable();
            $table->decimal('actual_cost', 12, 2)->nullable();
            $table->dateTime('scheduled_date')->nullable();
            $table->json('media')->nullable();
            $table->json('before_after_images')->nullable();
            $table->json('quotation')->nullable();
            $table->json('ai_triage')->nullable();
            $table->string('workflow_status', 40)->default('submitted');
            $table->timestamp('sla_due_at')->nullable();
        });

        Schema::create('notification_templates', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->string('key')->unique();
            $table->string('name');
            $table->string('channel', 30)->default('in_app');
            $table->string('subject')->nullable();
            $table->text('body');
            $table->json('variables')->nullable();
            $table->boolean('is_active')->default(true);
            $table->timestamps();
        });

        Schema::create('notification_preferences', function (Blueprint $table) {
            $table->id();
            $table->foreignId('user_id')->constrained()->cascadeOnDelete();
            $table->boolean('in_app')->default(true);
            $table->boolean('email')->default(true);
            $table->boolean('sms')->default(false);
            $table->boolean('whatsapp')->default(false);
            $table->boolean('push')->default(true);
            $table->json('categories')->nullable();
            $table->timestamps();
            $table->unique('user_id');
        });

        Schema::create('ai_suggestions', function (Blueprint $table) {
            $table->id();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('user_id')->nullable()->constrained()->nullOnDelete();
            $table->string('module', 50);
            $table->string('suggestion_type', 80);
            $table->string('title');
            $table->text('summary');
            $table->json('payload')->nullable();
            $table->string('status', 30)->default('recommended');
            $table->nullableMorphs('subject');
            $table->timestamps();
        });
    }

    public function down(): void
    {
        Schema::dropIfExists('ai_suggestions');
        Schema::dropIfExists('notification_preferences');
        Schema::dropIfExists('notification_templates');

        Schema::table('maintenance_requests', function (Blueprint $table) {
            $table->dropConstrainedForeignId('organization_id');
            $table->dropColumn([
                'ticket_number', 'permission_to_enter', 'preferred_visit_date',
                'estimated_cost', 'approved_cost', 'actual_cost', 'scheduled_date',
                'media', 'before_after_images', 'quotation', 'ai_triage',
                'workflow_status', 'sla_due_at',
            ]);
            $table->dropConstrainedForeignId('property_id');
            $table->dropConstrainedForeignId('assigned_vendor_id');
            $table->dropConstrainedForeignId('assigned_technician_id');
        });

        Schema::dropIfExists('vendors');

        Schema::table('rental_units', function (Blueprint $table) {
            $table->dropConstrainedForeignId('organization_id');
            $table->dropConstrainedForeignId('building_id');
            $table->dropConstrainedForeignId('floor_id');
            $table->dropConstrainedForeignId('assigned_manager_id');
            $table->dropColumn([
                'unit_type', 'area', 'furnishing_status', 'maintenance_charge',
                'availability_date', 'tenant_capacity', 'amenities', 'inventory',
                'meter_numbers', 'images', 'documents', 'is_listed',
                'listing_title', 'listing_description',
            ]);
        });

        Schema::dropIfExists('floors');
        Schema::dropIfExists('buildings');

        Schema::table('properties', function (Blueprint $table) {
            $table->dropConstrainedForeignId('organization_id');
        });

        Schema::table('users', function (Blueprint $table) {
            $table->dropConstrainedForeignId('organization_id');
            $table->dropColumn(['verification_status', 'assigned_property_ids', 'assigned_unit_ids']);
        });

        Schema::dropIfExists('organization_user');
        Schema::dropIfExists('organizations');
    }
};
