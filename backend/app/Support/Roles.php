<?php

namespace App\Support;

class Roles
{
    public const SUPER_ADMIN = 'super_admin';

    public const OWNER = 'owner'; // Organisation Owner

    public const MANAGER = 'manager';

    public const ACCOUNTANT = 'accountant';

    public const AGENT = 'agent';

    public const TENANT = 'tenant';

    public const VENDOR = 'vendor';

    public const TECHNICIAN = 'technician';

    /** @return list<string> Primary login / product roles. */
    public static function all(): array
    {
        return [
            self::SUPER_ADMIN,
            self::OWNER,
            self::MANAGER,
            self::TENANT,
        ];
    }

    /** @return list<string> */
    public static function staff(): array
    {
        return [
            self::SUPER_ADMIN,
            self::OWNER,
            self::MANAGER,
            self::ACCOUNTANT,
            self::AGENT,
        ];
    }

    /** @return list<string> */
    public static function orgAdmins(): array
    {
        return [self::SUPER_ADMIN, self::OWNER];
    }

    /** @return list<string> */
    public static function propertyOperators(): array
    {
        return [self::SUPER_ADMIN, self::OWNER, self::MANAGER, self::AGENT];
    }

    /** @return list<string> */
    public static function maintenanceActors(): array
    {
        return [
            self::SUPER_ADMIN,
            self::OWNER,
            self::MANAGER,
            self::TENANT,
            self::VENDOR,
            self::TECHNICIAN,
        ];
    }

    public static function normalize(?string $role): string
    {
        return match ($role) {
            'admin' => self::SUPER_ADMIN,
            'staff' => self::MANAGER,
            'organisation_owner', 'organization_owner', 'property_owner' => self::OWNER,
            'property_manager' => self::MANAGER,
            default => $role ?: self::TENANT,
        };
    }

    public static function label(string $role): string
    {
        return match (self::normalize($role)) {
            self::SUPER_ADMIN => 'Super Admin',
            self::OWNER => 'Organisation Owner',
            self::MANAGER => 'Property Manager',
            self::ACCOUNTANT => 'Accountant',
            self::AGENT => 'Agent',
            self::TENANT => 'Tenant',
            self::VENDOR => 'Vendor',
            self::TECHNICIAN => 'Technician',
            default => ucfirst(str_replace('_', ' ', $role)),
        };
    }

    /**
     * Descriptive permission matrix for UI / API discovery.
     * Enforcement remains role + org scoping in controllers.
     *
     * @return array<string, list<string>>
     */
    public static function permissions(): array
    {
        return [
            self::SUPER_ADMIN => [
                'manage_organizations', 'manage_plans', 'manage_platform_settings',
                'manage_all_users', 'view_all_data', 'manage_ai', 'manage_templates',
            ],
            self::OWNER => [
                'manage_org_users', 'assign_properties', 'assign_permissions',
                'manage_properties', 'manage_units', 'approve_maintenance_costs',
                'view_finance', 'manage_listings', 'view_ai_suggestions',
            ],
            self::MANAGER => [
                'manage_assigned_properties', 'manage_assigned_units',
                'manage_tenants', 'manage_leases', 'manage_maintenance',
                'assign_vendors', 'view_ai_suggestions',
            ],
            self::TENANT => [
                'view_own_lease', 'view_own_payments', 'view_own_unit',
                'create_maintenance', 'confirm_maintenance', 'pay_rent',
            ],
        ];
    }
}
