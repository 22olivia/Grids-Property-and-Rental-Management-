'use client';

import { useTranslations } from 'next-intl';
import { ResourceListScreen } from '@/domain/screens/resource-list-screen';
import type { DataTableColumn } from '@/domain/components/data-table';
import { useTableState } from '@/lib/tables/use-table-state';
import { toListQuery } from '@/lib/tables/to-list-query';
import { useProjects } from '@/features/lst/api/queries';
import type { Project } from '@/features/lst/types';
import { LISTINGS_ARE_MOCK } from '@/features/lst/api';

/** Project inventory list — FR-LST-002 ("project inventory"). */
export default function ProjectsPage() {
  const t = useTranslations('lst');
  const table = useTableState({ sort: 'name' });
  const query = useProjects(toListQuery(table.state));

  const columns: DataTableColumn<Project>[] = [
    { id: 'name', header: t('field.title'), sortable: true, priority: 'primary', cell: (row) => <span className="font-medium">{row.name}</span> },
    { id: 'reference', header: t('field.reference'), priority: 'secondary', cell: (row) => <code className="reference text-xs">{row.reference}</code> },
    { id: 'developerName', header: t('field.developer'), priority: 'secondary', cell: (row) => row.developerName ?? '—' },
    { id: 'city', header: t('field.city'), priority: 'meta', cell: (row) => row.city },
    {
      id: 'available',
      header: t('field.availableUnits'),
      numeric: true,
      priority: 'primary',
      cell: (row) => row.unitTypes.reduce((sum, type) => sum + type.availableUnits, 0),
    },
  ];

  return (
    <ResourceListScreen
      isMock={LISTINGS_ARE_MOCK}
      title={t('projects.title')}
      searchLabel={t('projects.search')}
      columns={columns}
      rowKey={(row) => row.id}
      rowHref={(row) => `/console/listings/projects/${row.id}`}
      record="listing"
      caption={t('projects.tableCaption')}
      emptyNoData={{ title: t('projects.emptyTitle'), description: t('projects.emptyDescription') }}
      table={table}
      query={query}
    />
  );
}
