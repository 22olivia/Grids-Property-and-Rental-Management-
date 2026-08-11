'use client';

import * as TooltipPrimitive from '@radix-ui/react-tooltip';
import { cn } from '@/lib/utils/cn';

/**
 * Tooltip.
 *
 * WCAG 1.4.13 (content on hover or focus): tooltip content must be
 * dismissible, hoverable and persistent. Radix handles all three.
 *
 * A tooltip must never be the ONLY way to reach information, and must never
 * wrap a control that has no accessible name of its own — use aria-label for
 * naming and the tooltip for supplementary detail.
 */

export const TooltipProvider = TooltipPrimitive.Provider;
export const Tooltip = TooltipPrimitive.Root;
export const TooltipTrigger = TooltipPrimitive.Trigger;

export function TooltipContent({
  className,
  sideOffset = 6,
  ...props
}: React.ComponentPropsWithoutRef<typeof TooltipPrimitive.Content>) {
  return (
    <TooltipPrimitive.Portal>
      <TooltipPrimitive.Content
        sideOffset={sideOffset}
        className={cn(
          'z-50 max-w-xs rounded-[var(--radius-sm)] px-2 py-1 text-sm',
          'bg-[var(--color-surface-inverse)] text-[var(--color-text-inverse)] shadow-[var(--shadow-md)]',
          className,
        )}
        {...props}
      />
    </TooltipPrimitive.Portal>
  );
}
