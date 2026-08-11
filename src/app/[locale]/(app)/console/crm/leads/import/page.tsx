'use client';

import { useTranslations } from 'next-intl';
import { Alert, Breadcrumb, Card, CardBody, CardHeader, CardTitle } from '@/design-system/ui';
import { MockDataNotice } from '@/domain/components/mock-data-notice';
import { CRM_IS_MOCK } from '@/features/crm/api';
import { LEAD_SOURCES } from '@/features/crm/types';
import { sourceLabelKey } from '@/features/crm/constants';

/**
 * Screen #109 — Lead import. FR-CRM-001 ("imports"), FR-API-009.
 *
 * ===========================================================================
 * NOT IMPLEMENTED — blocked on two unresolved dependencies.
 * ===========================================================================
 *
 * FR-API-009 (Should) requires "background jobs, validation reports and
 * resumable processing". Building this needs BOTH:
 *   - the file upload transport (MI-28) — signed URL vs multipart, undecided;
 *   - the async job contract (MI-H13) — submission, polling, progress, report
 *     shape. None of it is published.
 *
 * Column mapping is the part people assume is safe to build. It is not: the
 * mapping targets are the lead field names in the API contract, which does not
 * exist. Mapping a spreadsheet column to a guessed field name produces a
 * mapping UI that has to be rebuilt.
 *
 * So this screen states the dependency plainly rather than showing a
 * non-functional uploader, which in a demo reads as a broken feature rather
 * than an unbuilt one.
 * ===========================================================================
 */
export default function LeadImportPage() {
  const t = useTranslations('crm');

  return (
    <div className="flex flex-col gap-4">
      <MockDataNotice active={CRM_IS_MOCK} />
      <Breadcrumb
        label={t('breadcrumbLabel')}
        items={[
          { label: t('leads.title'), href: '/console/crm/leads' },
          { label: t('import.title') },
        ]}
      />
      <h1 className="text-xl font-semibold">{t('import.title')}</h1>

      <Alert tone="warning" title={t('import.blockedTitle')}>
        {t('import.blockedBody')}
      </Alert>

      <Card record="party">
        <CardHeader><CardTitle>{t('import.sourcesTitle')}</CardTitle></CardHeader>
        <CardBody>
          <p className="mb-3 text-sm">{t('import.sourcesBody')}</p>
          <ul className="flex flex-wrap gap-2">
            {LEAD_SOURCES.map((source) => (
              <li
                key={source}
                className="rounded-[var(--radius-full)] bg-[var(--color-surface-sunken)] px-3 py-1 text-xs"
              >
                {t(sourceLabelKey(source))}
              </li>
            ))}
          </ul>
        </CardBody>
      </Card>
    </div>
  );
}
