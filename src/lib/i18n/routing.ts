import { defineRouting } from 'next-intl/routing';
import { createNavigation } from 'next-intl/navigation';
import { locales, defaultLocale } from './config';

/**
 * Path-based locale routing: /en/… and /ar/….
 *
 * Deliberately path-based rather than query-parameter based. FR-MKT-007
 * (Must) requires "SEO-friendly URLs, metadata, structured data, sitemap and
 * canonical URLs"; a `?lang=` parameter gives search engines a weaker signal
 * and complicates canonicals and hreflang.
 */
export const routing = defineRouting({
  locales,
  defaultLocale,
  localePrefix: 'always',
});

/**
 * Locale-aware navigation primitives. Components import Link/redirect/
 * useRouter from here, never from next/link or next/navigation directly, so
 * the active locale is preserved across every navigation without any
 * component knowing about locales.
 */
export const { Link, redirect, usePathname, useRouter, getPathname } =
  createNavigation(routing);
