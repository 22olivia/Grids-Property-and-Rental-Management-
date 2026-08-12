'use client';

import { useTranslations } from 'next-intl';
import { ResourceListScreen } from '@/domain/screens/resource-list-screen';
import type { DataTableColumn } from '@/domain/components/data-table';
import { useTableState } from '@/lib/tables/use-table-state';
import { toListQuery } from '@/lib/tables/to-list-query';
import { useBuildings } from '@/features/ast/api/queries';
import type { Building } from '@/features/ast/types';
import { ASSETS_ARE_MOCK } from '@/features/ast/api';

/** Screen #84 — Buildings list. LIVE against GET /api/v1/buildings. */
export default function BuildingsPage() {
  const t = useTranslations('ast');
  const table = useTableState();
  const query = useBuildings(toListQuery(table.state));

  const columns: DataTableColumn<Building>[] = [
    { id: 'name', header: t('field.name'), priority: 'primary', cell: (r) => <span className="font-medium">{r.name}</span> },
    { id: 'code', header: t('field.code'), priority: 'secondary', cell: (r) => r.code ? <code className="reference text-xs">{r.code}</code> : '—' },
    { id: 'propertyName', header: t('field.property'), priority: 'secondary', cell: (r) => r.propertyName ?? '—' },
    { id: 'totalFloors', header: t('field.totalFloors'), numeric: true, priority: 'meta', cell: (r) => r.totalFloors },
    { id: 'unitCount', header: t('field.unitCount'), numeric: true, priority: 'meta', cell: (r) => r.unitCount },
  ];

  return (
    <ResourceListScreen
      isMock={ASSETS_ARE_MOCK}
      title={t('buildings.title')}
      searchLabel={t('buildings.search')}
      searchDisabled
      filters={[]}
      columns={columns}
      rowKey={(r) => String(r.id)}
      rowHref={(r) => `/console/assets/buildings/${r.id}`}
      record="asset"
      caption={t('buildings.tableCaption')}
      emptyNoData={{ title: t('buildings.emptyTitle'), description: t('buildings.emptyDescription') }}
      table={table}
      query={query}
    />
  );
}
