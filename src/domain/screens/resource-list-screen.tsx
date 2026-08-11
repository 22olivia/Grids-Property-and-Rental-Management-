'use client';

import type { ReactNode } from 'react';
import { Plus } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { Button, Card } from '@/design-system/ui';
import type { RecordClass } from '@/design-system/ui';
import { Link } from '@/lib/i18n/routing';
import { DataTable, type DataTableColumn } from '@/domain/components/data-table';
import { FilterBar, type FilterDefinition } from '@/domain/components/filter-bar';
import { MockDataNotice } from '@/domain/components/mock-data-notice';
import { toDisplayError } from '@/lib/api/display-error';
import type { ListResult } from '@/lib/data/repository';
import type { useTableState } from '@/lib/tables/use-table-state';

/**
 * ===========================================================================
 * SCREEN ARCHETYPE A — resource list
 * ===========================================================================
 *
 * Covers 43 of the 227 derived screens. Composes the header, create action,
 * filter bar, table, pagination, all four empty kinds and error mapping.
 *
 * Deliberately a COMPOSITION, not a generated screen. A page supplies a
 * descriptor and keeps ownership of its own data hook, so any screen can stop
 * using this and drop to raw parts without affecting the others. The 30% of
 * list screens that need something unusual — the occupancy board, bank
 * reconciliation — are not forced through a configuration flag.
 * ===========================================================================
 */

export interface ResourceListScreenProps<T> {
  title: string;
  createAction?: { label: string; href: string };
  /** Extra toolbar controls (bulk actions, view switches). */
  toolbar?: ReactNode;
  searchLabel: string;
  /**
   * Hides the search input when the backend endpoint accepts no `search`
   * parameter. A search box that silently does nothing is worse than no search
   * box — the user assumes their query was applied and the result set was
   * genuinely empty.
   */
  searchDisabled?: boolean;
  filters?: FilterDefinition[];
  columns: DataTableColumn<T>[];
  rowKey: (row: T) => string;
  rowHref?: (row: T) => string;
  record?: RecordClass;
  /** Screen-reader table caption. Required — see DataTable. */
  caption: string;
  emptyNoData: { title: string; description: string };
  /** True when this screen's module is running on fixtures. */
  isMock: boolean;
  table: ReturnType<typeof useTableState>;
  query: {
    data?: ListResult<T>;
    isLoading: boolean;
    isFetching?: boolean;
    error: unknown;
    refetch: () => void;
  };
}

export function ResourceListScreen<T>({
  title,
  createAction,
  toolbar,
  searchLabel,
  searchDisabled = false,
  filters = [],
  columns,
  rowKey,
  rowHref,
  record,
  caption,
  emptyNoData,
  isMock,
  table,
  query,
}: ResourceListScreenProps<T>) {
  const tc = useTranslations('common');

  return (
    <div className="flex flex-col gap-4">
      <MockDataNotice active={isMock} />

      <div className="flex flex-wrap items-center gap-3">
        <h1 className="text-xl font-semibold">{title}</h1>
        <div className="ms-auto flex items-center gap-2">
          {toolbar}
          {createAction && (
            <Button asChild>
              <Link href={createAction.href}>
                <Plus className="size-4" aria-hidden="true" />
                {createAction.label}
              </Link>
            </Button>
          )}
        </div>
      </div>

      <Card className="flex flex-col gap-4">
        <FilterBar
          state={table.state}
          filters={filters}
          onChange={table.update}
          onClear={table.clearFilters}
          hasFilters={table.hasFilters}
          resultCount={query.data?.total ?? null}
          searchLabel={searchLabel}
          searchDisabled={searchDisabled}
        />

        <DataTable
          columns={columns}
          rows={query.data?.items ?? []}
          rowKey={rowKey}
          caption={caption}
          state={table.state}
          hasFilters={table.hasFilters}
          onSort={table.toggleSort}
          onPageChange={(page) => table.update({ page })}
          onClearFilters={table.clearFilters}
          total={query.data?.total ?? null}
          effectivePerPage={query.data?.perPage}
          isLoading={query.isLoading}
          isFetching={query.isFetching}
          error={toDisplayError(query.error, tc('unexpectedError'))}
          onRetry={query.refetch}
          rowHref={rowHref}
          record={record}
          emptyNoData={emptyNoData}
        />
      </Card>
    </div>
  );
}
