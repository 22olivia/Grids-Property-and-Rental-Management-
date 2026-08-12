import 'server-only';
import { createServerApiClient } from '@/lib/api/client';
import type { AuthGateway, AuthSession, Credentials } from './gateway';
import { mapUser, type AuthenticatedUser, type BackendUserPayload } from './types';

/**
 * Sanctum implementation — VERIFIED against AuthController.
 *
 * Response shapes copied from the controller, not assumed:
 *   login → { message, user, token, role_label }
 *   me    → { user, role_label }
 */

interface LoginResponse {
  message: string;
  user: BackendUserPayload;
  token: string;
  role_label: string | null;
}

interface MeResponse {
  user: BackendUserPayload;
  role_label: string | null;
}

export const sanctumAuthGateway: AuthGateway = {
  async login(credentials: Credentials): Promise<AuthSession> {
    const client = createServerApiClient();
    const response = await client.request<LoginResponse>('auth.login', {
      method: 'POST',
      body: { email: credentials.email, password: credentials.password },
    });
    return {
      token: response.token,
      user: mapUser(response.user, response.role_label),
    };
  },

  async me(token: string): Promise<AuthenticatedUser> {
    const client = createServerApiClient();
    const response = await client.request<MeResponse>('auth.me', { accessToken: token });
    return mapUser(response.user, response.role_label);
  },

  async logout(token: string): Promise<void> {
    const client = createServerApiClient();
    await client.request<{ message: string }>('auth.logout', {
      method: 'POST',
      accessToken: token,
    });
  },
};
