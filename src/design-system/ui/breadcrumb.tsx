import { ChevronRight } from 'lucide-react';
import { cn } from '@/lib/utils/cn';
import { Link } from '@/lib/i18n/routing';
import { DirectionalIcon } from './directional-icon';

export interface BreadcrumbItem {
  label: string;
  href?: string;
}

export function Breadcrumb({
  items,
  label,
  className,
}: {
  items: BreadcrumbItem[];
  /** Accessible name for the nav landmark. */
  label: string;
  className?: string;
}) {
  return (
    <nav aria-label={label} className={className}>
      <ol className="flex flex-wrap items-center gap-1 text-sm">
        {items.map((item, index) => {
          const isLast = index === items.length - 1;
          return (
            <li key={`${item.label}-${index}`} className="flex items-center gap-1">
              {item.href && !isLast ? (
                <Link
                  href={item.href}
                  className="text-[var(--color-text-muted)] underline-offset-4 hover:underline"
                >
                  {item.label}
                </Link>
              ) : (
                // aria-current marks the current page for screen readers.
                <span aria-current={isLast ? 'page' : undefined} className={cn(isLast && 'font-medium')}>
                  {item.label}
                </span>
              )}
              {!isLast && (
                <DirectionalIcon className="text-[var(--color-text-subtle)]">
                  <ChevronRight className="size-4" />
                </DirectionalIcon>
              )}
            </li>
          );
        })}
      </ol>
    </nav>
  );
}
