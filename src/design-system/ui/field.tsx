'use client';

import { createContext, useContext, useId, type ReactNode } from 'react';
import { cn } from '@/lib/utils/cn';

/**
 * Field wrapper — the single place form accessibility is implemented.
 *
 * Every control in this design system consumes FieldContext rather than
 * wiring its own ids. This is what prevents the most common accessibility
 * regression in large codebases: labels and error messages that are visually
 * associated but not programmatically associated.
 *
 * Covers WCAG 1.3.1 (info and relationships), 3.3.1 (error identification)
 * and 3.3.2 (labels or instructions).
 */

interface FieldContextValue {
  id: string;
  descriptionId: string | undefined;
  errorId: string | undefined;
  invalid: boolean;
  required: boolean;
}

const FieldContext = createContext<FieldContextValue | null>(null);

export function useField(): FieldContextValue | null {
  return useContext(FieldContext);
}

/** Props a control spreads onto its input element to become accessible. */
export function useFieldControlProps() {
  const field = useField();
  if (!field) return {};
  return {
    id: field.id,
    'aria-invalid': field.invalid || undefined,
    'aria-required': field.required || undefined,
    'aria-describedby':
      [field.descriptionId, field.errorId].filter(Boolean).join(' ') || undefined,
  } as const;
}

export interface FieldProps {
  label: ReactNode;
  /** Help text. Rendered before the control so it is read before input. */
  description?: ReactNode;
  /** Validation message. Presence sets aria-invalid on the control. */
  error?: ReactNode;
  required?: boolean;
  children: ReactNode;
  className?: string;
}

export function Field({
  label,
  description,
  error,
  required = false,
  children,
  className,
}: FieldProps) {
  const id = useId();
  const descriptionId = description ? `${id}-description` : undefined;
  const errorId = error ? `${id}-error` : undefined;

  return (
    <FieldContext.Provider
      value={{ id, descriptionId, errorId, invalid: Boolean(error), required }}
    >
      <div className={cn('flex flex-col gap-1.5', className)}>
        <label htmlFor={id} className="text-sm font-medium text-[var(--color-text)]">
          {label}
          {required && (
            <>
              {/* Visible marker is decorative; aria-required on the control
                  carries the semantics, so the asterisk is hidden from AT. */}
              <span aria-hidden="true" className="ms-1 text-[var(--color-danger)]">
                *
              </span>
            </>
          )}
        </label>

        {description && (
          <p id={descriptionId} className="text-sm text-[var(--color-text-muted)]">
            {description}
          </p>
        )}

        {children}

        {error && (
          // role="alert" so the message is announced when it appears after
          // a failed submit, not only when the control is focused.
          <p id={errorId} role="alert" className="text-sm text-[var(--color-danger)]">
            {error}
          </p>
        )}
      </div>
    </FieldContext.Provider>
  );
}
