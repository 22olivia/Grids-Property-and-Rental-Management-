import { NextResponse } from 'next/server';
import { ApiError } from '@/lib/api/types';
import { authGateway } from '@/lib/auth';
import { clearSession, readSession, writeSession } from '@/lib/auth/session';

/**
 * ===========================================================================
 * BFF authentication routes — wired to the real Sanctum backend.
 * ===========================================================================
 *
 * The only place the Sanctum token is handled. It goes into an httpOnly cookie
 * and is never returned to the browser.
 *
 * There is no `refresh` action: the backend has no refresh endpoint.
 * ===========================================================================
 */

function errorResponse(error: unknown) {
  if (error instanceof ApiError) {
    return NextResponse.json(
      { message: error.message, errors: error.errors },
      { status: error.status },
    );
  }
  return NextResponse.json({ message: 'Request failed.' }, { status: 500 });
}

export async function POST(
  request: Request,
  { params }: { params: Promise<{ action: string }> },
) {
  const { action } = await params;

  try {
    switch (action) {
      case 'login': {
        const credentials = await request.json();
        const session = await authGateway.login(credentials);
        await writeSession({ token: session.token });
        // Deliberately returns the user but NOT the token.
        return NextResponse.json({ user: session.user });
      }

      case 'logout': {
        const session = await readSession();
        if (session) {
          try {
            await authGateway.logout(session.token);
          } catch {
            // Best-effort upstream revocation. The local session is cleared
            // regardless, so a failing API cannot strand a signed-in user.
          }
        }
        await clearSession();
        return NextResponse.json({ user: null });
      }

      default:
        return NextResponse.json({ message: 'Unknown action.' }, { status: 404 });
    }
  } catch (error) {
    return errorResponse(error);
  }
}

export async function GET(
  _request: Request,
  { params }: { params: Promise<{ action: string }> },
) {
  const { action } = await params;
  if (action !== 'session') {
    return NextResponse.json({ message: 'Unknown action.' }, { status: 404 });
  }

  const session = await readSession();
  if (!session) return NextResponse.json({ status: 'anonymous', user: null });

  try {
    const user = await authGateway.me(session.token);
    // The backend rejects non-active accounts at login; a status change while
    // signed in surfaces here as a distinct state, not as "wrong password".
    if (user.status !== 'active') {
      await clearSession();
      return NextResponse.json({ status: 'revoked', user: null, revocationReason: 'suspended' });
    }
    return NextResponse.json({ status: 'authenticated', user });
  } catch (error) {
    if (error instanceof ApiError && error.isUnauthenticated) {
      await clearSession();
      return NextResponse.json({ status: 'revoked', user: null, revocationReason: 'expired' });
    }
    return NextResponse.json({ status: 'anonymous', user: null });
  }
}
