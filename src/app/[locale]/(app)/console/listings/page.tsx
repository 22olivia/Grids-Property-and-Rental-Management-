'use client';

import { useTranslations } from 'next-intl';
import { ResourceListScreen } from '@/domain/screens/resource-list-screen';
import type { DataTableColumn } from '@/domain/components/data-table';
import { StatusPill } from '@/domain/components/status-pill';
import { MoneyDisplay } from '@/domain/components/money-display';
import { useTableState } from '@/lib/tables/use-table-state';
import { toListQuery } from '@/lib/tables/to-list-query';
import { useListings } from '@/features/lst/api/queries';
import type { Listing } from '@/features/lst/types';
import { LISTING_STATES, LISTING_TYPES } from '@/features/lst/types';
import { listingStateTone, listingStateLabelKey, listingTypeLabelKey } from '@/features/lst/constants';
import { LISTINGS_ARE_MOCK } from '@/features/lst/api';

/** Screen #99 — Listings list. FR-LST-001, FR-LST-002, FR-LST-006. */
export default function ListingsPage() {
  const t = useTranslations('lst');
  const table = useTableState({ sort: 'updatedAt', direction: 'desc' });
  const query = useListings(toListQuery(table.state));

  const columns: DataTableColumn<Listing>[] = [
    { id: 'title', header: t('field.title'), sortable: true, priority: 'primary', cell: (row) => <span className="font-medium">{row.title}</span> },
    { id: 'reference', header: t('field.reference'), priority: 'secondary', cell: (row) => <code className="reference text-xs">{row.reference}</code> },
    { id: 'type', header: t('field.type'), priority: 'secondary', cell: (row) => t(listingTypeLabelKey(row.type)) },
    {
      id: 'state',
      header: t('field.state'),
      sortable: true,
      priority: 'primary',
      cell: (row) => (
        <StatusPill label={t(listingStateLabelKey(row.state))} tone={listingStateTone(row.state)} />
      ),
    },
    { id: 'propertyName', header: t('field.property'), priority: 'meta', cell: (row) => row.propertyName },
    { id: 'price', header: t('field.price'), numeric: true, priority: 'secondary', cell: (row) => <MoneyDisplay value={row.price} /> },
    { id: 'viewCount', header: t('field.views'), numeric: true, sortable: true, priority: 'meta', cell: (row) => row.viewCount },
    { id: 'enquiryCount', header: t('field.enquiries'), numeric: true, sortable: true, priority: 'meta', cell: (row) => row.enquiryCount },
  ];

  return (
    <ResourceListScreen
      isMock={LISTINGS_ARE_MOCK}
      title={t('listings.title')}
      createAction={{ label: t('listings.create'), href: '/console/listings/new' }}
      searchLabel={t('listings.search')}
      filters={[
        { id: 'state', labelKey: 'lst.field.state', options: LISTING_STATES.map((value) => ({ value, labelKey: `lst.state.${value}` })) },
        { id: 'type', labelKey: 'lst.field.type', options: LISTING_TYPES.map((value) => ({ value, labelKey: `lst.type.${value}` })) },
      ]}
      columns={columns}
      rowKey={(row) => row.id}
      rowHref={(row) => `/console/listings/${row.id}`}
      record="listing"
      caption={t('listings.tableCaption')}
      emptyNoData={{ title: t('listings.emptyTitle'), description: t('listings.emptyDescription') }}
      table={table}
      query={query}
    />
  );
}
