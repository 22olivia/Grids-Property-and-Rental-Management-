import type { Money } from '@/domain/money/money';
import type { IsoInstant } from '@/domain/datetime/datetime';

/**
 * ===========================================================================
 * Property asset domain types — RECONCILED with the real GPMS backend.
 * ===========================================================================
 *
 * Every vocabulary below is copied from backend source, not from the SRS and
 * not invented:
 *   app/Support/UnitStatuses.php
 *   app/Http/Controllers/Api/PropertyController.php  (validation rules)
 *   app/Http/Controllers/Api/RentalUnitController.php (validatedPayload)
 *   app/Http/Controllers/Api/BuildingController.php
 *   database/migrations/2026_08_04_190000_create_saas_foundation_tables.php
 *
 * SRS §11 still governs the shape: the asset, the listing and the contract stay
 * separate. These types carry no listing or lease data.
 * ===========================================================================
 */

/**
 * Unit statuses — VERIFIED from `app/Support/UnitStatuses.php`.
 *
 * This REPLACES the four values previously derived from the SRS text
 * (available / reserved / occupied / unavailable). MI-17 is now answered by
 * the backend, and the answer is seven statuses plus two legacy aliases.
 *
 * `available` and `maintenance` are kept because the backend still accepts
 * them (`UnitStatuses::all()`) and normalises them on write
 * (`available → vacant`, `maintenance → under_maintenance`). Existing rows may
 * still hold them, so the UI must be able to render them.
 */
export const UNIT_STATUSES = [
  'vacant',
  'reserved',
  'application_pending',
  'occupied',
  'notice_period',
  'under_maintenance',
  'blocked',
] as const;

/** Accepted on write and possibly present on old rows. Normalised server-side. */
export const LEGACY_UNIT_STATUSES = ['available', 'maintenance'] as const;

export type UnitStatus = (typeof UNIT_STATUSES)[number] | (typeof LEGACY_UNIT_STATUSES)[number];

/**
 * Property classification — VERIFIED from PropertyController validation:
 * `'type' => ['sometimes', 'string', 'in:apartment,house,commercial,villa']`
 *
 * REPLACES the previous residential / commercial / mixed-use set, which was a
 * frontend placeholder (MI-20) and does not exist in the backend.
 */
export const PROPERTY_TYPES = ['apartment', 'house', 'commercial', 'villa'] as const;
export type PropertyType = (typeof PROPERTY_TYPES)[number];

/**
 * Property lifecycle status — VERIFIED from PropertyController validation:
 * `'status' => ['sometimes', 'string', 'in:active,inactive,under_maintenance']`
 *
 * REPLACES the previous active/archived placeholder (MI-18).
 */
export const PROPERTY_STATUSES = ['active', 'inactive', 'under_maintenance'] as const;
export type PropertyStatus = (typeof PROPERTY_STATUSES)[number];

/**
 * Building status — the backend validates only `string, max:30` with a default
 * of 'active'. There is NO enumeration, so none is invented here; the value is
 * displayed as returned.
 */
export type BuildingStatus = string;

/** Address as the backend stores it (properties table). */
export interface Address {
  line1: string;
  line2: string | null;
  city: string;
  state: string | null;
  postalCode: string | null;
  country: string | null;
}

export interface Coordinates {
  latitude: number;
  longitude: number;
}

/** Owner summary as eagerly loaded on a property. */
export interface OwnerSummary {
  id: number;
  fullName: string | null;
  email: string | null;
}

export interface Property {
  id: number;
  organisationId: number | null;
  name: string;
  type: string;
  status: string;
  address: Address;
  coordinates: Coordinates | null;
  description: string | null;
  totalUnits: number | null;
  owner: OwnerSummary | null;
  /** Count derived from the eagerly-loaded relation, not a stored column. */
  unitCount: number;
  createdAt: IsoInstant | null;
  updatedAt: IsoInstant | null;
}

export interface Building {
  id: number;
  organisationId: number | null;
  propertyId: number;
  propertyName: string | null;
  name: string;
  code: string | null;
  totalFloors: number;
  status: BuildingStatus;
  floorCount: number;
  unitCount: number;
  createdAt: IsoInstant | null;
  updatedAt: IsoInstant | null;
}

export interface Floor {
  id: number;
  buildingId: number;
  name: string;
  level: number;
}

export interface Unit {
  id: number;
  organisationId: number | null;
  propertyId: number;
  propertyName: string | null;
  buildingId: number | null;
  buildingName: string | null;
  floorId: number | null;
  floorName: string | null;
  /** Backend column is `unit_number`. */
  unitNumber: string;
  unitType: string | null;
  status: string;
  bedrooms: number | null;
  bathrooms: number | null;
  squareFeet: number | null;
  areaSqm: number | null;
  furnishingStatus: string | null;
  /**
   * Money as decimal strings — VERIFIED: `decimal(12,2)` columns with
   * `'decimal:2'` casts, which Laravel serialises as JSON strings.
   *
   * Currency is NOT stored on rental_units (only on payments/payment_orders),
   * so it is supplied from configuration. Recorded as a gap against
   * FR-FIN-002 rather than invented per row.
   */
  monthlyRent: Money | null;
  maintenanceCharge: Money | null;
  depositAmount: Money | null;
  availabilityDate: IsoInstant | null;
  isListed: boolean;
  description: string | null;
  amenities: string[];
  createdAt: IsoInstant | null;
  updatedAt: IsoInstant | null;
}
