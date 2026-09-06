<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('payment_orders', function (Blueprint $table) {
            $table->id();
            $table->string('order_number')->unique();
            $table->foreignId('tenant_id')->constrained()->cascadeOnDelete();
            $table->foreignId('contract_id')->nullable()->constrained()->nullOnDelete();
            $table->foreignId('organization_id')->nullable()->constrained()->nullOnDelete();
            $table->json('invoice_ids');
            $table->decimal('amount', 12, 2);
            $table->string('currency', 3)->default('AED');
            $table->string('method', 40);
            $table->unsignedTinyInteger('emi_months')->nullable();
            $table->string('status', 30)->default('pending');
            // pending | awaiting_payment | paid | failed | expired | cancelled | refunded
            $table->string('gateway', 40)->default('demo');
            $table->string('gateway_order_id')->nullable()->index();
            $table->string('gateway_txn_id')->nullable()->unique();
            $table->string('checkout_token')->nullable();
            $table->json('checkout_payload')->nullable();
            $table->string('idempotency_key')->nullable()->unique();
            $table->foreignId('payment_id')->nullable()->constrained()->nullOnDelete();
            $table->string('failure_reason')->nullable();
            $table->timestamp('expires_at')->nullable();
            $table->timestamp('paid_at')->nullable();
            $table->json('meta')->nullable();
            $table->timestamps();

            $table->index(['tenant_id', 'status']);
        });

        Schema::create('payment_webhook_events', function (Blueprint $table) {
            $table->id();
            $table->string('provider', 40);
            $table->string('event_id')->nullable();
            $table->string('order_number')->nullable()->index();
            $table->string('gateway_txn_id')->nullable()->index();
            $table->string('status', 30)->default('received');
            // received | processed | ignored | failed
            $table->boolean('signature_valid')->default(false);
            $table->json('payload')->nullable();
            $table->text('raw_body')->nullable();
            $table->text('processing_error')->nullable();
            $table->timestamp('processed_at')->nullable();
            $table->timestamps();

            $table->unique(['provider', 'event_id']);
        });

        Schema::table('payments', function (Blueprint $table) {
            if (! Schema::hasColumn('payments', 'payment_order_id')) {
                $table->foreignId('payment_order_id')->nullable()->after('invoice_id')->constrained('payment_orders')->nullOnDelete();
            }
            if (! Schema::hasColumn('payments', 'gateway')) {
                $table->string('gateway', 40)->nullable()->after('method');
            }
            if (! Schema::hasColumn('payments', 'gateway_txn_id')) {
                $table->string('gateway_txn_id')->nullable()->unique()->after('gateway');
            }
            if (! Schema::hasColumn('payments', 'currency')) {
                $table->string('currency', 3)->default('AED')->after('amount');
            }
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            if (Schema::hasColumn('payments', 'payment_order_id')) {
                $table->dropConstrainedForeignId('payment_order_id');
            }
            foreach (['gateway', 'gateway_txn_id', 'currency'] as $col) {
                if (Schema::hasColumn('payments', $col)) {
                    $table->dropColumn($col);
                }
            }
        });

        Schema::dropIfExists('payment_webhook_events');
        Schema::dropIfExists('payment_orders');
    }
};
