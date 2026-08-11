'use client';

import { useLocale } from 'next-intl';
import { formatDateTime, formatRelative, type IsoInstant } from '@/domain/datetime/datetime';
import type { Locale } from '@/lib/i18n/config';

/**
 * Renders a UTC instant in the viewer's timezone (NFR-DATA-001).
 *
 * MISSING INFORMATION (MI-08): NFR-DATA-001 says "company/user timezone"
 * without stating which wins. Until the precedence rule is published, the
 * timezone falls back to the browser's — visible and consistent, rather than a
 * silent guess at company policy. The fallback is isolated here, so resolving
 * MI-08 is a one-line change.
 */
export function DateTimeDisplay({
  value,
  timeZone,
  relative = false,
  withTime = false,
}: {
  value: IsoInstant | null | undefined;
  timeZone?: string;
  relative?: boolean;
  withTime?: boolean;
}) {
  const locale = useLocale() as Locale;
  if (!value) return <span className="text-[var(--color-text-subtle)]">—</span>;

  const zone = timeZone ?? Intl.DateTimeFormat().resolvedOptions().timeZone;

  return (
    <time dateTime={value}>
      {relative
        ? formatRelative(value, locale)
        : formatDateTime(value, {
            locale,
            timeZone: zone,
            dateStyle: 'medium',
            ...(withTime ? { timeStyle: 'short' } : {}),
          })}
    </time>
  );
}
