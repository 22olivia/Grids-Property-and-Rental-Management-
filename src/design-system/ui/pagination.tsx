'use client';

import { ChevronLeft, ChevronRight } from 'lucide-react';
import { cn } from '@/lib/utils/cn';
import { Button } from './button';
import { DirectionalIcon } from './directional-icon';

export interface PaginationProps {
  /**
   * Both pagination styles are supported.
   *
   * MISSING INFORMATION (MI-03): SRS §12 says "cursor or page pagination
   * according to resource characteristics" and leaves the convention
   * undecided. Supporting both costs more than either alone; a ruling would
   * simplify every list screen.
   */
  mode: 'page' | 'cursor';
  page?: number;
  totalPages?: number;
  hasPrevious: boolean;
  hasNext: boolean;
  onPrevious: () => void;
  onNext: () => void;
  labels: { navigation: string; previous: string; next: string; status: string };
  className?: string;
}

export function Pagination({
  mode,
  page,
  totalPages,
  hasPrevious,
  hasNext,
  onPrevious,
  onNext,
  labels,
  className,
}: PaginationProps) {
  return (
    <nav
      aria-label={labels.navigation}
      className={cn('flex items-center justify-between gap-3 p-3', className)}
    >
      <Button variant="secondary" size="sm" disabled={!hasPrevious} onClick={onPrevious}>
        <DirectionalIcon>
          <ChevronLeft className="size-4" />
        </DirectionalIcon>
        {labels.previous}
      </Button>

      {/* Live region so page changes are announced to screen readers. */}
      <p aria-live="polite" className="text-sm text-[var(--color-text-muted)]">
        {mode === 'page' && page !== undefined && totalPages !== undefined
          ? labels.status
          : null}
      </p>

      <Button variant="secondary" size="sm" disabled={!hasNext} onClick={onNext}>
        {labels.next}
        <DirectionalIcon>
          <ChevronRight className="size-4" />
        </DirectionalIcon>
      </Button>
    </nav>
  );
}
