import { z } from 'zod';
import { PROPERTY_TYPES, PROPERTY_STATUSES, UNIT_STATUSES } from '../types';
import { optionalNumber, optionalString } from '@/lib/forms/zod-helpers';

/**
 * ===========================================================================
 * Form schemas — mirror the backend's validation rules.
 * ===========================================================================
 *
 * Rules copied from:
 *   PropertyController::store / update
 *   RentalUnitController::validatedPayload
 *   BuildingController::store
 *
 * Client validation exists to give immediate feedback, not to be the
 * authority: the server revalidates everything and its answer wins (SRS §6).
 * Constraints are therefore matched, never tightened beyond the backend's.
 * ===========================================================================
 */

const addressSchema = z.object({
  // Backend: address_line1 required, max 255
  line1: z.string().min(1, 'required').max(255),
  line2: optionalString(z.string().max(255)),
  city: z.string().min(1, 'required').max(100),
  state: optionalString(z.string().max(100)),
  postalCode: optionalString(z.string().max(20)),
  country: optionalString(z.string().max(100)),
});

/** Both blank means "no coordinates", not the origin. */
const coordinatesSchema = z.preprocess(
  (value) => {
    if (!value || typeof value !== 'object') return null;
    const { latitude, longitude } = value as Record<string, unknown>;
    const empty = (v: unknown) => v === '' || v === null || v === undefined;
    if (empty(latitude) && empty(longitude)) return null;
    return value;
  },
  z
    .object({
      latitude: z.coerce.number().min(-90).max(90),
      longitude: z.coerce.number().min(-180).max(180),
    })
    .nullable(),
);

export const propertyFormSchema = z.object({
  name: z.string().min(1, 'required').max(255),
  // Backend: 'owner_id' => ['required', 'exists:owners,id']
  ownerId: z.coerce.number().int().positive('required'),
  type: z.enum(PROPERTY_TYPES),
  status: z.enum(PROPERTY_STATUSES),
  address: addressSchema,
  coordinates: coordinatesSchema,
  description: optionalString(z.string()),
  totalUnits: optionalNumber(z.number().int().min(1)),
});
export type PropertyFormValues = z.infer<typeof propertyFormSchema>;

export const buildingFormSchema = z.object({
  name: z.string().min(1, 'required').max(255),
  propertyId: z.coerce.number().int().positive('required'),
  code: optionalString(z.string().max(50)),
  totalFloors: optionalNumber(z.number().int().min(1).max(200)),
  // Backend validates only `string, max:30` — no enum, so none is imposed.
  status: z.string().max(30),
});
export type BuildingFormValues = z.infer<typeof buildingFormSchema>;

export const unitFormSchema = z.object({
  // Backend column is unit_number, required, max 50.
  unitNumber: z.string().min(1, 'required').max(50),
  propertyId: z.coerce.number().int().positive('required'),
  buildingId: optionalNumber(z.number().int().positive()),
  floorId: optionalNumber(z.number().int().positive()),
  unitType: optionalString(z.string().max(50)),
  furnishingStatus: optionalString(z.string().max(40)),
  status: z.enum(UNIT_STATUSES),
  bedrooms: optionalNumber(z.number().int().min(0)),
  bathrooms: optionalNumber(z.number().int().min(0)),
  squareFeet: optionalNumber(z.number().min(0)),
  areaSqm: optionalNumber(z.number().min(0)),

  /**
   * Money as decimal STRINGS.
   *
   * The backend validates `numeric` and stores decimal(12,2); Laravel returns
   * these as strings. The frontend types, validates and submits them as
   * strings and never calls Number() on them — verified as the correct
   * representation, and the reason the precision defect found during the AST
   * audit mattered.
   */
  monthlyRent: z.string().regex(/^\d+(\.\d{1,2})?$/, 'amount'),
  maintenanceCharge: optionalString(z.string().regex(/^\d+(\.\d{1,2})?$/, 'amount')),
  depositAmount: optionalString(z.string().regex(/^\d+(\.\d{1,2})?$/, 'amount')),

  availabilityDate: optionalString(z.string()),
  description: optionalString(z.string()),
  isListed: z.boolean(),
});
export type UnitFormValues = z.infer<typeof unitFormSchema>;
