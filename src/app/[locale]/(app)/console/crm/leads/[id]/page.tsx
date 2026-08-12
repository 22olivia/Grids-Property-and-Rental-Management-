'use client';

import { use } from 'react';
import { useTranslations } from 'next-intl';
import { Pencil, Search } from 'lucide-react';
import { Button, Card, CardBody, CardHeader, CardTitle, toast } from '@/design-system/ui';
import { Link } from '@/lib/i18n/routing';
import { ResourceDetailScreen } from '@/domain/screens/resource-detail-screen';
import { ActivityTimeline } from '@/domain/components/activity-timeline';
import { MoneyDisplay } from '@/domain/components/money-display';
import { DateTimeDisplay } from '@/domain/components/date-time-display';
import { useLead, useActivities, useCreateActivity } from '@/features/crm/api/queries';
import { ActivityComposer } from '@/features/crm/components/activity-composer';
import { stageTone, stageLabelKey, sourceLabelKey, activityLabelKey } from '@/features/crm/constants';
import { CRM_IS_MOCK } from '@/features/crm/api';

/** Screen #107 — Lead detail. FR-CRM-004, FR-CRM-005. */
export default function LeadDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('crm');
  const tc = useTranslations('common');

  const { data: lead, isLoading, error, refetch } = useLead(id);
  const { data: activities, isLoading: activitiesLoading } = useActivities(id);
  const createActivity = useCreateActivity(id);

  return (
    <ResourceDetailScreen
      isMock={CRM_IS_MOCK}
      breadcrumbLabel={t('breadcrumbLabel')}
      breadcrumb={[{ label: t('leads.title'), href: '/console/crm/leads' }, { label: lead?.name ?? '' }]}
      title={lead?.name ?? ''}
      reference={lead?.reference}
      status={lead ? { label: t(stageLabelKey(lead.stage)), tone: stageTone(lead.stage) } : undefined}
      actions={
        lead ? (
          <>
            <Button variant="secondary" asChild>
              <Link href={`/console/crm/leads/${id}/matches`}>
                <Search className="size-4" aria-hidden="true" />
                {t('matches.title')}
              </Link>
            </Button>
            <Button variant="secondary" asChild>
              <Link href={`/console/crm/leads/${id}/edit`}>
                <Pencil className="size-4" aria-hidden="true" />
                {tc('edit')}
              </Link>
            </Button>
          </>
        ) : undefined
      }
      isLoading={isLoading}
      error={error}
      onRetry={() => refetch()}
      notFoundCopy={{ title: t('detail.notFoundTitle'), description: t('detail.notFoundDescription') }}
      tabs={
        lead
          ? [
              {
                id: 'overview',
                label: t('tabs.overview'),
                content: (
                  <div className="grid gap-4 lg:grid-cols-2">
                    <Card record="party">
                      <CardHeader><CardTitle>{t('form.contact')}</CardTitle></CardHeader>
                      <CardBody>
                        <dl className="flex flex-col gap-2 text-sm">
                          <div className="flex justify-between gap-3">
                            <dt className="text-[var(--color-text-muted)]">{t('field.email')}</dt>
                            {/* Latin-script contact data stays LTR in Arabic. */}
                            <dd dir="ltr" className="text-end">{lead.email ?? '—'}</dd>
                          </div>
                          <div className="flex justify-between gap-3">
                            <dt className="text-[var(--color-text-muted)]">{t('field.phone')}</dt>
                            <dd dir="ltr" className="text-end">{lead.phone ?? '—'}</dd>
                          </div>
                          <div className="flex justify-between gap-3">
                            <dt className="text-[var(--color-text-muted)]">{t('field.source')}</dt>
                            <dd>{t(sourceLabelKey(lead.source))}</dd>
                          </div>
                          <div className="flex justify-between gap-3">
                            <dt className="text-[var(--color-text-muted)]">{t('field.agent')}</dt>
                            <dd>{lead.assignedAgentName ?? t('field.unassigned')}</dd>
                          </div>
                        </dl>
                      </CardBody>
                    </Card>

                    <Card record="party">
                      <CardHeader><CardTitle>{t('form.criteria')}</CardTitle></CardHeader>
                      <CardBody>
                        <dl className="grid grid-cols-2 gap-3 text-sm">
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.budget')}</dt>
                            <dd><MoneyDisplay value={lead.budget} /></dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.minArea')}</dt>
                            <dd className="tabular">{lead.minAreaSqm ?? '—'}</dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.preferredCity')}</dt>
                            <dd>{lead.preferredCity ?? '—'}</dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.preferredType')}</dt>
                            <dd>{lead.preferredType ?? '—'}</dd>
                          </div>
                        </dl>
                      </CardBody>
                    </Card>

                    {lead.nextActionAt && (
                      <Card record="party">
                        <CardHeader><CardTitle>{t('form.nextAction')}</CardTitle></CardHeader>
                        <CardBody>
                          <p className="text-sm">{lead.nextActionNote ?? '—'}</p>
                          <p className="mt-1 text-xs text-[var(--color-text-muted)]">
                            <DateTimeDisplay value={lead.nextActionAt} withTime />
                          </p>
                        </CardBody>
                      </Card>
                    )}

                    {lead.interestedListingId && (
                      <Card record="listing">
                        <CardHeader><CardTitle>{t('field.interestedListing')}</CardTitle></CardHeader>
                        <CardBody>
                          <Link
                            href={`/console/listings/${lead.interestedListingId}`}
                            className="text-[var(--color-action)] underline-offset-4 hover:underline"
                          >
                            {lead.interestedListingTitle}
                          </Link>
                        </CardBody>
                      </Card>
                    )}
                  </div>
                ),
              },
              {
                id: 'activities',
                label: t('tabs.activities'),
                content: (
                  <div className="flex flex-col gap-4">
                    <Card record="party">
                      <CardHeader><CardTitle>{t('activities.add')}</CardTitle></CardHeader>
                      <ActivityComposer
                        isSubmitting={createActivity.isPending}
                        onSubmit={async (values) => {
                          await createActivity.mutateAsync(values);
                          toast.success(t('activities.added'));
                        }}
                      />
                    </Card>
                    <ActivityTimeline
                      activities={activities}
                      isLoading={activitiesLoading}
                      typeLabel={(type) => t(activityLabelKey(type))}
                    />
                  </div>
                ),
              },
            ]
          : []
      }
    />
  );
}
