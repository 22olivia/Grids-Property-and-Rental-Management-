import type { ListingRepository } from './listing-repository';
import { mockListingRepository } from './mock-listing-repository';

/**
 * Listing data binding — ALWAYS mock.
 *
 * This deliberately ignores NEXT_PUBLIC_DATA_SOURCE. The GPMS backend has no
 * Listing entity: `GET /listings` is an inline closure over rental units, and
 * there is no listing lifecycle, media or approval endpoint.
 *
 * Honouring the global flag would resolve to `httpListingRepository`, whose
 * every method throws MissingApiContractError — so setting the flag to `http`
 * for the (real) asset module would break all eight listing screens. The
 * binding is per-module for exactly that reason.
 *
 * The HTTP repository is kept so the seam is visible and typed. Switch this
 * line when the backend implements listings.
 */
export const listingRepository: ListingRepository = mockListingRepository;

/** Drives the on-screen sample-data banner. */
export const LISTINGS_ARE_MOCK = true;

export type { ListingRepository } from './listing-repository';
