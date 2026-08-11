'use client';

import { useTranslations } from 'next-intl';
import { ResourceListScreen } from '@/domain/screens/resource-list-screen';
import type { DataTableColumn } from '@/domain/components/data-table';
import { StatusPill } from '@/domain/components/status-pill';
import { useTableState } from '@/lib/tables/use-table-state';
import { toListQuery } from '@/lib/tables/to-list-query';
import { useProperties } from '@/features/ast/api/queries';
import type { Property } from '@/features/ast/types';
import { PROPERTY_STATUSES, PROPERTY_TYPES } from '@/features/ast/types';
import { propertyStatusTone, propertyStatusLabelKey, propertyTypeLabelKey } from '@/features/ast/constants';
import { ASSETS_ARE_MOCK } from '@/features/ast/api';

/**
 * Screen #81 — Properties list. LIVE against GET /api/v1/properties.
 *
 * Columns are NOT sortable: no backend index reads a sort parameter (every one
 * is hardcoded `->latest()`). Marking them sortable would produce controls that
 * silently do nothing. Requested as Observation 4 in the defect report.
 *
 * There is no search input either — PropertyController accepts no `search`
 * parameter. The filters below are client-declared but the backend does not
 * read them on this endpoint, so they are omitted rather than faked.
 */
export default function PropertiesPage() {
  const t = useTranslations('ast');
  const table = useTableState();
  const query = useProperties(toListQuery(table.state));

  const columns: DataTableColumn<Property>[] = [
    { id: 'name', header: t('field.name'), priority: 'primary', cell: (r) => <span className="font-medium">{r.name}</span> },
    { id: 'type', header: t('field.propertyType'), priority: 'secondary', cell: (r) => r.type ? t(propertyTypeLabelKey(r.type)) : '—' },
    { id: 'city', header: t('field.city'), priority: 'secondary', cell: (r) => r.address.city || '—' },
    { id: 'owner', header: t('field.owner'), priority: 'meta', cell: (r) => r.owner?.fullName ?? '—' },
    { id: 'unitCount', header: t('field.unitCount'), numeric: true, priority: 'meta', cell: (r) => r.unitCount },
    {
      id: 'status',
      header: t('field.propertyStatus'),
      priority: 'secondary',
      cell: (r) => <StatusPill label={t(propertyStatusLabelKey(r.status))} tone={propertyStatusTone(r.status)} />,
    },
  ];

  return (
    <ResourceListScreen
      isMock={ASSETS_ARE_MOCK}
      title={t('properties.title')}
      createAction={{ label: t('properties.create'), href: '/console/assets/properties/new' }}
      searchLabel={t('properties.search')}
      searchDisabled
      filters={[]}
      columns={columns}
      rowKey={(r) => String(r.id)}
      rowHref={(r) => `/console/assets/properties/${r.id}`}
      record="asset"
      caption={t('properties.tableCaption')}
      emptyNoData={{ title: t('properties.emptyTitle'), description: t('properties.emptyDescription') }}
      table={table}
      query={query}
    />
  );
}
