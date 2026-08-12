import 'server-only';
import { ApiError, NetworkError, type LaravelPaginator } from './types';
import { resolveEndpoint, type EndpointKey } from './endpoints';
import type { ListResult } from '@/lib/data/repository';
import type { Locale } from '@/lib/i18n/config';
import { currentToken } from './with-token';

/**
 * ===========================================================================
 * GPMS API client — matched to the real backend.
 * ===========================================================================
 *
 * Verified characteristics:
 *   - Laravel 13 + Sanctum personal access tokens
 *   - `Authorization: Bearer {token}` on authenticated requests
 *   - page/`per_page` pagination, no cursor
 *   - Laravel validation errors: { message, errors: { field: [msg] } }
 *   - decimal money serialised as STRINGS ("1500.00")
 *   - UTC ISO-8601 timestamps
 *
 * Server-only. The access token never reaches the browser: it is held in an
 * httpOnly cookie by the BFF and attached here, server-side.
 *
 * Deliberately narrow: transport only. It does not transform business data or
 * aggregate endpoints — SRS §6 forbids reimplementing business rules in
 * clients, and every transformation here is a place the two can disagree.
 * ===========================================================================
 */

export interface RequestOptions {
  method?: 'GET' | 'POST' | 'PUT' | 'PATCH' | 'DELETE';
  body?: unknown;
  query?: Record<string, string | number | boolean | undefined>;
  params?: Record<string, string | number>;
  locale?: Locale;
  accessToken?: string;
  signal?: AbortSignal;
}

export interface ApiClientConfig {
  baseUrl: string;
  timeoutMs: number;
}

export class ApiClient {
  constructor(private readonly config: ApiClientConfig) {}

  /**
   * Callers pass a registry KEY, never a URL. There is no way to reach an
   * arbitrary path through this client, which is what keeps fabricated
   * endpoints out. Unimplemented keys throw MissingApiContractError.
   */
  async request<T>(key: EndpointKey, options: RequestOptions = {}): Promise<T> {
    const path = resolveEndpoint(key, options.params);
    const url = this.buildUrl(path, options.query);

    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), this.config.timeoutMs);

    const headers: Record<string, string> = {
      Accept: 'application/json',
    };
    if (options.body !== undefined) headers['Content-Type'] = 'application/json';
    // Explicit token wins; otherwise take the request-scoped one set by the
    // BFF handler. Either way the token is only ever read server-side.
    const token = options.accessToken ?? currentToken();
    if (token) headers['Authorization'] = `Bearer ${token}`;
    // The backend is currently English-only (APP_LOCALE=en) so this has no
    // effect yet, but it costs nothing and is correct the moment it localises.
    if (options.locale) headers['Accept-Language'] = options.locale;

    let response: Response;
    try {
      response = await fetch(url, {
        method: options.method ?? 'GET',
        headers,
        body: options.body !== undefined ? JSON.stringify(options.body) : undefined,
        signal: options.signal ?? controller.signal,
        cache: 'no-store',
      });
    } catch (cause) {
      throw new NetworkError(cause);
    } finally {
      clearTimeout(timeout);
    }

    const text = await response.text();
    let payload: unknown = null;
    if (text) {
      try {
        payload = JSON.parse(text);
      } catch {
        throw new ApiError(
          response.status,
          [{ code: 'invalid_response', message: 'The server returned an unreadable response.' }],
          null,
        );
      }
    }

    if (!response.ok) {
      // Laravel's shape, converted once, here.
      throw ApiError.fromLaravel(response.status, payload);
    }

    return payload as T;
  }

  private buildUrl(path: string, query?: RequestOptions['query']): string {
    const base = this.config.baseUrl.endsWith('/')
      ? this.config.baseUrl.slice(0, -1)
      : this.config.baseUrl;
    const url = new URL(`${base}${path}`);
    if (query) {
      for (const [key, value] of Object.entries(query)) {
        if (value !== undefined && value !== '') url.searchParams.set(key, String(value));
      }
    }
    return url.toString();
  }
}

/**
 * Normalise a Laravel paginator into the shape the frontend's list screens use.
 *
 * The backend returns page-based pagination only (19 `paginate()` calls, zero
 * `cursorPaginate`), so cursor support has been removed rather than carried
 * as dead weight.
 */
export function fromPaginator<TSource, TResult>(
  paginator: LaravelPaginator<TSource>,
  map: (row: TSource) => TResult,
): ListResult<TResult> {
  return {
    items: (paginator.data ?? []).map(map),
    total: paginator.total ?? null,
    page: paginator.current_page ?? 1,
    perPage: paginator.per_page ?? 20,
  };
}

export function createServerApiClient(): ApiClient {
  const baseUrl = process.env.GPMS_API_BASE_URL;
  if (!baseUrl) {
    throw new Error(
      'GPMS_API_BASE_URL is not set. Expected the API base including the version ' +
        'prefix, e.g. http://127.0.0.1:8000/api/v1 — see .env.example.',
    );
  }
  return new ApiClient({
    baseUrl,
    timeoutMs: Number(process.env.GPMS_API_TIMEOUT_MS ?? 15000),
  });
}
