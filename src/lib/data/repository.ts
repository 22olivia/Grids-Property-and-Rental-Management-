/**
 * Repository pattern for data access.
 *
 * Every module talks to an interface, never to the API client directly. Two
 * implementations exist per module:
 *
 *   Http*Repository   the real one. Throws MissingApiContractError until the
 *                     endpoint is published — it never guesses a URL.
 *   Mock*Repository   in-memory fixtures, for UI development only.
 *
 * The binding is chosen by NEXT_PUBLIC_DATA_SOURCE. When the contract lands
 * (US-API-006, Sprint 12), implement the Http repository and flip the flag —
 * no screen, hook or component changes, because nothing above this layer knows
 * which implementation it is talking to.
 */

export type DataSource = 'mock' | 'http';

export function activeDataSource(): DataSource {
  return process.env.NEXT_PUBLIC_DATA_SOURCE === 'http' ? 'http' : 'mock';
}

/** Standard list query shape. Mirrors what SRS §12 promises the API supports. */
export interface ListQuery {
  page?: number;
  perPage?: number;
  /** Cursor pagination is also modelled — the convention is undecided (MI-03). */
  cursor?: string | null;
  search?: string;
  sort?: string;
  direction?: 'asc' | 'desc';
  filters?: Record<string, string | undefined>;
}

export interface ListResult<T> {
  items: T[];
  total: number | null;
  page: number;
  perPage: number;
  nextCursor?: string | null;
}

/**
 * Marks a value the UI is displaying from mock fixtures rather than the API.
 * Surfaced visibly in the interface so nobody mistakes fixture data for real
 * data during review or a demo.
 */
/**
 * True when the application is running without the real API.
 *
 * Replaces the old IS_MOCK_DATA global: data sources are now per-module, so a
 * single flag can no longer answer "is this screen showing fixtures?". This
 * one answers only "is the whole app in offline demo mode?", which is a
 * different and still useful question.
 */
export const DEMO_MODE = activeDataSource() !== 'http';
