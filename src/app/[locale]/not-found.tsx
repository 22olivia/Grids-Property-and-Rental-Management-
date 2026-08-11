'use client';

import { useTranslations } from 'next-intl';
import { useRouter } from '@/lib/i18n/routing';
import { EmptyState } from '@/design-system/ui';

export default function NotFound() {
  const t = useTranslations('errors');
  const router = useRouter();

  return (
    <main id="main-content" className="flex min-h-dvh items-center justify-center p-6">
      <EmptyState
        kind="no-data"
        title={t('notFound.title')}
        description={t('notFound.description')}
        action={{ label: t('notFound.action'), onClick: () => router.push('/') }}
      />
    </main>
  );
}
