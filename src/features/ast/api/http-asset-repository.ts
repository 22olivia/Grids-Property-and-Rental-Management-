import 'server-only';
import { createServerApiClient, fromPaginator } from '@/lib/api/client';
import type { ListQuery, ListResult } from '@/lib/data/repository';
import type { LaravelPaginator, DataEnvelope } from '@/lib/api/types';
import type { AssetRepository } from './asset-repository';
import type { Building, Floor, Property, Unit } from '../types';
import type { BuildingFormValues, PropertyFormValues, UnitFormValues } from '../schemas/asset-schemas';
import {
  mapBuilding, mapFloor, mapProperty, mapUnit,
  type BackendBuilding, type BackendFloor, type BackendProperty, type BackendUnit,
} from './mappers';

/**
 * ===========================================================================
 * Real asset repository — GPMS Laravel backend.
 * ===========================================================================
 *
 * Query parameters are only those the backend actually reads:
 *
 *   properties  : per_page, page                     (PropertyController::index)
 *   buildings   : per_page, page, property_id, organization_id
 *   rental-units: per_page, page, property_id, building_id, floor_id, status,
 *                 organization_id, listed_only
 *
 * NOT sent, because no controller reads them:
 *   sort / direction  — every index is hardcoded `->latest()`
 *   search            — absent on these three resources
 *
 * Sending them would be harmless but misleading: the UI would appear to sort
 * while the server ignored it. Instead the capability is reported as
 * unavailable, and Observations 4 and 5 in the defect report ask for it.
 *
 * `organization_id` is deliberately NEVER sent from the client. Tenancy is the
 * server's to enforce; a client-supplied scope is not an authorisation
 * boundary. See Defect 2 in the report.
 * ===========================================================================
 */

function pageParams(query: ListQuery): Record<string, string | number | undefined> {
  return {
    page: query.page ?? 1,
    per_page: query.perPage ?? 20,
  };
}

/** Only forward filters the backend is known to read. */
function passthroughFilters(
  query: ListQuery,
  allowed: readonly string[],
): Record<string, string | undefined> {
  const result: Record<string, string | undefined> = {};
  for (const key of allowed) {
    const value = query.filters?.[key];
    if (value) result[key] = value;
  }
  return result;
}

export const httpAssetRepository: AssetRepository = {
  async listProperties(query: ListQuery): Promise<ListResult<Property>> {
    const client = createServerApiClient();
    const paginator = await client.request<LaravelPaginator<BackendProperty>>(
      'properties.index',
      { query: pageParams(query) },
    );
    return fromPaginator(paginator, mapProperty);
  },

  async getProperty(id: string): Promise<Property> {
    const client = createServerApiClient();
    const response = await client.request<DataEnvelope<BackendProperty>>('properties.show', {
      params: { id },
    });
    return mapProperty(response.data);
  },

  async createProperty(values: PropertyFormValues): Promise<Property> {
    const client = createServerApiClient();
    const response = await client.request<DataEnvelope<BackendProperty>>('properties.store', {
      method: 'POST',
      body: toPropertyPayload(values),
    });
    return mapProperty(response.data);
  },

  async updateProperty(id: string, values: PropertyFormValues): Promise<Property> {
    const client = createServerApiClient();
    const response = await client.request<DataEnvelope<BackendProperty>>('properties.update', {
      method: 'PUT',
      params: { id },
      body: toPropertyPayload(values),
    });
    return mapProperty(response.data);
  },

  async deleteProperty(id: string): Promise<void> {
    const client = createServerApiClient();
    await client.request<{ message: string }>('properties.destroy', {
      method: 'DELETE',
      params: { id },
    });
  },

  async deleteProperty(id: string): Promise<void> {
    const client = createServerApiClient();
    // Backend returns { message } only — nothing to map.
    await client.request<{ message: string }>('properties.destroy', {
      method: 'DELETE',
      params: { id },
    });
  },

  async listBuildings(query: ListQuery): Promise<ListResult<Building>> {
    const client = createServerApiClient();
    const paginator = await client.request<LaravelPaginator<BackendBuilding>>('buildings.index', {
      query: { ...pageParams(query), ...passthroughFilters(query, ['property_id']) },
    });
    return fromPaginator(paginator, mapBuilding);
  },

  async getBuilding(id: string): Promise<Building> {
    const client = createServerApiClient();
    const response = await client.request<DataEnvelope<BackendBuilding>>('buildings.show', {
      params: { id },
    });
    return mapBuilding(response.data);
  },

  async createBuilding(values: BuildingFormValues): Promise<Building> {
    const client = createServerApiClient();
    const response = await client.request<DataEnvelope<BackendBuilding>>('buildings.store', {
      method: 'POST',
      body: {
        property_id: values.propertyId,
        name: values.name,
        code: values.code ?? null,
        total_floors: values.totalFloors ?? 1,
        status: values.status,
      },
    });
    return mapBuilding(response.data);
  },

  async updateBuilding(id: string, values: BuildingFormValues): Promise<Building> {
    const client = createServerApiClient();
    // NOTE: `property_id` is deliberately NOT sent. BuildingController::update
    // validates only name, code, total_floors and status — an unvalidated key
    // is dropped, so sending it would let the UI imply a building can be moved
    // between properties when the API silently ignores the request.
    const response = await client.request<DataEnvelope<BackendBuilding>>('buildings.update', {
      method: 'PUT',
      params: { id },
      body: {
        name: values.name,
        code: values.code ?? null,
        total_floors: values.totalFloors ?? 1,
        status: values.status,
      },
    });
    return mapBuilding(response.data);
  },

  async deleteBuilding(id: string): Promise<void> {
    const client = createServerApiClient();
    await client.request<{ message: string }>('buildings.destroy', {
      method: 'DELETE',
      params: { id },
    });
  },

  async deleteBuilding(id: string): Promise<void> {
    const client = createServerApiClient();
    await client.request<{ message: string }>('buildings.destroy', {
      method: 'DELETE',
      params: { id },
    });
  },

  async listFloors(buildingId: string): Promise<Floor[]> {
    // No standalone floors endpoint exists — floors arrive eagerly loaded on
    // the building (`BuildingController::show` loads 'floors'). Fetching the
    // building is the only way to read them.
    const client = createServerApiClient();
    const response = await client.request<DataEnvelope<BackendBuilding & { floors?: BackendFloor[] }>>(
      'buildings.show',
      { params: { id: buildingId } },
    );
    return (response.data.floors ?? []).map(mapFloor);
  },

  async listUnits(query: ListQuery): Promise<ListResult<Unit>> {
    const client = createServerApiClient();
    const paginator = await client.request<LaravelPaginator<BackendUnit>>('units.index', {
      query: {
        ...pageParams(query),
        ...passthroughFilters(query, ['property_id', 'building_id', 'floor_id', 'status']),
      },
    });
    return fromPaginator(paginator, mapUnit);
  },

  async deleteUnit(id: string): Promise<void> {
    const client = createServerApiClient();
    await client.request<{ message: string }>('units.destroy', {
      method: 'DELETE',
      params: { id },
    });
  },

  async getUnit(id: string): Promise<Unit> {
    const client = createServerApiClient();
    const response = await client.request<DataEnvelope<BackendUnit>>('units.show', {
      params: { id },
    });
    return mapUnit(response.data);
  },

  async createUnit(values: UnitFormValues): Promise<Unit> {
    const client = createServerApiClient();
    const response = await client.request<DataEnvelope<BackendUnit>>('units.store', {
      method: 'POST',
      body: toUnitPayload(values),
    });
    return mapUnit(response.data);
  },

  async updateUnit(id: string, values: UnitFormValues): Promise<Unit> {
    const client = createServerApiClient();
    const response = await client.request<DataEnvelope<BackendUnit>>('units.update', {
      method: 'PUT',
      params: { id },
      body: toUnitPayload(values),
    });
    return mapUnit(response.data);
  },

  async deleteUnit(id: string): Promise<void> {
    const client = createServerApiClient();
    await client.request<{ message: string }>('units.destroy', {
      method: 'DELETE',
      params: { id },
    });
  },
};

/** Form values → backend payload. Field names verified from validation rules. */
function toPropertyPayload(values: PropertyFormValues) {
  return {
    owner_id: values.ownerId,
    name: values.name,
    type: values.type,
    status: values.status,
    address_line1: values.address.line1,
    address_line2: values.address.line2 ?? null,
    city: values.address.city,
    state: values.address.state ?? null,
    postal_code: values.address.postalCode ?? null,
    country: values.address.country ?? null,
    description: values.description ?? null,
    total_units: values.totalUnits ?? undefined,
    latitude: values.coordinates?.latitude ?? null,
    longitude: values.coordinates?.longitude ?? null,
    // organization_id intentionally omitted — the server derives it.
  };
}

function toUnitPayload(values: UnitFormValues) {
  return {
    property_id: values.propertyId,
    building_id: values.buildingId ?? null,
    floor_id: values.floorId ?? null,
    unit_number: values.unitNumber,
    unit_type: values.unitType ?? null,
    status: values.status,
    bedrooms: values.bedrooms ?? undefined,
    bathrooms: values.bathrooms ?? undefined,
    square_feet: values.squareFeet ?? null,
    area: values.areaSqm ?? null,
    furnishing_status: values.furnishingStatus ?? null,
    // Decimal strings sent verbatim. Never parsed to a number anywhere in the
    // frontend — the backend column is decimal(12,2).
    monthly_rent: values.monthlyRent,
    maintenance_charge: values.maintenanceCharge ?? null,
    deposit_amount: values.depositAmount ?? null,
    availability_date: values.availabilityDate ?? null,
    description: values.description ?? null,
    is_listed: values.isListed,
  };
}
