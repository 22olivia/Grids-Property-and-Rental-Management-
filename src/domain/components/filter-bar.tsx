'use client';

import { useTranslations } from 'next-intl';
import { SearchInput, Button, SelectRoot, SelectTrigger, SelectValue, SelectContent, SelectItem, Field } from '@/design-system/ui';
import type { TableState } from '@/lib/tables/use-table-state';

/**
 * Sentinel for "no filter". Radix Select rejects an empty-string value —
 * it reserves "" for the unset/placeholder case — so the reset option needs
 * a real value that is mapped back to "" on the way out.
 */
const ALL_VALUE = '__all__';

export interface FilterDefinition {
  id: string;
  labelKey: string;
  options: { value: string; labelKey: string }[];
}

/**
 * Filter bar over URL state.
 *
 * Generic over any resource: it takes filter DEFINITIONS (message keys +
 * option values) rather than knowing about any domain. Promoted out of the
 * asset feature after review — nothing in it was asset-specific, and every
 * list screen in the product needs the same behaviour.
 *
 * Every control writes to the URL, so a filtered view is shareable and the
 * back button restores it. `aria-live` on the result count means a screen
 * reader hears that the list changed — otherwise filtering is a silent
 * operation for a non-sighted user (WCAG 4.1.3).
 */
export function FilterBar({
  state,
  filters,
  onChange,
  onClear,
  hasFilters,
  resultCount,
  searchLabel,
  searchDisabled = false,
}: {
  state: TableState;
  filters: FilterDefinition[];
  onChange: (patch: Partial<TableState>) => void;
  onClear: () => void;
  hasFilters: boolean;
  resultCount: number | null;
  searchLabel: string;
  /** Backend endpoint accepts no `search` parameter. */
  searchDisabled?: boolean;
}) {
  const t = useTranslations();

  return (
    <div className="flex flex-col gap-3">
      <div className="flex flex-col gap-3 sm:flex-row sm:items-end">
        {!searchDisabled && (
        <div className="flex-1">
          <SearchInput
            label={searchLabel}
            placeholder={searchLabel}
            value={state.search}
            onChange={(event) => onChange({ search: event.target.value })}
            onClear={() => onChange({ search: '' })}
            clearLabel={t('common.clear')}
          />
        </div>
        )}

        {filters.map((filter) => (
          <div key={filter.id} className="sm:w-48">
            <Field label={t(filter.labelKey)}>
              <SelectRoot
                value={state.filters[filter.id] || ALL_VALUE}
                onValueChange={(value) =>
                  onChange({
                    filters: {
                      ...state.filters,
                      [filter.id]: value === ALL_VALUE ? '' : value,
                    },
                  })
                }
              >
                <SelectTrigger>
                  <SelectValue placeholder={t('common.all')} />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value={ALL_VALUE}>{t('common.all')}</SelectItem>
                  {filter.options.map((option) => (
                    <SelectItem key={option.value} value={option.value}>
                      {t(option.labelKey)}
                    </SelectItem>
                  ))}
                </SelectContent>
              </SelectRoot>
            </Field>
          </div>
        ))}

        {hasFilters && (
          <Button variant="ghost" onClick={onClear}>
            {t('common.clearFilters')}
          </Button>
        )}
      </div>

      {/* Announced when the count changes, so filtering is not silent. */}
      <p aria-live="polite" className="text-sm text-[var(--color-text-muted)]">
        {resultCount !== null ? t('common.resultCount', { count: resultCount }) : ''}
      </p>
    </div>
  );
}
