'use client';

import * as SwitchPrimitive from '@radix-ui/react-switch';
import { cn } from '@/lib/utils/cn';

/**
 * The thumb translation uses a logical transform via RTL-aware utilities so
 * the switch travels toward the end edge in both directions.
 */
export function Switch({
  className,
  ...props
}: React.ComponentPropsWithoutRef<typeof SwitchPrimitive.Root>) {
  return (
    <SwitchPrimitive.Root
      className={cn(
        'peer inline-flex h-6 w-11 shrink-0 items-center rounded-full border-2 border-transparent',
        'transition-colors data-[state=checked]:bg-[var(--color-action)]',
        'data-[state=unchecked]:bg-[var(--color-border-strong)]',
        'disabled:cursor-not-allowed disabled:opacity-50',
        className,
      )}
      {...props}
    >
      <SwitchPrimitive.Thumb
        className={cn(
          'pointer-events-none block size-5 rounded-full bg-[var(--color-surface-raised)] shadow-[var(--shadow-sm)]',
          'transition-transform',
          'data-[state=unchecked]:translate-x-0',
          'data-[state=checked]:rtl:-translate-x-5 data-[state=checked]:ltr:translate-x-5',
        )}
      />
    </SwitchPrimitive.Root>
  );
}
