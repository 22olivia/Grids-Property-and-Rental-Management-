import 'server-only';
import { AsyncLocalStorage } from 'node:async_hooks';

/**
 * Request-scoped Sanctum token.
 *
 * The alternative was threading a token through every repository method
 * signature, which would put an auth concern into 14 domain-shaped functions
 * and make the interface harder to implement for mocks. AsyncLocalStorage
 * keeps the token where it belongs — the transport layer — while the
 * repository stays a plain data interface.
 *
 * Server-only, and scoped to a single request: there is no cross-request
 * leakage because each BFF handler opens its own context.
 */
const tokenStore = new AsyncLocalStorage<string>();

export function withToken<T>(token: string, run: () => Promise<T>): Promise<T> {
  return tokenStore.run(token, run);
}

export function currentToken(): string | undefined {
  return tokenStore.getStore();
}
