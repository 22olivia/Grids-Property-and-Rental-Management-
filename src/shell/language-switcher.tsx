'use client';

import { useTransition } from 'react';
import { useLocale, useTranslations } from 'next-intl';
import { Languages } from 'lucide-react';
import { usePathname, useRouter } from '@/lib/i18n/routing';
import { locales, localeNames, type Locale } from '@/lib/i18n/config';
import {
  Button,
  DropdownMenu,
  DropdownMenuContent,
  DropdownMenuItem,
  DropdownMenuTrigger,
} from '@/design-system/ui';

/**
 * Language switcher.
 *
 * Preserves pathname AND query string. Switching language on a filtered
 * search must not discard the filters — losing a user's work because they
 * changed language is a real failure, and it is easy to ship by accident.
 *
 * Language is a durable user preference, not a session property: next-intl
 * persists the choice in a cookie, so it survives logout.
 */
export function LanguageSwitcher() {
  const t = useTranslations('shell');
  const activeLocale = useLocale() as Locale;
  const pathname = usePathname();
  const router = useRouter();
  const [isPending, startTransition] = useTransition();

  function switchTo(nextLocale: Locale) {
    // Read the query string at click time rather than via useSearchParams().
    // The hook opts the whole subtree out of static rendering and requires a
    // Suspense boundary, which would break static generation of the public
    // marketplace — and SSG is what FR-MKT-007 and NFR-PERF-002 depend on.
    const query = typeof window === 'undefined' ? '' : window.location.search;
    const target = query ? `${pathname}${query}` : pathname;
    startTransition(() => {
      router.replace(target, { locale: nextLocale });
    });
  }

  return (
    <DropdownMenu>
      <DropdownMenuTrigger asChild>
        <Button variant="ghost" size="sm" aria-label={t('changeLanguage')} disabled={isPending}>
          <Languages className="size-4" aria-hidden="true" />
          <span>{localeNames[activeLocale]}</span>
        </Button>
      </DropdownMenuTrigger>
      <DropdownMenuContent align="end">
        {locales.map((locale) => (
          <DropdownMenuItem
            key={locale}
            onSelect={() => switchTo(locale)}
            // Each language name renders in its own script and direction.
            lang={locale}
            dir={locale === 'ar' ? 'rtl' : 'ltr'}
          >
            {localeNames[locale]}
            {locale === activeLocale && <span aria-hidden="true">✓</span>}
          </DropdownMenuItem>
        ))}
      </DropdownMenuContent>
    </DropdownMenu>
  );
}
