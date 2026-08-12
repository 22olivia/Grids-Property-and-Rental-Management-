'use client';

import * as SelectPrimitive from '@radix-ui/react-select';
import { Check, ChevronDown } from 'lucide-react';
import { cn } from '@/lib/utils/cn';
import { useFieldControlProps } from './field';

/**
 * Select — Radix primitive.
 *
 * Radix reads `dir` from the nearest DirectionProvider (mounted in the locale
 * layout), so keyboard semantics and popover alignment mirror in Arabic
 * without any component-level branching.
 */

export const SelectRoot = SelectPrimitive.Root;
export const SelectGroup = SelectPrimitive.Group;
export const SelectValue = SelectPrimitive.Value;

export function SelectTrigger({
  className,
  children,
  ...props
}: React.ComponentPropsWithoutRef<typeof SelectPrimitive.Trigger>) {
  const fieldProps = useFieldControlProps();
  return (
    <SelectPrimitive.Trigger
      className={cn(
        'flex min-h-[var(--density-control-height)] w-full items-center justify-between gap-2',
        'rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-raised)] px-3',
        'text-start text-[var(--color-text)] disabled:cursor-not-allowed disabled:opacity-60',
        'aria-[invalid=true]:border-[var(--color-danger)]',
        className,
      )}
      {...fieldProps}
      {...props}
    >
      {children}
      <SelectPrimitive.Icon asChild>
        <ChevronDown className="size-4 opacity-60" aria-hidden="true" />
      </SelectPrimitive.Icon>
    </SelectPrimitive.Trigger>
  );
}

export function SelectContent({
  className,
  children,
  position = 'popper',
  ...props
}: React.ComponentPropsWithoutRef<typeof SelectPrimitive.Content>) {
  return (
    <SelectPrimitive.Portal>
      <SelectPrimitive.Content
        position={position}
        className={cn(
          'z-50 min-w-[8rem] overflow-hidden rounded-[var(--radius-md)] border',
          'border-[var(--color-border)] bg-[var(--color-surface-raised)] shadow-[var(--shadow-md)]',
          className,
        )}
        {...props}
      >
        <SelectPrimitive.Viewport className="p-1">{children}</SelectPrimitive.Viewport>
      </SelectPrimitive.Content>
    </SelectPrimitive.Portal>
  );
}

export function SelectItem({
  className,
  children,
  ...props
}: React.ComponentPropsWithoutRef<typeof SelectPrimitive.Item>) {
  return (
    <SelectPrimitive.Item
      className={cn(
        'relative flex cursor-default select-none items-center rounded-[var(--radius-sm)]',
        'py-2 pe-2 ps-8 text-sm outline-none',
        'data-[highlighted]:bg-[var(--color-surface-sunken)]',
        'data-[disabled]:pointer-events-none data-[disabled]:opacity-50',
        className,
      )}
      {...props}
    >
      <span className="absolute start-2 flex size-4 items-center justify-center">
        <SelectPrimitive.ItemIndicator>
          <Check className="size-4" aria-hidden="true" />
        </SelectPrimitive.ItemIndicator>
      </span>
      <SelectPrimitive.ItemText>{children}</SelectPrimitive.ItemText>
    </SelectPrimitive.Item>
  );
}
