'use client';

import { useTranslations } from 'next-intl';
import { ResourceListScreen } from '@/domain/screens/resource-list-screen';
import type { DataTableColumn } from '@/domain/components/data-table';
import { StatusPill } from '@/domain/components/status-pill';
import { DateTimeDisplay } from '@/domain/components/date-time-display';
import { useTableState } from '@/lib/tables/use-table-state';
import { toListQuery } from '@/lib/tables/to-list-query';
import { useApprovalQueue } from '@/features/lst/api/queries';
import type { Listing } from '@/features/lst/types';
import { listingStateTone, listingStateLabelKey } from '@/features/lst/constants';
import { LISTINGS_ARE_MOCK } from '@/features/lst/api';

/**
 * Screen #103 — Listing approval queue. FR-LST-006 (review / approval states).
 *
 * Archetype G (work queue) built on the same list kit: a queue is a filtered
 * list with a decision, not a separate species of screen. The decision itself
 * lives on the listing detail's workflow tab, so approvers see full context
 * before acting rather than approving from a row.
 */
export default function ListingApprovalsPage() {
  const t = useTranslations('lst');
  const table = useTableState({ sort: 'updatedAt', direction: 'asc' });
  const query = useApprovalQueue(toListQuery(table.state));

  const columns: DataTableColumn<Listing>[] = [
    { id: 'title', header: t('field.title'), sortable: true, priority: 'primary', cell: (row) => <span className="font-medium">{row.title}</span> },
    { id: 'reference', header: t('field.reference'), priority: 'secondary', cell: (row) => <code className="reference text-xs">{row.reference}</code> },
    {
      id: 'state',
      header: t('field.state'),
      priority: 'primary',
      cell: (row) => (
        <StatusPill label={t(listingStateLabelKey(row.state))} tone={listingStateTone(row.state)} />
      ),
    },
    { id: 'propertyName', header: t('field.property'), priority: 'meta', cell: (row) => row.propertyName },
    {
      id: 'updatedAt',
      header: t('field.submitted'),
      sortable: true,
      priority: 'secondary',
      cell: (row) => <DateTimeDisplay value={row.updatedAt} relative />,
    },
  ];

  return (
    <ResourceListScreen
      isMock={LISTINGS_ARE_MOCK}
      title={t('approvals.title')}
      searchLabel={t('approvals.search')}
      columns={columns}
      rowKey={(row) => row.id}
      rowHref={(row) => `/console/listings/${row.id}?tab=workflow`}
      record="listing"
      caption={t('approvals.tableCaption')}
      emptyNoData={{ title: t('approvals.emptyTitle'), description: t('approvals.emptyDescription') }}
      table={table}
      query={query}
    />
  );
}
