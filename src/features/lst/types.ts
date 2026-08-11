import type { Money } from '@/domain/money/money';
import type { IsoInstant } from '@/domain/datetime/datetime';

/**
 * ===========================================================================
 * Listing domain types.
 * ===========================================================================
 *
 * SRS §11 is emphatic: "The property asset, listing and contract shall be
 * separate concepts… This separation is mandatory to prevent availability,
 * occupancy and billing conflicts."
 *
 * So a Listing REFERENCES an asset; it does not extend one and does not
 * duplicate its fields. The tempting shared "PropertyLike" supertype is
 * exactly the thing §11 forbids.
 *
 * Field basis, all enumerated verbatim in the requirements:
 *   FR-LST-002 (Must) — "sale, long-term rent, short-term rent, commercial
 *     lease, land and project inventory"
 *   FR-LST-003 (Must) — "price, currency, area, rooms, bathrooms, amenities,
 *     location, media, availability and legal status"
 *   FR-LST-006 (Must) — "draft, review, approval, publish, pause, expire,
 *     sold/rented and archive states"
 * ===========================================================================
 */

/** FR-LST-002 — the enumerated listing purposes, verbatim. */
export const LISTING_TYPES = [
  'sale',
  'long-term-rent',
  'short-term-rent',
  'commercial-lease',
  'land',
  'project',
] as const;
export type ListingType = (typeof LISTING_TYPES)[number];

/**
 * FR-LST-006 — the eight enumerated states, verbatim.
 *
 * The STATES are specified. The TRANSITIONS are not — see MI-24. Transitions
 * therefore arrive from the repository as data and are never derived here.
 */
export const LISTING_STATES = [
  'draft',
  'review',
  'approval',
  'published',
  'paused',
  'expired',
  'closed',
  'archived',
] as const;
export type ListingState = (typeof LISTING_STATES)[number];

/** FR-LST-003 — "media". FR-LST-007 enumerates the kinds. */
export const MEDIA_KINDS = ['image', 'video', 'floor-plan', 'tour-360', 'document'] as const;
export type MediaKind = (typeof MEDIA_KINDS)[number];

export interface ListingMedia {
  id: string;
  kind: MediaKind;
  /** Server-issued URL. Never constructed client-side. */
  url: string | null;
  caption: string | null;
  position: number;
  /** FR-LST-007 (Should) — watermarking. Server-applied. */
  watermarked: boolean;
}

/** FR-LST-003 — "location". Mirrors the asset address rather than sharing it. */
export interface ListingLocation {
  city: string;
  neighborhood: string | null;
  landmark: string | null;
  latitude: number | null;
  longitude: number | null;
}

export interface Listing {
  id: string;
  reference: string;
  title: string;
  type: ListingType;
  state: ListingState;

  /** FR-LST-001 — "linked to a canonical property asset and optional unit". */
  propertyId: string;
  propertyName: string;
  unitId: string | null;
  unitName: string | null;

  /** FR-LST-003 — price and currency. Decimal string only; see MI-02. */
  price: Money | null;
  areaSqm: number | null;
  bedrooms: number | null;
  bathrooms: number | null;
  amenities: string[];
  location: ListingLocation;
  media: ListingMedia[];

  /**
   * FR-LST-003 — "availability and legal status".
   *
   * MISSING INFORMATION (MI-25): "legal status" is named but never defined —
   * no vocabulary, no values, no meaning. Modelled as an opaque server-supplied
   * string so the field exists without the frontend inventing a meaning for it.
   */
  legalStatus: string | null;
  availableFrom: IsoInstant | null;

  /**
   * FR-LST-008 — "prevent advertising an occupied or unavailable unit unless
   * an authorized future-availability rule applies".
   *
   * Server-decided. The client displays the reason and disables the action; it
   * never evaluates occupancy itself, because SRS §6 forbids reimplementing
   * business rules in clients.
   */
  publishBlockedReason: string | null;

  /** FR-LST-006 — permitted next actions, supplied by the server (MI-24). */
  availableTransitions: ListingTransition[];

  viewCount: number;
  enquiryCount: number;
  customFields: Record<string, unknown>;
  createdAt: IsoInstant;
  updatedAt: IsoInstant;
}

export interface ListingTransition {
  id: string;
  targetState: ListingState;
  blockedReason: string | null;
}

/** FR-LST-002 — "project inventory". */
export interface ProjectUnitType {
  id: string;
  name: string;
  totalUnits: number;
  availableUnits: number;
  areaSqmFrom: number | null;
  areaSqmTo: number | null;
  priceFrom: Money | null;
  priceTo: Money | null;
}

export interface Project {
  id: string;
  reference: string;
  name: string;
  developerName: string | null;
  city: string;
  unitTypes: ProjectUnitType[];
  updatedAt: IsoInstant;
}
