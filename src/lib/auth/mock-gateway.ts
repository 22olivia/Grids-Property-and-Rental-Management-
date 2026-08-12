import 'server-only';
import type { AuthGateway, AuthSession, Credentials } from './gateway';
import type { AuthenticatedUser } from './types';
import { ApiError } from '@/lib/api/types';

/**
 * ===========================================================================
 * DEMO AUTH — active only when NEXT_PUBLIC_DATA_SOURCE is not `http`.
 * ===========================================================================
 *
 * Lets the whole application be reviewed without a running Laravel instance.
 * Without it, route protection locks every authenticated screen behind a login
 * that cannot succeed, and 32 of 33 screens become undemonstrable offline.
 *
 * This is a FIXTURE, not an auth implementation:
 *   - it issues an obviously fake token that no real API would accept;
 *   - it grants NO permissions, because the backend returns none either
 *     (MI-11) — a demo session must not be more capable than a real one;
 *   - the roles it reports are the four the backend actually allows to sign
 *     in, so nothing here implies a capability the product does not have.
 *
 * It never runs when the real API is configured — see `src/lib/auth/index.ts`.
 * ===========================================================================
 */

const DEMO_TOKEN = 'demo-session-not-a-real-token';

/**
 * Mirrors the four roles `AuthController::login` permits. Any password is
 * accepted in demo mode; an unknown email is rejected so the error path is
 * demonstrable too.
 */
const DEMO_USERS: Record<string, { name: string; role: string; roleLabel: string }> = {
  'admin@rental.test': { name: 'Demo Super Admin', role: 'super_admin', roleLabel: 'Super Admin' },
  'owner@grids.test': { name: 'Demo Owner', role: 'owner', roleLabel: 'Owner' },
  'manager@grids.test': { name: 'Demo Manager', role: 'manager', roleLabel: 'Manager' },
  'tenant@grids.test': { name: 'Demo Tenant', role: 'tenant', roleLabel: 'Tenant' },
};

function toUser(email: string): AuthenticatedUser {
  const profile = DEMO_USERS[email]!;
  return {
    id: 1,
    name: profile.name,
    email,
    role: profile.role,
    roleLabel: profile.roleLabel,
    organisationId: 1,
    phone: null,
    status: 'active',
    verificationStatus: 'verified',
    photoPath: null,
    // Empty, exactly as the real /me returns.
    permissions: [],
  };
}

export const mockAuthGateway: AuthGateway = {
  async login(credentials: Credentials): Promise<AuthSession> {
    const email = credentials.email?.toLowerCase().trim();
    if (!email || !DEMO_USERS[email]) {
      // Same shape Laravel produces, so the login screen's error handling is
      // exercised rather than bypassed.
      throw new ApiError(
        422,
        [{ code: 'http_422', field: 'email', message: 'No account found with this email.' }],
        null,
      );
    }
    return { token: `${DEMO_TOKEN}:${email}`, user: toUser(email) };
  },

  async me(token: string): Promise<AuthenticatedUser> {
    const email = token.split(':')[1];
    if (!email || !DEMO_USERS[email]) {
      throw new ApiError(401, [{ code: 'http_401', message: 'Unauthenticated.' }], null);
    }
    return toUser(email);
  },

  async logout(): Promise<void> {
    // Nothing upstream to revoke.
  },
};
