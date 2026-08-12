import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils/cn';

const badgeVariants = cva(
  'inline-flex items-center gap-1 rounded-[var(--radius-full)] px-2 py-0.5 text-xs font-medium',
  {
    variants: {
      tone: {
        neutral: 'bg-[var(--color-surface-sunken)] text-[var(--color-text-muted)]',
        success: 'bg-[var(--color-success-surface)] text-[var(--color-success)]',
        warning: 'bg-[var(--color-warning-surface)] text-[var(--color-warning)]',
        danger: 'bg-[var(--color-danger-surface)] text-[var(--color-danger)]',
        info: 'bg-[var(--color-info-surface)] text-[var(--color-info)]',
      },
    },
    defaultVariants: { tone: 'neutral' },
  },
);

export interface BadgeProps
  extends React.HTMLAttributes<HTMLSpanElement>,
    VariantProps<typeof badgeVariants> {}

/**
 * Colour must never be the only carrier of meaning — WCAG 1.4.1.
 * Every badge renders its own text, so tone is reinforcement, not signal.
 */
export function Badge({ className, tone, ...props }: BadgeProps) {
  return <span className={cn(badgeVariants({ tone }), className)} {...props} />;
}
