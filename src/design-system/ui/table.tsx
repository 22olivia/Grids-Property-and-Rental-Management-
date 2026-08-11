import { cn } from '@/lib/utils/cn';

/**
 * Table primitives.
 *
 * Accessibility contract:
 *  - <caption> is REQUIRED. A data table without one is unnavigable by
 *    screen reader (WCAG 1.3.1). Use VisuallyHidden if it must not be seen.
 *  - Header cells use scope="col" / scope="row" so cell-to-header
 *    association is programmatic.
 *  - Sortable headers carry aria-sort.
 *
 * RTL: column order mirrors automatically because table layout follows the
 * document direction. Numeric columns use text-end (logical), so figures
 * align to the reading edge in both directions rather than jumping sides.
 */

export function TableContainer({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      // tabIndex + role make a horizontally scrollable region keyboard
      // reachable — WCAG 2.1.1.
      tabIndex={0}
      role="region"
      className={cn(
        'w-full overflow-x-auto rounded-[var(--radius-lg)] border border-[var(--color-border)]',
        className,
      )}
      {...props}
    />
  );
}

export function Table({ className, ...props }: React.TableHTMLAttributes<HTMLTableElement>) {
  return <table className={cn('w-full border-collapse text-sm', className)} {...props} />;
}

export function TableCaption({ className, ...props }: React.HTMLAttributes<HTMLElement>) {
  return (
    <caption className={cn('p-3 text-start text-[var(--color-text-muted)]', className)} {...props} />
  );
}

export function TableHead({ className, ...props }: React.HTMLAttributes<HTMLTableSectionElement>) {
  return <thead className={cn('bg-[var(--color-surface-sunken)]', className)} {...props} />;
}

export function TableBody(props: React.HTMLAttributes<HTMLTableSectionElement>) {
  return <tbody {...props} />;
}

export interface TableRowProps extends React.HTMLAttributes<HTMLTableRowElement> {
  record?: 'asset' | 'listing' | 'contract' | 'money' | 'party';
}

export function TableRow({ className, record, ...props }: TableRowProps) {
  return (
    <tr
      data-record={record}
      className={cn(
        'border-b border-[var(--color-border)] last:border-0',
        record && 'record-spine',
        className,
      )}
      {...props}
    />
  );
}

export interface TableHeaderCellProps extends React.ThHTMLAttributes<HTMLTableCellElement> {
  /** Set on sortable columns so state is announced. */
  sort?: 'ascending' | 'descending' | 'none';
  numeric?: boolean;
}

export function TableHeaderCell({ className, sort, numeric, ...props }: TableHeaderCellProps) {
  return (
    <th
      scope="col"
      aria-sort={sort}
      className={cn(
        'h-[var(--density-row-height)] px-3 text-start align-middle font-medium',
        numeric && 'text-end tabular',
        className,
      )}
      {...props}
    />
  );
}

export interface TableCellProps extends React.TdHTMLAttributes<HTMLTableCellElement> {
  numeric?: boolean;
}

export function TableCell({ className, numeric, ...props }: TableCellProps) {
  return (
    <td
      className={cn(
        'h-[var(--density-row-height)] px-3 align-middle',
        numeric && 'text-end tabular',
        className,
      )}
      {...props}
    />
  );
}
