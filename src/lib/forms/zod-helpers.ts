import { z } from 'zod';

/**
 * Empty-input handling for optional fields.
 *
 * An HTML input the user clears yields `''`, not `null`. Passing that into
 * `z.coerce.number()` is a trap because `Number('') === 0`. Two consequences
 * observed in review:
 *   - a cleared optional "area" became 0, then failed `.positive()`, so the
 *     user saw an error for leaving an optional field blank;
 *   - a cleared coordinate pair became `{ 0, 0 }` and passed range validation,
 *     silently recording Null Island as a property's real location.
 *
 * ---------------------------------------------------------------------------
 * IMPLEMENTATION NOTE — why `.nullable()` and not `z.union([inner, z.null()])`.
 *
 * The union form looks equivalent and is not. A failing union reports
 * `invalid_union` with Zod's default message ("Invalid input") and DISCARDS
 * the inner custom message. Since the forms translate via
 * `t('validation.' + message)`, every optional field's error resolved to an
 * unknown message key — silently, because the happy path never hits it.
 *
 * `inner.nullable()` delegates to `inner` for non-null values, so custom
 * messages ('positive', 'amount', 'email') survive to the UI.
 * ---------------------------------------------------------------------------
 */

const isEmpty = (value: unknown) => value === '' || value === null || value === undefined;

/** Optional number: `''` becomes null instead of 0; inner messages survive. */
export function optionalNumber<T extends z.ZodNumber>(inner: T) {
  return z.preprocess((value) => (isEmpty(value) ? null : value), inner.nullable());
}

/** Optional string: `''` becomes null instead of failing a length/format rule. */
export function optionalString<T extends z.ZodString>(inner: T) {
  return z.preprocess((value) => (isEmpty(value) ? null : value), inner.nullable());
}

/**
 * Optional coordinate pair.
 * Both blank means "no coordinates", not the origin. One blank is a genuine
 * error and is left to the inner schema to report on the offending field.
 */
export function optionalCoordinates() {
  return z.preprocess(
    (value) => {
      if (!value || typeof value !== 'object') return null;
      const { latitude, longitude } = value as Record<string, unknown>;
      if (isEmpty(latitude) && isEmpty(longitude)) return null;
      return value;
    },
    z
      .object({
        latitude: z.coerce.number().min(-90).max(90),
        longitude: z.coerce.number().min(-180).max(180),
      })
      .nullable(),
  );
}

/**
 * Maps a Zod message onto a known translation key.
 *
 * Defence in depth for the bug above: if a schema ever surfaces a message that
 * has no catalogue entry, the user sees a generic "invalid" message rather
 * than a raw key or a thrown missing-message error. A wrong-looking message is
 * a bug; a crashed form is an outage.
 */
const KNOWN_VALIDATION_KEYS = new Set([
  'required',
  'email',
  'phone',
  'positive',
  'amount',
  'contactRequired',
]);

export function validationKey(message: string | undefined): string | undefined {
  if (!message) return undefined;
  return KNOWN_VALIDATION_KEYS.has(message) ? message : 'invalid';
}
