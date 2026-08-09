<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::create('invoices', function (Blueprint $table) {
            $table->id();
            $table->foreignId('contract_id')->constrained()->cascadeOnDelete();
            $table->string('invoice_number')->unique();
            $table->string('billing_month', 7);
            $table->decimal('rent_amount', 12, 2);
            $table->decimal('additional_charges', 12, 2)->default(0);
            $table->decimal('discounts', 12, 2)->default(0);
            $table->decimal('late_fee', 12, 2)->default(0);
            $table->decimal('previous_balance', 12, 2)->default(0);
            $table->decimal('total_amount', 12, 2);
            $table->decimal('paid_amount', 12, 2)->default(0);
            $table->decimal('remaining_balance', 12, 2);
            $table->date('due_date');
            $table->string('status', 30)->default('unpaid');
            $table->text('notes')->nullable();
            $table->timestamps();

            $table->index(['contract_id', 'billing_month']);
            $table->index('status');
        });

        Schema::table('payments', function (Blueprint $table) {
            $table->foreignId('invoice_id')->nullable()->after('contract_id')->constrained()->nullOnDelete();
            $table->string('transaction_number')->nullable()->unique()->after('reference');
            $table->string('proof_path')->nullable()->after('notes');
            $table->string('approval_status', 30)->nullable()->after('proof_path');
            $table->text('refund_reason')->nullable()->after('approval_status');
            $table->decimal('refunded_amount', 12, 2)->default(0)->after('refund_reason');
        });
    }

    public function down(): void
    {
        Schema::table('payments', function (Blueprint $table) {
            $table->dropConstrainedForeignId('invoice_id');
            $table->dropColumn([
                'transaction_number',
                'proof_path',
                'approval_status',
                'refund_reason',
                'refunded_amount',
            ]);
        });

        Schema::dropIfExists('invoices');
    }
};
