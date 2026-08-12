/**
 * Locale configuration.
 *
 * SRS FR-MKT-005 (Must): "multilingual and RTL content with Arabic and
 * English as launch languages". FR-ADM-002 additionally lets companies
 * configure languages, implying more locales later — so the list is a
 * single source of truth rather than being spread through the codebase.
 *
 * MISSING INFORMATION (MI-06): the SRS does not say whether additional
 * languages are per-company or platform-wide, nor whether a company may
 * disable one of the two launch languages. Routing currently assumes a
 * platform-wide locale set.
 */
export const locales = ['en', 'ar'] as const;
export type Locale = (typeof locales)[number];

export const defaultLocale: Locale = 'en';

/** Text direction per locale. The only direction mapping in the codebase. */
export const localeDirection: Record<Locale, 'ltr' | 'rtl'> = {
  en: 'ltr',
  ar: 'rtl',
};

/** Native locale names, shown in the language switcher in their own script. */
export const localeNames: Record<Locale, string> = {
  en: 'English',
  ar: 'العربية',
};

/**
 * BCP-47 tags used for Intl formatting.
 *
 * MISSING INFORMATION (MI-04): the numeral system for Arabic is undecided —
 * Western (123) vs Eastern Arabic (١٢٣). It affects money, dates, invoice
 * numbers, phone numbers and every table, and some markets have legal
 * expectations for financial documents. `ar` currently resolves to the
 * platform default. To switch to Eastern digits, change to
 * 'ar-u-nu-arab' here and nowhere else — this is the single point of change.
 */
export const intlLocale: Record<Locale, string> = {
  en: 'en-US',
  ar: 'ar',
};

export function isLocale(value: string): value is Locale {
  return (locales as readonly string[]).includes(value);
}

export function getDirection(locale: Locale): 'ltr' | 'rtl' {
  return localeDirection[locale];
}
