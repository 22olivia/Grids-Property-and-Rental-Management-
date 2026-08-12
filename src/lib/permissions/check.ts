import type { Permission, PermissionMode } from './types';

/**
 * Permission evaluation.
 *
 * IMPORTANT — these checks are for USABILITY, not security.
 *
 * SRS §16 states it directly: "Enforce authorization in APIs and query
 * scopes; hiding interface controls is not sufficient." FR-SEC-004 requires
 * authorization tests verifying isolation between companies and roles, and
 * AC-01 requires that a user cannot reach another company's record "through
 * UI, API or identifier manipulation".
 *
 * So the API is the security boundary. These helpers exist so we don't show
 * someone a button that will return 403 — nothing more. No check here may be
 * treated as protecting data.
 */

export function hasPermission(
  granted: readonly Permission[],
  required: Permission,
): boolean {
  return granted.includes(required);
}

export function checkPermissions(
  granted: readonly Permission[],
  required: readonly Permission[],
  mode: PermissionMode = 'all',
): boolean {
  if (required.length === 0) return true;
  return mode === 'all'
    ? required.every((p) => granted.includes(p))
    : required.some((p) => granted.includes(p));
}

/**
 * Scope is separate from permission and is applied SERVER-SIDE.
 *
 * An owner sees only their portfolio, a tenant only their lease, an agent
 * possibly only their branch (FR-IAM-004). The frontend must never build
 * client-side filtering that implies it is enforcing scope — a list endpoint
 * returns what the caller is entitled to see, and that is the contract.
 *
 * This function exists only to document the boundary and to give a single
 * place to attach organisation context to a request.
 */
export interface RequestScope {
  organisationId: string | null;
  branchId: string | null;
}
