'use client';

import { useTranslations } from 'next-intl';
import { ResourceListScreen } from '@/domain/screens/resource-list-screen';
import type { DataTableColumn } from '@/domain/components/data-table';
import { StatusPill } from '@/domain/components/status-pill';
import { MoneyDisplay } from '@/domain/components/money-display';
import { DateTimeDisplay } from '@/domain/components/date-time-display';
import { useTableState } from '@/lib/tables/use-table-state';
import { toListQuery } from '@/lib/tables/to-list-query';
import { useOffers } from '@/features/crm/api/queries';
import { OFFER_STATES, type Offer } from '@/features/crm/types';
import { offerTone, offerStateLabelKey } from '@/features/crm/constants';
import { CRM_IS_MOCK } from '@/features/crm/api';

/** Screen #115 — Offers list. FR-CRM-007. */
export default function OffersPage() {
  const t = useTranslations('crm');
  const table = useTableState({ sort: 'createdAt', direction: 'desc' });
  const query = useOffers(toListQuery(table.state));

  const columns: DataTableColumn<Offer>[] = [
    { id: 'reference', header: t('field.reference'), priority: 'primary', cell: (r) => <code className="reference text-xs">{r.reference}</code> },
    { id: 'leadName', header: t('field.lead'), priority: 'primary', cell: (r) => <span className="font-medium">{r.leadName}</span> },
    { id: 'listingTitle', header: t('field.listing'), priority: 'secondary', cell: (r) => r.listingTitle ?? '—' },
    { id: 'amount', header: t('field.amount'), numeric: true, priority: 'primary', cell: (r) => <MoneyDisplay value={r.amount} /> },
    { id: 'state', header: t('field.status'), priority: 'secondary', cell: (r) => <StatusPill label={t(offerStateLabelKey(r.state))} tone={offerTone(r.state)} /> },
    { id: 'expiresAt', header: t('field.expiresAt'), priority: 'meta', cell: (r) => r.expiresAt ? <DateTimeDisplay value={r.expiresAt} relative /> : '—' },
  ];

  return (
    <ResourceListScreen
      isMock={CRM_IS_MOCK}
      title={t('offers.title')}
      searchLabel={t('offers.search')}
      filters={[
        { id: 'state', labelKey: 'crm.field.status', options: OFFER_STATES.map((v) => ({ value: v, labelKey: `crm.offerState.${v}` })) },
      ]}
      columns={columns}
      rowKey={(r) => r.id}
      rowHref={(r) => `/console/crm/offers/${r.id}`}
      record="money"
      caption={t('offers.tableCaption')}
      emptyNoData={{ title: t('offers.emptyTitle'), description: t('offers.emptyDescription') }}
      table={table}
      query={query}
    />
  );
}
