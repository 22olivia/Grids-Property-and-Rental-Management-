import type { ListQuery } from '@/lib/data/repository';
import type { TableState } from './use-table-state';

/**
 * Maps URL table state onto a repository query.
 *
 * Extracted after the third copy appeared in the asset module. Three copies of
 * a mapping is how a filter silently stops being applied on one screen.
 */
export function toListQuery(state: TableState): ListQuery {
  return {
    page: state.page,
    perPage: state.perPage,
    search: state.search,
    sort: state.sort ?? undefined,
    direction: state.direction,
    filters: state.filters,
  };
}
