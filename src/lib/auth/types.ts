import type { Permission } from '@/lib/permissions/types';

/**
 * ===========================================================================
 * Identity types — matched to the ACTUAL backend `/me` response.
 * ===========================================================================
 *
 * Verified (`AuthController::me`): `{ user, role_label }`, where `user` is the
 * Eloquent `User` model with `owner`, `tenant` and `managedProperties` loaded.
 *
 * User columns verified from the model's Fillable attribute and migrations:
 *   id, organization_id, name, email, role, phone, photo_path, address,
 *   status, verification_status, assigned_property_ids, assigned_unit_ids,
 *   last_login_at
 *
 * `password` and `remember_token` are Hidden and never serialised.
 * ===========================================================================
 */

/**
 * Roles as the backend defines them (`app/Support/Roles.php`).
 *
 * NOT a permission model. The backend authorises by ROLE only — the
 * `organization_user.permissions` JSON column exists but is never read.
 *
 * MI-11 therefore stands: no permission taxonomy exists. `Permission` remains
 * a branded string and `PERMISSIONS` remains empty. Role names are recorded
 * here for display and for the role-gating stopgap, and no component branches
 * on them.
 */
export const BACKEND_ROLES = [
  'super_admin',
  'owner',
  'manager',
  'accountant',
  'agent',
  'tenant',
  'vendor',
  'technician',
] as const;
export type BackendRole = (typeof BACKEND_ROLES)[number];

/**
 * Roles that can actually authenticate (`AuthController::login` line 108).
 * The other four are used in route middleware but cannot obtain a token —
 * raised as Observation 3 in the backend defect report.
 */
export const LOGIN_CAPABLE_ROLES = ['super_admin', 'owner', 'manager', 'tenant'] as const;

export interface AuthenticatedUser {
  id: number;
  name: string;
  email: string;
  /** Backend role string. Never branched on — see the note above. */
  role: string;
  /** Human label supplied by the backend (`Roles::label`). */
  roleLabel: string | null;
  organisationId: number | null;
  phone: string | null;
  status: string;
  verificationStatus: string | null;
  photoPath: string | null;
  /**
   * Always empty against this backend — no permission list is returned.
   * Kept so the permission layer stays wired and lights up when one exists.
   */
  permissions: Permission[];
}

/**
 * Session lifecycle.
 *
 * `step-up-required` is retained but unreachable: the backend has no 2FA
 * endpoint (FR-IAM-006 is unimplemented). `revoked` is reachable — the role
 * middleware returns 403 "Account is not active" for a suspended user, and
 * login rejects a non-active status.
 */
export type SessionStatus =
  | 'anonymous'
  | 'authenticating'
  | 'authenticated'
  | 'step-up-required'
  | 'revoked';

export interface SessionState {
  status: SessionStatus;
  user: AuthenticatedUser | null;
  revocationReason?: 'forced-logout' | 'suspended' | 'expired';
}

export const ANONYMOUS_SESSION: SessionState = { status: 'anonymous', user: null };

/** Raw user payload as the backend serialises it. Mapped, never used directly. */
export interface BackendUserPayload {
  id: number;
  name: string;
  email: string;
  role: string;
  organization_id: number | null;
  phone: string | null;
  status: string | null;
  verification_status: string | null;
  photo_path: string | null;
}

export function mapUser(
  payload: BackendUserPayload,
  roleLabel: string | null,
): AuthenticatedUser {
  return {
    id: payload.id,
    name: payload.name,
    email: payload.email,
    role: payload.role,
    roleLabel,
    organisationId: payload.organization_id ?? null,
    phone: payload.phone ?? null,
    status: payload.status ?? 'active',
    verificationStatus: payload.verification_status ?? null,
    photoPath: payload.photo_path ?? null,
    // The backend returns no permissions. Not fabricated.
    permissions: [],
  };
}
