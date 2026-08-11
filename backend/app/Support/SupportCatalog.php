<?php

namespace App\Support;

final class SupportCatalog
{
    public const PRIORITIES = ['low', 'normal', 'high', 'urgent'];

    public const STATUSES = [
        'open',
        'assigned',
        'in_progress',
        'waiting_for_user',
        'resolved',
        'closed',
    ];

    public const CONTACT_TYPES = [
        'owner' => 'Contact Property Owner',
        'manager' => 'Contact Property Manager',
        'platform' => 'Contact Platform Support',
        'problem' => 'Report a Problem',
        'feedback' => 'Submit Feedback',
    ];

    /**
     * @return array<string, array{name: string, route_to: string, description: string}>
     */
    public static function categories(): array
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
    public static function faqs(): array
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
