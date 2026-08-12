'use client';

import { useTranslations } from 'next-intl';
import { EmptyState, LoadingState } from '@/design-system/ui';
import { DateTimeDisplay } from './date-time-display';
import { StatusPill } from './status-pill';

export interface AuditEntry {
  id: string;
  occurredAt: string;
  actorName: string;
  category: string;
  field: string;
  previousValue: string | null;
  newValue: string | null;
}

/**
 * Change history.
 *
 * FR-AST-008 (Must): "every change to ownership, occupancy, price or
 * availability shall be historically traceable"
 * FR-IAM-008 (Must): complete audit trail for authentication, permission,
 * financial and master-data events
 *
 * Renders actor, timestamp and a before/after diff. Reused by every module
 * that has a history requirement, which is most of them.
 */
export function AuditTrail({
  entries,
  isLoading,
  categoryLabel,
}: {
  entries: AuditEntry[] | undefined;
  isLoading: boolean;
  categoryLabel: (category: string) => string;
}) {
  const t = useTranslations();

  if (isLoading) return <LoadingState label={t('common.loading')} />;

  if (!entries || entries.length === 0) {
    return (
      <EmptyState
        kind="no-data"
        title={t('audit.emptyTitle')}
        description={t('audit.emptyDescription')}
      />
    );
  }

  return (
    <ol className="flex flex-col gap-3">
      {entries.map((entry) => (
        <li
          key={entry.id}
          className="rounded-[var(--radius-md)] border border-[var(--color-border)] p-3"
        >
          <div className="flex flex-wrap items-center gap-2">
            <StatusPill label={categoryLabel(entry.category)} tone="info" />
            <span className="text-sm font-medium">{entry.field}</span>
            <span className="ms-auto text-xs text-[var(--color-text-muted)]">
              <DateTimeDisplay value={entry.occurredAt} withTime />
            </span>
          </div>
          <p className="mt-2 text-sm">
            <span className="text-[var(--color-text-muted)] line-through">
              {entry.previousValue ?? t('audit.none')}
            </span>
            {' → '}
            <span className="font-medium">{entry.newValue ?? t('audit.none')}</span>
          </p>
          <p className="mt-1 text-xs text-[var(--color-text-muted)]">
            {t('audit.by', { actor: entry.actorName })}
          </p>
        </li>
      ))}
    </ol>
  );
}
