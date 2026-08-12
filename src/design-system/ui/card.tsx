import { cn } from '@/lib/utils/cn';

export type RecordClass = 'asset' | 'listing' | 'contract' | 'money' | 'party';

export interface CardProps extends React.HTMLAttributes<HTMLDivElement> {
  /**
   * Record class for the spine.
   *
   * SRS §11: "The property asset, listing and contract shall be separate
   * concepts… This separation is mandatory to prevent availability,
   * occupancy and billing conflicts."
   *
   * The spine encodes that distinction structurally. It is reinforcement,
   * never the sole carrier of meaning (WCAG 1.4.1) — the card content always
   * names what it is.
   */
  record?: RecordClass;
}

export function Card({ className, record, ...props }: CardProps) {
  return (
    <div
      data-record={record}
      className={cn(
        'rounded-[var(--radius-lg)] border border-[var(--color-border)]',
        'bg-[var(--color-surface-raised)] p-[var(--density-card-padding)]',
        record && 'record-spine',
        className,
      )}
      {...props}
    />
  );
}

export function CardHeader({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('mb-3 flex flex-col gap-1', className)} {...props} />;
}

export function CardTitle({ className, ...props }: React.HTMLAttributes<HTMLHeadingElement>) {
  return <h3 className={cn('text-base font-semibold', className)} {...props} />;
}

export function CardBody({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('text-[var(--color-text-muted)]', className)} {...props} />;
}

export function CardFooter({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return <div className={cn('mt-4 flex items-center gap-2', className)} {...props} />;
}
