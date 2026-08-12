'use client';

import { useTranslations } from 'next-intl';
import { filterNavigation, type NavigationSection } from '@/config/navigation';
import { useCan } from '@/lib/permissions/permission-provider';
import { Link, usePathname } from '@/lib/i18n/routing';
import { cn } from '@/lib/utils/cn';

/**
 * Sidebar navigation.
 *
 * Sits at the inline-start edge via logical positioning, so it appears on the
 * left in English and the right in Arabic without any direction branching.
 *
 * The tree is empty until the permission taxonomy and approved scope exist
 * (see src/config/navigation.ts). The filtering and rendering are complete.
 */
export function AppSidebar({
  sections,
  open,
  className,
}: {
  sections: NavigationSection[];
  open: boolean;
  className?: string;
}) {
  const t = useTranslations();
  const can = useCan();
  const pathname = usePathname();
  const visible = filterNavigation(sections, can);

  // Longest-prefix wins. A plain startsWith marks BOTH "Listings"
  // (/console/listings) and "Approval queue" (/console/listings/approvals)
  // as current, which tells a screen-reader user they are on two pages.
  const activeHref = visible
    .flatMap((section) => section.items)
    .map((item) => item.href)
    .filter((href) => pathname === href || pathname.startsWith(`${href}/`))
    .sort((a, b) => b.length - a.length)[0];

  return (
    <nav
      id="app-navigation"
      aria-label={t('shell.mainNavigation')}
      className={cn(
        'w-64 shrink-0 border-e border-[var(--color-border)] bg-[var(--color-surface-raised)] p-3',
        'lg:block',
        open ? 'block' : 'hidden',
        className,
      )}
    >
      {visible.length === 0 ? (
        <p className="p-2 text-sm text-[var(--color-text-subtle)]">
          {t('shell.navigationUnavailable')}
        </p>
      ) : (
        <ul className="flex flex-col gap-1">
          {visible.map((section) => (
            <li key={section.labelKey}>
              <p className="px-2 py-1 text-xs font-medium uppercase text-[var(--color-text-subtle)]">
                {t(section.labelKey)}
              </p>
              <ul className="flex flex-col gap-0.5">
                {section.items.map((item) => (
                  <li key={item.href}>
                    <Link
                      href={item.href}
                      // aria-current tells a screen reader which page it is on.
                      // Visual highlight alone does not (WCAG 1.3.1).
                      aria-current={item.href === activeHref ? 'page' : undefined}
                      className={cn(
                        'flex min-h-11 items-center rounded-[var(--radius-md)] px-2 text-sm',
                        'hover:bg-[var(--color-surface-sunken)]',
                        item.href === activeHref &&
                          'bg-[var(--color-surface-sunken)] font-medium',
                      )}
                    >
                      {t(item.labelKey)}
                    </Link>
                  </li>
                ))}
              </ul>
            </li>
          ))}
        </ul>
      )}
    </nav>
  );
}
