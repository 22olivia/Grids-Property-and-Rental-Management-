<?php

use App\Http\Controllers\Api\AiAssistantController;
use App\Http\Controllers\Api\AuthController;
use App\Http\Controllers\Api\AutomationController;
use App\Http\Controllers\Api\BuildingController;
use App\Http\Controllers\Api\ContractController;
use App\Http\Controllers\Api\DashboardController;
use App\Http\Controllers\Api\InvoiceController;
use App\Http\Controllers\Api\LeaseController;
use App\Http\Controllers\Api\MaintenanceRequestController;
use App\Http\Controllers\Api\NotificationCentreController;
use App\Http\Controllers\Api\OrganizationController;
use App\Http\Controllers\Api\OwnerController;
use App\Http\Controllers\Api\PaymentController;
use App\Http\Controllers\Api\PropertyController;
use App\Http\Controllers\Api\RentalUnitController;
use App\Http\Controllers\Api\SearchController;
use App\Http\Controllers\Api\SupportController;
use App\Http\Controllers\Api\TenantController;
use App\Http\Controllers\Api\TenantPortalController;
use App\Http\Controllers\Api\UserController;
use App\Http\Controllers\Api\VendorController;
use App\Models\RentalUnit;
use App\Support\Roles;
use Illuminate\Support\Facades\Route;

Route::prefix('v1')->group(function () {
    Route::get('/health', function () {
        return response()->json([
            'status' => 'ok',
            'service' => 'grids-gpms-api',
            'product' => 'Grids Property Management System – GPMS',
            'timestamp' => now()->toIso8601String(),
        ]);
    });

    Route::post('/signup', [AuthController::class, 'signup']);
    Route::post('/register', [AuthController::class, 'register']);
    Route::post('/login', [AuthController::class, 'login']);
    Route::post('/forgot-password', [AuthController::class, 'forgotPassword']);
    Route::post('/reset-password', [AuthController::class, 'resetPassword']);

    // Payment provider webhooks (signature-verified — no Sanctum)
    Route::post('/payments/webhook', [TenantPortalController::class, 'paymentWebhook'])
        ->middleware('throttle:60,1');
    Route::post('/payments/webhook/{provider}', [TenantPortalController::class, 'paymentWebhook'])
        ->middleware('throttle:60,1');

    Route::get('/listings', function () {
        $units = RentalUnit::query()
            ->where(function ($q) {
                $q->where('is_listed', true)
                    ->orWhereIn('status', ['available', 'vacant']);
            })
            ->with('property')
            ->orderBy('monthly_rent')
            ->get()
            ->map(fn (RentalUnit $unit) => [
                'id' => $unit->id,
                'unit_number' => $unit->unit_number,
                'bedrooms' => $unit->bedrooms,
                'bathrooms' => $unit->bathrooms,
                'square_feet' => $unit->square_feet,
                'monthly_rent' => $unit->monthly_rent,
                'deposit_amount' => $unit->deposit_amount,
                'description' => $unit->listing_description ?: $unit->description,
                'listing_title' => $unit->listing_title,
                'property' => $unit->property ? [
                    'id' => $unit->property->id,
                    'name' => $unit->property->name,
                    'type' => $unit->property->type,
                    'city' => $unit->property->city,
                    'address_line1' => $unit->property->address_line1,
                    'country' => $unit->property->country,
                ] : null,
            ]);

        return response()->json([
            'message' => 'Available rental listings.',
            'data' => $units,
        ]);
    });

    // Public map markers for the marketing home page (no auth).
    Route::get('/public/properties', [PropertyController::class, 'mapIndex']);
    Route::get('/map/properties', [PropertyController::class, 'mapIndex']);

    Route::middleware('auth:sanctum')->group(function () {
        Route::get('/me', [AuthController::class, 'me']);
        Route::put('/profile', [AuthController::class, 'updateProfile']);
        Route::post('/profile/photo', [AuthController::class, 'uploadPhoto']);
        Route::delete('/profile/photo', [AuthController::class, 'deletePhoto']);
        Route::post('/change-password', [AuthController::class, 'changePassword']);
        Route::post('/verify-email', [AuthController::class, 'verifyEmail']);
        Route::get('/login-history', [AuthController::class, 'loginHistory']);
        Route::post('/logout', [AuthController::class, 'logout']);

        Route::get('/dashboard', DashboardController::class);

        // Help & Support
        Route::get('/support/meta', [SupportController::class, 'meta']);
        Route::get('/support/tickets', [SupportController::class, 'index']);
        Route::post('/support/tickets', [SupportController::class, 'store'])->middleware('throttle:10,1');
        Route::get('/support/tickets/{id}', [SupportController::class, 'show']);
        Route::post('/support/tickets/{id}/reply', [SupportController::class, 'reply'])->middleware('throttle:30,1');
        Route::post('/support/tickets/{id}/close', [SupportController::class, 'close']);
        Route::post('/support/tickets/{id}/resolve', [SupportController::class, 'resolve']);
        Route::post('/support/tickets/{id}/rate', [SupportController::class, 'rate']);

        // Notification centre (centralized, role-aware)
        Route::get('/notifications/catalog', [NotificationCentreController::class, 'catalog']);
        Route::get('/notifications/unread-count', [NotificationCentreController::class, 'unreadCount']);
        Route::get('/notifications', [NotificationCentreController::class, 'index']);
        Route::post('/notifications/read-all', [NotificationCentreController::class, 'markAllRead']);
        Route::post('/notifications/{id}/read', [NotificationCentreController::class, 'markRead']);
        Route::post('/notifications/{id}/archive', [NotificationCentreController::class, 'archive']);
        Route::delete('/notifications/{id}', [NotificationCentreController::class, 'destroy']);
        Route::get('/notification-preferences', [NotificationCentreController::class, 'preferences']);
        Route::put('/notification-preferences', [NotificationCentreController::class, 'updatePreferences']);
        Route::get('/notification-templates', [NotificationCentreController::class, 'templates']);
        Route::get('/notification-channels', [NotificationCentreController::class, 'channels']);
        Route::get('/notification-delivery-logs', [NotificationCentreController::class, 'deliveryLogs']);
        Route::get('/notification-settings', [NotificationCentreController::class, 'globalSettings']);

        // AI recommendations (never auto-approve / mutate money or leases)
        Route::get('/ai/suggestions', [AiAssistantController::class, 'index']);
        Route::get('/ai/dashboard-suggestions', [AiAssistantController::class, 'dashboardSuggestions']);
        Route::get('/ai/unit-insights', [AiAssistantController::class, 'unitInsights']);
        Route::post('/ai/maintenance-triage', [AiAssistantController::class, 'triage']);
        Route::post('/ai/units/{unit}/listing', [AiAssistantController::class, 'listing']);
        Route::post('/ai/tenant-assist', [AiAssistantController::class, 'tenantAssist']);

        // Tenant portal (scoped to authenticated tenant)
        Route::get('/search', [TenantPortalController::class, 'search']);
        Route::get('/tenant/lease', [TenantPortalController::class, 'lease']);
        Route::post('/tenant/lease/sign', [TenantPortalController::class, 'signLease']);
        Route::post('/tenant/lease/renewal-request', [TenantPortalController::class, 'requestRenewal']);
        Route::post('/tenant/lease/notice', [TenantPortalController::class, 'submitNotice']);
        Route::get('/tenant/receipts', [TenantPortalController::class, 'receipts']);
        Route::get('/tenant/documents', [TenantPortalController::class, 'documents']);
        Route::post('/tenant/documents', [TenantPortalController::class, 'uploadDocument']);
        Route::delete('/tenant/documents/{document}', [TenantPortalController::class, 'deleteDocument']);
        Route::get('/tenant/documents/{document}/download', [TenantPortalController::class, 'downloadDocument']);
        Route::get('/tenant/calendar', [TenantPortalController::class, 'calendar']);
        Route::get('/tenant/profile', [TenantPortalController::class, 'profile']);
        Route::put('/tenant/profile', [TenantPortalController::class, 'updateProfile']);
        Route::get('/tenant/settings', [TenantPortalController::class, 'settings']);
        Route::put('/tenant/settings', [TenantPortalController::class, 'updateSettings']);
        Route::get('/payments/summary', [TenantPortalController::class, 'paymentSummary']);
        Route::post('/payments/orders', [TenantPortalController::class, 'createPaymentOrder']);
        Route::get('/payments/orders/{order}', [TenantPortalController::class, 'showPaymentOrder']);
        Route::post('/payments/orders/{order}/confirm', [TenantPortalController::class, 'confirmPaymentOrder']);

        // Tenants + vendors/technicians can work maintenance tickets (scoped in controller)
        Route::apiResource('maintenance-requests', MaintenanceRequestController::class);
        Route::get('/rental-units', [RentalUnitController::class, 'index']);

        Route::middleware('role:'.Roles::SUPER_ADMIN.','.Roles::OWNER)->group(function () {
            Route::post('/notification-templates', [NotificationCentreController::class, 'storeTemplate']);
            Route::put('/notification-templates/{template}', [NotificationCentreController::class, 'updateTemplate']);
        });

        Route::middleware('role:'.Roles::SUPER_ADMIN)->group(function () {
            Route::get('/users/stats', [UserController::class, 'stats']);
            Route::get('/roles', [UserController::class, 'roles']);
            Route::apiResource('users', UserController::class);
            Route::post('/users/{user}/deactivate', [UserController::class, 'deactivate']);
            Route::put('/notification-channels', [NotificationCentreController::class, 'updateChannel']);
        });

        Route::middleware('role:'.implode(',', Roles::staff()))->group(function () {
            Route::get('/admin/search', SearchController::class);
            Route::post('/automation/run', [AutomationController::class, 'run']);
            Route::post('/automation/reset-demo', [AutomationController::class, 'resetDemo']);
            Route::post('/invoices/generate', [InvoiceController::class, 'generate']);
            Route::post('/leases/{lease}/activate', [LeaseController::class, 'activate']);
            Route::post('/leases/{lease}/terminate', [LeaseController::class, 'terminate']);
            Route::post('/leases/{lease}/renew', [LeaseController::class, 'renew']);
            Route::post('/payments/{payment}/approve', [PaymentController::class, 'approve']);
            Route::post('/payments/{payment}/reject', [PaymentController::class, 'reject']);
            Route::post('/payments/{payment}/refund', [PaymentController::class, 'refund']);
            Route::post('/invoices/{invoice}/cancel', [InvoiceController::class, 'cancel']);
            Route::delete('/invoices/{invoice}', [InvoiceController::class, 'destroy']);

            Route::apiResource('organizations', OrganizationController::class);
            Route::post('/organizations/{organization}/assign-user', [OrganizationController::class, 'assignUser']);
            Route::apiResource('buildings', BuildingController::class);
            Route::post('/buildings/{building}/floors', [BuildingController::class, 'storeFloor']);
            Route::apiResource('vendors', VendorController::class);
            Route::apiResource('owners', OwnerController::class);
            Route::apiResource('properties', PropertyController::class);
            Route::apiResource('rental-units', RentalUnitController::class)->except(['index']);
            Route::post('/rental-units/{rental_unit}/publish', [RentalUnitController::class, 'publishListing']);
            Route::apiResource('tenants', TenantController::class);
            Route::apiResource('contracts', ContractController::class);
        });

        // Shared lease/invoice/payment access (tenants scoped in controllers)
        Route::get('/leases/{lease}/timeline', [LeaseController::class, 'timeline']);
        Route::apiResource('leases', LeaseController::class);
        Route::apiResource('invoices', InvoiceController::class)->only(['index', 'show', 'store']);
        Route::get('/transactions', [PaymentController::class, 'transactions']);
        Route::apiResource('payments', PaymentController::class);
    });
});
