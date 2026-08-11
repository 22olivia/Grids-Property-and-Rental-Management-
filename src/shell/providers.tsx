'use client';

import { useState, type ReactNode } from 'react';
import { QueryClient, QueryClientProvider } from '@tanstack/react-query';
import { DirectionProvider } from '@radix-ui/react-direction';
import { TooltipProvider, Toaster } from '@/design-system/ui';
import { SessionLoader } from './session-loader';
import type { Direction } from '@/lib/i18n/direction';
import { ApiError } from '@/lib/api/types';

/**
 * Client providers.
 *
 * DirectionProvider is what makes every Radix primitive mirror correctly —
 * popover alignment, arrow-key semantics and submenu direction all read from
 * it. Mounted once here rather than per component.
 */
export function Providers({
  children,
  direction,
}: {
  children: ReactNode;
  direction: Direction;
}) {
  const [queryClient] = useState(
    () =>
      new QueryClient({
        defaultOptions: {
          queries: {
            staleTime: 30_000,
            retry: (failureCount, error) => {
              // Never retry a client error — a 403 or 422 will not become a
              // 200, and retrying a 401 fights the refresh flow.
              if (error instanceof ApiError && error.status < 500) return false;
              return failureCount < 2;
            },
            refetchOnWindowFocus: true,
          },
          mutations: {
            // Mutations are never retried automatically. Financial and
            // approval actions must not be replayed without an explicit
            // idempotency key held by the caller (FR-API-005, FR-FIN-010).
            retry: false,
          },
        },
      }),
  );

  return (
    <QueryClientProvider client={queryClient}>
      <DirectionProvider dir={direction}>
        <SessionLoader>
          <TooltipProvider delayDuration={300}>
            {children}
            <Toaster direction={direction} />
          </TooltipProvider>
        </SessionLoader>
      </DirectionProvider>
    </QueryClientProvider>
  );
}
