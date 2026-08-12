/**
 * ===========================================================================
 * API response and error types — matched to the ACTUAL GPMS backend.
 * ===========================================================================
 *
 * SRS §12 specifies a single envelope with `data`, `meta`, `links`, `errors`
 * and `correlation_id`. **The backend does not implement it.** Four shapes are
 * in use, verified in the controllers:
 *
 *   index   raw Laravel paginator: { data: [], current_page, per_page, total, … }
 *   store   { message, data }
 *   show    { data }  (rental-units/show adds { data, meta })
 *   login   { message, user, token, role_label }
 *
 * These types describe reality. When the backend adopts the SRS envelope, this
 * file and `client.ts` are the only places that change.
 * ===========================================================================
 */

/** Laravel `LengthAwarePaginator` JSON shape. */
export interface LaravelPaginator<T> {
  data: T[];
  current_page: number;
  per_page: number;
  total: number;
  last_page: number;
  from: number | null;
  to: number | null;
}

export interface DataEnvelope<T> {
  data: T;
  message?: string;
  meta?: Record<string, unknown>;
}

export interface ApiErrorItem {
  code: string;
  message: string;
  field?: string;
}

/**
 * Normalised client-side error.
 *
 * `correlationId` stays on the type but will be `null` against this backend —
 * no endpoint returns one. Keeping it costs nothing and means the UI lights up
 * automatically if the backend adds it (see BACKEND_DEFECT_REPORT observation 7).
 */
export class ApiError extends Error {
  constructor(
    public readonly status: number,
    public readonly errors: ApiErrorItem[],
    public readonly correlationId: string | null,
  ) {
    super(errors[0]?.message ?? `Request failed with status ${status}`);
    this.name = 'ApiError';
  }

  /**
   * Build from Laravel's validation body:
   *   { "message": "...", "errors": { "email": ["msg", ...] } }
   *
   * Note the shape difference from SRS §12, which expects an ARRAY of
   * `{ field, message, code }`. Laravel gives an object keyed by field with an
   * array of strings. Converted here so nothing downstream has to know.
   */
  static fromLaravel(status: number, body: unknown): ApiError {
    const payload = (body ?? {}) as {
      message?: string;
      errors?: Record<string, string[] | string>;
    };

    const items: ApiErrorItem[] = [];

    if (payload.errors && typeof payload.errors === 'object') {
      for (const [field, messages] of Object.entries(payload.errors)) {
        const list = Array.isArray(messages) ? messages : [messages];
        for (const message of list) {
          // Laravel provides no machine code, so one is derived from the
          // status. It is a label for our own branching, never displayed.
          items.push({ code: `http_${status}`, message, field });
        }
      }
    }

    if (items.length === 0) {
      items.push({
        code: `http_${status}`,
        message: payload.message ?? `Request failed (${status}).`,
      });
    }

    return new ApiError(status, items, null);
  }

  /** Validation errors keyed by field path, for binding onto a form. */
  get fieldErrors(): Record<string, string> {
    const result: Record<string, string> = {};
    for (const error of this.errors) {
      if (error.field && !result[error.field]) result[error.field] = error.message;
    }
    return result;
  }

  get isValidation(): boolean {
    return this.status === 422;
  }
  get isUnauthenticated(): boolean {
    return this.status === 401;
  }
  get isForbidden(): boolean {
    return this.status === 403;
  }
  get isNotFound(): boolean {
    return this.status === 404;
  }
  get isConflict(): boolean {
    return this.status === 409;
  }
  get isRateLimited(): boolean {
    return this.status === 429;
  }
  get isServer(): boolean {
    return this.status >= 500;
  }
}

export class NetworkError extends Error {
  constructor(cause?: unknown) {
    super('The request could not be completed.');
    this.name = 'NetworkError';
    this.cause = cause;
  }
}
