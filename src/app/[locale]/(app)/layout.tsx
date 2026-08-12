'use client';

import { useState, type ReactNode } from 'react';
import { AppHeader } from '@/shell/app-header';
import { AppSidebar } from '@/shell/app-sidebar';
import { consoleNavigation } from '@/config/navigation';
import { RequireSession } from '@/shell/require-session';

/**
 * Authenticated application shell.
 *
 * Route protection is now applied: middleware redirects when no session cookie
 * exists, and RequireSession handles a revoked or expired token once /me has
 * answered. Previously this layout rendered for anyone.
 *
 * Compact density: the console is used for hours at a time on desktop, and an
 * accountant reconciling hundreds of payments needs rows, not cards. The
 * marketplace and portals stay comfortable. One token set, two settings —
 * not two design systems.
 * */
export default function AppLayout({ children }: { children: ReactNode }) {
  const [navigationOpen, setNavigationOpen] = useState(false);

  return (
    <RequireSession>
    <div data-density="compact" className="flex min-h-dvh flex-col">
      <AppHeader
        onToggleNavigation={() => setNavigationOpen((open) => !open)}
        navigationOpen={navigationOpen}
      />
      <div className="flex flex-1">
        <AppSidebar sections={consoleNavigation} open={navigationOpen} />
        <main id="main-content" className="flex-1 p-4">
          {children}
        </main>
      </div>
    </div>
    </RequireSession>
  );
}
