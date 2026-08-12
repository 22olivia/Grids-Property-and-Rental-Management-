import type { Locale } from '@/lib/i18n/config';
import { intlLocale } from '@/lib/i18n/config';

/**
 * Date and time.
 *
 * NFR-DATA-001 (Must): "All time values shall be stored in UTC and displayed
 * in the company/user timezone." UTC therefore crosses the API boundary in
 * both directions; local-time values never do.
 *
 * All display conversion happens here. No call site should reach for
 * toLocaleString() directly — that is how timezone bugs spread.
 *
 * MISSING INFORMATION (MI-08): NFR-DATA-001 says "company/user timezone"
 * without stating which wins when they differ. `timeZone` is therefore a
 * required argument rather than a default, so the decision is made explicitly
 * by the caller until the precedence rule is confirmed.
 *
 * MISSING INFORMATION (MI-09): whether Hijri display is required alongside
 * Gregorian for the `ar` locale is unspecified. Gregorian is assumed. Adding
 * Hijri would mean an `ar-u-ca-islamic` variant here plus a calendar-aware
 * date picker.
 */

export type IsoInstant = string;

export interface FormatDateOptions {
  locale: Locale;
  /** IANA timezone, e.g. "Asia/Dubai". Explicit by design — see MI-08. */
  timeZone: string;
  dateStyle?: Intl.DateTimeFormatOptions['dateStyle'];
  timeStyle?: Intl.DateTimeFormatOptions['timeStyle'];
}

export function formatDateTime(
  instant: IsoInstant,
  { locale, timeZone, dateStyle = 'medium', timeStyle }: FormatDateOptions,
): string {
  const date = new Date(instant);
  if (Number.isNaN(date.getTime())) return '—';

  return new Intl.DateTimeFormat(intlLocale[locale], {
    timeZone,
    dateStyle,
    ...(timeStyle ? { timeStyle } : {}),
  }).format(date);
}

export function formatRelative(instant: IsoInstant, locale: Locale): string {
  const date = new Date(instant);
  if (Number.isNaN(date.getTime())) return '—';

  const deltaSeconds = (date.getTime() - Date.now()) / 1000;
  const units: [Intl.RelativeTimeFormatUnit, number][] = [
    ['year', 60 * 60 * 24 * 365],
    ['month', 60 * 60 * 24 * 30],
    ['day', 60 * 60 * 24],
    ['hour', 60 * 60],
    ['minute', 60],
  ];

  const rtf = new Intl.RelativeTimeFormat(intlLocale[locale], { numeric: 'auto' });
  for (const [unit, seconds] of units) {
    if (Math.abs(deltaSeconds) >= seconds) {
      return rtf.format(Math.round(deltaSeconds / seconds), unit);
    }
  }
  return rtf.format(Math.round(deltaSeconds), 'second');
}
