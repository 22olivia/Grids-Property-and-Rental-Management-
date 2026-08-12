import type { Locale } from '@/lib/i18n/config';
import { intlLocale } from '@/lib/i18n/config';

/**
 * Money.
 *
 * SRS §6: "financial and authorization rules shall not be independently
 * reimplemented in clients." The frontend therefore FORMATS money and never
 * COMPUTES it. There is deliberately no add(), subtract() or total() here —
 * totals, allocations, aging, settlement nets, commissions and tax all arrive
 * from the API already computed.
 *
 * An amount is never a bare number: FR-FIN-002 requires multi-currency, so
 * currency travels with every value.
 *
 * MISSING INFORMATION (MI-02): the wire representation of `amount` is not
 * specified. Minor-unit integers (e.g. 150000 for 1,500.00) and decimal
 * strings are both defensible; floating-point is not, and SRS risk R-04
 * ("financial functions require greater assurance than ordinary CRUD") is
 * the reason. `amount` is typed as `string` below because a decimal string
 * survives either decision without precision loss. This must be confirmed
 * before any financial screen is built.
 */
export interface Money {
  /** Decimal string, e.g. "1500.00". Never a JS number — see MI-02. */
  readonly amount: string;
  /** ISO 4217 code, e.g. "AED". Never translated. */
  readonly currency: string;
}

export interface FormatMoneyOptions {
  locale: Locale;
  /** Show the currency code instead of the symbol (useful in dense tables). */
  showCode?: boolean;
  /**
   * Fraction digits. Omit to use the currency's own convention — do NOT
   * round for display in a way that makes a total disagree with its lines.
   */
  fractionDigits?: number;
}

/** A well-formed decimal string. Validated by shape, never by Number(). */
const DECIMAL_PATTERN = /^-?\d+(\.\d+)?$/;

export function formatMoney(
  money: Money,
  { locale, showCode = false, fractionDigits }: FormatMoneyOptions,
): string {
  // A malformed amount must be visible, not silently rendered as 0 — a wrong
  // number on a financial screen is worse than an obvious placeholder.
  if (!DECIMAL_PATTERN.test(money.amount)) return '—';

  const formatter = new Intl.NumberFormat(intlLocale[locale], {
    style: 'currency',
    currency: money.currency,
    currencyDisplay: showCode ? 'code' : 'symbol',
    ...(fractionDigits !== undefined
      ? { minimumFractionDigits: fractionDigits, maximumFractionDigits: fractionDigits }
      : {}),
  });

  // Format the STRING, not a Number.
  //
  // Intl.NumberFormat V3 accepts a decimal string and formats it exactly.
  // Going through Number() first silently rounds beyond 2^53 — verified:
  //   "12345678901234567.89" -> 12,345,678,901,234,568.00
  // The whole point of carrying money as a string (MI-02) is defeated if the
  // display layer converts it back. SRS risk R-04 is explicit that financial
  // functions need more assurance than ordinary CRUD.
  return formatter.format(money.amount as unknown as number);
}

export function formatNumber(
  value: number,
  locale: Locale,
  options?: Intl.NumberFormatOptions,
): string {
  return new Intl.NumberFormat(intlLocale[locale], options).format(value);
}

export function formatPercent(value: number, locale: Locale, fractionDigits = 1): string {
  return new Intl.NumberFormat(intlLocale[locale], {
    style: 'percent',
    minimumFractionDigits: fractionDigits,
    maximumFractionDigits: fractionDigits,
  }).format(value);
}
