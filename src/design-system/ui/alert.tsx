import { AlertCircle, CheckCircle2, Info, TriangleAlert } from 'lucide-react';
import { cva, type VariantProps } from 'class-variance-authority';
import { cn } from '@/lib/utils/cn';

const alertVariants = cva(
  'flex gap-3 rounded-[var(--radius-md)] border p-4 record-spine',
  {
    variants: {
      tone: {
        info: 'border-[var(--color-border)] bg-[var(--color-info-surface)] text-[var(--color-text)]',
        success:
          'border-[var(--color-border)] bg-[var(--color-success-surface)] text-[var(--color-text)]',
        warning:
          'border-[var(--color-border)] bg-[var(--color-warning-surface)] text-[var(--color-text)]',
        danger:
          'border-[var(--color-border)] bg-[var(--color-danger-surface)] text-[var(--color-text)]',
      },
    },
    defaultVariants: { tone: 'info' },
  },
);

const icons = {
  info: Info,
  success: CheckCircle2,
  warning: TriangleAlert,
  danger: AlertCircle,
} as const;

export interface AlertProps
  extends React.HTMLAttributes<HTMLDivElement>,
    VariantProps<typeof alertVariants> {
  title?: React.ReactNode;
  /**
   * Use 'assertive' only for errors that interrupt the user's task.
   * Over-using assertive live regions makes a screen reader unusable.
   */
  live?: 'off' | 'polite' | 'assertive';
}

export function Alert({ className, tone = 'info', title, live = 'off', children, ...props }: AlertProps) {
  const Icon = icons[tone ?? 'info'];
  return (
    <div
      role={tone === 'danger' ? 'alert' : 'status'}
      aria-live={live === 'off' ? undefined : live}
      className={cn(alertVariants({ tone }), className)}
      {...props}
    >
      <Icon className="mt-0.5 size-5 shrink-0" aria-hidden="true" />
      <div className="flex flex-col gap-1">
        {title && <p className="font-medium">{title}</p>}
        <div className="text-sm text-[var(--color-text-muted)]">{children}</div>
      </div>
    </div>
  );
}
