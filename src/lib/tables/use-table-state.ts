'use client';

import { useCallback, useMemo } from 'react';
import { useRouter, usePathname, useSearchParams } from 'next/navigation';

/**
 * List state lives in the URL, never in component state.
 *
 * Three reasons this is non-negotiable across ~60 eventual list screens:
 *  - a filtered view is shareable, which is how colleagues hand work over;
 *  - the back button behaves correctly instead of silently dropping filters;
 *  - dashboard drill-down (FR-RPT-001, "drill-down to source records") becomes
 *    an ordinary link rather than cross-screen state plumbing.
 */

export interface TableState {
  page: number;
  perPage: number;
  search: string;
  sort: string | null;
  direction: 'asc' | 'desc';
  filters: Record<string, string>;
}

const RESERVED = new Set(['page', 'perPage', 'q', 'sort', 'dir']);

export interface TableStateOptions extends Partial<TableState> {
  /**
   * URL params that are display preferences rather than filters — a view
   * toggle, for instance.
   *
   * Without this they are treated as filters, which has two visible
   * consequences: "clear filters" silently resets the view, and an empty
   * result set reports "no matches for your filters" when the only active
   * param is a layout choice.
   */
  displayParams?: string[];
}

export function useTableState(defaults?: TableStateOptions) {
  const router = useRouter();
  const pathname = usePathname();
  const params = useSearchParams();

  const state = useMemo<TableState>(() => {
    const display = new Set(defaults?.displayParams ?? []);
    const filters: Record<string, string> = {};
    params.forEach((value, key) => {
      if (!RESERVED.has(key) && !display.has(key) && value) filters[key] = value;
    });
    return {
      page: Number(params.get('page') ?? defaults?.page ?? 1),
      perPage: Number(params.get('perPage') ?? defaults?.perPage ?? 20),
      search: params.get('q') ?? '',
      sort: params.get('sort') ?? defaults?.sort ?? null,
      direction: (params.get('dir') as 'asc' | 'desc' | null) ?? defaults?.direction ?? 'asc',
      filters,
    };
  }, [params, defaults]);

  const update = useCallback(
    (patch: Partial<TableState>) => {
      const next = new URLSearchParams(params.toString());

      const set = (key: string, value: string | number | null | undefined) => {
        if (value === null || value === undefined || value === '') next.delete(key);
        else next.set(key, String(value));
      };

      if ('search' in patch) set('q', patch.search);
      if ('sort' in patch) set('sort', patch.sort);
      if ('direction' in patch) set('dir', patch.direction);
      if ('perPage' in patch) set('perPage', patch.perPage);

      if (patch.filters) {
        for (const key of Object.keys(state.filters)) next.delete(key);
        for (const [key, value] of Object.entries(patch.filters)) set(key, value);
      }

      // Any change other than paging returns to page 1 — staying on page 7 of
      // a newly filtered result set shows an empty table and reads as a bug.
      set('page', 'page' in patch ? patch.page : 1);

      router.replace(`${pathname}?${next.toString()}`, { scroll: false });
    },
    [params, pathname, router, state.filters],
  );

  const toggleSort = useCallback(
    (column: string) => {
      if (state.sort !== column) return update({ sort: column, direction: 'asc' });
      if (state.direction === 'asc') return update({ sort: column, direction: 'desc' });
      return update({ sort: null, direction: 'asc' });
    },
    [state.sort, state.direction, update],
  );

  const hasFilters = state.search !== '' || Object.keys(state.filters).length > 0;

  const clearFilters = useCallback(() => {
    update({ search: '', filters: {}, page: 1 });
  }, [update]);

  /** Read a display-only param (see displayParams). */
  const displayParam = useCallback(
    (key: string) => params.get(key) ?? undefined,
    [params],
  );

  /** Set a display-only param without touching filters or resetting the page. */
  const setDisplayParam = useCallback(
    (key: string, value: string | null) => {
      const next = new URLSearchParams(params.toString());
      if (value === null || value === '') next.delete(key);
      else next.set(key, value);
      router.replace(`${pathname}?${next.toString()}`, { scroll: false });
    },
    [params, pathname, router],
  );

  return { state, update, toggleSort, hasFilters, clearFilters, displayParam, setDisplayParam };
}
