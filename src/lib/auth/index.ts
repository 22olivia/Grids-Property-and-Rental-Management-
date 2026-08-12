import { activeDataSource } from '@/lib/data/repository';
import type { AuthGateway } from './gateway';
import { sanctumAuthGateway } from './sanctum-gateway';
import { mockAuthGateway } from './mock-gateway';

/**
 * Active authentication binding.
 *
 * `http` uses the real Sanctum backend. Anything else uses the demo gateway so
 * the application can be reviewed without a running Laravel instance — see
 * mock-gateway.ts for why that is a fixture and not a shortcut.
 */
export const AUTH_IS_MOCK = activeDataSource() !== 'http';

export const authGateway: AuthGateway = AUTH_IS_MOCK ? mockAuthGateway : sanctumAuthGateway;

export type { AuthGateway, Credentials, AuthSession } from './gateway';
export { MissingApiContractError } from '@/lib/api/endpoints';
export type { AuthenticatedUser, SessionState, SessionStatus } from './types';
export { ANONYMOUS_SESSION, BACKEND_ROLES, LOGIN_CAPABLE_ROLES } from './types';
