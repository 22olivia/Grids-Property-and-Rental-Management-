<?php

namespace App\Services;

use App\Models\AiSuggestion;
use App\Models\Contract;
use App\Models\MaintenanceRequest;
use App\Models\RentalUnit;
use App\Support\MaintenanceWorkflow;
use App\Support\UnitStatuses;
use Illuminate\Support\Str;

/**
 * Recommendation-only AI helpers. Never mutates leases, payments, or approvals.
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

        return [
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
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public function listingAssistant(RentalUnit $unit): array
    {
        $property = $unit->property?->name ?? 'Property';
        $beds = $unit->bedrooms ?? 1;
        $rent = number_format((float) $unit->monthly_rent, 0);

        return [
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
        ];
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

        $vacant = $units->filter(fn ($u) => in_array(UnitStatuses::normalize($u->status), [UnitStatuses::VACANT, UnitStatuses::AVAILABLE], true));
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
                    'status' => UnitStatuses::normalize($unit->status),
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

        return array_map(fn ($row) => $row + ['recommendation_only' => true], $insights);
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
            ->whereNotIn('workflow_status', [MaintenanceWorkflow::CLOSED, MaintenanceWorkflow::COMPLETED]);

        if ($organizationId) {
            $unitQuery->where('organization_id', $organizationId);
            $ticketQuery->where('organization_id', $organizationId);
        }

        $expiring = $leaseQuery->count();
        $vacantUnlisted = (clone $unitQuery)
            ->whereIn('status', [UnitStatuses::VACANT, UnitStatuses::AVAILABLE, 'available'])
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

        return array_map(fn ($row) => $row + ['recommendation_only' => true], $suggestions);
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
