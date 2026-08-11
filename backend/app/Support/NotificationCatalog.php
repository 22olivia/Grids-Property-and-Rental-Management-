<?php

namespace App\Support;

final class NotificationCatalog
{
    public const PRIORITIES = ['critical', 'high', 'normal', 'low'];

    public const CHANNELS = ['in_app', 'email', 'whatsapp'];

    public const CATEGORIES = [
        'account_security' => 'Account and Security',
        'subscription_billing' => 'Subscription and Billing',
        'property_unit' => 'Property and Unit',
        'listing_lead' => 'Listing and Lead',
        'lease' => 'Lease',
        'rent_payment' => 'Rent and Payment',
        'maintenance' => 'Maintenance',
        'documents' => 'Documents',
        'approval' => 'Approval',
        'announcement' => 'Announcement',
        'support' => 'Support',
        'system' => 'System',
    ];

    /**
     * Role-specific event keys used by templates and the dispatcher.
     *
     * Product role map:
     * - Super Admin → super_admin
     * - Tenant (Company) / Property Owner → owner
     * - Manager → manager
     * - Residential renter → tenant
     *
     * @return array<string, list<string>>
     */
    public static function eventsByRole(): array
    {
        return [
            Roles::SUPER_ADMIN => [
                'org.registered',
                'org.verification_requested',
                'org.activated',
                'org.deactivated',
                'org.deletion_requested',
                'subscription.purchased',
                'subscription.renewed',
                'subscription.expiring',
                'subscription.expired',
                'subscription.payment_failed',
                'subscription.payment_successful',
                'subscription.refund_processed',
                'announcement.platform',
                'system.maintenance',
                'security.alert',
                'system.job_failed',
                'integration.failure',
                'delivery.email_failed',
                'delivery.whatsapp_failed',
                'support.high_priority',
                'report.daily',
                'report.weekly',
                'report.monthly',
            ],
            Roles::OWNER => [
                'org.approved',
                'subscription.activated',
                'subscription.renewal_reminder',
                'subscription.expired',
                'invoice.generated',
                'payment.successful',
                'payment.failed',
                'owner.registered',
                'manager.added',
                'manager.removed',
                'property.submitted',
                'property.approved',
                'property.rejected',
                'listing.expiring',
                'announcement.from_super_admin',
                'security.important',
                'property.added',
                'lease.expiring',
                'rent.overdue',
                'maintenance.quotation_awaiting_approval',
            ],
            Roles::MANAGER => [
                'property.assigned',
                'property.updated',
                'property.approved',
                'property.rejected',
                'property.requires_review',
                'listing.expires_soon',
                'owner.submitted_changes',
                'document.uploaded',
                'payment.confirmation',
                'announcement.internal',
                'task.reminder',
                'announcement.from_owner',
                'announcement.from_super_admin',
                'maintenance.submitted',
                'maintenance.sla_breached',
                'rent.overdue',
                'tenant.application_received',
            ],
            Roles::ACCOUNTANT => [
                'invoice.generated',
                'payment.received',
                'payment.failed',
                'refund.requested',
                'balance.overdue',
                'deposit.received',
                'deposit.adjusted',
                'vendor.invoice_submitted',
                'owner.payout_due',
            ],
            Roles::AGENT => [
                'lead.created',
                'enquiry.received',
                'visit.scheduled',
                'lead.follow_up_due',
                'listing.approved',
                'listing.rejected',
                'listing.expired',
                'offer.submitted',
            ],
            Roles::TENANT => [
                'invoice.generated',
                'rent.due',
                'rent.overdue',
                'payment.successful',
                'payment.failed',
                'receipt.available',
                'lease.ready_for_signature',
                'lease.expiring',
                'maintenance.status_updated',
                'maintenance.visit_scheduled',
                'document.uploaded',
                'announcement.published',
            ],
            Roles::VENDOR => [
                'maintenance.job_assigned',
                'maintenance.assignment_cancelled',
                'maintenance.visit_scheduled',
                'maintenance.visit_changed',
                'quotation.approved',
                'quotation.rejected',
                'maintenance.deadline_approaching',
                'maintenance.job_reopened',
                'invoice.approved',
                'invoice.paid',
            ],
            Roles::TECHNICIAN => [
                'maintenance.job_assigned',
                'maintenance.assignment_cancelled',
                'maintenance.visit_scheduled',
                'maintenance.visit_changed',
                'maintenance.deadline_approaching',
                'maintenance.job_reopened',
            ],
        ];
    }

    /**
     * @return array<string, mixed>
     */
    public static function deliveryRules(): array
    {
        return [
            'priorities' => self::PRIORITIES,
            'instant_when' => ['critical', 'high', 'mandatory'],
            'batched' => ['report.daily', 'report.weekly', 'report.monthly', 'announcement.platform'],
            'reminder_days' => [1, 3, 7],
            'escalate_if_unread' => true,
            'duplicate_prevention' => 'hourly dedupe_key',
            'throttling' => 'max 20 non-critical / hour / user',
            'quiet_hours' => 'honoured except emergency_override',
            'timezone_aware' => true,
        ];
    }

    /**
     * @return list<string>
     */
    public static function templateVariables(): array
    {
        return [
            'user_name',
            'property_name',
            'unit_number',
            'tenant_name',
            'invoice_number',
            'amount',
            'due_date',
            'ticket_number',
            'scheduled_date',
            'vendor_name',
            'action_link',
            'organisation_name',
            'lease_number',
        ];
    }

    public static function label(string $category): string
    {
        return self::CATEGORIES[$category] ?? str_replace('_', ' ', ucfirst($category));
    }
}
