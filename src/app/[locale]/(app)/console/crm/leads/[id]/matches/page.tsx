'use client';

import { use } from 'react';
import { useTranslations } from 'next-intl';
import { Alert, Card, CardHeader, CardTitle, EmptyState, LoadingState } from '@/design-system/ui';
import { Link } from '@/lib/i18n/routing';
import { MockDataNotice } from '@/domain/components/mock-data-notice';
import { CRM_IS_MOCK } from '@/features/crm/api';
import { MoneyDisplay } from '@/domain/components/money-display';
import { Breadcrumb, Badge } from '@/design-system/ui';
import { useLead, useMatches } from '@/features/crm/api/queries';

/**
 * Screen #114 — Property matching. FR-CRM-005 (Should).
 *
 * The scores and reasons are SERVER-COMPUTED. The client never ranks matches
 * itself — a client-side scoring function would be a business rule in the
 * client (SRS §6) and would disagree with the server the moment the criteria
 * weighting changed.
 */
export default function LeadMatchesPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('crm');
  const tc = useTranslations('common');

  const { data: lead } = useLead(id);
  const { data: matches, isLoading } = useMatches(id);

  return (
    <div className="flex flex-col gap-4">
      <MockDataNotice active={CRM_IS_MOCK} />
      <Breadcrumb
        label={t('breadcrumbLabel')}
        items={[
          { label: t('leads.title'), href: '/console/crm/leads' },
          { label: lead?.name ?? '', href: `/console/crm/leads/${id}` },
          { label: t('matches.title') },
        ]}
      />
      <h1 className="text-xl font-semibold">{t('matches.title')}</h1>

      <Alert tone="info" title={t('matches.noticeTitle')}>{t('matches.noticeBody')}</Alert>

      {isLoading ? (
        <LoadingState label={tc('loading')} />
      ) : !matches || matches.items.length === 0 ? (
        <EmptyState
          kind="no-results"
          title={t('matches.emptyTitle')}
          description={t('matches.emptyDescription')}
        />
      ) : (
        <ol className="flex flex-col gap-2">
          {matches.items.map((match) => (
            <li key={match.listingId}>
              <Card record="listing">
                <CardHeader>
                  <CardTitle>
                    <Link
                      href={`/console/listings/${match.listingId}`}
                      className="underline-offset-4 hover:underline"
                    >
                      {match.title}
                    </Link>
                  </CardTitle>
                </CardHeader>
                <div className="flex flex-wrap items-center gap-3 text-sm">
                  <Badge tone="success">{t('matches.score', { score: match.matchScore })}</Badge>
                  <span className="text-[var(--color-text-muted)]">{match.city}</span>
                  <span className="tabular">{match.areaSqm} m²</span>
                  <MoneyDisplay value={match.price} />
                  <span className="ms-auto text-xs text-[var(--color-text-muted)]">
                    {match.matchReason}
                  </span>
                </div>
              </Card>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}
