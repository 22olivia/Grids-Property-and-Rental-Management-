import createMiddleware from 'next-intl/middleware';
import { NextResponse, type NextRequest } from 'next/server';
import { routing } from '@/lib/i18n/routing';
import { locales, defaultLocale } from '@/lib/i18n/config';

const handleI18n = createMiddleware(routing);

const SESSION_COOKIE = process.env.SESSION_COOKIE_NAME ?? 'gpms_session';

/**
 * Locale routing plus a first line of route protection.
 *
 * ---------------------------------------------------------------------------
 * The session cookie's PRESENCE is checked here, not its validity. That is a
 * deliberate division:
 *
 *   middleware  cheap redirect so an unauthenticated visitor never renders the
 *               console shell and never fires a burst of doomed API calls;
 *   BFF         the real boundary — it holds the token and the upstream API
 *               rejects an invalid one with 401;
 *   SessionLoader  reconciles the client once /me answers, and redirects on a
 *               revoked or expired session.
 *
 * A forged cookie gets past this check and straight into a 401 from the API.
 * That is correct: middleware is a routing convenience, and treating it as the
 * authorisation boundary is how people end up trusting the client.
 * ---------------------------------------------------------------------------
 *
 * NOT IMPLEMENTED — custom domain / microsite host resolution (FR-MKT-008).
 * The provisioning model is unspecified (MI-15).
 */

/** Segments that require a session. */
const PROTECTED_SEGMENTS = ['/console', '/platform', '/tenant', '/owner', '/account'];

function stripLocale(pathname: string): string {
  for (const locale of locales) {
    if (pathname === `/${locale}`) return '/';
    if (pathname.startsWith(`/${locale}/`)) return pathname.slice(locale.length + 1);
  }
  return pathname;
}

function localeOf(pathname: string): string {
  for (const locale of locales) {
    if (pathname === `/${locale}` || pathname.startsWith(`/${locale}/`)) return locale;
  }
  return defaultLocale;
}

export default function middleware(request: NextRequest) {
  const { pathname, search } = request.nextUrl;
  const path = stripLocale(pathname);

  if (PROTECTED_SEGMENTS.some((segment) => path === segment || path.startsWith(`${segment}/`))) {
    const hasSession = request.cookies.has(SESSION_COOKIE);
    if (!hasSession) {
      const locale = localeOf(pathname);
      const url = request.nextUrl.clone();
      url.pathname = `/${locale}/login`;
      url.search = '';
      // Preserve where they were going, so sign-in returns them there.
      url.searchParams.set('next', `${pathname}${search}`);
      return NextResponse.redirect(url);
    }
  }

  return handleI18n(request);
}

export const config = {
  matcher: ['/((?!api|_next|_vercel|.*\\..*).*)'],
};
