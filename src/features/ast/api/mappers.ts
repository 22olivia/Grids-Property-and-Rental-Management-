import type { Building, Floor, Property, Unit } from '../types';
import { UNIT_CURRENCY_FALLBACK } from '../constants';
import type { Money } from '@/domain/money/money';

/**
 * ===========================================================================
 * Backend → frontend mapping.
 * ===========================================================================
 *
 * The ONLY place backend field names appear. Screens never see snake_case, and
 * a backend rename is a change here rather than across 9 screens.
 *
 * Field names verified from the controllers' validation rules and migrations.
 * ===========================================================================
 */

/** Raw shapes, as the backend serialises them. */
export interface BackendProperty {
  id: number;
  organization_id: number | null;
  owner_id: number | null;
  name: string;
  type: string | null;
  address_line1: string | null;
  address_line2: string | null;
  city: string | null;
  state: string | null;
  postal_code: string | null;
  country: string | null;
  latitude: number | string | null;
  longitude: number | string | null;
  description: string | null;
  total_units: number | null;
  status: string | null;
  created_at: string | null;
  updated_at: string | null;
  owner?: { id: number; full_name?: string | null; email?: string | null } | null;
  rental_units?: unknown[];
}

export interface BackendBuilding {
  id: number;
  organization_id: number | null;
  property_id: number;
  name: string;
  code: string | null;
  total_floors: number | null;
  status: string | null;
  created_at: string | null;
  updated_at: string | null;
  property?: { id: number; name: string } | null;
  floors?: unknown[];
  rental_units?: unknown[];
}

export interface BackendFloor {
  id: number;
  building_id: number;
  name: string;
  level: number;
}

export interface BackendUnit {
  id: number;
  organization_id: number | null;
  property_id: number;
  building_id: number | null;
  floor_id: number | null;
  unit_number: string;
  unit_type: string | null;
  floor: string | null;
  bedrooms: number | null;
  bathrooms: number | null;
  square_feet: string | number | null;
  area: string | number | null;
  furnishing_status: string | null;
  monthly_rent: string | number | null;
  maintenance_charge: string | number | null;
  deposit_amount: string | number | null;
  availability_date: string | null;
  status: string | null;
  description: string | null;
  amenities: string[] | null;
  is_listed: boolean | null;
  created_at: string | null;
  updated_at: string | null;
  property?: { id: number; name: string } | null;
  building?: { id: number; name: string } | null;
  floor_level?: { id: number; name: string } | null;
}

/**
 * Money conversion.
 *
 * Laravel serialises `decimal:2` casts as STRINGS ("1500.00"), which is
 * exactly what the frontend carries. The `String()` fallback exists only for
 * the case where a column is ever changed to a float — it keeps the value
 * readable rather than throwing, and any precision loss would have happened
 * server-side already.
 *
 * Currency is not stored on these tables; it comes from configuration. See
 * UNIT_CURRENCY_FALLBACK and the FR-FIN-002 gap.
 */
function toMoney(value: string | number | null | undefined): Money | null {
  if (value === null || value === undefined || value === '') return null;
  return { amount: String(value), currency: UNIT_CURRENCY_FALLBACK };
}

function toNumber(value: string | number | null | undefined): number | null {
  if (value === null || value === undefined || value === '') return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

export function mapProperty(row: BackendProperty): Property {
  const latitude = toNumber(row.latitude);
  const longitude = toNumber(row.longitude);

  return {
    id: row.id,
    organisationId: row.organization_id ?? null,
    name: row.name,
    type: row.type ?? '',
    status: row.status ?? 'active',
    address: {
      line1: row.address_line1 ?? '',
      line2: row.address_line2 ?? null,
      city: row.city ?? '',
      state: row.state ?? null,
      postalCode: row.postal_code ?? null,
      country: row.country ?? null,
    },
    coordinates: latitude !== null && longitude !== null ? { latitude, longitude } : null,
    description: row.description ?? null,
    totalUnits: row.total_units ?? null,
    owner: row.owner
      ? { id: row.owner.id, fullName: row.owner.full_name ?? null, email: row.owner.email ?? null }
      : null,
    // Derived from the eagerly-loaded relation. `total_units` is a separate,
    // manually-maintained column and the two can disagree — both are shown.
    unitCount: Array.isArray(row.rental_units) ? row.rental_units.length : 0,
    createdAt: row.created_at ?? null,
    updatedAt: row.updated_at ?? null,
  };
}

export function mapBuilding(row: BackendBuilding): Building {
  return {
    id: row.id,
    organisationId: row.organization_id ?? null,
    propertyId: row.property_id,
    propertyName: row.property?.name ?? null,
    name: row.name,
    code: row.code ?? null,
    totalFloors: row.total_floors ?? 0,
    status: row.status ?? 'active',
    floorCount: Array.isArray(row.floors) ? row.floors.length : 0,
    unitCount: Array.isArray(row.rental_units) ? row.rental_units.length : 0,
    createdAt: row.created_at ?? null,
    updatedAt: row.updated_at ?? null,
  };
}

export function mapFloor(row: BackendFloor): Floor {
  return { id: row.id, buildingId: row.building_id, name: row.name, level: row.level };
}

export function mapUnit(row: BackendUnit): Unit {
  return {
    id: row.id,
    organisationId: row.organization_id ?? null,
    propertyId: row.property_id,
    propertyName: row.property?.name ?? null,
    buildingId: row.building_id ?? null,
    buildingName: row.building?.name ?? null,
    floorId: row.floor_id ?? null,
    // Two distinct fields exist: `floor` (free text) and `floor_level`
    // (the Floor relation). The relation wins; the string is the fallback.
    floorName: row.floor_level?.name ?? row.floor ?? null,
    unitNumber: row.unit_number,
    unitType: row.unit_type ?? null,
    status: row.status ?? 'vacant',
    bedrooms: row.bedrooms ?? null,
    bathrooms: row.bathrooms ?? null,
    squareFeet: toNumber(row.square_feet),
    areaSqm: toNumber(row.area),
    furnishingStatus: row.furnishing_status ?? null,
    monthlyRent: toMoney(row.monthly_rent),
    maintenanceCharge: toMoney(row.maintenance_charge),
    depositAmount: toMoney(row.deposit_amount),
    availabilityDate: row.availability_date ?? null,
    isListed: Boolean(row.is_listed),
    description: row.description ?? null,
    amenities: Array.isArray(row.amenities) ? row.amenities : [],
    createdAt: row.created_at ?? null,
    updatedAt: row.updated_at ?? null,
  };
}
