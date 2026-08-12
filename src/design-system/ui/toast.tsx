'use client';

import { Toaster as SonnerToaster, toast } from 'sonner';
import type { Direction } from '@/lib/i18n/direction';

/**
 * Toasts.
 *
 * Direction is passed explicitly so toasts anchor to the correct edge in
 * Arabic. Sonner renders into a live region, so routine confirmations are
 * announced without stealing focus.
 *
 * Toasts are for ROUTINE confirmations only. Financial results are never
 * announced this way — a payment reference must remain on screen, selectable
 * and copyable, not disappear after four seconds.
 */
export function Toaster({ direction }: { direction: Direction }) {
  return (
    <SonnerToaster
      dir={direction}
      position={direction === 'rtl' ? 'top-left' : 'top-right'}
      toastOptions={{
        classNames: {
          toast:
            'rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-raised)] text-[var(--color-text)]',
        },
      }}
    />
  );
}

export { toast };
