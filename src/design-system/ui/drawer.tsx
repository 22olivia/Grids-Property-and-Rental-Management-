'use client';

import * as DialogPrimitive from '@radix-ui/react-dialog';
import { X } from 'lucide-react';
import { cn } from '@/lib/utils/cn';

/**
 * Drawer — a Dialog anchored to an edge.
 *
 * Sides are LOGICAL ('start' / 'end'), not physical. A drawer opening from
 * 'end' appears on the right in English and the left in Arabic, which is what
 * "the trailing edge" means to a reader in each language. Exposing left/right
 * here would push a direction decision onto every call site.
 */

export const Drawer = DialogPrimitive.Root;
export const DrawerTrigger = DialogPrimitive.Trigger;
export const DrawerClose = DialogPrimitive.Close;
export const DrawerTitle = DialogPrimitive.Title;
export const DrawerDescription = DialogPrimitive.Description;

type DrawerSide = 'start' | 'end' | 'bottom';

const sideClasses: Record<DrawerSide, string> = {
  start: 'inset-y-0 start-0 h-full w-[min(24rem,90vw)] border-e',
  end: 'inset-y-0 end-0 h-full w-[min(24rem,90vw)] border-s',
  bottom: 'inset-x-0 bottom-0 max-h-[85vh] w-full border-t rounded-t-[var(--radius-lg)]',
};

export function DrawerContent({
  className,
  children,
  side = 'end',
  closeLabel,
  ...props
}: React.ComponentPropsWithoutRef<typeof DialogPrimitive.Content> & {
  side?: DrawerSide;
  closeLabel: string;
}) {
  return (
    <DialogPrimitive.Portal>
      <DialogPrimitive.Overlay className="fixed inset-0 z-50 bg-[var(--color-overlay)]" />
      <DialogPrimitive.Content
        className={cn(
          'fixed z-50 flex flex-col overflow-y-auto',
          'border-[var(--color-border)] bg-[var(--color-surface-raised)]',
          'p-[var(--density-card-padding)] shadow-[var(--shadow-lg)]',
          sideClasses[side],
          className,
        )}
        {...props}
      >
        {children}
        <DialogPrimitive.Close
          aria-label={closeLabel}
          className="absolute end-3 top-3 flex size-8 items-center justify-center rounded-[var(--radius-sm)] text-[var(--color-text-muted)] hover:bg-[var(--color-surface-sunken)]"
        >
          <X className="size-4" aria-hidden="true" />
        </DialogPrimitive.Close>
      </DialogPrimitive.Content>
    </DialogPrimitive.Portal>
  );
}
