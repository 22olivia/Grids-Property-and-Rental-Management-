import type { ListQuery, ListResult } from '@/lib/data/repository';
import type { Listing, ListingMedia, Project, ListingState } from '../types';
import type { ListingFormValues } from '../schemas/listing-schemas';
import type { AuditEntry } from '@/domain/components/audit-trail';

/**
 * Listing data access contract.
 *
 * Method set derived from requirements only:
 *   list/get/create/update    FR-LST-001, FR-LST-003
 *   applyTransition           FR-LST-006 (server decides legality — MI-24)
 *   listApprovalQueue         FR-LST-006 review/approval states
 *   media operations          FR-LST-007
 *   listProjects/getProject   FR-LST-002 project inventory
 */
export interface ListingRepository {
  listListings(query: ListQuery): Promise<ListResult<Listing>>;
  getListing(id: string): Promise<Listing>;
  createListing(values: ListingFormValues): Promise<Listing>;
  updateListing(id: string, values: ListingFormValues): Promise<Listing>;

  /** The server validates the transition; the client only requests it. */
  applyTransition(id: string, targetState: ListingState): Promise<Listing>;

  listApprovalQueue(query: ListQuery): Promise<ListResult<Listing>>;

  listMedia(listingId: string): Promise<ListingMedia[]>;
  reorderMedia(listingId: string, orderedIds: string[]): Promise<ListingMedia[]>;
  removeMedia(listingId: string, mediaId: string): Promise<void>;

  listProjects(query: ListQuery): Promise<ListResult<Project>>;
  getProject(id: string): Promise<Project>;

  listChangeEvents(listingId: string): Promise<AuditEntry[]>;
}
