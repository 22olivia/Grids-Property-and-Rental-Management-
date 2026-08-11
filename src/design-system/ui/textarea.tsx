'use client';

import { forwardRef } from 'react';
import { cn } from '@/lib/utils/cn';
import { useFieldControlProps } from './field';

export const Textarea = forwardRef<
  HTMLTextAreaElement,
  React.TextareaHTMLAttributes<HTMLTextAreaElement>
>(function Textarea({ className, rows = 4, ...props }, ref) {
  const fieldProps = useFieldControlProps();
  return (
    <textarea
      ref={ref}
      rows={rows}
      className={cn(
        'w-full rounded-[var(--radius-md)] border px-3 py-2',
        'border-[var(--color-border)] bg-[var(--color-surface-raised)] text-[var(--color-text)]',
        'placeholder:text-[var(--color-text-subtle)] resize-y',
        'disabled:cursor-not-allowed disabled:opacity-60',
        'aria-[invalid=true]:border-[var(--color-danger)]',
        className,
      )}
      {...fieldProps}
      {...props}
    />
  );
});
