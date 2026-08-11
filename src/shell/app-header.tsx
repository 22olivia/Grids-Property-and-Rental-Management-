'use client';

import { Menu } from 'lucide-react';
import { useTranslations } from 'next-intl';
import { Button } from '@/design-system/ui';
import { LanguageSwitcher } from './language-switcher';

/**
 * Application header.
 *
 * Deliberately structural only — no business content, no dashboards, no
 * organisation switcher (whether a user may belong to multiple companies is
 * unresolved, MI-05).
 */
export function AppHeader({
  onToggleNavigation,
  navigationOpen,
}: {
  onToggleNavigation?: () => void;
  navigationOpen?: boolean;
}) {
  const t = useTranslations('shell');

  return (
    <header
      // <header> is a banner landmark; screen-reader users navigate by these.
      className="sticky top-0 z-30 flex h-16 items-center gap-3 border-b border-[var(--color-border)] bg-[var(--color-surface-raised)] px-4"
    >
      {onToggleNavigation && (
        <Button
          variant="ghost"
          size="icon"
          onClick={onToggleNavigation}
          aria-label={t('toggleNavigation')}
          aria-expanded={navigationOpen}
          aria-controls="app-navigation"
          className="lg:hidden"
        >
          <Menu className="size-5" aria-hidden="true" />
        </Button>
      )}

      <span className="font-semibold">{t('productName')}</span>

      {/* ms-auto is logical — pushes to the trailing edge in both directions. */}
      <div className="ms-auto flex items-center gap-2">
        <LanguageSwitcher />
      </div>
    </header>
  );
}
