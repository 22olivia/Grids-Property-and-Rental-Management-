import { cn } from '@/lib/utils/cn';

/**
 * Visually hidden but available to assistive technology.
 * Used for required-but-redundant labels: table captions, dialog titles,
 * and the skip link before it receives focus.
 */
export function VisuallyHidden({
  className,
  as: Component = 'span',
  ...props
}: React.HTMLAttributes<HTMLElement> & { as?: 'span' | 'div' | 'h1' | 'h2' }) {
  return (
    <Component
      className={cn(
        'absolute size-px overflow-hidden whitespace-nowrap border-0 p-0',
        '[clip:rect(0,0,0,0)] [clip-path:inset(50%)]',
        className,
      )}
      {...props}
    />
  );
}
