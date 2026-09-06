<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AiSuggestion;
use App\Models\MaintenanceRequest;
use App\Models\RentalUnit;
use App\Models\ActivityLog;
use App\Services\AiAssistantService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AiAssistantController extends Controller
{
    public function __construct(private readonly AiAssistantService $ai) {}

    public function triage(Request $request): JsonResponse
    {
        $validated = $request->validate([
            'title' => ['required', 'string', 'max:255'],
            'description' => ['required', 'string'],
            'category' => ['nullable', 'string'],
            'maintenance_request_id' => ['nullable', 'exists:maintenance_requests,id'],
        ]);

        $result = $this->ai->triageMaintenance(
            $validated['title'],
            $validated['description'],
            $validated['category'] ?? null,
        );

        if (! empty($validated['maintenance_request_id'])) {
            $ticket = MaintenanceRequest::query()->find($validated['maintenance_request_id']);
            $ticket?->update([
                'ai_triage' => $result,
                'workflow_status' => 'ai_triaged',
            ]);
        }

        $suggestion = $this->ai->storeSuggestion(
            'maintenance',
            'triage',
            'Maintenance triage recommendation',
            $result['manager_summary'],
            $result,
            $request->user()->organization_id,
            $request->user()->id,
        );

        ActivityLog::record('ai.triage', $suggestion, ['recommendation_only' => true], $request);

        return response()->json([
            'message' => 'AI triage recommendation ready. No automatic actions were taken.',
            'data' => $result,
        ]);
    }

    public function listing(Request $request, RentalUnit $unit): JsonResponse
    {
        $unit->load('property');
        $result = $this->ai->listingAssistant($unit);

        $this->ai->storeSuggestion(
            'listing',
            'listing_copy',
            $result['title'],
            $result['description'],
            $result,
            $request->user()->organization_id,
            $request->user()->id,
        );

        return response()->json([
            'message' => 'Listing assistant draft ready (recommendation only).',
            'data' => $result,
        ]);
    }

    public function unitInsights(Request $request): JsonResponse
    {
        $orgId = $request->user()->isSuperAdmin()
            ? $request->integer('organization_id') ?: null
            : $request->user()->organization_id;

        return response()->json([
            'message' => 'Unit insights are recommendations only.',
            'data' => $this->ai->unitInsights($orgId),
        ]);
    }

    public function dashboardSuggestions(Request $request): JsonResponse
    {
        $orgId = $request->user()->isSuperAdmin()
            ? $request->integer('organization_id') ?: null
            : $request->user()->organization_id;

        return response()->json([
            'message' => 'Dashboard suggestions are recommendations only.',
            'data' => $this->ai->dashboardSuggestions($orgId),
        ]);
    }

    public function index(Request $request): JsonResponse
    {
        $rows = AiSuggestion::query()
            ->when(
                ! $request->user()->isSuperAdmin(),
                fn ($q) => $q->where('organization_id', $request->user()->organization_id)
            )
            ->latest()
            ->paginate(30);

        return response()->json($rows);
    }

    public function tenantAssist(Request $request): JsonResponse
    {
        abort_unless($request->user()?->normalizedRole() === 'tenant', 403);

        $validated = $request->validate([
            'prompt' => ['required', 'string', 'max:2000'],
        ]);

        $result = $this->ai->tenantAssist($request->user(), $validated['prompt']);

        return response()->json([
            'message' => 'Tenant assistant response (recommendation only).',
            'data' => $result,
        ]);
    }
}
