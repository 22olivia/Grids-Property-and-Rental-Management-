import type { ReactNode } from 'react';
import { AppHeader } from '@/shell/app-header';

/**
 * Public marketing / marketplace shell.
 *
 * Comfortable density: image-led, generous spacing, mobile-first. The public
 * surface carries most traffic on phones.
 */
export default function MarketingLayout({ children }: { children: ReactNode }) {
  return (
    <div data-density="comfortable" className="flex min-h-dvh flex-col">
      <AppHeader />
      <main id="main-content" className="flex-1">
        {children}
      </main>
      <footer className="border-t border-[var(--color-border)] px-4 py-6 text-sm text-[var(--color-text-muted)]">
        {/* Footer content is CMS-managed (FR-CMS-001). Structure only. */}
      </footer>
    </div>
  );
}
