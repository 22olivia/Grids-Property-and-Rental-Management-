import type { AuthenticatedUser } from './types';

/**
 * Authentication gateway.
 *
 * The application depends on this interface, never on a transport. The
 * Sanctum implementation lives in `sanctum-gateway.ts`.
 *
 * ---------------------------------------------------------------------------
 * VERIFIED against the backend (AuthController, routes/api.php):
 *
 *   POST /login  { email, password }
 *     → { message, user, token, role_label }
 *   GET  /me     (Bearer)
 *     → { user, role_label }
 *   POST /logout (Bearer)
 *
 * `refresh()` is deliberately absent. Sanctum issues one long-lived personal
 * access token; there is no refresh endpoint and no rotation. This CONFLICTS
 * with FR-API-002 (Must) — "short-lived access tokens and refresh-token
 * rotation" — and the conflict is recorded rather than worked around.
 * ---------------------------------------------------------------------------
 */

export interface Credentials {
  email: string;
  password: string;
}

export interface AuthSession {
  /** Sanctum plain-text personal access token. */
  token: string;
  user: AuthenticatedUser;
}

export interface AuthGateway {
  login(credentials: Credentials): Promise<AuthSession>;
  logout(token: string): Promise<void>;
  me(token: string): Promise<AuthenticatedUser>;
}
