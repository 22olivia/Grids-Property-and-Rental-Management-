<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Models\AiSuggestion;
use App\Models\MaintenanceRequest;
use App\Models\RentalUnit;
use App\Services\ActivityLogger;
use App\Services\AiAssistantService;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;

class AiAssistantController extends Controller
{
    public function __construct(private readonly AiAssistantService $ai) {}

    public function triage(Request $request, ActivityLogger $logger): JsonResponse
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

        $logger->log('ai.triage', $suggestion, ['recommendation_only' => true], $request);

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

        $text = strtolower($validated['prompt']);
        $tenant = $request->user()->tenant;
        $lease = $tenant
            ? \App\Models\Contract::query()->where('tenant_id', $tenant->id)->latest()->first()
            : null;
        $invoice = $lease
            ? \App\Models\Invoice::query()
                ->where('contract_id', $lease->id)
                ->whereIn('status', ['unpaid', 'partially_paid', 'overdue', 'pending'])
                ->orderBy('due_date')
                ->first()
            : null;

        if (str_contains($text, 'invoice') || str_contains($text, 'rent') || str_contains($text, 'late fee')) {
            $reply = $invoice
                ? "Your open invoice {$invoice->invoice_number} has a remaining balance of {$invoice->remaining_balance}, due ".optional($invoice->due_date)->toDateString().'. Late fees follow your organisation policy after the grace period. Pay from Invoices — I cannot confirm payments or waive fees.'
                : 'I do not see an open invoice on your tenancy right now. Check Invoices for history.';
        } elseif (str_contains($text, 'lease') || str_contains($text, 'notice') || str_contains($text, 'renew')) {
            $reply = $lease
                ? "Lease {$lease->contract_number} is {$lease->status}. Term ".optional($lease->start_date)->toDateString().' to '.optional($lease->end_date)->toDateString().'. Use My Lease to request renewal or submit notice. I cannot change lease terms.'
                : 'No active lease was found for your account.';
        } elseif (
            str_contains($text, 'maintenance')
            || str_contains($text, 'leak')
            || str_contains($text, 'ac')
            || str_contains($text, 'repair')
        ) {
            $emergency = str_contains($text, 'flood') || str_contains($text, 'fire') || str_contains($text, 'gas');
            $reply = $emergency
                ? 'This may be an emergency. Contact building security or emergency services first. Suggested priority: Urgent. I will not promise a resolution time. Open Maintenance to submit with photos.'
                : 'Suggested category based on your description: Plumbing or HVAC. Suggested priority: High for active leaks or no cooling. Include clear photos and access notes. I only draft recommendations — managers assign work.';
        } else {
            $reply = implode("\n", [
                '• Check Invoices if rent is due soon.',
                '• Review My Lease for renewal or notice options.',
                '• Open Maintenance to raise a request.',
                '• Download receipts from Receipts when payments are verified.',
                '',
                'I cannot change leases, waive rent, confirm payments, approve refunds, or close tickets.',
            ]);
        }

        return response()->json([
            'message' => 'Tenant assistant response (recommendation only).',
            'data' => [
                'reply' => $reply,
                'recommendation_only' => true,
            ],
        ]);
    }
}
