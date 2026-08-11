import { z } from 'zod';
import { LISTING_TYPES } from '../types';
import { optionalNumber, optionalString } from '@/lib/forms/zod-helpers';

/**
 * @provisional — proposed contract, to be replaced by generated types when the
 * OpenAPI spec is published (US-API-006).
 *
 * Not validated here, deliberately: the FR-LST-008 availability guard, state
 * transitions, and duplicate detection. All are business rules the server owns
 * (SRS §6). A client rule that disagrees with the server blocks legitimate
 * work with no way past it.
 */
export const listingFormSchema = z.object({
  title: z.string().min(1, 'required'),
  reference: z.string().min(1, 'required'),
  type: z.enum(LISTING_TYPES),

  // FR-LST-001 — a listing binds to a canonical asset, optionally to a unit.
  propertyId: z.string().min(1, 'required'),
  unitId: optionalString(z.string().min(1)),

  // Decimal string end to end. Never coerced to a number — see MI-02 and the
  // precision regression fixed in tests/money-precision.test.ts.
  priceAmount: optionalString(z.string().regex(/^\d+(\.\d{1,4})?$/, 'amount')),
  priceCurrency: optionalString(z.string().length(3)),

  areaSqm: optionalNumber(z.number().positive('positive')),
  bedrooms: optionalNumber(z.number().int().min(0)),
  bathrooms: optionalNumber(z.number().int().min(0)),
  amenities: z.array(z.string()),

  city: z.string().min(1, 'required'),
  neighborhood: optionalString(z.string().min(1)),
  landmark: optionalString(z.string().min(1)),

  // MI-25: "legal status" is required by FR-LST-003 but never defined. Free
  // text rather than an invented vocabulary.
  legalStatus: optionalString(z.string().min(1)),
  availableFrom: optionalString(z.string().min(1)),
});

export type ListingFormValues = z.infer<typeof listingFormSchema>;
