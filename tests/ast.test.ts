import { describe, expect, it } from 'vitest';
import en from '../messages/en.json';
import ar from '../messages/ar.json';
import { mockAssetRepository } from '@/features/ast/api/mock-asset-repository';
import { propertyFormSchema, unitFormSchema } from '@/features/ast/schemas/asset-schemas';
import { UNIT_STATUSES, LEGACY_UNIT_STATUSES, PROPERTY_TYPES, PROPERTY_STATUSES } from '@/features/ast/types';
import { unitStatusTone, propertyStatusTone } from '@/features/ast/constants';
import { mapProperty, mapUnit } from '@/features/ast/api/mappers';

describe('AST — vocabularies match the backend', () => {
  it('labels every unit status the backend can return, including legacy aliases', () => {
    for (const status of [...UNIT_STATUSES, ...LEGACY_UNIT_STATUSES]) {
      expect(en.ast.unitStatus, `en: ${status}`).toHaveProperty(status);
      expect(ar.ast.unitStatus, `ar: ${status}`).toHaveProperty(status);
    }
  });

  it('labels every property type from PropertyController validation', () => {
    for (const type of PROPERTY_TYPES) {
      expect(en.ast.propertyType, `en: ${type}`).toHaveProperty(type);
      expect(ar.ast.propertyType, `ar: ${type}`).toHaveProperty(type);
    }
  });

  it('labels every property status', () => {
    for (const status of PROPERTY_STATUSES) {
      expect(en.ast.propertyStatus).toHaveProperty(status);
      expect(ar.ast.propertyStatus).toHaveProperty(status);
    }
  });

  it('falls back to neutral for a status the backend adds later', () => {
    expect(unitStatusTone('some_future_status')).toBe('neutral');
    expect(propertyStatusTone('some_future_status')).toBe('neutral');
  });
});

describe('AST — backend response mapping', () => {
  it('maps a property payload without inventing fields', () => {
    const mapped = mapProperty({
      id: 7, organization_id: 2, owner_id: 3, name: 'Test', type: 'villa',
      address_line1: 'L1', address_line2: null, city: 'C', state: null,
      postal_code: null, country: 'X', latitude: '25.20', longitude: '55.27',
      description: null, total_units: 12, status: 'active',
      created_at: '2026-01-01T00:00:00.000000Z', updated_at: null,
      owner: { id: 3, full_name: 'Owner', email: 'o@example.invalid' },
      rental_units: [{}, {}, {}],
    });
    expect(mapped.id).toBe(7);
    expect(mapped.coordinates).toEqual({ latitude: 25.2, longitude: 55.27 });
    expect(mapped.unitCount).toBe(3);
    expect(mapped.totalUnits).toBe(12);
    expect(mapped.owner?.fullName).toBe('Owner');
  });

  it('keeps decimal money as strings through mapping', () => {
    // Laravel serialises decimal:2 casts as strings. The mapper must not
    // convert them — this is the guarantee the whole money layer rests on.
    const mapped = mapUnit({
      id: 1, organization_id: 1, property_id: 1, building_id: null, floor_id: null,
      unit_number: 'U-1', unit_type: null, floor: null, bedrooms: 2, bathrooms: 1,
      square_feet: '850.00', area: '79.00', furnishing_status: null,
      monthly_rent: '4500.00', maintenance_charge: null, deposit_amount: '9000.00',
      availability_date: null, status: 'vacant', description: null, amenities: null,
      is_listed: false, created_at: null, updated_at: null,
    });
    expect(mapped.monthlyRent?.amount).toBe('4500.00');
    expect(typeof mapped.monthlyRent?.amount).toBe('string');
    expect(mapped.maintenanceCharge).toBeNull();
    expect(mapped.depositAmount?.amount).toBe('9000.00');
    expect(mapped.amenities).toEqual([]);
  });

  it('prefers the floor relation over the free-text floor column', () => {
    const mapped = mapUnit({
      id: 1, organization_id: null, property_id: 1, building_id: null, floor_id: 5,
      unit_number: 'U', unit_type: null, floor: 'free text', bedrooms: null,
      bathrooms: null, square_feet: null, area: null, furnishing_status: null,
      monthly_rent: '0.00', maintenance_charge: null, deposit_amount: null,
      availability_date: null, status: null, description: null, amenities: [],
      is_listed: null, created_at: null, updated_at: null,
      floor_level: { id: 5, name: 'Level 5' },
    });
    expect(mapped.floorName).toBe('Level 5');
    expect(mapped.status).toBe('vacant');
  });
});

describe('AST — validation mirrors backend rules', () => {
  const property = {
    name: 'P', ownerId: 3, type: 'villa', status: 'active',
    address: { line1: 'a', line2: null, city: 'b', state: null, postalCode: null, country: 'c' },
    coordinates: null, description: null, totalUnits: null,
  };

  it('requires owner_id, which the backend marks required', () => {
    expect(propertyFormSchema.safeParse(property).success).toBe(true);
    expect(propertyFormSchema.safeParse({ ...property, ownerId: undefined }).success).toBe(false);
  });

  it('rejects a property type the backend does not accept', () => {
    expect(propertyFormSchema.safeParse({ ...property, type: 'mixed-use' }).success).toBe(false);
  });

  it('treats blank coordinates as null rather than Null Island', () => {
    const result = propertyFormSchema.safeParse({
      ...property, coordinates: { latitude: '', longitude: '' },
    });
    expect(result.success).toBe(true);
    if (result.success) expect(result.data.coordinates).toBeNull();
  });

  const unit = {
    unitNumber: 'U-1', propertyId: 1, buildingId: null, floorId: null,
    unitType: null, furnishingStatus: null, status: 'vacant',
    bedrooms: null, bathrooms: null, squareFeet: null, areaSqm: null,
    monthlyRent: '4500.00', maintenanceCharge: null, depositAmount: null,
    availabilityDate: null, description: null, isListed: false,
  };

  it('accepts a decimal rent string and preserves it exactly', () => {
    const result = unitFormSchema.safeParse(unit);
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.monthlyRent).toBe('4500.00');
      expect(typeof result.data.monthlyRent).toBe('string');
    }
  });

  it('requires monthly rent, as the backend does', () => {
    expect(unitFormSchema.safeParse({ ...unit, monthlyRent: '' }).success).toBe(false);
  });

  it('rejects a unit status outside the backend vocabulary', () => {
    expect(unitFormSchema.safeParse({ ...unit, status: 'unavailable' }).success).toBe(false);
    expect(unitFormSchema.safeParse({ ...unit, status: 'notice_period' }).success).toBe(true);
  });

  it('surfaces the inner message rather than a union error', () => {
    const result = unitFormSchema.safeParse({ ...unit, maintenanceCharge: '1,500' });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues.map((i) => i.message)).toContain('amount');
    }
  });
});

describe('AST — mock repository still matches the real shapes', () => {
  it('paginates properties', async () => {
    const page = await mockAssetRepository.listProperties({ page: 1, perPage: 10 });
    expect(page.items).toHaveLength(10);
    expect(page.total).toBeGreaterThan(10);
  });

  it('emits only backend-valid unit statuses', async () => {
    const page = await mockAssetRepository.listUnits({ page: 1, perPage: 50 });
    const allowed = new Set<string>([...UNIT_STATUSES, ...LEGACY_UNIT_STATUSES]);
    for (const unit of page.items) expect(allowed.has(unit.status)).toBe(true);
  });

  it('emits money as decimal strings', async () => {
    const page = await mockAssetRepository.listUnits({ page: 1, perPage: 5 });
    for (const unit of page.items) {
      if (unit.monthlyRent) expect(typeof unit.monthlyRent.amount).toBe('string');
    }
  });
});
