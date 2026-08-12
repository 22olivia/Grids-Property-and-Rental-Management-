'use client';

import { useTranslations } from 'next-intl';
import { Button } from '@/design-system/ui';
import { Link } from '@/lib/i18n/routing';
import { ResourceListScreen } from '@/domain/screens/resource-list-screen';
import type { DataTableColumn } from '@/domain/components/data-table';
import { StatusPill } from '@/domain/components/status-pill';
import { MoneyDisplay } from '@/domain/components/money-display';
import { DateTimeDisplay } from '@/domain/components/date-time-display';
import { useTableState } from '@/lib/tables/use-table-state';
import { toListQuery } from '@/lib/tables/to-list-query';
import { useLeads } from '@/features/crm/api/queries';
import type { Lead } from '@/features/crm/types';
import { LEAD_SOURCES, PIPELINE_STAGES } from '@/features/crm/types';
import { stageTone, stageLabelKey, sourceLabelKey } from '@/features/crm/constants';
import { CRM_IS_MOCK } from '@/features/crm/api';

/** Screen #105 — Leads list. FR-CRM-001, FR-CRM-003. */
export default function LeadsPage() {
  const t = useTranslations('crm');
  const table = useTableState({ sort: 'updatedAt', direction: 'desc' });
  const query = useLeads(toListQuery(table.state));

  const columns: DataTableColumn<Lead>[] = [
    { id: 'name', header: t('field.name'), sortable: true, priority: 'primary', cell: (r) => <span className="font-medium">{r.name}</span> },
    { id: 'reference', header: t('field.reference'), priority: 'meta', cell: (r) => <code className="reference text-xs">{r.reference}</code> },
    { id: 'stage', header: t('field.stage'), sortable: true, priority: 'primary', cell: (r) => <StatusPill label={t(stageLabelKey(r.stage))} tone={stageTone(r.stage)} /> },
    { id: 'source', header: t('field.source'), priority: 'secondary', cell: (r) => t(sourceLabelKey(r.source)) },
    { id: 'assignedAgentName', header: t('field.agent'), priority: 'secondary', cell: (r) => r.assignedAgentName ?? t('field.unassigned') },
    { id: 'budget', header: t('field.budget'), numeric: true, priority: 'secondary', cell: (r) => <MoneyDisplay value={r.budget} /> },
    { id: 'nextActionAt', header: t('field.nextAction'), priority: 'meta', cell: (r) => r.nextActionAt ? <DateTimeDisplay value={r.nextActionAt} relative /> : '—' },
  ];

  return (
    <ResourceListScreen
      isMock={CRM_IS_MOCK}
      title={t('leads.title')}
      createAction={{ label: t('leads.create'), href: '/console/crm/leads/new' }}
      toolbar={
        <>
          <Button variant="secondary" asChild>
            <Link href="/console/crm/pipeline">{t('pipeline.title')}</Link>
          </Button>
          <Button variant="secondary" asChild>
            <Link href="/console/crm/leads/import">{t('import.title')}</Link>
          </Button>
        </>
      }
      searchLabel={t('leads.search')}
      filters={[
        { id: 'stage', labelKey: 'crm.field.stage', options: PIPELINE_STAGES.map((v) => ({ value: v, labelKey: `crm.stage.${v}` })) },
        { id: 'source', labelKey: 'crm.field.source', options: LEAD_SOURCES.map((v) => ({ value: v, labelKey: `crm.source.${v}` })) },
      ]}
      columns={columns}
      rowKey={(r) => r.id}
      rowHref={(r) => `/console/crm/leads/${r.id}`}
      record="party"
      caption={t('leads.tableCaption')}
      emptyNoData={{ title: t('leads.emptyTitle'), description: t('leads.emptyDescription') }}
      table={table}
      query={query}
    />
  );
}
