<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    /**
     * Run the migrations.
     */
    public function up(): void
    {
        Schema::create('payments', function (Blueprint $table) {
            $table->id();
            $table->foreignId('contract_id')->constrained()->cascadeOnDelete();
            $table->string('reference')->nullable()->unique();
            $table->decimal('amount', 12, 2);
            $table->date('due_date');
            $table->date('paid_at')->nullable();
            $table->string('method')->nullable(); // cash, bank_transfer, card, check
            $table->string('status')->default('pending'); // pending, paid, overdue, cancelled, refunded
            $table->string('period')->nullable(); // e.g. 2026-07
            $table->text('notes')->nullable();
            $table->timestamps();
        });
    }

    /**
     * Reverse the migrations.
     */
    public function down(): void
    {
        Schema::dropIfExists('payments');
    }
};
