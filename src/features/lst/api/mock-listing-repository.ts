import type { ListQuery, ListResult } from '@/lib/data/repository';
import type {
  Listing,
  ListingMedia,
  ListingState,
  ListingTransition,
  ListingType,
  Project,
} from '../types';
import { LISTING_STATES, LISTING_TYPES } from '../types';
import type { ListingFormValues } from '../schemas/listing-schemas';
import type { ListingRepository } from './listing-repository';
import type { AuditEntry } from '@/domain/components/audit-trail';

/**
 * ===========================================================================
 * MOCK DATA — UI development only. Never ships enabled.
 * ===========================================================================
 *
 * IMPORTANT — the transitions below are PLACEHOLDERS, not a specification.
 *
 * FR-LST-006 enumerates the eight listing states verbatim, so the states are
 * real. The transition MATRIX is not specified anywhere (MI-24): nothing says
 * which moves are legal, who may make them, or what preconditions apply.
 *
 * The simple forward-only rule below exists so the stepper can be built and
 * reviewed. It must be replaced wholesale by the server's matrix — it is not a
 * proposal and no screen depends on its shape beyond "a list of transitions".
 * ===========================================================================
 */

const LATENCY_MS = 320;
const delay = () => new Promise((resolve) => setTimeout(resolve, LATENCY_MS));
const CURRENCY = 'AED';

/** Fixture vocabulary — see the note in the asset mock repository. */
const PROPERTY_NAMES = [
  'Marina Heights', 'Al Reem Residences', 'Cedar Court', 'Pearl Tower',
  'Jasmine Villas', 'Corniche Plaza', 'Olive Grove Estate', 'Sapphire Bay',
  'Falcon Business Park', 'Lantern Quarter', 'Rosewood Gardens', 'Harbour View',
];
const HEADLINES = [
  'Sea-view apartment with balcony', 'Family villa near the park',
  'Fitted office suite, high floor', 'Bright studio, walk to metro',
  'Two-bedroom with maid\u2019s room', 'Retail unit on the main strip',
];
const DISTRICTS = ['Marina', 'Downtown', 'Al Khalidiyah', 'Al Majaz', 'Business Bay'];

/** Placeholder only — see the header. */
function mockTransitions(state: ListingState, blocked: string | null): ListingTransition[] {
  const forward: Partial<Record<ListingState, ListingState[]>> = {
    draft: ['review'],
    review: ['approval', 'draft'],
    approval: ['published', 'draft'],
    published: ['paused', 'closed'],
    paused: ['published', 'archived'],
    expired: ['draft', 'archived'],
    closed: ['archived'],
    archived: [],
  };
  return (forward[state] ?? []).map((target) => ({
    id: `${state}->${target}`,
    targetState: target,
    // FR-LST-008: publishing is blocked when the linked unit is unavailable.
    // The reason is server-supplied; the client only renders it.
    blockedReason: target === 'published' ? blocked : null,
  }));
}

function makeListing(index: number): Listing {
  const state = LISTING_STATES[index % LISTING_STATES.length] as ListingState;
  const type = LISTING_TYPES[index % LISTING_TYPES.length] as ListingType;
  // Every 7th listing simulates the FR-LST-008 guard being active.
  const blocked = index % 7 === 0 ? 'The linked unit is currently occupied.' : null;

  return {
    id: `lst-${index}`,
    reference: `LST-${String(index).padStart(4, '0')}`,
    title: `${HEADLINES[index % HEADLINES.length]} — ${PROPERTY_NAMES[index % PROPERTY_NAMES.length]}`,
    type,
    state,
    propertyId: `prop-${(index % 12) + 1}`,
    propertyName: PROPERTY_NAMES[index % PROPERTY_NAMES.length]!,
    unitId: index % 5 === 0 ? null : `unit-${index}`,
    unitName: index % 5 === 0 ? null : `${(index % 12) + 1}0${(index % 8) + 1}`,
    // Decimal string, never a float.
    price: { amount: `${(index % 12) * 25000 + 350000}.00`, currency: CURRENCY },
    areaSqm: 60 + (index % 8) * 20,
    bedrooms: index % 5,
    bathrooms: (index % 3) + 1,
    amenities: ['parking', 'lift', 'security'].slice(0, (index % 3) + 1),
    location: {
      city: ['Dubai', 'Abu Dhabi', 'Sharjah'][index % 3]!,
      neighborhood: DISTRICTS[index % DISTRICTS.length]!,
      landmark: null,
      latitude: 25.2 + index * 0.001,
      longitude: 55.27 + index * 0.001,
    },
    media: Array.from({ length: (index % 4) + 1 }, (_, i) => ({
      id: `lst-${index}-media-${i}`,
      kind: i === 0 ? 'image' : i === 1 ? 'floor-plan' : 'image',
      url: null,
      caption: null,
      position: i,
      watermarked: i === 0,
    })) as ListingMedia[],
    legalStatus: null,
    availableFrom: null,
    publishBlockedReason: blocked,
    availableTransitions: mockTransitions(state, blocked),
    viewCount: (index * 37) % 900,
    enquiryCount: index % 15,
    customFields: {},
    createdAt: '2026-01-15T09:00:00Z',
    updatedAt: '2026-07-20T14:20:00Z',
  };
}

function makeProject(index: number): Project {
  return {
    id: `proj-${index}`,
    reference: `PRJ-${String(index).padStart(4, '0')}`,
    name: ['Emerald Quarter', 'Northshore Phase 2', 'Palm Residences', 'Cedar Park'][index % 4]!,
    developerName: ['Grids Developments', 'Northshore Properties', 'Palm Estates'][index % 3]!,
    city: ['Dubai', 'Abu Dhabi', 'Sharjah'][index % 3]!,
    unitTypes: Array.from({ length: (index % 3) + 2 }, (_, i) => ({
      id: `proj-${index}-type-${i}`,
      name: ['Studio', '1 Bedroom', '2 Bedroom', '3 Bedroom'][i % 4]!,
      totalUnits: 20 + i * 10,
      availableUnits: 5 + i * 3,
      areaSqmFrom: 55 + i * 20,
      areaSqmTo: 90 + i * 25,
      priceFrom: { amount: `${350000 + i * 50000}.00`, currency: CURRENCY },
      priceTo: { amount: `${520000 + i * 60000}.00`, currency: CURRENCY },
    })),
    updatedAt: '2026-06-01T10:00:00Z',
  };
}

const listings = Array.from({ length: 96 }, (_, i) => makeListing(i + 1));
const projects = Array.from({ length: 9 }, (_, i) => makeProject(i + 1));

function paginate<T>(all: T[], query: ListQuery): ListResult<T> {
  const page = query.page ?? 1;
  const perPage = query.perPage ?? 20;
  const start = (page - 1) * perPage;
  return { items: all.slice(start, start + perPage), total: all.length, page, perPage };
}

function search(all: Listing[], term?: string): Listing[] {
  if (!term) return all;
  const needle = term.toLowerCase();
  return all.filter(
    (item) =>
      item.title.toLowerCase().includes(needle) ||
      item.reference.toLowerCase().includes(needle) ||
      item.propertyName.toLowerCase().includes(needle),
  );
}

function sortBy(all: Listing[], query: ListQuery): Listing[] {
  if (!query.sort) return all;
  const factor = query.direction === 'desc' ? -1 : 1;
  return [...all].sort((a, b) => {
    const key = query.sort as keyof Listing;
    const left = a[key];
    const right = b[key];
    if (typeof left === 'number' && typeof right === 'number') return (left - right) * factor;
    return String(left ?? '').localeCompare(String(right ?? '')) * factor;
  });
}

export const mockListingRepository: ListingRepository = {
  async listListings(query) {
    await delay();
    let result = search(listings, query.search);
    if (query.filters?.state) result = result.filter((l) => l.state === query.filters?.state);
    if (query.filters?.type) result = result.filter((l) => l.type === query.filters?.type);
    if (query.filters?.propertyId)
      result = result.filter((l) => l.propertyId === query.filters?.propertyId);
    return paginate(sortBy(result, query), query);
  },

  async getListing(id) {
    await delay();
    const found = listings.find((l) => l.id === id);
    if (!found) throw new Error('NOT_FOUND');
    return found;
  },

  async createListing(values: ListingFormValues) {
    await delay();
    return { ...makeListing(listings.length + 1), ...values } as unknown as Listing;
  },

  async updateListing(id, values: ListingFormValues) {
    await delay();
    const existing = listings.find((l) => l.id === id);
    if (!existing) throw new Error('NOT_FOUND');
    return { ...existing, ...values } as unknown as Listing;
  },

  async applyTransition(id, targetState) {
    await delay();
    const existing = listings.find((l) => l.id === id);
    if (!existing) throw new Error('NOT_FOUND');
    // Mirrors what the server must enforce: the guard is checked on commit.
    if (targetState === 'published' && existing.publishBlockedReason) {
      throw new Error('TRANSITION_BLOCKED');
    }
    return {
      ...existing,
      state: targetState,
      availableTransitions: mockTransitions(targetState, existing.publishBlockedReason),
    };
  },

  async listApprovalQueue(query) {
    await delay();
    const pending = listings.filter((l) => l.state === 'review' || l.state === 'approval');
    return paginate(sortBy(search(pending, query.search), query), query);
  },

  async listMedia(listingId) {
    await delay();
    return listings.find((l) => l.id === listingId)?.media ?? [];
  },

  async reorderMedia(listingId, orderedIds) {
    await delay();
    const media = listings.find((l) => l.id === listingId)?.media ?? [];
    return orderedIds
      .map((id, position) => {
        const item = media.find((m) => m.id === id);
        return item ? { ...item, position } : null;
      })
      .filter((item): item is ListingMedia => item !== null);
  },

  async removeMedia() {
    await delay();
  },

  async listProjects(query) {
    await delay();
    return paginate(projects, query);
  },

  async getProject(id) {
    await delay();
    const found = projects.find((p) => p.id === id);
    if (!found) throw new Error('NOT_FOUND');
    return found;
  },

  async listChangeEvents(listingId) {
    await delay();
    return [
      {
        id: `${listingId}-e1`,
        occurredAt: '2026-07-20T14:20:00Z',
        actorName: 'Demo User',
        category: 'state',
        field: 'state',
        previousValue: 'review',
        newValue: 'approval',
      },
      {
        id: `${listingId}-e2`,
        occurredAt: '2026-05-02T08:00:00Z',
        actorName: 'Demo User',
        category: 'price',
        field: 'price',
        previousValue: '350000.00',
        newValue: '375000.00',
      },
    ] satisfies AuditEntry[];
  },
};
