'use client';

import { useState } from 'react';
import { DayPicker } from 'react-day-picker';
import * as PopoverPrimitive from '@radix-ui/react-popover';
import { CalendarDays } from 'lucide-react';
import { ar, enUS } from 'date-fns/locale';
import { cn } from '@/lib/utils/cn';
import { useFieldControlProps } from './field';
import type { Locale as AppLocale } from '@/lib/i18n/config';
import { intlLocale } from '@/lib/i18n/config';

/**
 * Date picker.
 *
 * MISSING INFORMATION (MI-09): whether Hijri display is required alongside
 * Gregorian for the `ar` locale is unspecified. Gregorian only for now.
 *
 * MISSING INFORMATION (MI-14): week start (Saturday / Sunday / Monday) is
 * market-dependent and undefined. It affects every calendar surface —
 * viewings, maintenance schedules, rent schedules. Currently left to the
 * date-fns locale default.
 *
 * The trigger displays a formatted date via Intl, so it inherits the numeral
 * system decision (MI-04) from one place rather than formatting locally.
 */

export interface DatePickerProps {
  value: Date | undefined;
  onChange: (date: Date | undefined) => void;
  locale: AppLocale;
  placeholder: string;
  /** Accessible name for the trigger. */
  label: string;
  disabled?: boolean;
  className?: string;
}

export function DatePicker({
  value,
  onChange,
  locale,
  placeholder,
  label,
  disabled,
  className,
}: DatePickerProps) {
  const [open, setOpen] = useState(false);
  const fieldProps = useFieldControlProps();

  const formatted = value
    ? new Intl.DateTimeFormat(intlLocale[locale], { dateStyle: 'medium' }).format(value)
    : null;

  return (
    <PopoverPrimitive.Root open={open} onOpenChange={setOpen}>
      <PopoverPrimitive.Trigger
        type="button"
        disabled={disabled}
        aria-label={label}
        className={cn(
          'flex min-h-[var(--density-control-height)] w-full items-center justify-between gap-2',
          'rounded-[var(--radius-md)] border border-[var(--color-border)] px-3',
          'bg-[var(--color-surface-raised)] text-start text-[var(--color-text)]',
          'disabled:cursor-not-allowed disabled:opacity-60',
          className,
        )}
        {...fieldProps}
      >
        <span className={cn(!formatted && 'text-[var(--color-text-subtle)]')}>
          {formatted ?? placeholder}
        </span>
        <CalendarDays className="size-4 opacity-60" aria-hidden="true" />
      </PopoverPrimitive.Trigger>

      <PopoverPrimitive.Portal>
        <PopoverPrimitive.Content
          align="start"
          sideOffset={4}
          className="z-50 rounded-[var(--radius-md)] border border-[var(--color-border)] bg-[var(--color-surface-raised)] p-3 shadow-[var(--shadow-md)]"
        >
          <DayPicker
            mode="single"
            selected={value}
            onSelect={(date) => {
              onChange(date);
              setOpen(false);
            }}
            locale={locale === 'ar' ? ar : enUS}
            // DayPicker mirrors its own grid and navigation from this flag.
            dir={locale === 'ar' ? 'rtl' : 'ltr'}
          />
        </PopoverPrimitive.Content>
      </PopoverPrimitive.Portal>
    </PopoverPrimitive.Root>
  );
}
