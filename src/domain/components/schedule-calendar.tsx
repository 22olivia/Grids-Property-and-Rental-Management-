'use client';

import { useLocale, useTranslations } from 'next-intl';
import { Alert, EmptyState, LoadingState } from '@/design-system/ui';
import { Link } from '@/lib/i18n/routing';
import { intlLocale, type Locale } from '@/lib/i18n/config';
import { StatusPill, type StatusTone } from './status-pill';

/**
 * ===========================================================================
 * SCREEN ARCHETYPE Q — schedule.
 * ===========================================================================
 *
 * Rendered as a grouped LIST by day rather than a month grid.
 *
 * That is not a shortcut. MISSING INFORMATION (MI-14): the week start
 * (Saturday / Sunday / Monday) is market-dependent and undefined anywhere in
 * the SRS. A month or week GRID cannot be laid out without it — the columns
 * would be wrong for whichever markets ship first (baseline decision #5 is
 * also open). A day-grouped list is correct under every possible answer,
 * mirrors cleanly in RTL, and is more usable on a phone.
 *
 * The grid view is a straight upgrade once MI-14 and the v1 markets are
 * decided; nothing here has to be unpicked.
 * ===========================================================================
 */

export interface ScheduleEntry {
  id: string;
  /** UTC instant — NFR-DATA-001. */
  startsAt: string;
  title: string;
  subtitle: string | null;
  status: { label: string; tone: StatusTone };
  href?: string;
}

export function ScheduleCalendar({
  entries,
  isLoading,
  timeZone,
}: {
  entries: ScheduleEntry[] | undefined;
  isLoading: boolean;
  timeZone?: string;
}) {
  const t = useTranslations('crm');
  const tc = useTranslations('common');
  const locale = useLocale() as Locale;

  if (isLoading) return <LoadingState label={tc('loading')} />;
  if (!entries || entries.length === 0) {
    return (
      <EmptyState
        kind="no-data"
        title={t('viewings.emptyTitle')}
        description={t('viewings.emptyDescription')}
      />
    );
  }

  const zone = timeZone ?? Intl.DateTimeFormat().resolvedOptions().timeZone;
  const dayFormatter = new Intl.DateTimeFormat(intlLocale[locale], {
    timeZone: zone,
    weekday: 'long',
    day: 'numeric',
    month: 'long',
  });
  const timeFormatter = new Intl.DateTimeFormat(intlLocale[locale], {
    timeZone: zone,
    timeStyle: 'short',
  });

  const groups = new Map<string, ScheduleEntry[]>();
  for (const entry of [...entries].sort((a, b) => a.startsAt.localeCompare(b.startsAt))) {
    const key = dayFormatter.format(new Date(entry.startsAt));
    groups.set(key, [...(groups.get(key) ?? []), entry]);
  }

  return (
    <div className="flex flex-col gap-4">
      <Alert tone="info" title={t('viewings.calendarNoticeTitle')}>
        {t('viewings.calendarNoticeBody')}
      </Alert>

      {[...groups.entries()].map(([day, dayEntries]) => (
        <section key={day} aria-label={day}>
          <h3 className="mb-2 text-sm font-medium text-[var(--color-text-muted)]">{day}</h3>
          <ol className="flex flex-col gap-2">
            {dayEntries.map((entry) => (
              <li
                key={entry.id}
                data-record="party"
                className="record-spine flex flex-wrap items-center gap-3 rounded-[var(--radius-md)] border border-[var(--color-border)] p-3"
              >
                {/* Times are Latin-numeric in most locales; tabular keeps a
                    column of them aligned. */}
                <time
                  dateTime={entry.startsAt}
                  className="tabular text-sm font-medium"
                >
                  {timeFormatter.format(new Date(entry.startsAt))}
                </time>
                <span className="text-sm">
                  {entry.href ? (
                    <Link href={entry.href} className="underline-offset-4 hover:underline">
                      {entry.title}
                    </Link>
                  ) : (
                    entry.title
                  )}
                </span>
                {entry.subtitle && (
                  <span className="text-xs text-[var(--color-text-muted)]">{entry.subtitle}</span>
                )}
                <span className="ms-auto">
                  <StatusPill label={entry.status.label} tone={entry.status.tone} />
                </span>
              </li>
            ))}
          </ol>
        </section>
      ))}
    </div>
  );
}
