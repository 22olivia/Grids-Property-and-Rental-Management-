import type { ListQuery, ListResult } from '@/lib/data/repository';
import type { Building, Floor, Property, Unit } from '../types';
import { PROPERTY_TYPES, PROPERTY_STATUSES, UNIT_STATUSES } from '../types';
import { UNIT_CURRENCY_FALLBACK } from '../constants';
import type { BuildingFormValues, PropertyFormValues, UnitFormValues } from '../schemas/asset-schemas';
import type { AssetRepository } from './asset-repository';

/**
 * ===========================================================================
 * MOCK DATA — offline UI development only.
 * ===========================================================================
 *
 * Kept after backend integration so the UI can be worked on without a running
 * Laravel instance. Now shaped to the REAL backend vocabularies (seven unit
 * statuses, four property types, decimal-string money) so that switching
 * between mock and http cannot change what the UI has to handle.
 * ===========================================================================
 */

const delay = () => new Promise((resolve) => setTimeout(resolve, 300));

/**
 * Fixture vocabulary.
 *
 * Names are plausible so a walkthrough reads naturally, but every screen using
 * these carries a prominent "sample data" banner. Realism in the rows and
 * honesty in the chrome — the alternative (obviously fake rows) makes a review
 * harder without making it safer, and the banner is what actually prevents a
 * fixture being quoted as a fact.
 */
const PROPERTY_NAMES = [
  'Marina Heights', 'Al Reem Residences', 'Cedar Court', 'Pearl Tower',
  'Jasmine Villas', 'Corniche Plaza', 'Olive Grove Estate', 'Sapphire Bay',
  'Falcon Business Park', 'Lantern Quarter', 'Rosewood Gardens', 'Harbour View',
];
const CITIES = ['Dubai', 'Abu Dhabi', 'Sharjah', 'Ajman'];
const STREETS = ['Marina Walk', 'Corniche Road', 'Al Wasl Road', 'Airport Street'];

function makeProperty(index: number): Property {
  return {
    id: index,
    organisationId: 1,
    name: PROPERTY_NAMES[index % PROPERTY_NAMES.length] +
      (index > PROPERTY_NAMES.length ? ` ${Math.ceil(index / PROPERTY_NAMES.length)}` : ''),
    type: PROPERTY_TYPES[index % PROPERTY_TYPES.length]!,
    status: PROPERTY_STATUSES[index % PROPERTY_STATUSES.length]!,
    address: {
      line1: `${100 + index} ${STREETS[index % STREETS.length]}`,
      line2: null,
      city: CITIES[index % CITIES.length]!,
      state: null,
      postalCode: `0000${index % 10}`,
      country: 'United Arab Emirates',
    },
    coordinates: { latitude: 25.2 + index * 0.001, longitude: 55.27 + index * 0.001 },
    description: null,
    totalUnits: (index % 7) * 4 + 2,
    owner: {
      id: index,
      fullName: ['Layla Haddad', 'Omar Nasser', 'Grids Holdings LLC', 'Maya Rahman'][index % 4]!,
      email: `owner${index}@example.invalid`,
    },
    unitCount: (index % 7) * 4 + 2,
    createdAt: '2026-03-01T09:00:00Z',
    updatedAt: '2026-06-14T11:30:00Z',
  };
}

function makeBuilding(index: number): Building {
  return {
    id: index,
    organisationId: 1,
    propertyId: index,
    propertyName: PROPERTY_NAMES[index % PROPERTY_NAMES.length]!,
    name: `${PROPERTY_NAMES[index % PROPERTY_NAMES.length]} — Tower ${String.fromCharCode(65 + (index % 3))}`,
    code: `BLD-${String(index).padStart(3, '0')}`,
    totalFloors: (index % 5) + 2,
    status: 'active',
    floorCount: (index % 5) + 2,
    unitCount: (index % 6) * 3 + 4,
    createdAt: '2026-03-05T09:00:00Z',
    updatedAt: '2026-05-20T10:00:00Z',
  };
}

function makeUnit(index: number): Unit {
  const propertyIndex = (index % 12) + 1;
  return {
    id: index,
    organisationId: 1,
    propertyId: propertyIndex,
    propertyName: PROPERTY_NAMES[propertyIndex % PROPERTY_NAMES.length]!,
    buildingId: propertyIndex,
    buildingName: `${PROPERTY_NAMES[propertyIndex % PROPERTY_NAMES.length]} — Tower A`,
    floorId: null,
    floorName: `Floor ${index % 5}`,
    unitNumber: `${(index % 12) + 1}0${(index % 8) + 1}`,
    unitType: ['Studio', '1 Bedroom', '2 Bedroom', 'Office'][index % 4] ?? null,
    status: UNIT_STATUSES[index % UNIT_STATUSES.length]!,
    bedrooms: index % 5,
    bathrooms: (index % 3) + 1,
    squareFeet: 500 + (index % 10) * 120,
    areaSqm: 45 + (index % 10) * 15,
    furnishingStatus: index % 2 === 0 ? 'furnished' : 'unfurnished',
    // Decimal strings — matching the backend's decimal(12,2) serialisation.
    monthlyRent: { amount: `${(index % 9) * 1500 + 45000}.00`, currency: UNIT_CURRENCY_FALLBACK },
    maintenanceCharge: { amount: `${(index % 4) * 100 + 200}.00`, currency: UNIT_CURRENCY_FALLBACK },
    depositAmount: { amount: `${(index % 9) * 1500 + 7500}.00`, currency: UNIT_CURRENCY_FALLBACK },
    availabilityDate: null,
    isListed: index % 3 === 0,
    description: null,
    amenities: ['Covered parking', 'Lift', 'Security', 'Gym'].slice(0, (index % 4) + 1),
    createdAt: '2026-04-10T09:00:00Z',
    updatedAt: '2026-07-02T08:15:00Z',
  };
}

const properties = Array.from({ length: 47 }, (_, i) => makeProperty(i + 1));
const buildings = Array.from({ length: 12 }, (_, i) => makeBuilding(i + 1));
const units = Array.from({ length: 138 }, (_, i) => makeUnit(i + 1));

function paginate<T>(all: T[], query: ListQuery): ListResult<T> {
  const page = query.page ?? 1;
  const perPage = query.perPage ?? 20;
  const start = (page - 1) * perPage;
  return { items: all.slice(start, start + perPage), total: all.length, page, perPage };
}

export const mockAssetRepository: AssetRepository = {
  async listProperties(query) {
    await delay();
    return paginate(properties, query);
  },
  async getProperty(id) {
    await delay();
    const found = properties.find((p) => String(p.id) === String(id));
    if (!found) throw new Error('NOT_FOUND');
    return found;
  },
  async createProperty(values: PropertyFormValues) {
    await delay();
    return { ...makeProperty(properties.length + 1), name: values.name, type: values.type };
  },
  async updateProperty(id, values: PropertyFormValues) {
    await delay();
    const existing = properties.find((p) => String(p.id) === String(id));
    if (!existing) throw new Error('NOT_FOUND');
    return { ...existing, name: values.name, type: values.type, status: values.status };
  },

  async deleteProperty() {
    await delay();
  },

  async listBuildings(query) {
    await delay();
    const propertyId = query.filters?.property_id;
    const result = propertyId
      ? buildings.filter((b) => String(b.propertyId) === propertyId)
      : buildings;
    return paginate(result, query);
  },
  async getBuilding(id) {
    await delay();
    const found = buildings.find((b) => String(b.id) === String(id));
    if (!found) throw new Error('NOT_FOUND');
    return found;
  },
  async createBuilding(values: BuildingFormValues) {
    await delay();
    return { ...makeBuilding(buildings.length + 1), name: values.name };
  },
  async updateBuilding(id, values: BuildingFormValues) {
    await delay();
    const existing = buildings.find((b) => String(b.id) === String(id));
    if (!existing) throw new Error('NOT_FOUND');
    return { ...existing, name: values.name, status: values.status };
  },
  async deleteBuilding() {
    await delay();
  },
  async listFloors(buildingId) {
    await delay();
    const building = buildings.find((b) => String(b.id) === String(buildingId));
    return Array.from<unknown, Floor>({ length: building?.floorCount ?? 0 }, (_, i) => ({
      id: i + 1,
      buildingId: Number(buildingId),
      name: `Floor ${i}`,
      level: i,
    }));
  },

  async listUnits(query) {
    await delay();
    let result = units;
    if (query.filters?.status) result = result.filter((u) => u.status === query.filters?.status);
    if (query.filters?.property_id)
      result = result.filter((u) => String(u.propertyId) === query.filters?.property_id);
    return paginate(result, query);
  },
  async getUnit(id) {
    await delay();
    const found = units.find((u) => String(u.id) === String(id));
    if (!found) throw new Error('NOT_FOUND');
    return found;
  },
  async createUnit(values: UnitFormValues) {
    await delay();
    return { ...makeUnit(units.length + 1), unitNumber: values.unitNumber, status: values.status };
  },
  async updateUnit(id, values: UnitFormValues) {
    await delay();
    const existing = units.find((u) => String(u.id) === String(id));
    if (!existing) throw new Error('NOT_FOUND');
    return { ...existing, unitNumber: values.unitNumber, status: values.status };
  },
  async deleteUnit() {
    await delay();
  },
};
