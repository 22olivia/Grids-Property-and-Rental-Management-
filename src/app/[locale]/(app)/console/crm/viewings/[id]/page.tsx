'use client';

import { use } from 'react';
import { useTranslations } from 'next-intl';
import { Alert, Card, CardBody, CardHeader, CardTitle } from '@/design-system/ui';
import { Link } from '@/lib/i18n/routing';
import { ResourceDetailScreen } from '@/domain/screens/resource-detail-screen';
import { DateTimeDisplay } from '@/domain/components/date-time-display';
import { useViewing } from '@/features/crm/api/queries';
import { viewingTone, viewingStatusLabelKey } from '@/features/crm/constants';
import { CRM_IS_MOCK } from '@/features/crm/api';

/**
 * Screen #113 — Viewing detail. FR-CRM-006.
 *
 * Feedback is displayed read-only. Recording attendance, a no-show or a
 * reschedule are state transitions, and — as with listings (MI-24) — no
 * requirement defines who may perform them or under what preconditions. The
 * actions appear once the transition contract exists.
 */
export default function ViewingDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('crm');

  const { data: viewing, isLoading, error, refetch } = useViewing(id);

  return (
    <ResourceDetailScreen
      isMock={CRM_IS_MOCK}
      breadcrumbLabel={t('breadcrumbLabel')}
      breadcrumb={[
        { label: t('viewings.title'), href: '/console/crm/viewings' },
        { label: viewing?.reference ?? '' },
      ]}
      title={viewing?.leadName ?? ''}
      reference={viewing?.reference}
      status={
        viewing
          ? { label: t(viewingStatusLabelKey(viewing.status)), tone: viewingTone(viewing.status) }
          : undefined
      }
      isLoading={isLoading}
      error={error}
      onRetry={() => refetch()}
      notFoundCopy={{ title: t('detail.notFoundTitle'), description: t('detail.notFoundDescription') }}
      tabs={
        viewing
          ? [
              {
                id: 'overview',
                label: t('tabs.overview'),
                content: (
                  <div className="flex flex-col gap-4">
                    <Card record="party">
                      <CardHeader><CardTitle>{t('viewings.appointment')}</CardTitle></CardHeader>
                      <CardBody>
                        <dl className="flex flex-col gap-2 text-sm">
                          <div className="flex justify-between gap-3">
                            <dt className="text-[var(--color-text-muted)]">{t('field.scheduledFor')}</dt>
                            <dd><DateTimeDisplay value={viewing.scheduledFor} withTime /></dd>
                          </div>
                          <div className="flex justify-between gap-3">
                            <dt className="text-[var(--color-text-muted)]">{t('field.lead')}</dt>
                            <dd>
                              <Link
                                href={`/console/crm/leads/${viewing.leadId}`}
                                className="text-[var(--color-action)] underline-offset-4 hover:underline"
                              >
                                {viewing.leadName}
                              </Link>
                            </dd>
                          </div>
                          <div className="flex justify-between gap-3">
                            <dt className="text-[var(--color-text-muted)]">{t('field.listing')}</dt>
                            <dd>
                              {viewing.listingId ? (
                                <Link
                                  href={`/console/listings/${viewing.listingId}`}
                                  className="text-[var(--color-action)] underline-offset-4 hover:underline"
                                >
                                  {viewing.listingTitle}
                                </Link>
                              ) : '—'}
                            </dd>
                          </div>
                          <div className="flex justify-between gap-3">
                            <dt className="text-[var(--color-text-muted)]">{t('field.agent')}</dt>
                            <dd>{viewing.agentName ?? '—'}</dd>
                          </div>
                        </dl>
                      </CardBody>
                    </Card>

                    <Card record="party">
                      <CardHeader><CardTitle>{t('viewings.feedback')}</CardTitle></CardHeader>
                      <CardBody>
                        <p className="text-sm">{viewing.feedback ?? t('viewings.noFeedback')}</p>
                      </CardBody>
                    </Card>

                    <Alert tone="info" title={t('viewings.actionsBlockedTitle')}>
                      {t('viewings.actionsBlockedBody')}
                    </Alert>
                  </div>
                ),
              },
            ]
          : []
      }
    />
  );
}
