'use client';

import { useTranslations } from 'next-intl';
import { ResourceListScreen } from '@/domain/screens/resource-list-screen';
import type { DataTableColumn } from '@/domain/components/data-table';
import { StatusPill } from '@/domain/components/status-pill';
import { MoneyDisplay } from '@/domain/components/money-display';
import { DateTimeDisplay } from '@/domain/components/date-time-display';
import { useTableState } from '@/lib/tables/use-table-state';
import { toListQuery } from '@/lib/tables/to-list-query';
import { useDeals } from '@/features/crm/api/queries';
import type { Deal } from '@/features/crm/types';
import { stageTone, stageLabelKey } from '@/features/crm/constants';
import { CRM_IS_MOCK } from '@/features/crm/api';

/** Screen #117 — Deals. FR-CRM-003 (won/lost). */
export default function DealsPage() {
  const t = useTranslations('crm');
  const table = useTableState({ sort: 'closedAt', direction: 'desc' });
  const query = useDeals(toListQuery(table.state));

  const columns: DataTableColumn<Deal>[] = [
    { id: 'reference', header: t('field.reference'), priority: 'secondary', cell: (r) => <code className="reference text-xs">{r.reference}</code> },
    { id: 'leadName', header: t('field.lead'), priority: 'primary', cell: (r) => <span className="font-medium">{r.leadName}</span> },
    { id: 'listingTitle', header: t('field.listing'), priority: 'meta', cell: (r) => r.listingTitle ?? '—' },
    { id: 'value', header: t('field.value'), numeric: true, priority: 'primary', cell: (r) => <MoneyDisplay value={r.value} /> },
    { id: 'stage', header: t('field.outcome'), priority: 'secondary', cell: (r) => <StatusPill label={t(stageLabelKey(r.stage))} tone={stageTone(r.stage)} /> },
    { id: 'closedAt', header: t('field.closedAt'), sortable: true, priority: 'meta', cell: (r) => r.closedAt ? <DateTimeDisplay value={r.closedAt} /> : '—' },
  ];

  return (
    <ResourceListScreen
      isMock={CRM_IS_MOCK}
      title={t('deals.title')}
      searchLabel={t('deals.search')}
      filters={[
        { id: 'stage', labelKey: 'crm.field.outcome', options: [
          { value: 'won', labelKey: 'crm.stage.won' },
          { value: 'lost', labelKey: 'crm.stage.lost' },
        ] },
      ]}
      columns={columns}
      rowKey={(r) => r.id}
      record="money"
      caption={t('deals.tableCaption')}
      emptyNoData={{ title: t('deals.emptyTitle'), description: t('deals.emptyDescription') }}
      table={table}
      query={query}
    />
  );
}
