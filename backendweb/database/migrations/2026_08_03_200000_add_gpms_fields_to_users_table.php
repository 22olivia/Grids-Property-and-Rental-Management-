<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (! Schema::hasColumn('users', 'photo_path')) {
                $table->string('photo_path')->nullable()->after('phone');
            }
            if (! Schema::hasColumn('users', 'address')) {
                $table->text('address')->nullable()->after('photo_path');
            }
            if (! Schema::hasColumn('users', 'status')) {
                $table->string('status', 30)->default('active')->after('address');
            }
            if (! Schema::hasColumn('users', 'last_login_at')) {
                $table->timestamp('last_login_at')->nullable()->after('status');
            }
        });

        DB::table('users')->where('role', 'admin')->update(['role' => 'super_admin']);
        DB::table('users')->where('role', 'staff')->update(['role' => 'manager']);
    }

    public function down(): void
    {
        DB::table('users')->where('role', 'super_admin')->update(['role' => 'admin']);
        DB::table('users')->where('role', 'manager')->update(['role' => 'staff']);

        Schema::table('users', function (Blueprint $table) {
            $table->dropColumn(['photo_path', 'address', 'status', 'last_login_at']);
        });
    }
};
