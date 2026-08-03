<?php

use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AutomationController;
use App\Http\Controllers\Api\ContractController;
use App\Http\Controllers\Api\MaintenanceRequestController;
use App\Http\Controllers\Api\OwnerController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\PropertyController;
use App\Http\Controllers\Api\RentalUnitController;
use App\Http\Controllers\Api\TenantController;
use App\Models\Contract;
use App\Models\MaintenanceRequest;
use App\Models\Owner;
use App\Models\Payment;
use App\Models\Property;
use App\Models\RentalUnit;
use App\Models\Tenant;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('/health', function () {
        return response()->json([
            'status' => 'ok',
            'service' => 'rental-api',
            'timestamp' => now()->toIso8601String(),
        ]);
    });

    // Auth (public)
    Route::post('/signup', [AuthController::class, 'signup']);
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::post('/logout', [AuthController::class, 'logout']);

        Route::get('/dashboard', function () {
            return response()->json([
                'data' => [
                    'owners' => Owner::count(),
                    'tenants' => Tenant::count(),
                    'properties' => Property::count(),
                    'rental_units' => RentalUnit::count(),
                    'available_units' => RentalUnit::where('status', 'available')->count(),
                    'occupied_units' => RentalUnit::where('status', 'occupied')->count(),
                    'active_contracts' => Contract::where('status', 'active')->count(),
                    'pending_payments' => Payment::where('status', 'pending')->count(),
                    'overdue_payments' => Payment::where('status', 'overdue')->count(),
                    'open_maintenance_requests' => MaintenanceRequest::whereIn('status', ['open', 'in_progress'])->count(),
                ],
            ]);
        });

        Route::post('/automation/run', [AutomationController::class, 'run']);

        Route::apiResource('owners', OwnerController::class);
        Route::apiResource('tenants', TenantController::class);
        Route::apiResource('properties', PropertyController::class);
        Route::apiResource('rental-units', RentalUnitController::class);
        Route::apiResource('contracts', ContractController::class);
        Route::apiResource('payments', PaymentController::class);
        Route::apiResource('maintenance-requests', MaintenanceRequestController::class);
    });
});
