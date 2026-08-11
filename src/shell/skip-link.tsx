import { useTranslations } from 'next-intl';

/**
 * Skip link — WCAG 2.4.1 (bypass blocks).
 *
 * Visually hidden until focused, then anchored to the start edge so it
 * appears on the correct side in both directions.
 */
export function SkipLink() {
  const t = useTranslations('a11y');
  return (
    <a
      href="#main-content"
      className="sr-only focus:not-sr-only focus:absolute focus:start-4 focus:top-4 focus:z-50 focus:rounded-[var(--radius-md)] focus:bg-[var(--color-surface-raised)] focus:px-4 focus:py-2 focus:shadow-[var(--shadow-md)]"
    >
      {t('skipToContent')}
    </a>
  );
}
