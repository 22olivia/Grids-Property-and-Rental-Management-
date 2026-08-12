'use client';

import { useTranslations } from 'next-intl';
import { Alert } from '@/design-system/ui';

/**
 * Banner shown whenever a screen is displaying fixtures rather than API data.
 *
 * `active` is passed EXPLICITLY by the screen rather than read from a global
 * flag. Data sources are now per-module — assets can be live while listings
 * and CRM are still mock — so one global boolean would have shown the banner
 * on live screens and hidden it on mock ones, which is worse than not having
 * it at all.
 *
 * Deliberately prominent: mock data that looks real in a stakeholder demo is
 * how a fixture ends up quoted as a fact in a meeting.
 */
export function MockDataNotice({ active }: { active: boolean }) {
  const t = useTranslations('data');
  if (!active) return null;

  return (
    <Alert tone="warning" title={t('mockTitle')} className="mb-4">
      {t('mockDescription')}
    </Alert>
  );
}
