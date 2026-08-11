<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\MaintenanceRequest;
use App\Models\Organization;
use App\Models\RentalUnit;
use App\Services\ActivityLogger;
use App\Services\AiAssistantService;
use App\Support\MaintenanceWorkflow;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Str;
use Illuminate\Validation\Rule;

class MaintenanceRequestController extends Controller
{
    public function index(Request $request): JsonResponse
    {
        $user = $request->user();

        $requests = MaintenanceRequest::with([
            'rentalUnit.property',
            'tenant',
            'assignedVendor',
            'assignedTechnician:id,name,email',
        ])
            ->when($request->status, fn ($q) => $q->where('status', $request->status))
            ->when($request->workflow_status, fn ($q) => $q->where('workflow_status', $request->workflow_status))
            ->when($request->priority, fn ($q) => $q->where('priority', $request->priority))
            ->when($request->category, fn ($q) => $q->where('category', $request->category))
            ->when($user->isTenant(), function ($q) use ($user) {
                $tenantId = $user->tenant?->id;
                $q->where('tenant_id', $tenantId ?: 0);
            })
            ->when($user->isVendor(), function ($q) use ($user) {
                $vendorId = $user->vendor?->id;
                $q->where('assigned_vendor_id', $vendorId ?: 0);
            })
            ->when($user->isTechnician(), fn ($q) => $q->where('assigned_technician_id', $user->id))
            ->when(
                ! $user->isSuperAdmin() && $user->organization_id,
                fn ($q) => $q->where('organization_id', $user->organization_id)
            )
            ->latest()
            ->paginate((int) $request->get('per_page', 15));

        return response()->json($requests);
    }

    public function store(
        Request $request,
        AiAssistantService $ai,
        ActivityLogger $logger,
        \App\Services\TenantCalendarService $calendar,
        \App\Services\NotificationService $notifications,
    ): JsonResponse
    {
        $validated = $request->validate([
            'rental_unit_id' => ['required', 'exists:rental_units,id'],
            'tenant_id' => ['nullable', 'exists:tenants,id'],
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
            'category' => ['sometimes', Rule::in(MaintenanceWorkflow::categories())],
            'priority' => ['sometimes', Rule::in(MaintenanceWorkflow::priorities())],
            'permission_to_enter' => ['sometimes', 'boolean'],
            'preferred_visit_date' => ['nullable', 'date'],
            'media' => ['sometimes', 'array'],
            'run_ai_triage' => ['sometimes', 'boolean'],
        ]);

        $unit = RentalUnit::query()->with('property')->findOrFail($validated['rental_unit_id']);
        $triage = null;
        if ($request->boolean('run_ai_triage', true)) {
            $triage = $ai->triageMaintenance(
                $validated['title'],
                $validated['description'],
                $validated['category'] ?? null,
            );
        }

        $maintenanceRequest = MaintenanceRequest::create([
            'organization_id' => $unit->organization_id ?? $request->user()->organization_id,
            'ticket_number' => 'MT-'.strtoupper(Str::random(8)),
            'rental_unit_id' => $unit->id,
            'property_id' => $unit->property_id,
            'tenant_id' => $validated['tenant_id'] ?? $request->user()->tenant?->id,
            'title' => $validated['title'],
            'description' => $validated['description'],
            'category' => $triage['category'] ?? ($validated['category'] ?? 'other'),
            'priority' => $validated['priority'] ?? ($triage['priority'] ?? 'normal'),
            'status' => 'open',
            'workflow_status' => $triage ? MaintenanceWorkflow::AI_TRIAGED : MaintenanceWorkflow::SUBMITTED,
            'permission_to_enter' => $validated['permission_to_enter'] ?? false,
            'preferred_visit_date' => $validated['preferred_visit_date'] ?? null,
            'media' => $validated['media'] ?? [],
            'ai_triage' => $triage,
            'sla_due_at' => now()->addHours(($triage['is_emergency'] ?? false) ? 4 : 48),
            'reported_at' => now(),
        ]);

        $calendar->syncMaintenanceEvent($maintenanceRequest);

        $tenantUser = $maintenanceRequest->tenant?->user;
        if ($tenantUser) {
            $notifications->notify($tenantUser, 'maintenance.created', [
                'title' => 'Maintenance request received',
                'message' => "Ticket {$maintenanceRequest->ticket_number}: {$maintenanceRequest->title}",
                'action_url' => '/maintenance',
                'channels' => ['in_app', 'email', 'whatsapp'],
                'record_type' => MaintenanceRequest::class,
                'record_id' => $maintenanceRequest->id,
                'module' => 'maintenance',
            ]);
        }

        $logger->log('maintenance.created', $maintenanceRequest, [
            'ticket_number' => $maintenanceRequest->ticket_number,
            'ai_recommendation_only' => true,
        ], $request);

        return response()->json([
            'message' => 'Maintenance request created.'.($triage ? ' AI triage attached as recommendation only.' : ''),
            'data' => $maintenanceRequest->load(['rentalUnit.property', 'tenant', 'assignedVendor']),
        ], 201);
    }

    public function show(MaintenanceRequest $maintenanceRequest): JsonResponse
    {
        $maintenanceRequest->load([
            'rentalUnit.property',
            'tenant',
            'assignedVendor',
            'assignedTechnician:id,name,email',
        ]);

        return response()->json(['data' => $maintenanceRequest]);
    }

    public function update(
        Request $request,
        MaintenanceRequest $maintenanceRequest,
        ActivityLogger $logger,
        \App\Services\TenantCalendarService $calendar,
    ): JsonResponse
    {
        $validated = $request->validate([
            'title' => ['sometimes', 'string', 'max:255'],
            'description' => ['sometimes', 'string'],
            'category' => ['sometimes', Rule::in(MaintenanceWorkflow::categories())],
            'priority' => ['sometimes', Rule::in(MaintenanceWorkflow::priorities())],
            'status' => ['sometimes', 'string', 'in:open,in_progress,resolved,closed,cancelled'],
            'workflow_status' => ['sometimes', Rule::in(MaintenanceWorkflow::all())],
            'permission_to_enter' => ['sometimes', 'boolean'],
            'preferred_visit_date' => ['nullable', 'date'],
            'assigned_vendor_id' => ['nullable', 'exists:vendors,id'],
            'assigned_technician_id' => ['nullable', 'exists:users,id'],
            'estimated_cost' => ['nullable', 'numeric', 'min:0'],
            'approved_cost' => ['nullable', 'numeric', 'min:0'],
            'actual_cost' => ['nullable', 'numeric', 'min:0'],
            'scheduled_date' => ['nullable', 'date'],
            'media' => ['sometimes', 'array'],
            'before_after_images' => ['sometimes', 'array'],
            'quotation' => ['sometimes', 'array'],
            'resolved_at' => ['nullable', 'date'],
            'resolution_notes' => ['nullable', 'string'],
        ]);

        if (($validated['status'] ?? null) === 'resolved' && blank($validated['resolved_at'] ?? null)) {
            $validated['resolved_at'] = now();
            $validated['workflow_status'] = $validated['workflow_status'] ?? MaintenanceWorkflow::COMPLETED;
        }

        if (($validated['status'] ?? null) === 'in_progress') {
            $validated['resolved_at'] = null;
            $validated['workflow_status'] = $validated['workflow_status'] ?? MaintenanceWorkflow::IN_PROGRESS;
        }

        if (! empty($validated['assigned_vendor_id']) || ! empty($validated['assigned_technician_id'])) {
            $validated['workflow_status'] = $validated['workflow_status'] ?? MaintenanceWorkflow::ASSIGNED;
        }

        if (! empty($validated['scheduled_date'])) {
            $validated['workflow_status'] = $validated['workflow_status'] ?? MaintenanceWorkflow::VISIT_SCHEDULED;
        }

        if (! empty($validated['quotation'])) {
            $validated['workflow_status'] = $validated['workflow_status'] ?? MaintenanceWorkflow::QUOTE_SUBMITTED;
        }

        // Cost approval is never automatic — only when an owner/admin explicitly sets approved_cost.
        if (array_key_exists('approved_cost', $validated) && $validated['approved_cost'] !== null) {
            $org = Organization::query()->find($maintenanceRequest->organization_id);
            $limit = (float) ($org?->maintenance_approval_limit ?? 1000);
            if ((float) $validated['approved_cost'] > $limit && ! $request->user()->isSuperAdmin() && ! $request->user()->isOwner()) {
                return response()->json([
                    'message' => 'Approved cost exceeds organization limit. Organisation Owner approval required.',
                    'data' => ['limit' => $limit],
                ], 422);
            }
            $validated['workflow_status'] = MaintenanceWorkflow::IN_PROGRESS;
        }

        $maintenanceRequest->update($validated);
        $calendar->syncMaintenanceEvent($maintenanceRequest->fresh());
        $logger->log('maintenance.updated', $maintenanceRequest, $validated, $request);

        return response()->json([
            'message' => 'Maintenance request updated successfully.',
            'data' => $maintenanceRequest->fresh([
                'rentalUnit.property',
                'tenant',
                'assignedVendor',
                'assignedTechnician:id,name,email',
            ]),
        ]);
    }

    public function destroy(MaintenanceRequest $maintenanceRequest, ActivityLogger $logger): JsonResponse
    {
        $logger->log('maintenance.deleted', $maintenanceRequest, [
            'ticket_number' => $maintenanceRequest->ticket_number,
        ]);
        $maintenanceRequest->delete();

        return response()->json([
            'message' => 'Maintenance request deleted successfully.',
        ]);
    }
}
