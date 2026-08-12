'use client';

import { useLocale, useTranslations } from 'next-intl';
import { StatusPill, type StatusTone } from '@/domain/components/status-pill';

/**
 * A period during which a record held one status.
 * Shared shape: units (FR-AST-003), and later listings (FR-LST-006), leases
 * (FR-LSE-004) and maintenance requests (FR-MNT-002) all express history this
 * way.
 */
export interface StatusPeriod {
  id: string;
  status: string;
  from: string;
  to: string | null;
  reference: string | null;
}
import { DateTimeDisplay } from '@/domain/components/date-time-display';
import { EmptyState, LoadingState, VisuallyHidden } from '@/design-system/ui';
import { isRtl } from '@/lib/i18n/direction';
import type { Locale } from '@/lib/i18n/config';

/**
 * Status timeline — generic over any record with a status history.
 *
 * First required by FR-AST-003 (unit availability, occupancy, reservation and
 * historical status timelines). Promoted out of the asset feature because
 * listing states (FR-LST-006), lease lifecycle (FR-LSE-004) and maintenance
 * workflow (FR-MNT-002) express history in exactly the same shape.
 *
 * ---------------------------------------------------------------------------
 * RTL NOTE — this is the component class most likely to break silently in
 * Arabic. A timeline computes positions from percentages, and percentage-based
 * horizontal offsets do NOT mirror automatically the way logical CSS does.
 *
 * Handled by anchoring bars with `inset-inline-start`, which IS direction-aware,
 * rather than `left`. The earliest period therefore sits at the reading start
 * in both languages — which is what "earliest" means to a reader in each.
 * ---------------------------------------------------------------------------
 *
 * Accessibility: the bar chart is decorative and aria-hidden. The same data is
 * rendered as a real list beneath it, which is what a screen reader and a
 * keyboard user actually navigate. A visual-only timeline would fail WCAG
 * 1.1.1 and 1.3.1.
 */
export function StatusTimeline({
  periods,
  isLoading,
  statusLabel,
  statusTone,
  toneClass,
}: {
  periods: StatusPeriod[] | undefined;
  isLoading: boolean;
  /** Message lookup for a status value — the vocabulary belongs to the module. */
  statusLabel: (status: string) => string;
  statusTone: (status: string) => StatusTone;
  /** Background class per status for the visual band. */
  toneClass: Record<string, string>;
}) {
  const t = useTranslations();
  const locale = useLocale() as Locale;

  if (isLoading) return <LoadingState label={t('common.loading')} />;

  if (!periods || periods.length === 0) {
    return (
      <EmptyState
        kind="no-data"
        title={t('timeline.emptyTitle')}
        description={t('timeline.emptyDescription')}
      />
    );
  }

  const times = periods.flatMap((period) => [
    new Date(period.from).getTime(),
    period.to ? new Date(period.to).getTime() : Date.now(),
  ]);
  const start = Math.min(...times);
  const end = Math.max(...times, Date.now());
  const span = Math.max(end - start, 1);

  return (
    <div className="flex flex-col gap-4">
      {/* Visual band — decorative. The list below is the accessible source. */}
      <div
        aria-hidden="true"
        className="relative h-8 w-full overflow-hidden rounded-[var(--radius-md)] bg-[var(--color-surface-sunken)]"
        data-direction={isRtl(locale) ? 'rtl' : 'ltr'}
      >
        {periods.map((period) => {
          const from = new Date(period.from).getTime();
          const to = period.to ? new Date(period.to).getTime() : Date.now();
          const offset = ((from - start) / span) * 100;
          const width = Math.max(((to - from) / span) * 100, 1);
          return (
            <span
              key={period.id}
              className={`absolute top-0 h-full ${toneClass[period.status] ?? 'bg-[var(--color-border-strong)]'}`}
              // inset-inline-start is direction-aware; `left` would pin the
              // earliest period to the visual left in Arabic, which reads as
              // "latest" to an Arabic reader.
              style={{ insetInlineStart: `${offset}%`, width: `${width}%` }}
            />
          );
        })}
      </div>

      <VisuallyHidden as="h3">{t('timeline.listLabel')}</VisuallyHidden>
      <ol className="flex flex-col gap-2">
        {periods.map((period) => (
          <li
            key={period.id}
            className="flex flex-wrap items-center gap-2 rounded-[var(--radius-md)] border border-[var(--color-border)] p-3"
          >
            <StatusPill
              label={statusLabel(period.status)}
              tone={statusTone(period.status)}
            />
            <span className="text-sm">
              <DateTimeDisplay value={period.from} />
              {' – '}
              {period.to ? (
                <DateTimeDisplay value={period.to} />
              ) : (
                <span>{t('timeline.present')}</span>
              )}
            </span>
            {period.reference && (
              <code className="reference ms-auto text-xs text-[var(--color-text-muted)]">
                {period.reference}
              </code>
            )}
          </li>
        ))}
      </ol>
    </div>
  );
}
