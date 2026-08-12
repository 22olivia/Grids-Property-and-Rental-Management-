import 'server-only';
import { cookies } from 'next/headers';

/**
 * ===========================================================================
 * Server-side session storage — Sanctum.
 * ===========================================================================
 *
 * The Sanctum token is held in an httpOnly, Secure, SameSite cookie and never
 * reaches client JavaScript. The BFF attaches it server-side. This removes the
 * XSS token-theft class that FR-SEC-001 (OWASP Top 10) targets, and matters
 * MORE here than it would with rotation, because the token is long-lived.
 *
 * ---------------------------------------------------------------------------
 * The single-flight refresh machinery that previously lived here has been
 * REMOVED, not disabled.
 *
 * The backend issues one long-lived personal access token with no refresh
 * endpoint and no rotation. Keeping refresh code that can never run would be
 * dead weight that reads as though rotation is handled. It is not.
 *
 * FR-API-002 (Must) requires short-lived tokens with refresh rotation. That
 * requirement is currently UNMET by the backend — recorded in the defect
 * report, not papered over here.
 * ---------------------------------------------------------------------------
 */

const COOKIE_NAME = process.env.SESSION_COOKIE_NAME ?? 'gpms_session';

export interface StoredSession {
  token: string;
}

export async function readSession(): Promise<StoredSession | null> {
  const store = await cookies();
  const raw = store.get(COOKIE_NAME)?.value;
  if (!raw) return null;
  try {
    const parsed = JSON.parse(raw) as StoredSession;
    return parsed.token ? parsed : null;
  } catch {
    return null;
  }
}

export async function writeSession(session: StoredSession): Promise<void> {
  const store = await cookies();
  store.set(COOKIE_NAME, JSON.stringify(session), {
    httpOnly: true,
    secure: process.env.NODE_ENV === 'production',
    sameSite: 'lax',
    path: '/',
    // Sanctum tokens do not expire by default, so this cookie lifetime is the
    // effective session length the frontend enforces.
    maxAge: 60 * 60 * 24 * 14,
  });
}

export async function clearSession(): Promise<void> {
  const store = await cookies();
  store.delete(COOKIE_NAME);
}
