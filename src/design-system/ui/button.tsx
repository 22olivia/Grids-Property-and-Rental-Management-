'use client';

import { forwardRef } from 'react';
import { Slot } from '@radix-ui/react-slot';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils/cn';
import { Spinner } from './spinner';

const buttonVariants = cva(
  // Base: logical padding only, so the control mirrors in RTL.
  // min-h uses the density token so console and marketplace differ without
  // two component sets.
  'inline-flex items-center justify-center gap-2 rounded-[var(--radius-md)] font-medium ' +
    'transition-colors duration-[var(--gpms-duration-fast)] ' +
    'disabled:pointer-events-none disabled:opacity-50 ' +
    'focus-visible:outline-2 focus-visible:outline-offset-2 ' +
    '[&_svg]:size-4 [&_svg]:shrink-0',
  {
    variants: {
      variant: {
        primary: 'bg-[var(--color-action)] text-[var(--color-text-on-brand)] hover:bg-[var(--color-action-hover)]',
        secondary:
          'bg-[var(--color-surface-raised)] text-[var(--color-text)] border border-[var(--color-border)] hover:bg-[var(--color-surface-sunken)]',
        ghost: 'text-[var(--color-text)] hover:bg-[var(--color-surface-sunken)]',
        danger: 'bg-[var(--color-danger)] text-[var(--color-text-inverse)] hover:opacity-90',
        link: 'text-[var(--color-action)] underline underline-offset-4 hover:no-underline',
      },
      size: {
        // 44px minimum target in comfortable density — WCAG 2.5.5.
        sm: 'min-h-9 px-3 text-sm',
        md: 'min-h-11 px-4',
        lg: 'min-h-12 px-6 text-lg',
        icon: 'min-h-11 w-11',
      },
    },
    defaultVariants: { variant: 'primary', size: 'md' },
  },
);

export interface ButtonProps
  extends React.ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof buttonVariants> {
  asChild?: boolean;
  loading?: boolean;
  /** Announced while loading. Required when `loading` can be true. */
  loadingLabel?: string;
}

export const Button = forwardRef<HTMLButtonElement, ButtonProps>(function Button(
  { className, variant, size, asChild, loading, loadingLabel, children, disabled, ...props },
  ref,
) {
  const Component = asChild ? Slot : 'button';
  return (
    <Component
      ref={ref}
      className={cn(buttonVariants({ variant, size }), className)}
      // aria-busy tells assistive tech the control is working; disabling
      // during submission is what actually prevents double-posting.
      aria-busy={loading || undefined}
      disabled={disabled || loading}
      {...props}
    >
      {loading ? (
        <>
          <Spinner className="size-4" />
          <span>{loadingLabel ?? children}</span>
        </>
      ) : (
        children
      )}
    </Component>
  );
});

export { buttonVariants };
