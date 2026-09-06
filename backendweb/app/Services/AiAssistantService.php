<?php

namespace App\Services;

use App\Models\AiSuggestion;
use App\Models\Contract;
use App\Models\Invoice;
use App\Models\MaintenanceRequest;
use App\Models\RentalUnit;
use App\Models\User;
use App\Support\DomainCatalog;
use Illuminate\Support\Facades\Http;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Str;

/**
 * Recommendation-only AI helpers. Never mutates leases, payments, or approvals.
 * Uses Google Gemini (free tier) when GEMINI_API_KEY is set; otherwise heuristics.
 */
class AiAssistantService
{

    /**
     * @return array<string, mixed>
     */
    public function triageMaintenance(string $title, string $description, ?string $category = null): array
    {
        $text = Str::lower($title.' '.$description);
        $detectedCategory = $category ?: $this->detectCategory($text);
        $emergency = $this->isEmergency($text);
        $priority = $emergency ? 'emergency' : $this->recommendPriority($text, $detectedCategory);
        $vendorType = match ($detectedCategory) {
            'plumbing' => 'Licensed plumber',
            'electrical' => 'Electrician',
            'hvac' => 'HVAC technician',
            'appliance' => 'Appliance technician',
            'pest_control' => 'Pest control vendor',
            'painting' => 'Painter',
            'carpentry' => 'Carpenter',
            'cleaning' => 'Cleaning crew',
            'security' => 'Security vendor',
            'structural' => 'Structural contractor',
            default => 'General maintenance vendor',
        };

        $followUps = [
            'When did the issue first appear?',
            'Is water/power shutoff required before entry?',
            'Are there pets or access restrictions?',
        ];

        if ($detectedCategory === 'plumbing') {
            $followUps[] = 'Is there active leaking right now?';
        }

        $base = [
            'recommendation_only' => true,
            'category' => $detectedCategory,
            'priority' => $priority,
            'is_emergency' => $emergency,
            'vendor_type' => $vendorType,
            'manager_summary' => sprintf(
                'AI triage suggests %s / %s%s. Assign a %s and confirm access before scheduling.',
                str_replace('_', ' ', $detectedCategory),
                $priority,
                $emergency ? ' (possible emergency)' : '',
                Str::lower($vendorType)
            ),
            'follow_up_questions' => $followUps,
            'possible_duplicate' => false,
            'disclaimer' => 'AI provides recommendations only. Humans must approve costs and close tickets.',
            'provider' => 'heuristic',
        ];

        $gemini = $this->geminiGenerateJson(
            'You are a property-maintenance triage assistant for a rental platform. '.
            'Improve the manager_summary and follow_up_questions. Keep category/priority/vendor_type '.
            'unless clearly wrong. Never approve spend or assign vendors. JSON keys: '.
            'category, priority, is_emergency, vendor_type, manager_summary, follow_up_questions (array).',
            json_encode([
                'title' => $title,
                'description' => $description,
                'baseline' => $base,
            ], JSON_THROW_ON_ERROR),
        );

        if (is_array($gemini)) {
            $base['category'] = (string) ($gemini['category'] ?? $base['category']);
            $base['priority'] = (string) ($gemini['priority'] ?? $base['priority']);
            $base['is_emergency'] = (bool) ($gemini['is_emergency'] ?? $base['is_emergency']);
            $base['vendor_type'] = (string) ($gemini['vendor_type'] ?? $base['vendor_type']);
            if (! empty($gemini['manager_summary'])) {
                $base['manager_summary'] = (string) $gemini['manager_summary'];
            }
            if (! empty($gemini['follow_up_questions']) && is_array($gemini['follow_up_questions'])) {
                $base['follow_up_questions'] = array_values(array_map('strval', $gemini['follow_up_questions']));
            }
            $base['provider'] = 'gemini';
        }

        return $base;
    }

    /**
     * @return array<string, mixed>
     */
    public function listingAssistant(RentalUnit $unit): array
    {
        $property = $unit->property?->name ?? 'Property';
        $beds = $unit->bedrooms ?? 1;
        $rent = number_format((float) $unit->monthly_rent, 0);

        $base = [
            'recommendation_only' => true,
            'title' => sprintf('%s · Unit %s · %sBR', $property, $unit->unit_number, $beds),
            'description' => sprintf(
                'Bright %s-bedroom unit %s at %s. Monthly rent AED %s. Ideal for professionals seeking a well-kept home with convenient access.',
                $beds,
                $unit->unit_number,
                $property,
                $rent
            ),
            'highlights' => array_values(array_filter([
                $beds.' bedroom'.($beds > 1 ? 's' : ''),
                ($unit->bathrooms ?? 1).' bathroom'.(($unit->bathrooms ?? 1) > 1 ? 's' : ''),
                $unit->furnishing_status ? ucfirst(str_replace('_', ' ', $unit->furnishing_status)) : null,
                $unit->area || $unit->square_feet ? 'Approx. '.($unit->area ?: $unit->square_feet).' sq ft' : null,
            ])),
            'seo' => [
                'meta_title' => "Rent Unit {$unit->unit_number} at {$property}",
                'meta_description' => "Available {$beds}BR unit at {$property}. Rent AED {$rent}/month.",
                'keywords' => [$property, 'rent', $beds.'BR', 'Abu Dhabi'],
            ],
            'missing_information' => array_values(array_filter([
                blank($unit->images) ? 'Unit images' : null,
                blank($unit->amenities) ? 'Amenities list' : null,
                blank($unit->furnishing_status) ? 'Furnishing status' : null,
                blank($unit->listing_description) ? 'Listing description' : null,
            ])),
            'disclaimer' => 'AI listing copy is a draft suggestion only.',
            'provider' => 'heuristic',
        ];

        $gemini = $this->geminiGenerateJson(
            'You write short, professional rental listing drafts. Keep facts accurate. '.
            'JSON keys: title, description, highlights (array of short strings), seo (object with meta_title, meta_description, keywords array).',
            json_encode([
                'property' => $property,
                'unit_number' => $unit->unit_number,
                'bedrooms' => $beds,
                'bathrooms' => $unit->bathrooms,
                'monthly_rent' => $unit->monthly_rent,
                'furnishing_status' => $unit->furnishing_status,
                'area' => $unit->area ?: $unit->square_feet,
                'amenities' => $unit->amenities,
                'baseline' => $base,
            ], JSON_THROW_ON_ERROR),
        );

        if (is_array($gemini)) {
            if (! empty($gemini['title'])) {
                $base['title'] = (string) $gemini['title'];
            }
            if (! empty($gemini['description'])) {
                $base['description'] = (string) $gemini['description'];
            }
            if (! empty($gemini['highlights']) && is_array($gemini['highlights'])) {
                $base['highlights'] = array_values(array_map('strval', $gemini['highlights']));
            }
            if (! empty($gemini['seo']) && is_array($gemini['seo'])) {
                $base['seo'] = array_merge($base['seo'], $gemini['seo']);
            }
            $base['provider'] = 'gemini';
        }

        return $base;
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function unitInsights(?int $organizationId = null): array
    {
        $units = RentalUnit::query()
            ->with('property')
            ->withCount('maintenanceRequests')
            ->when($organizationId, fn ($q) => $q->where('organization_id', $organizationId))
            ->get();

        $insights = [];

        $vacant = $units->filter(fn ($u) => in_array(DomainCatalog::normalizeUnitStatus($u->status), [DomainCatalog::VACANT, DomainCatalog::AVAILABLE], true));
        if ($vacant->isNotEmpty()) {
            $labels = $vacant->map(function (RentalUnit $unit) {
                $property = $unit->property?->name ?: 'Property';

                return $property.' · '.$unit->unit_number.($unit->is_listed ? ' (listed)' : ' (not listed)');
            })->values()->all();

            $insights[] = [
                'type' => 'vacant_units',
                'title' => $vacant->count().' vacant unit(s)',
                'summary' => 'Vacant: '.implode('; ', $labels).'.',
                'unit_ids' => $vacant->pluck('id')->values(),
                'units' => $vacant->map(fn (RentalUnit $unit) => [
                    'id' => $unit->id,
                    'unit_number' => $unit->unit_number,
                    'status' => DomainCatalog::normalizeUnitStatus($unit->status),
                    'is_listed' => (bool) $unit->is_listed,
                    'property' => $unit->property?->name,
                    'monthly_rent' => $unit->monthly_rent,
                ])->values(),
            ];
        }

        $unlist = $vacant->where('is_listed', false);
        if ($unlist->isNotEmpty()) {
            $insights[] = [
                'type' => 'vacant_without_listing',
                'title' => $unlist->count().' vacant unit(s) have no active listing',
                'summary' => 'Publish listings for: '.$unlist->pluck('unit_number')->implode(', ').'.',
                'unit_ids' => $unlist->pluck('id')->values(),
            ];
        }

        $highMaint = $units->where('maintenance_requests_count', '>=', 3);
        if ($highMaint->isNotEmpty()) {
            $insights[] = [
                'type' => 'high_maintenance_units',
                'title' => $highMaint->count().' high-maintenance unit(s)',
                'summary' => 'Repeated tickets may indicate asset or tenant issues.',
                'unit_ids' => $highMaint->pluck('id')->values(),
            ];
        }

        $insights = array_map(fn ($row) => $row + ['recommendation_only' => true, 'provider' => 'heuristic'], $insights);

        return $this->enrichInsightRows($insights, 'unit portfolio insights');
    }

    /**
     * @return list<array<string, mixed>>
     */
    public function dashboardSuggestions(?int $organizationId = null): array
    {
        $leaseQuery = Contract::query()->where('status', 'active')
            ->whereBetween('end_date', [now(), now()->addDays(60)]);
        $unitQuery = RentalUnit::query();
        $ticketQuery = MaintenanceRequest::query()
            ->whereNotNull('sla_due_at')
            ->where('sla_due_at', '<', now())
            ->whereNotIn('workflow_status', [DomainCatalog::CLOSED, DomainCatalog::COMPLETED]);

        if ($organizationId) {
            $unitQuery->where('organization_id', $organizationId);
            $ticketQuery->where('organization_id', $organizationId);
        }

        $expiring = $leaseQuery->count();
        $vacantUnlisted = (clone $unitQuery)
            ->whereIn('status', [DomainCatalog::VACANT, DomainCatalog::AVAILABLE, 'available'])
            ->where(fn ($q) => $q->where('is_listed', false)->orWhereNull('is_listed'))
            ->count();
        $slaBreaches = $ticketQuery->count();

        $suggestions = [];
        if ($expiring > 0) {
            $suggestions[] = [
                'type' => 'leases_expiring',
                'title' => "{$expiring} lease(s) expire in the next 60 days.",
                'summary' => 'Start renewal outreach early to reduce vacancy risk.',
            ];
        }
        if ($vacantUnlisted > 0) {
            $suggestions[] = [
                'type' => 'vacant_no_listing',
                'title' => "{$vacantUnlisted} vacant unit(s) have no active listing.",
                'summary' => 'Use the listing assistant to draft publish-ready copy.',
            ];
        }
        if ($slaBreaches > 0) {
            $suggestions[] = [
                'type' => 'sla_breaches',
                'title' => "{$slaBreaches} maintenance ticket(s) have crossed their SLA.",
                'summary' => 'Review assignments and escalate urgent work.',
            ];
        }

        $repeatPlumbing = MaintenanceRequest::query()
            ->selectRaw('rental_unit_id, count(*) as total')
            ->where('category', 'plumbing')
            ->when($organizationId, fn ($q) => $q->where('organization_id', $organizationId))
            ->groupBy('rental_unit_id')
            ->havingRaw('count(*) >= 2')
            ->get();

        foreach ($repeatPlumbing as $row) {
            $unitNo = RentalUnit::query()->whereKey($row->rental_unit_id)->value('unit_number') ?? ('#'.$row->rental_unit_id);
            $suggestions[] = [
                'type' => 'repeat_complaints',
                'title' => "Unit {$unitNo} has repeated plumbing complaints.",
                'summary' => 'Investigate root cause before the next lease renewal.',
                'unit_id' => $row->rental_unit_id,
            ];
        }

        if ($suggestions === []) {
            $suggestions[] = [
                'type' => 'healthy',
                'title' => 'No urgent AI alerts right now.',
                'summary' => 'Portfolio signals look stable. Keep monitoring vacancy and SLA.',
            ];
        }

        $suggestions = array_map(fn ($row) => $row + ['recommendation_only' => true, 'provider' => 'heuristic'], $suggestions);

        return $this->enrichInsightRows($suggestions, 'manager dashboard suggestions');
    }

    /**
     * @return array{reply: string, recommendation_only: bool, provider: string}
     */
    public function tenantAssist(User $user, string $prompt): array
    {
        $text = strtolower($prompt);
        $tenant = $user->tenant;
        $lease = $tenant
            ? Contract::query()->where('tenant_id', $tenant->id)->latest()->first()
            : null;
        $invoice = $lease
            ? Invoice::query()
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

        $provider = 'heuristic';
        $context = [
            'prompt' => $prompt,
            'baseline_reply' => $reply,
            'lease' => $lease ? [
                'number' => $lease->contract_number,
                'status' => $lease->status,
                'start' => optional($lease->start_date)?->toDateString(),
                'end' => optional($lease->end_date)?->toDateString(),
            ] : null,
            'invoice' => $invoice ? [
                'number' => $invoice->invoice_number,
                'remaining' => $invoice->remaining_balance,
                'due' => optional($invoice->due_date)?->toDateString(),
                'status' => $invoice->status,
            ] : null,
        ];

        $geminiReply = $this->geminiGenerate(
            'You are a helpful tenant portal assistant for a rental platform. '.
            'Use only the provided context facts. Be concise and clear. '.
            'Never change leases, waive fees, confirm payments, or close tickets. '.
            'Always end by reminding the tenant you only recommend actions.',
            json_encode($context, JSON_THROW_ON_ERROR),
            700,
        );

        if ($geminiReply) {
            $reply = $geminiReply;
            $provider = 'gemini';
        }

        return [
            'reply' => $reply,
            'recommendation_only' => true,
            'provider' => $provider,
        ];
    }

    /**
     * @param  array<string, mixed>  $payload
     */
    public function storeSuggestion(
        string $module,
        string $type,
        string $title,
        string $summary,
        array $payload = [],
        ?int $organizationId = null,
        ?int $userId = null,
    ): AiSuggestion {
        return AiSuggestion::query()->create([
            'organization_id' => $organizationId,
            'user_id' => $userId,
            'module' => $module,
            'suggestion_type' => $type,
            'title' => $title,
            'summary' => $summary,
            'payload' => $payload + ['recommendation_only' => true],
            'status' => 'recommended',
        ]);
    }

    /**
     * @param  list<array<string, mixed>>  $rows
     * @return list<array<string, mixed>>
     */
    private function enrichInsightRows(array $rows, string $label): array
    {
        if ($rows === [] || ! $this->geminiConfigured()) {
            return $rows;
        }

        $gemini = $this->geminiGenerateJson(
            "You refine {$label} for a property manager. Keep each item's type and facts. ".
            'Improve title/summary wording only. JSON shape: {"items":[{"type":"...","title":"...","summary":"..."}]}',
            json_encode(['items' => $rows], JSON_THROW_ON_ERROR),
            1200,
        );

        $items = $gemini['items'] ?? null;
        if (! is_array($items) || $items === []) {
            return $rows;
        }

        return array_map(function ($row, $index) use ($items) {
            $g = $items[$index] ?? null;
            if (! is_array($g)) {
                return $row;
            }
            if (! empty($g['title'])) {
                $row['title'] = (string) $g['title'];
            }
            if (! empty($g['summary'])) {
                $row['summary'] = (string) $g['summary'];
            }
            $row['provider'] = 'gemini';

            return $row;
        }, $rows, array_keys($rows));
    }


    private function geminiConfigured(): bool
    {
        // External Gemini provider removed — always use built-in heuristics.
        return false;
    }

    private function geminiGenerate(string $system, string $user, int $maxTokens = 1024): ?string
    {
        $key = (string) config('services.gemini.key');
        if ($key === '') {
            return null;
        }

        $model = (string) config('services.gemini.model', 'gemini-2.0-flash');
        $url = sprintf(
            'https://generativelanguage.googleapis.com/v1beta/models/%s:generateContent?key=%s',
            rawurlencode($model),
            rawurlencode($key),
        );

        try {
            $response = Http::timeout(25)
                ->acceptJson()
                ->post($url, [
                    'systemInstruction' => [
                        'parts' => [['text' => $system]],
                    ],
                    'contents' => [
                        [
                            'role' => 'user',
                            'parts' => [['text' => $user]],
                        ],
                    ],
                    'generationConfig' => [
                        'temperature' => 0.35,
                        'maxOutputTokens' => $maxTokens,
                    ],
                ]);

            if (! $response->successful()) {
                Log::warning('Gemini API error', [
                    'status' => $response->status(),
                    'body' => $response->json() ?: $response->body(),
                ]);

                return null;
            }

            $text = data_get($response->json(), 'candidates.0.content.parts.0.text');
            $text = is_string($text) ? trim($text) : '';

            return $text !== '' ? $text : null;
        } catch (\Throwable $e) {
            Log::warning('Gemini API exception', ['message' => $e->getMessage()]);

            return null;
        }
    }

    /**
     * @return array<string, mixed>|null
     */
    private function geminiGenerateJson(string $system, string $user, int $maxTokens = 1024): ?array
    {
        $raw = $this->geminiGenerate(
            $system."\nRespond with valid JSON only. No markdown fences.",
            $user,
            $maxTokens,
        );
        if (! $raw) {
            return null;
        }

        $cleaned = preg_replace('/^```(?:json)?\s*|\s*```$/u', '', trim($raw)) ?: trim($raw);
        $decoded = json_decode($cleaned, true);

        return is_array($decoded) ? $decoded : null;
    }

    private function detectCategory(string $text): string
    {
        $map = [
            'plumbing' => ['leak', 'pipe', 'drain', 'toilet', 'water', 'sink', 'plumbing'],
            'electrical' => ['electric', 'power', 'outlet', 'breaker', 'light', 'wiring'],
            'hvac' => ['ac', 'a/c', 'hvac', 'air condition', 'heating', 'cooling'],
            'appliance' => ['fridge', 'washer', 'dryer', 'oven', 'dishwasher', 'appliance'],
            'pest_control' => ['pest', 'roach', 'ant', 'rodent', 'insect'],
            'painting' => ['paint', 'wall stain'],
            'carpentry' => ['door', 'cabinet', 'wood', 'carpentry'],
            'cleaning' => ['clean', 'dirty', 'trash'],
            'security' => ['lock', 'camera', 'security', 'gate'],
            'structural' => ['crack', 'ceiling', 'foundation', 'structural'],
        ];

        foreach ($map as $category => $keywords) {
            foreach ($keywords as $keyword) {
                if (str_contains($text, $keyword)) {
                    return $category;
                }
            }
        }

        return 'other';
    }

    private function isEmergency(string $text): bool
    {
        foreach (['flood', 'fire', 'gas leak', 'no power', 'sparking', 'burst pipe', 'emergency'] as $needle) {
            if (str_contains($text, $needle)) {
                return true;
            }
        }

        return false;
    }

    private function recommendPriority(string $text, string $category): string
    {
        if (str_contains($text, 'urgent') || $category === 'electrical') {
            return 'urgent';
        }
        if (in_array($category, ['plumbing', 'hvac', 'security'], true)) {
            return 'high';
        }
        if (in_array($category, ['cleaning', 'painting'], true)) {
            return 'low';
        }

        return 'normal';
    }
}
