'use client';

import { useTranslations } from 'next-intl';
import { ResourceListScreen } from '@/domain/screens/resource-list-screen';
import type { DataTableColumn } from '@/domain/components/data-table';
import { StatusPill } from '@/domain/components/status-pill';
import { MoneyDisplay } from '@/domain/components/money-display';
import { useTableState } from '@/lib/tables/use-table-state';
import { toListQuery } from '@/lib/tables/to-list-query';
import { useUnits } from '@/features/ast/api/queries';
import type { Unit } from '@/features/ast/types';
import { UNIT_STATUSES } from '@/features/ast/types';
import { unitStatusLabelKey, unitStatusTone } from '@/features/ast/constants';
import { ASSETS_ARE_MOCK } from '@/features/ast/api';

/**
 * Screen #86 — Units list. LIVE against GET /api/v1/rental-units.
 *
 * The status filter IS backed: RentalUnitController::index reads `status`
 * (and property_id, building_id, floor_id). Sorting and search are not
 * supported by that endpoint, so neither is offered.
 */
export default function UnitsPage() {
  const t = useTranslations('ast');
  const table = useTableState();
  const query = useUnits(toListQuery(table.state));

  const columns: DataTableColumn<Unit>[] = [
    { id: 'unitNumber', header: t('field.unitNumber'), priority: 'primary', cell: (r) => <span className="font-medium">{r.unitNumber}</span> },
    { id: 'propertyName', header: t('field.property'), priority: 'secondary', cell: (r) => r.propertyName ?? '—' },
    { id: 'buildingName', header: t('field.building'), priority: 'meta', cell: (r) => r.buildingName ?? '—' },
    {
      id: 'status',
      header: t('field.status'),
      priority: 'primary',
      cell: (r) => <StatusPill label={t(unitStatusLabelKey(r.status))} tone={unitStatusTone(r.status)} />,
    },
    { id: 'bedrooms', header: t('field.bedrooms'), numeric: true, priority: 'meta', cell: (r) => r.bedrooms ?? '—' },
    { id: 'areaSqm', header: t('field.areaSqm'), numeric: true, priority: 'meta', cell: (r) => r.areaSqm ?? '—' },
    { id: 'monthlyRent', header: t('field.rent'), numeric: true, priority: 'secondary', cell: (r) => <MoneyDisplay value={r.monthlyRent} /> },
  ];

  return (
    <ResourceListScreen
      isMock={ASSETS_ARE_MOCK}
      title={t('units.title')}
      createAction={{ label: t('units.create'), href: '/console/assets/units/new' }}
      searchLabel={t('units.search')}
      searchDisabled
      filters={[
        {
          id: 'status',
          labelKey: 'ast.field.status',
          options: UNIT_STATUSES.map((value) => ({ value, labelKey: `ast.unitStatus.${value}` })),
        },
      ]}
      columns={columns}
      rowKey={(r) => String(r.id)}
      rowHref={(r) => `/console/assets/units/${r.id}`}
      record="asset"
      caption={t('units.tableCaption')}
      emptyNoData={{ title: t('units.emptyTitle'), description: t('units.emptyDescription') }}
      table={table}
      query={query}
    />
  );
}
