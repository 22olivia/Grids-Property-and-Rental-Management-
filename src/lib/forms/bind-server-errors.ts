import type { FieldValues, Path, UseFormSetError } from 'react-hook-form';
import { ApiError } from '@/lib/api/types';

/**
 * Bind server validation errors onto a form.
 *
 * ---------------------------------------------------------------------------
 * Laravel keys its validation errors by its OWN field names — `owner_id`,
 * `address_line1`, `monthly_rent`, `unit_number`. React Hook Form addresses
 * fields by the form's paths — `ownerId`, `address.line1`, `monthlyRent`,
 * `unitNumber`.
 *
 * Without an explicit map, EVERY server-side validation error fell through to
 * the form-level banner instead of landing on the offending control. The
 * happy path hid it; only a rejected submit reveals it.
 *
 * The caller supplies the mapping because only the feature knows how its form
 * shape relates to the API payload — the same place `toPropertyPayload` and
 * `toUnitPayload` already encode that relationship.
 * ---------------------------------------------------------------------------
 *
 * Messages arrive already localised where the backend localises. It is
 * currently English-only (APP_LOCALE=en), so server messages appear in English
 * even in the Arabic UI — recorded, not worked around.
 */
export function bindServerErrors<T extends FieldValues>(
  error: unknown,
  setError: UseFormSetError<T>,
  /** Backend field name → form path. Unmapped fields go to the form banner. */
  fieldMap: Record<string, Path<T>>,
): { formErrors: string[]; correlationId: string | null } {
  if (!(error instanceof ApiError)) {
    return { formErrors: [], correlationId: null };
  }

  const formErrors: string[] = [];

  for (const item of error.errors) {
    const path = item.field ? fieldMap[item.field] : undefined;
    if (path) {
      setError(path, { type: 'server', message: item.message });
    } else {
      formErrors.push(item.message);
    }
  }

  return { formErrors, correlationId: error.correlationId };
}
