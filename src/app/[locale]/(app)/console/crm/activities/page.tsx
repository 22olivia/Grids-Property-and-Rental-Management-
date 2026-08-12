'use client';

import { useTranslations } from 'next-intl';
import { ResourceListScreen } from '@/domain/screens/resource-list-screen';
import type { DataTableColumn } from '@/domain/components/data-table';
import { StatusPill } from '@/domain/components/status-pill';
import { DateTimeDisplay } from '@/domain/components/date-time-display';
import { useTableState } from '@/lib/tables/use-table-state';
import { toListQuery } from '@/lib/tables/to-list-query';
import { useTasks } from '@/features/crm/api/queries';
import type { Activity } from '@/features/crm/types';
import { ACTIVITY_TYPES } from '@/features/crm/types';
import { activityLabelKey } from '@/features/crm/constants';
import { CRM_IS_MOCK } from '@/features/crm/api';

/** Screen #111 — Activities and tasks. FR-CRM-004. */
export default function ActivitiesPage() {
  const t = useTranslations('crm');
  const table = useTableState({ sort: 'dueAt' });
  const query = useTasks(toListQuery(table.state));

  const columns: DataTableColumn<Activity>[] = [
    { id: 'summary', header: t('field.summary'), priority: 'primary', cell: (r) => <span className="font-medium">{r.summary}</span> },
    { id: 'type', header: t('field.activityType'), priority: 'secondary', cell: (r) => t(activityLabelKey(r.type)) },
    { id: 'dueAt', header: t('field.dueAt'), sortable: true, priority: 'primary', cell: (r) => r.dueAt ? <DateTimeDisplay value={r.dueAt} relative /> : '—' },
    { id: 'actorName', header: t('field.actor'), priority: 'meta', cell: (r) => r.actorName },
    {
      id: 'completed',
      header: t('field.status'),
      priority: 'secondary',
      cell: (r) => (
        <StatusPill
          label={r.completed ? t('activities.done') : t('activities.due')}
          tone={r.completed ? 'success' : 'warning'}
        />
      ),
    },
  ];

  return (
    <ResourceListScreen
      isMock={CRM_IS_MOCK}
      title={t('activities.title')}
      searchLabel={t('activities.search')}
      filters={[
        { id: 'completed', labelKey: 'crm.field.status', options: [
          { value: 'false', labelKey: 'crm.activities.due' },
          { value: 'true', labelKey: 'crm.activities.done' },
        ] },
        { id: 'type', labelKey: 'crm.field.activityType', options: ACTIVITY_TYPES.map((v) => ({ value: v, labelKey: `crm.activityType.${v}` })) },
      ]}
      columns={columns}
      rowKey={(r) => r.id}
      rowHref={(r) => `/console/crm/leads/${r.leadId}?tab=activities`}
      record="party"
      caption={t('activities.tableCaption')}
      emptyNoData={{ title: t('activities.emptyTitle'), description: t('activities.emptyDescription') }}
      table={table}
      query={query}
    />
  );
}
