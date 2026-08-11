import { MissingApiContractError } from '@/lib/api/endpoints';
import type { ListingRepository } from './listing-repository';

/**
 * The real repository — intentionally unimplemented.
 * SRS §12 lists a "Marketplace" endpoint group as an EXAMPLE: no methods, no
 * schemas, no filter grammar. Every method throws rather than guessing a URL.
 */
function unavailable(operation: string): never {
  throw new MissingApiContractError(`listings.${operation}`);
}

export const httpListingRepository: ListingRepository = {
  listListings: () => unavailable('listListings'),
  getListing: () => unavailable('getListing'),
  createListing: () => unavailable('createListing'),
  updateListing: () => unavailable('updateListing'),
  applyTransition: () => unavailable('applyTransition'),
  listApprovalQueue: () => unavailable('listApprovalQueue'),
  listMedia: () => unavailable('listMedia'),
  reorderMedia: () => unavailable('reorderMedia'),
  removeMedia: () => unavailable('removeMedia'),
  listProjects: () => unavailable('listProjects'),
  getProject: () => unavailable('getProject'),
  listChangeEvents: () => unavailable('listChangeEvents'),
};
