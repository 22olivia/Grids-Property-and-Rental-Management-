<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'notify_email')) {
                $table->string('notify_email')->nullable()->after('email');
            }
            if (! Schema::hasColumn('users', 'whatsapp_phone')) {
                $table->string('whatsapp_phone', 32)->nullable()->after('phone');
            }
        });
    }

    public function down(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (Schema::hasColumn('users', 'whatsapp_phone')) {
                $table->dropColumn('whatsapp_phone');
            }
            if (Schema::hasColumn('users', 'notify_email')) {
                $table->dropColumn('notify_email');
            }
        });
    }
};
