'use client';

import { useCallback } from 'react';
import { usePathname, useRouter, useSearchParams } from 'next/navigation';

/**
 * Tab selection in the URL rather than component state.
 *
 * Required, not stylistic: notification deep links (FR-NOT-002) and dashboard
 * drill-down (FR-RPT-001) need to target a specific tab. A tab held in
 * useState is not addressable, so those links can only ever land on a record's
 * default view.
 */
export function useTabState(defaultTab: string) {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();
  const active = params.get('tab') ?? defaultTab;

  const setTab = useCallback(
    (tab: string) => {
      const next = new URLSearchParams(params.toString());
      if (tab === defaultTab) next.delete('tab');
      else next.set('tab', tab);
      const query = next.toString();
      router.replace(query ? `${pathname}?${query}` : pathname, { scroll: false });
    },
    [params, pathname, router, defaultTab],
  );

  return { active, setTab };
}
