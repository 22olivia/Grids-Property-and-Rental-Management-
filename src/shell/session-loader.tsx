'use client';

import { useEffect, useState, type ReactNode } from 'react';
import { SessionProvider } from '@/lib/permissions/permission-provider';
import { ANONYMOUS_SESSION, type SessionState } from '@/lib/auth/types';

/**
 * Loads the session from the BFF (`GET /api/auth/session`) and provides it.
 *
 * The BFF calls `/me` upstream with the httpOnly-cookie token; the browser
 * never holds a token. A 401 upstream clears the cookie and reports `revoked`,
 * so a suspended or token-revoked user gets an accurate message rather than
 * "wrong password".
 */
export function SessionLoader({ children }: { children: ReactNode }) {
  const [session, setSession] = useState<SessionState>(ANONYMOUS_SESSION);

  useEffect(() => {
    let cancelled = false;
    fetch('/api/auth/session', { credentials: 'same-origin' })
      .then((response) => (response.ok ? response.json() : ANONYMOUS_SESSION))
      .then((data: SessionState) => {
        if (!cancelled) setSession(data ?? ANONYMOUS_SESSION);
      })
      .catch(() => {
        // A failed session probe means anonymous, not an error screen.
        if (!cancelled) setSession(ANONYMOUS_SESSION);
      });
    return () => {
      cancelled = true;
    };
  }, []);

  return <SessionProvider session={session}>{children}</SessionProvider>;
}
