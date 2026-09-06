<?php

namespace App\Support;

/**
 * Domain constants for units, maintenance workflow, and support tickets.
 */
final class DomainCatalog
{
    // —— Unit statuses ——
    public const VACANT = 'vacant';

    public const RESERVED = 'reserved';

    public const APPLICATION_PENDING = 'application_pending';

    public const OCCUPIED = 'occupied';

    public const NOTICE_PERIOD = 'notice_period';

    public const UNDER_MAINTENANCE = 'under_maintenance';

    public const BLOCKED = 'blocked';

    /** Legacy aliases kept for backward compatibility. */
    public const AVAILABLE = 'available';

    public const MAINTENANCE = 'maintenance';

    // —— Maintenance workflow ——
    public const SUBMITTED = 'submitted';

    public const AI_TRIAGED = 'ai_triaged';

    public const MANAGER_REVIEW = 'manager_review';

    public const ASSIGNED = 'assigned';

    public const VISIT_SCHEDULED = 'visit_scheduled';

    public const QUOTE_SUBMITTED = 'quote_submitted';

    public const APPROVAL_REQUIRED = 'approval_required';

    public const IN_PROGRESS = 'in_progress';

    public const COMPLETED = 'completed';

    public const TENANT_CONFIRMATION = 'tenant_confirmation';

    public const CLOSED = 'closed';

    // —— Support ——
    public const SUPPORT_PRIORITIES = ['low', 'normal', 'high', 'urgent'];

    public const SUPPORT_STATUSES = [
        'open',
        'assigned',
        'in_progress',
        'waiting_for_user',
        'resolved',
        'closed',
    ];

    public const SUPPORT_CONTACT_TYPES = [
        'owner' => 'Contact Property Owner',
        'manager' => 'Contact Property Manager',
        'platform' => 'Contact Platform Support',
        'problem' => 'Report a Problem',
        'feedback' => 'Submit Feedback',
    ];

    /** @return list<string> */
    public static function unitStatuses(): array
    {
        return [
            self::VACANT,
            self::RESERVED,
            self::APPLICATION_PENDING,
            self::OCCUPIED,
            self::NOTICE_PERIOD,
            self::UNDER_MAINTENANCE,
            self::BLOCKED,
            self::AVAILABLE,
            self::MAINTENANCE,
        ];
    }

    public static function normalizeUnitStatus(?string $status): string
    {
        return match ($status) {
            'available' => self::VACANT,
            'maintenance' => self::UNDER_MAINTENANCE,
            default => $status ?: self::VACANT,
        };
    }

    /** @return list<string> */
    public static function maintenanceStatuses(): array
    {
        return [
            self::SUBMITTED,
            self::AI_TRIAGED,
            self::MANAGER_REVIEW,
            self::ASSIGNED,
            self::VISIT_SCHEDULED,
            self::QUOTE_SUBMITTED,
            self::APPROVAL_REQUIRED,
            self::IN_PROGRESS,
            self::COMPLETED,
            self::TENANT_CONFIRMATION,
            self::CLOSED,
        ];
    }

    /** @return list<string> */
    public static function maintenanceCategories(): array
    {
        return [
            'plumbing', 'electrical', 'appliance', 'hvac', 'cleaning',
            'carpentry', 'painting', 'pest_control', 'security',
            'structural', 'common_area', 'other', 'general',
        ];
    }

    /** @return list<string> */
    public static function maintenancePriorities(): array
    {
        return ['emergency', 'urgent', 'high', 'normal', 'low', 'medium'];
    }

    /**
     * @return array<string, array{name: string, route_to: string, description: string}>
     */
    public static function supportCategories(): array
    {
        return [
            'general_query' => [
                'name' => 'General Query',
                'route_to' => 'manager',
                'description' => 'General questions about your property or account.',
            ],
            'rent' => [
                'name' => 'Rent',
                'route_to' => 'owner_or_manager',
                'description' => 'Rent amount, due dates, and billing questions.',
            ],
            'lease' => [
                'name' => 'Lease',
                'route_to' => 'owner_or_manager',
                'description' => 'Lease terms, renewals, and documents.',
            ],
            'payment' => [
                'name' => 'Payment',
                'route_to' => 'owner_or_manager',
                'description' => 'Payments, receipts, and failed transactions.',
            ],
            'maintenance' => [
                'name' => 'Maintenance',
                'route_to' => 'manager',
                'description' => 'Repairs, visits, and maintenance tickets.',
            ],
            'technical_issue' => [
                'name' => 'Technical Issue',
                'route_to' => 'platform',
                'description' => 'Login, app, or platform problems.',
            ],
            'property_issue' => [
                'name' => 'Property Issue',
                'route_to' => 'manager',
                'description' => 'Building, amenities, or unit issues.',
            ],
            'complaint' => [
                'name' => 'Complaint',
                'route_to' => 'owner',
                'description' => 'Formal complaints to the organisation owner.',
            ],
            'feature_request' => [
                'name' => 'Feature Request',
                'route_to' => 'platform',
                'description' => 'Ideas to improve GPMS.',
            ],
            'other' => [
                'name' => 'Other',
                'route_to' => 'manager',
                'description' => 'Anything that does not fit other categories.',
            ],
        ];
    }

    /**
     * @return list<array{q: string, a: string}>
     */
    public static function supportFaqs(): array
    {
        return [
            [
                'q' => 'How do I pay rent?',
                'a' => 'Open Invoices → My bills, choose the bill, and tap Pay. You will confirm the amount and payment method.',
            ],
            [
                'q' => 'How do I contact support?',
                'a' => 'Open Help & Support and use the support email or helpline number shown on the page.',
            ],
            [
                'q' => 'When is the helpline available?',
                'a' => 'Sunday–Thursday, 9:00–18:00 GST. Outside these hours, email support@gpms.test and the team will reply on the next business day.',
            ],
        ];
    }
}
