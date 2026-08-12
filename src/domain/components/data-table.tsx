'use client';

import type { ReactNode } from 'react';
import { ArrowDown, ArrowUp, ChevronsUpDown } from 'lucide-react';
import { useTranslations } from 'next-intl';
import {
  TableContainer,
  Table,
  TableCaption,
  TableHead,
  TableBody,
  TableRow,
  TableHeaderCell,
  TableCell,
  TableSkeleton,
  EmptyState,
  ErrorState,
  Pagination,
  VisuallyHidden,
} from '@/design-system/ui';
import type { RecordClass } from '@/design-system/ui';
import { cn } from '@/lib/utils/cn';
import { Link } from '@/lib/i18n/routing';
import type { DisplayError } from '@/lib/api/display-error';
import type { TableState } from '@/lib/tables/use-table-state';

/**
 * The list primitive. ~60 eventual list screens depend on it, so its
 * behaviours are decided once here rather than per screen.
 *
 * Notable decisions:
 *  - A refetching table RETAINS its rows and dims them. Blanking a populated
 *    table on every filter keystroke is disorienting and looks like data loss.
 *  - Empty has four distinct kinds and the table picks between them from the
 *    filter state, so no screen can accidentally show "nothing exists" to a
 *    user who has simply over-filtered.
 *  - Below `md` the table becomes a card list. This is a configuration of one
 *    component, not a second implementation per screen.
 */

export interface DataTableColumn<T> {
  id: string;
  header: string;
  cell: (row: T) => ReactNode;
  sortable?: boolean;
  numeric?: boolean;
  /** Shown in the mobile card layout. Others are hidden below `md`. */
  priority?: 'primary' | 'secondary' | 'meta';
}

export interface DataTableProps<T> {
  columns: DataTableColumn<T>[];
  rows: T[];
  rowKey: (row: T) => string;
  /** Required. A data table without one is unnavigable by screen reader. */
  caption: string;
  state: TableState;
  hasFilters: boolean;
  onSort: (columnId: string) => void;
  onPageChange: (page: number) => void;
  onClearFilters: () => void;
  total: number | null;
  /**
   * Page size the SERVER actually applied.
   *
   * Not the same as the requested size: PropertyController hardcodes
   * `paginate(15)` and ignores `per_page`. Computing page count from the
   * request produced a wrong last page and offered "next" past the end.
   * Always derive paging from what came back.
   */
  effectivePerPage?: number;
  isLoading: boolean;
  isFetching?: boolean;
  error?: DisplayError | null;
  onRetry?: () => void;
  /**
   * Destination for a row.
   *
   * A LINK, not a click handler. An onClick on <tr> is unreachable by keyboard
   * (WCAG 2.1.1), invisible to screen readers as a navigation target, and
   * cannot be opened in a new tab or copied. The link lives in the primary
   * column; the rest of the row is styled as hoverable for pointer users.
   */
  rowHref?: (row: T) => string;
  record?: RecordClass;
  /** Copy for the first-run empty state — always module-specific. */
  emptyNoData: { title: string; description: string };
}

export function DataTable<T>({
  columns,
  rows,
  rowKey,
  caption,
  state,
  hasFilters,
  onSort,
  onPageChange,
  onClearFilters,
  total,
  effectivePerPage,
  isLoading,
  isFetching,
  error,
  onRetry,
  rowHref,
  record,
  emptyNoData,
}: DataTableProps<T>) {
  const t = useTranslations();

  if (error) {
    return (
      <ErrorState
        title={t('states.error.title')}
        description={error.message}
        retryLabel={t('common.retry')}
        onRetry={onRetry}
        correlationId={error.correlationId}
        correlationLabel={t('errors.reference')}
      />
    );
  }

  if (isLoading) {
    return (
      <div role="status" aria-busy="true" aria-live="polite">
        <VisuallyHidden>{t('common.loading')}</VisuallyHidden>
        <TableSkeleton rows={6} columns={Math.min(columns.length, 5)} />
      </div>
    );
  }

  if (rows.length === 0) {
    // Two genuinely different situations. Telling a user their records are
    // gone when they have merely over-filtered is alarming and false.
    return hasFilters ? (
      <EmptyState
        kind="no-results"
        title={t('states.noResults.title')}
        description={t('states.noResults.description')}
        action={{ label: t('states.noResults.action'), onClick: onClearFilters }}
      />
    ) : (
      <EmptyState kind="no-data" title={emptyNoData.title} description={emptyNoData.description} />
    );
  }

  const perPage = effectivePerPage ?? state.perPage;
  const totalPages = total !== null ? Math.max(1, Math.ceil(total / perPage)) : undefined;
  const mobileColumns = columns.filter((column) => column.priority && column.priority !== 'meta');
  const primaryColumnId = columns.find((column) => column.priority === 'primary')?.id;

  return (
    <div className={cn('flex flex-col', isFetching && 'opacity-60 transition-opacity')}>
      {/* Desktop: real table semantics. */}
      <TableContainer className="hidden md:block">
        <Table>
          <TableCaption>
            <VisuallyHidden>{caption}</VisuallyHidden>
          </TableCaption>
          <TableHead>
            <TableRow>
              {columns.map((column) => {
                const active = state.sort === column.id;
                const ariaSort = active
                  ? state.direction === 'asc'
                    ? ('ascending' as const)
                    : ('descending' as const)
                  : ('none' as const);
                return (
                  <TableHeaderCell
                    key={column.id}
                    numeric={column.numeric}
                    sort={column.sortable ? ariaSort : undefined}
                  >
                    {column.sortable ? (
                      <button
                        type="button"
                        onClick={() => onSort(column.id)}
                        className="inline-flex min-h-9 items-center gap-1 hover:underline"
                      >
                        {column.header}
                        {active ? (
                          state.direction === 'asc' ? (
                            <ArrowUp className="size-3.5" aria-hidden="true" />
                          ) : (
                            <ArrowDown className="size-3.5" aria-hidden="true" />
                          )
                        ) : (
                          <ChevronsUpDown className="size-3.5 opacity-40" aria-hidden="true" />
                        )}
                      </button>
                    ) : (
                      column.header
                    )}
                  </TableHeaderCell>
                );
              })}
            </TableRow>
          </TableHead>
          <TableBody>
            {rows.map((row) => (
              <TableRow
                key={rowKey(row)}
                record={record}
                className={rowHref ? 'hover:bg-[var(--color-surface-sunken)]' : undefined}
              >
                {columns.map((column) => (
                  <TableCell key={column.id} numeric={column.numeric}>
                    {rowHref && column.id === primaryColumnId ? (
                      <Link
                        href={rowHref(row)}
                        className="underline-offset-4 hover:underline focus-visible:underline"
                      >
                        {column.cell(row)}
                      </Link>
                    ) : (
                      column.cell(row)
                    )}
                  </TableCell>
                ))}
              </TableRow>
            ))}
          </TableBody>
        </Table>
      </TableContainer>

      {/* Below md: cards. A 9-column table on a 320px screen is not usable,
          and horizontal scrolling through it is worse than a card list. */}
      <ul className="flex flex-col gap-2 md:hidden">
        {rows.map((row) => (
          <li key={rowKey(row)}>
            {(() => {
              const body = mobileColumns.map((column) => (
                <span key={column.id} className="flex justify-between gap-3 py-0.5">
                  <span className="text-xs text-[var(--color-text-muted)]">{column.header}</span>
                  <span className={cn('text-sm', column.numeric && 'tabular')}>
                    {column.cell(row)}
                  </span>
                </span>
              ));
              const cardClass = cn(
                'block w-full rounded-[var(--radius-lg)] border border-[var(--color-border)] p-4 text-start',
                'bg-[var(--color-surface-raised)]',
                record && 'record-spine',
                rowHref && 'hover:bg-[var(--color-surface-sunken)]',
              );
              return rowHref ? (
                <Link href={rowHref(row)} data-record={record} className={cardClass}>
                  {body}
                </Link>
              ) : (
                <div data-record={record} className={cardClass}>
                  {body}
                </div>
              );
            })()}
          </li>
        ))}
      </ul>

      <Pagination
        mode="page"
        page={state.page}
        totalPages={totalPages}
        hasPrevious={state.page > 1}
        hasNext={totalPages !== undefined ? state.page < totalPages : rows.length === perPage}
        onPrevious={() => onPageChange(state.page - 1)}
        onNext={() => onPageChange(state.page + 1)}
        labels={{
          navigation: t('pagination.navigation'),
          previous: t('pagination.previous'),
          next: t('pagination.next'),
          status: t('pagination.status', { page: state.page, total: totalPages ?? 1 }),
        }}
      />
    </div>
  );
}
