'use client';

import { forwardRef } from 'react';
import { Search, X } from 'lucide-react';
import { cn } from '@/lib/utils/cn';
import type { InputProps } from './input';

export interface SearchInputProps extends Omit<InputProps, 'type'> {
  onClear?: () => void;
  clearLabel: string;
  /** Accessible name. Search fields are frequently unlabelled — required here. */
  label: string;
}

export const SearchInput = forwardRef<HTMLInputElement, SearchInputProps>(
  function SearchInput({ className, onClear, clearLabel, label, value, ...props }, ref) {
    return (
      <div className="relative">
        {/* Icon sits at the start edge and moves with direction. */}
        <Search
          className="pointer-events-none absolute start-3 top-1/2 size-4 -translate-y-1/2 text-[var(--color-text-subtle)]"
          aria-hidden="true"
        />
        <input
          ref={ref}
          type="search"
          role="searchbox"
          aria-label={label}
          value={value}
          className={cn(
            'min-h-[var(--density-control-height)] w-full rounded-[var(--radius-md)] border',
            'border-[var(--color-border)] bg-[var(--color-surface-raised)]',
            'ps-9 pe-9 text-[var(--color-text)] placeholder:text-[var(--color-text-subtle)]',
            // Suppress the UA clear affordance; we provide an accessible one.
            '[&::-webkit-search-cancel-button]:appearance-none',
            className,
          )}
          {...props}
        />
        {onClear && value ? (
          <button
            type="button"
            onClick={onClear}
            aria-label={clearLabel}
            className="absolute end-2 top-1/2 flex size-6 -translate-y-1/2 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-muted)] hover:bg-[var(--color-surface-sunken)]"
          >
            <X className="size-4" aria-hidden="true" />
          </button>
        ) : null}
      </div>
    );
  },
);
