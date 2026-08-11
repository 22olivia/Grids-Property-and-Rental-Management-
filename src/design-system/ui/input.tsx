'use client';

import { forwardRef } from 'react';
import { cn } from '@/lib/utils/cn';
import { useFieldControlProps } from './field';

export interface InputProps extends React.InputHTMLAttributes<HTMLInputElement> {
  /**
   * Force LTR content direction inside an RTL layout.
   *
   * Necessary, not optional. Email addresses, URLs, phone numbers, IBANs and
   * coordinates render scrambled if they inherit RTL direction. The field
   * still SITS at the start edge and its label still mirrors — only the
   * content direction is pinned.
   */
  contentDirection?: 'auto' | 'ltr';
}

export const Input = forwardRef<HTMLInputElement, InputProps>(function Input(
  { className, contentDirection = 'auto', type = 'text', ...props },
  ref,
) {
  const fieldProps = useFieldControlProps();
  const forceLtr =
    contentDirection === 'ltr' ||
    (contentDirection === 'auto' && ['email', 'url', 'tel'].includes(type));

  return (
    <input
      ref={ref}
      type={type}
      dir={forceLtr ? 'ltr' : undefined}
      className={cn(
        'min-h-[var(--density-control-height)] w-full rounded-[var(--radius-md)] border px-3',
        'border-[var(--color-border)] bg-[var(--color-surface-raised)] text-[var(--color-text)]',
        'placeholder:text-[var(--color-text-subtle)]',
        'disabled:cursor-not-allowed disabled:opacity-60',
        'aria-[invalid=true]:border-[var(--color-danger)]',
        // Pin the text edge when direction is forced, so an email field in
        // Arabic still reads naturally.
        forceLtr && 'text-start',
        className,
      )}
      {...fieldProps}
      {...props}
    />
  );
});
