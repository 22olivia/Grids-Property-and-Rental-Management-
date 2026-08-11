'use client';

import { useTranslations } from 'next-intl';
import { ChevronLeft, ChevronRight } from 'lucide-react';
import { Button, LoadingState } from '@/design-system/ui';
import { Link } from '@/lib/i18n/routing';
import { DirectionalIcon } from '@/design-system/ui';
import { cn } from '@/lib/utils/cn';

/**
 * ===========================================================================
 * SCREEN ARCHETYPE R — pipeline board.
 * ===========================================================================
 *
 * ACCESSIBILITY IS THE WHOLE DESIGN HERE.
 *
 * The obvious implementation is HTML5 drag-and-drop, which is unusable by
 * keyboard and largely invisible to screen readers — a WCAG 2.1.1 failure that
 * would exclude anyone who cannot use a pointer from the sales pipeline.
 *
 * So the primary interaction is a pair of MOVE BUTTONS on every card, each
 * with an explicit accessible name ("Move Sample lead 3 to Viewing"). The
 * board is an ordered list of columns, each an ordered list of cards; the
 * structure alone conveys the pipeline. Pointer drag can be layered on top
 * later — as an addition, never as the only path.
 *
 * The move buttons are direction-aware: in Arabic, "previous stage" is to the
 * right, and DirectionalIcon mirrors the chevrons accordingly.
 * ===========================================================================
 */

export interface BoardColumn<T> {
  id: string;
  label: string;
  items: T[];
}

export interface PipelineBoardProps<T> {
  columns: BoardColumn<T>[];
  itemKey: (item: T) => string;
  itemHref?: (item: T) => string;
  renderItem: (item: T) => React.ReactNode;
  /** Accessible name for a move, e.g. "Move {name} to {stage}". */
  moveLabel: (item: T, targetColumnLabel: string) => string;
  /** Name for a move button that has nowhere to go. A disabled icon-only
   *  button still needs an accessible name — otherwise a screen reader
   *  announces "button" with no indication of what it would do. */
  noMoveLabel: (direction: 'previous' | 'next') => string;
  onMove: (item: T, targetColumnId: string) => void;
  isLoading?: boolean;
  isPending?: boolean;
  boardLabel: string;
  emptyColumnLabel: string;
}

export function PipelineBoard<T>({
  columns,
  itemKey,
  itemHref,
  renderItem,
  moveLabel,
  noMoveLabel,
  onMove,
  isLoading,
  isPending,
  boardLabel,
  emptyColumnLabel,
}: PipelineBoardProps<T>) {
  const tc = useTranslations('common');
  if (isLoading) return <LoadingState label={tc('loading')} />;

  return (
    <div
      // Horizontal scrolling region must be keyboard reachable (WCAG 2.1.1).
      role="region"
      aria-label={boardLabel}
      tabIndex={0}
      className={cn('w-full overflow-x-auto pb-2', isPending && 'opacity-60')}
    >
      <ol className="flex min-w-max gap-3">
        {columns.map((column, columnIndex) => {
          const previous = columns[columnIndex - 1];
          const next = columns[columnIndex + 1];
          return (
            <li key={column.id} className="w-72 shrink-0">
              <div className="rounded-[var(--radius-lg)] bg-[var(--color-surface-sunken)] p-2">
                <h3 className="flex items-center justify-between px-2 py-1 text-sm font-medium">
                  {column.label}
                  <span className="tabular text-xs text-[var(--color-text-muted)]">
                    {column.items.length}
                  </span>
                </h3>

                {column.items.length === 0 ? (
                  <p className="px-2 py-6 text-center text-xs text-[var(--color-text-subtle)]">
                    {emptyColumnLabel}
                  </p>
                ) : (
                  <ol aria-label={column.label} className="flex flex-col gap-2">
                    {column.items.map((item) => (
                      <li
                        key={itemKey(item)}
                        data-record="party"
                        className="record-spine rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-raised)] p-3"
                      >
                        {itemHref ? (
                          <Link
                            href={itemHref(item)}
                            className="block underline-offset-4 hover:underline focus-visible:underline"
                          >
                            {renderItem(item)}
                          </Link>
                        ) : (
                          renderItem(item)
                        )}

                        <div className="mt-2 flex items-center gap-1">
                          <Button
                            variant="ghost"
                            size="icon"
                            disabled={!previous || isPending}
                            aria-label={
                              previous ? moveLabel(item, previous.label) : noMoveLabel('previous')
                            }
                            onClick={() => previous && onMove(item, previous.id)}
                          >
                            <DirectionalIcon>
                              <ChevronLeft className="size-4" />
                            </DirectionalIcon>
                          </Button>
                          <Button
                            variant="ghost"
                            size="icon"
                            disabled={!next || isPending}
                            aria-label={next ? moveLabel(item, next.label) : noMoveLabel('next')}
                            onClick={() => next && onMove(item, next.id)}
                          >
                            <DirectionalIcon>
                              <ChevronRight className="size-4" />
                            </DirectionalIcon>
                          </Button>
                        </div>
                      </li>
                    ))}
                  </ol>
                )}
              </div>
            </li>
          );
        })}
      </ol>
    </div>
  );
}
