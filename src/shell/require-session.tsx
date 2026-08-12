'use client';

import { useEffect, type ReactNode } from 'react';
import { useTranslations } from 'next-intl';
import { LoadingState } from '@/design-system/ui';
import { useSession } from '@/lib/permissions/permission-provider';
import { usePathname, useRouter } from '@/lib/i18n/routing';

/**
 * Client-side session guard for authenticated surfaces.
 *
 * The middleware already redirects when no cookie is present. This handles the
 * cases it cannot see: a cookie whose token the API has revoked, and an
 * account suspended while signed in. Both surface as `revoked` from the BFF,
 * and both must send the user to sign-in rather than leaving them on a shell
 * where every request 401s.
 */
export function RequireSession({ children }: { children: ReactNode }) {
  const session = useSession();
  const router = useRouter();
  const pathname = usePathname();
  const tc = useTranslations('common');

  const blocked = session.status === 'anonymous' || session.status === 'revoked';

  useEffect(() => {
    if (!blocked) return;
    const params = new URLSearchParams({ next: pathname });
    if (session.status === 'revoked' && session.revocationReason) {
      // Lets the sign-in screen say why, instead of implying bad credentials.
      params.set('reason', session.revocationReason);
    }
    router.replace(`/login?${params.toString()}`);
  }, [blocked, pathname, router, session.status, session.revocationReason]);

  if (blocked) return <LoadingState label={tc('loading')} />;
  return <>{children}</>;
}
