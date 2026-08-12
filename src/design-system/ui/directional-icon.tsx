'use client';

import { cn } from '@/lib/utils/cn';

/**
 * Wrapper for icons whose MEANING depends on reading direction.
 *
 * Opt-in, never global. Chevrons, arrows and "back" affordances mirror.
 * A play button, clock, checkmark, logo or external-link glyph does NOT —
 * mirroring those makes them wrong. Getting this distinction right is why
 * the wrapper exists rather than a blanket `rtl:scale-x-[-1]` rule.
 */
export function DirectionalIcon({
  children,
  className,
}: {
  children: React.ReactNode;
  className?: string;
}) {
  return (
    <span className={cn('inline-flex rtl:-scale-x-100', className)} aria-hidden="true">
      {children}
    </span>
  );
}
