'use client';

import type { ReactNode } from 'react';
import { cn } from '@/lib/utils/cn';
import { Button } from './button';
import { Spinner } from './spinner';

/**
 * ===========================================================================
 * Loading, empty and error states.
 * ===========================================================================
 *
 * FR-MOB-001's acceptance criteria require that "loading, empty, error and
 * success states are usable and accessible". Stated for mobile; applied here
 * as the product standard for web.
 *
 * The EMPTY state has FOUR distinct kinds. Collapsing them is the most common
 * quality failure in admin products, and each needs different copy and a
 * different action:
 *
 *   'no-data'      first run. Explain the concept, offer the primary action.
 *   'no-results'   data exists, filters exclude it. Offer to clear filters.
 *                  Showing 'no-data' copy here tells the user their records
 *                  are gone, which is alarming and false.
 *   'no-access'    403. Name what is needed and who to ask. NEVER render an
 *                  empty list for this — an empty list means "nothing
 *                  exists", which is misleading and leaks nothing useful.
 *   'scope-empty'  the user's scope genuinely contains nothing (an owner with
 *                  no properties assigned). The fix is administrative.
 * ===========================================================================
 */

export function LoadingState({ label, className }: { label: string; className?: string }) {
  return (
    <div
      role="status"
      aria-live="polite"
      aria-busy="true"
      className={cn('flex flex-col items-center justify-center gap-3 p-10', className)}
    >
      <Spinner className="size-6 text-[var(--color-text-muted)]" />
      <p className="text-sm text-[var(--color-text-muted)]">{label}</p>
    </div>
  );
}

export type EmptyKind = 'no-data' | 'no-results' | 'no-access' | 'scope-empty';

export interface EmptyStateProps {
  kind: EmptyKind;
  title: string;
  description: string;
  /** Primary action. Omit for 'no-access' — there is nothing to retry. */
  action?: { label: string; onClick: () => void };
  icon?: ReactNode;
  className?: string;
}

export function EmptyState({ kind, title, description, action, icon, className }: EmptyStateProps) {
  return (
    <div
      data-empty-kind={kind}
      className={cn(
        'flex flex-col items-center justify-center gap-3 p-10 text-center',
        className,
      )}
    >
      {icon && (
        <span className="text-[var(--color-text-subtle)]" aria-hidden="true">
          {icon}
        </span>
      )}
      <h3 className="text-base font-semibold">{title}</h3>
      <p className="max-w-prose text-sm text-[var(--color-text-muted)]">{description}</p>
      {action && (
        <Button variant="secondary" onClick={action.onClick} className="mt-2">
          {action.label}
        </Button>
      )}
    </div>
  );
}

export interface ErrorStateProps {
  title: string;
  description: string;
  retryLabel?: string;
  onRetry?: () => void;
  /**
   * Surfaced verbatim so a user can quote it to support.
   * SRS §12 puts correlation_id in every envelope; carrying it to the UI
   * costs nothing and is disproportionately useful in a support call.
   */
  correlationId?: string | null;
  correlationLabel?: string;
  className?: string;
}

export function ErrorState({
  title,
  description,
  retryLabel,
  onRetry,
  correlationId,
  correlationLabel,
  className,
}: ErrorStateProps) {
  return (
    <div
      role="alert"
      className={cn('flex flex-col items-center justify-center gap-3 p-10 text-center', className)}
    >
      <h3 className="text-base font-semibold">{title}</h3>
      <p className="max-w-prose text-sm text-[var(--color-text-muted)]">{description}</p>
      {onRetry && retryLabel && (
        <Button variant="secondary" onClick={onRetry} className="mt-2">
          {retryLabel}
        </Button>
      )}
      {correlationId && (
        <p className="mt-2 text-xs text-[var(--color-text-subtle)]">
          {correlationLabel}{' '}
          <code className="reference select-all">{correlationId}</code>
        </p>
      )}
    </div>
  );
}
