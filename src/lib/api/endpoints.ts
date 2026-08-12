/**
 * ===========================================================================
 * GPMS API endpoint registry — VERIFIED against the backend source.
 * ===========================================================================
 *
 * Every path below was read from `routes/api.php` in the GPMS Laravel backend
 * (Laravel 13 + Sanctum, reviewed 10 Aug 2026). Nothing here is guessed.
 *
 * Base path is `/api/v1` and lives in GPMS_API_BASE_URL, so paths are relative
 * to it.
 *
 * Endpoints that the backend does NOT implement stay `null` and throw
 * MissingApiContractError when resolved. That is how a screen fails loudly
 * instead of silently calling a fabricated URL.
 * ===========================================================================
 */

export class MissingApiContractError extends Error {
  constructor(public readonly key: string) {
    super(
      `MISSING API CONTRACT: no published endpoint for "${key}". ` +
        `The GPMS backend does not implement this capability yet. ` +
        `See docs/BACKEND-CONTRACT-REQUEST.md.`,
    );
    this.name = 'MissingApiContractError';
  }
}

interface EndpointDefinition {
  /** Real path, verified in routes/api.php. `null` when not implemented. */
  path: string | null;
  /** Where it was verified, or why it is absent. */
  source: string;
}

export const endpoints = {
  // ---- Auth (AuthController) — VERIFIED ----------------------------------
  'auth.login': { path: '/login', source: 'routes/api.php' },
  'auth.register': { path: '/register', source: 'routes/api.php' },
  'auth.logout': { path: '/logout', source: 'routes/api.php' },
  'auth.me': { path: '/me', source: 'routes/api.php' },
  'auth.forgotPassword': { path: '/forgot-password', source: 'routes/api.php' },
  'auth.resetPassword': { path: '/reset-password', source: 'routes/api.php' },
  'auth.changePassword': { path: '/change-password', source: 'routes/api.php' },
  'auth.profile': { path: '/profile', source: 'routes/api.php' },
  'auth.loginHistory': { path: '/login-history', source: 'routes/api.php' },
  health: { path: '/health', source: 'routes/api.php' },

  /**
   * NOT IMPLEMENTED — Sanctum issues a single long-lived personal access
   * token. There is no refresh endpoint and no rotation.
   * This CONFLICTS with FR-API-002 (Must): "short-lived access tokens and
   * refresh-token rotation". Recorded, not worked around.
   */
  'auth.refresh': { path: null, source: 'ABSENT — Sanctum has no refresh (conflicts with FR-API-002)' },

  // ---- Assets (PropertyController / BuildingController / RentalUnit) -----
  'properties.index': { path: '/properties', source: 'apiResource properties' },
  'properties.show': { path: '/properties/{id}', source: 'apiResource properties' },
  'properties.store': { path: '/properties', source: 'apiResource properties' },
  'properties.update': { path: '/properties/{id}', source: 'apiResource properties' },
  'properties.destroy': { path: '/properties/{id}', source: 'apiResource properties' },

  'buildings.index': { path: '/buildings', source: 'apiResource buildings' },
  'buildings.show': { path: '/buildings/{id}', source: 'apiResource buildings' },
  'buildings.store': { path: '/buildings', source: 'apiResource buildings' },
  'buildings.update': { path: '/buildings/{id}', source: 'apiResource buildings' },
  'buildings.destroy': { path: '/buildings/{id}', source: 'apiResource buildings' },
  // Verified route, no UI yet: floors are read-only in the console because the
  // backend has no floor update or delete endpoint, so a create-only editor
  // would be a one-way door for the user.
  'buildings.storeFloor': { path: '/buildings/{id}/floors', source: 'routes/api.php' },

  'units.index': { path: '/rental-units', source: 'GET /rental-units' },
  'units.show': { path: '/rental-units/{id}', source: 'apiResource rental-units' },
  'units.store': { path: '/rental-units', source: 'apiResource rental-units' },
  'units.update': { path: '/rental-units/{id}', source: 'apiResource rental-units' },
  'units.destroy': { path: '/rental-units/{id}', source: 'apiResource rental-units' },
  'units.publish': { path: '/rental-units/{id}/publish', source: 'routes/api.php' },

  // ---- Verified but no frontend yet (kept for later modules) -------------
  'owners.index': { path: '/owners', source: 'apiResource owners' },
  'tenants.index': { path: '/tenants', source: 'apiResource tenants' },
  'leases.index': { path: '/leases', source: 'apiResource leases' },
  'invoices.index': { path: '/invoices', source: 'apiResource invoices' },
  'payments.index': { path: '/payments', source: 'apiResource payments' },
  'maintenance.index': { path: '/maintenance-requests', source: 'apiResource' },
  'dashboard.show': { path: '/dashboard', source: 'GET /dashboard' },
  'search.admin': { path: '/admin/search', source: 'GET /admin/search' },

  // ---- Confirmed ABSENT from the backend ---------------------------------
  // Asset capabilities the SRS requires but the backend has no route for.
  'assets.statusTimeline': { path: null, source: 'ABSENT — no endpoint (FR-AST-003)' },
  'assets.changeEvents': { path: null, source: 'ABSENT — ActivityLog model exists, no route (FR-AST-008)' },
  'assets.duplicates': { path: null, source: 'ABSENT — no endpoint (FR-AST-007)' },
  'assets.customFields': { path: null, source: 'ABSENT — no endpoint (FR-AST-006)' },

  // Listings: no Listing entity exists. GET /listings is an inline closure
  // over RentalUnit and is read-only public data, not a listing lifecycle.
  'listings.index': { path: null, source: 'ABSENT — no Listing entity (FR-LST-001..008)' },

  // CRM: zero migrations, zero controllers.
  'crm.leads': { path: null, source: 'ABSENT — no CRM in backend (FR-CRM-001..008)' },
} as const satisfies Record<string, EndpointDefinition>;

export type EndpointKey = keyof typeof endpoints;

/** Resolve an endpoint path, substituting `{id}`-style parameters. */
export function resolveEndpoint(
  key: EndpointKey,
  params?: Record<string, string | number>,
): string {
  const definition = endpoints[key];
  if (!definition.path) throw new MissingApiContractError(key);

  let path: string = definition.path;
  for (const [name, value] of Object.entries(params ?? {})) {
    path = path.replace(`{${name}}`, encodeURIComponent(String(value)));
  }
  if (path.includes('{')) {
    throw new Error(`Endpoint "${key}" still has unresolved parameters: ${path}`);
  }
  return path;
}

export function isEndpointAvailable(key: EndpointKey): boolean {
  return endpoints[key].path !== null;
}
