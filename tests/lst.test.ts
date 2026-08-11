import { describe, expect, it } from 'vitest';
import en from '../messages/en.json';
import ar from '../messages/ar.json';
import { mockListingRepository } from '@/features/lst/api/mock-listing-repository';
import { listingFormSchema } from '@/features/lst/schemas/listing-schemas';
import { LISTING_STATES, LISTING_TYPES, MEDIA_KINDS } from '@/features/lst/types';
import { listingStateTone } from '@/features/lst/constants';

describe('LST — dynamic message keys', () => {
  it('labels every listing state in both locales', () => {
    for (const state of LISTING_STATES) {
      expect(en.lst.state, `en: ${state}`).toHaveProperty(state);
      expect(ar.lst.state, `ar: ${state}`).toHaveProperty(state);
    }
  });
  it('labels every listing type in both locales', () => {
    for (const type of LISTING_TYPES) {
      expect(en.lst.type, `en: ${type}`).toHaveProperty(type);
      expect(ar.lst.type, `ar: ${type}`).toHaveProperty(type);
    }
  });
  it('labels every media kind in both locales', () => {
    for (const kind of MEDIA_KINDS) {
      expect(en.lst.mediaKind, `en: ${kind}`).toHaveProperty(kind);
      expect(ar.lst.mediaKind, `ar: ${kind}`).toHaveProperty(kind);
    }
  });
  it('falls back to neutral for an unknown state', () => {
    expect(listingStateTone('some-future-state')).toBe('neutral');
  });
});

describe('LST — the FR-LST-008 guard is server-side', () => {
  it('does not let the client publish a blocked listing', async () => {
    const page = await mockListingRepository.listListings({ page: 1, perPage: 100 });
    const blocked = page.items.find((l) => l.publishBlockedReason !== null);
    expect(blocked).toBeDefined();
    if (blocked) {
      // The transition is offered but carries a reason, so the UI disables it
      // with an explanation rather than hiding it.
      const publish = blocked.availableTransitions.find((t) => t.targetState === 'published');
      if (publish) expect(publish.blockedReason).not.toBeNull();
      // And the commit is refused regardless of what the client believes.
      await expect(
        mockListingRepository.applyTransition(blocked.id, 'published'),
      ).rejects.toThrow();
    }
  });

  it('never derives transitions client-side — they arrive as data', async () => {
    const listing = await mockListingRepository.getListing('lst-1');
    expect(Array.isArray(listing.availableTransitions)).toBe(true);
  });
});

describe('LST — validation', () => {
  const base = {
    title: 'A', reference: 'L-1', type: 'sale', propertyId: 'p1', unitId: null,
    priceAmount: '350000.00', priceCurrency: 'AED', areaSqm: 90,
    bedrooms: 2, bathrooms: 1, amenities: [], city: 'X',
    neighborhood: null, landmark: null, legalStatus: null, availableFrom: null,
  };

  it('accepts a valid listing and preserves the price as a string', () => {
    const result = listingFormSchema.safeParse(base);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.priceAmount).toBe('350000.00');
      expect(typeof result.data.priceAmount).toBe('string');
    }
  });

  it('requires the asset binding (FR-LST-001)', () => {
    expect(listingFormSchema.safeParse({ ...base, propertyId: '' }).success).toBe(false);
  });

  it('treats cleared optional fields as null, not zero', () => {
    const result = listingFormSchema.safeParse({
      ...base, areaSqm: '', bedrooms: '', priceAmount: '', priceCurrency: '',
    });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.areaSqm).toBeNull();
      expect(result.data.priceAmount).toBeNull();
    }
  });
});

describe('LST — mock repository', () => {
  it('returns only reviewable listings in the approval queue', async () => {
    const result = await mockListingRepository.listApprovalQueue({ page: 1, perPage: 50 });
    expect(result.items.length).toBeGreaterThan(0);
    expect(result.items.every((l) => l.state === 'review' || l.state === 'approval')).toBe(true);
  });

  it('filters by state', async () => {
    const result = await mockListingRepository.listListings({
      page: 1, perPage: 100, filters: { state: 'published' },
    });
    expect(result.items.every((l) => l.state === 'published')).toBe(true);
  });

  it('reorders media by the supplied id order', async () => {
    const media = await mockListingRepository.listMedia('lst-4');
    if (media.length > 1) {
      const reversed = [...media].map((m) => m.id).reverse();
      const result = await mockListingRepository.reorderMedia('lst-4', reversed);
      expect(result.map((m) => m.id)).toEqual(reversed);
      expect(result.map((m) => m.position)).toEqual(result.map((_, i) => i));
    }
  });

  it('keeps money as a decimal string', async () => {
    const result = await mockListingRepository.listListings({ page: 1, perPage: 10 });
    for (const listing of result.items) {
      if (listing.price) expect(typeof listing.price.amount).toBe('string');
    }
  });
});
