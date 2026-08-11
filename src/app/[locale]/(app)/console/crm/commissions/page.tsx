'use client';

import { useTranslations } from 'next-intl';
import { Alert } from '@/design-system/ui';
import { ResourceListScreen } from '@/domain/screens/resource-list-screen';
import type { DataTableColumn } from '@/domain/components/data-table';
import { StatusPill } from '@/domain/components/status-pill';
import { MoneyDisplay } from '@/domain/components/money-display';
import { useTableState } from '@/lib/tables/use-table-state';
import { toListQuery } from '@/lib/tables/to-list-query';
import { useCommissions } from '@/features/crm/api/queries';
import { COMMISSION_PARTIES, type Commission } from '@/features/crm/types';
import { partyLabelKey } from '@/features/crm/constants';
import { CRM_IS_MOCK } from '@/features/crm/api';

/**
 * Screen #118 — Commissions. FR-CRM-008.
 *
 * ---------------------------------------------------------------------------
 * DISPLAY ONLY. FR-CRM-008 says the platform "shall CALCULATE agent, agency,
 * referral and company commissions according to configurable rules" — the
 * calculation is the server's. This screen formats what it is given and
 * performs no arithmetic: no totals row, no split percentages, no derived
 * figures. Settlement itself belongs to FIN, which is blocked on B7.
 * ---------------------------------------------------------------------------
 */
export default function CommissionsPage() {
  const t = useTranslations('crm');
  const table = useTableState({ sort: 'dealReference' });
  const query = useCommissions(toListQuery(table.state));

  const columns: DataTableColumn<Commission>[] = [
    { id: 'dealReference', header: t('field.deal'), sortable: true, priority: 'primary', cell: (r) => <code className="reference text-xs">{r.dealReference}</code> },
    { id: 'party', header: t('field.party'), priority: 'primary', cell: (r) => t(partyLabelKey(r.party)) },
    { id: 'partyName', header: t('field.name'), priority: 'secondary', cell: (r) => r.partyName },
    { id: 'amount', header: t('field.amount'), numeric: true, priority: 'primary', cell: (r) => <MoneyDisplay value={r.amount} /> },
    { id: 'ruleLabel', header: t('field.rule'), priority: 'meta', cell: (r) => r.ruleLabel ?? '—' },
    {
      id: 'settled',
      header: t('field.status'),
      priority: 'secondary',
      cell: (r) => (
        <StatusPill
          label={r.settled ? t('commissions.settled') : t('commissions.pending')}
          tone={r.settled ? 'success' : 'warning'}
        />
      ),
    },
  ];

  return (
    <div className="flex flex-col gap-4">
      <Alert tone="info" title={t('commissions.calculationNoticeTitle')}>
        {t('commissions.calculationNoticeBody')}
      </Alert>
      <ResourceListScreen
      isMock={CRM_IS_MOCK}
        title={t('commissions.title')}
        searchLabel={t('commissions.search')}
        filters={[
          { id: 'party', labelKey: 'crm.field.party', options: COMMISSION_PARTIES.map((v) => ({ value: v, labelKey: `crm.party.${v}` })) },
        ]}
        columns={columns}
        rowKey={(r) => r.id}
        record="money"
        caption={t('commissions.tableCaption')}
        emptyNoData={{ title: t('commissions.emptyTitle'), description: t('commissions.emptyDescription') }}
        table={table}
        query={query}
      />
    </div>
  );
}
