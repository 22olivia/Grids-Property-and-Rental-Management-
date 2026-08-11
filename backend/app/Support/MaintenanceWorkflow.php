<?php

namespace App\Support;

class MaintenanceWorkflow
{
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

    /** @return list<string> */
    public static function all(): array
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
    public static function categories(): array
    {
        return [
            'plumbing', 'electrical', 'appliance', 'hvac', 'cleaning',
            'carpentry', 'painting', 'pest_control', 'security',
            'structural', 'common_area', 'other', 'general',
        ];
    }

    /** @return list<string> */
    public static function priorities(): array
    {
        return ['emergency', 'urgent', 'high', 'normal', 'low', 'medium'];
    }
}
