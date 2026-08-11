import 'server-only';
import { NextResponse } from 'next/server';
import { ApiError, NetworkError } from './types';
import { MissingApiContractError } from './endpoints';
import { readSession } from '@/lib/auth/session';

/**
 * ===========================================================================
 * BFF helpers.
 * ===========================================================================
 *
 * Every browser→API call goes through a Next.js route handler so the Sanctum
 * token stays in the httpOnly cookie and never reaches client JavaScript.
 *
 * These are NOT a generic proxy. Each route handler names the specific
 * repository method it calls, so there is no path the browser can use to reach
 * an arbitrary upstream URL — an open proxy would hand any authenticated user
 * the whole API surface regardless of what the UI exposes.
 * ===========================================================================
 */

/** Reads the Sanctum token, or returns a 401 response to send straight back. */
export async function requireToken(): Promise<
  { token: string } | { response: NextResponse }
> {
  const session = await readSession();
  if (!session) {
    return {
      response: NextResponse.json({ message: 'Unauthenticated.' }, { status: 401 }),
    };
  }
  return { token: session.token };
}

/** Maps a thrown error onto the response shape the browser repository expects. */
export function toErrorResponse(error: unknown): NextResponse {
  if (error instanceof MissingApiContractError) {
    return NextResponse.json(
      { message: error.message, errors: [{ code: 'missing_api_contract', message: error.message }] },
      { status: 501 },
    );
  }
  if (error instanceof ApiError) {
    return NextResponse.json({ message: error.message, errors: error.errors }, { status: error.status });
  }
  if (error instanceof NetworkError) {
    return NextResponse.json({ message: 'The API could not be reached.' }, { status: 503 });
  }
  return NextResponse.json({ message: 'Request failed.' }, { status: 500 });
}

/** Turns a request's search params into a ListQuery. */
export function readListQuery(request: Request) {
  const url = new URL(request.url);
  const filters: Record<string, string> = {};
  for (const [key, value] of url.searchParams.entries()) {
    if (!['page', 'perPage'].includes(key) && value) filters[key] = value;
  }
  return {
    page: Number(url.searchParams.get('page') ?? 1),
    perPage: Number(url.searchParams.get('perPage') ?? 20),
    filters,
  };
}
