'use client';

import { useLocale } from 'next-intl';
import { formatMoney, type Money } from '@/domain/money/money';
import type { Locale } from '@/lib/i18n/config';
import { cn } from '@/lib/utils/cn';

/**
 * Renders a server-computed monetary value.
 *
 * `tabular` is not cosmetic: proportional figures make a column of amounts
 * unreadable, and this component appears in every financial table.
 */
export function MoneyDisplay({
  value,
  className,
  showCode = false,
}: {
  value: Money | null | undefined;
  className?: string;
  showCode?: boolean;
}) {
  const locale = useLocale() as Locale;
  if (!value) return <span className={cn('text-[var(--color-text-subtle)]', className)}>—</span>;
  return (
    <span className={cn('tabular', className)}>
      {formatMoney(value, { locale, showCode })}
    </span>
  );
}
