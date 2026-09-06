<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('contracts', function (Blueprint $table) {
            $table->unsignedTinyInteger('grace_period_days')->default(3)->after('payment_day');
            $table->decimal('late_fee_amount', 12, 2)->default(0)->after('grace_period_days');
            $table->string('payment_frequency', 30)->default('monthly')->after('late_fee_amount');
            $table->string('agreement_path')->nullable()->after('terms');
            $table->date('move_in_date')->nullable()->after('agreement_path');
            $table->date('move_out_date')->nullable()->after('move_in_date');
            $table->foreignId('created_by')->nullable()->after('move_out_date')->constrained('users')->nullOnDelete();
            $table->text('notes')->nullable()->after('created_by');
        });
    }

    public function down(): void
    {
        Schema::table('contracts', function (Blueprint $table) {
            $table->dropConstrainedForeignId('created_by');
            $table->dropColumn([
                'grace_period_days',
                'late_fee_amount',
                'payment_frequency',
                'agreement_path',
                'move_in_date',
                'move_out_date',
                'notes',
            ]);
        });
    }
};
