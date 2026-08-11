import { cn } from '@/lib/utils/cn';

/**
 * Skeleton placeholder.
 *
 * aria-hidden: a skeleton is a visual affordance. The surrounding region
 * carries aria-busy so assistive tech is told "loading" once, not per shape.
 */
export function Skeleton({ className, ...props }: React.HTMLAttributes<HTMLDivElement>) {
  return (
    <div
      aria-hidden="true"
      className={cn(
        'animate-pulse rounded-[var(--radius-sm)] bg-[var(--color-surface-sunken)]',
        className,
      )}
      {...props}
    />
  );
}

/** Skeleton shaped like a data table, so layout does not shift on load. */
export function TableSkeleton({ rows = 5, columns = 4 }: { rows?: number; columns?: number }) {
  return (
    <div className="flex flex-col gap-2 p-3" aria-hidden="true">
      {Array.from({ length: rows }).map((_, rowIndex) => (
        <div key={rowIndex} className="flex gap-3">
          {Array.from({ length: columns }).map((_, columnIndex) => (
            <Skeleton key={columnIndex} className="h-6 flex-1" />
          ))}
        </div>
      ))}
    </div>
  );
}
