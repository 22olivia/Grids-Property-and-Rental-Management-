/**
 * ===========================================================================
 * PERMISSION MODEL — deliberately open
 * ===========================================================================
 *
 * FR-IAM-002 (Must): "enforce role-based and permission-based access at UI,
 * API and data-query levels."
 * FR-IAM-005 (Must): roles are CONFIGURABLE.
 *
 * Because roles are configurable, role names are DATA, not code. Nothing in
 * this codebase may branch on a role name. All UI checks go through
 * permission strings supplied by the API in the `/me` response.
 *
 * MISSING INFORMATION (MI-11): no permission taxonomy exists in the SRS, the
 * backlog PDF or the workbook. Roles are named; individual permission
 * strings, their granularity and their naming convention are undefined.
 *
 * `Permission` is therefore a BRANDED STRING, not a union of literals.
 * A union would require inventing the permission list, which would then be
 * wrong in a way that is expensive to unpick. A branded string gives type
 * safety at boundaries (a raw string cannot be passed by accident) while
 * leaving the vocabulary to the backend team.
 *
 * WHEN THE TAXONOMY IS PUBLISHED: change `Permission` to a union of the real
 * literals and populate PERMISSIONS below. Every call site then type-checks
 * against the real list, and typos become compile errors.
 * ===========================================================================
 */

declare const permissionBrand: unique symbol;

export type Permission = string & { readonly [permissionBrand]?: never };

export function permission(value: string): Permission {
  return value as Permission;
}

/**
 * Permission constants.
 *
 * INTENTIONALLY EMPTY. Populating this with guessed strings such as
 * 'lease.approve' would be inventing a requirement. Add entries only when
 * the backend publishes the taxonomy.
 */
export const PERMISSIONS = {} as const satisfies Record<string, Permission>;

/**
 * Role identifiers.
 *
 * ALSO INTENTIONALLY EMPTY — and this one needs stating clearly.
 *
 * The source documents contain three different role vocabularies:
 *   - SRS §5 names 11 stakeholder roles
 *   - FR-IAM-005 names 8 configurable roles
 *   - backlog epic "Primary Actors" fields introduce ~10 further names
 *     (Listing Manager, Leasing Officer, Customer Service, Marketing
 *      Manager, Compliance Officer, Business Manager, Seller, …)
 *
 * Roughly 21 distinct actor names against 8 configurable roles. Three SRS §5
 * roles have no counterpart in FR-IAM-005 at all: Developer/Agency,
 * Support/Auditor, and Buyer/Renter/Public User. E10 additionally lists
 * "Vendor" separately from "Maintainer".
 *
 * Hardcoding any of these would embed an unresolved scope decision in the
 * codebase. See docs/UNRESOLVED-ROLES.md for the full register and the
 * questions pending with the CEO.
 */
export const ROLES = {} as const satisfies Record<string, string>;

/** How multiple required permissions combine. */
export type PermissionMode = 'all' | 'any';
