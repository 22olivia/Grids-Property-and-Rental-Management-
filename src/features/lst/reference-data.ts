/**
 * Listing reference data.
 *
 * MISSING INFORMATION (MI-20, MI-26): FR-LST-003 requires "amenities" but
 * never enumerates them, and FR-ADM-004 makes reference data configurable with
 * no endpoint in §12. Declared once here so replacing it with an API call is a
 * single change rather than a hunt through forms.
 */
export const AMENITIES = [
  'parking',
  'lift',
  'security',
  'pool',
  'gym',
  'balcony',
  'garden',
  'furnished',
] as const;
