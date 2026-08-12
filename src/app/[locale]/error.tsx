'use client';

import { useEffect } from 'react';
import { useTranslations } from 'next-intl';
import { ErrorState } from '@/design-system/ui';

/**
 * Recoverable route-level error boundary.
 * `digest` is Next.js's server-error identifier and is shown so a user can
 * quote it — the same role correlation_id plays for API failures.
 */
export default function RouteError({
  error,
  reset,
}: {
  error: Error & { digest?: string };
  reset: () => void;
}) {
  const t = useTranslations('errors');

  useEffect(() => {
    // MISSING INFORMATION (MI-16): no error-reporting provider has been
    // selected. EN-DEV-004 covers centralised logs and alerts on the backend;
    // no frontend equivalent is specified. Console until then.
    console.error(error);
  }, [error]);

  return (
    <main id="main-content" className="flex min-h-dvh items-center justify-center p-6">
      <ErrorState
        title={t('unexpected.title')}
        description={t('unexpected.description')}
        retryLabel={t('unexpected.retry')}
        onRetry={reset}
        correlationId={error.digest ?? null}
        correlationLabel={t('reference')}
      />
    </main>
  );
}
