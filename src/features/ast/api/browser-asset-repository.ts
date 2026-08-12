'use client';

import { ApiError } from '@/lib/api/types';
import type { ListQuery, ListResult } from '@/lib/data/repository';
import type { AssetRepository } from './asset-repository';
import type { Building, Floor, Property, Unit } from '../types';
import type { BuildingFormValues, PropertyFormValues, UnitFormValues } from '../schemas/asset-schemas';

/**
 * ===========================================================================
 * Browser-side asset repository.
 * ===========================================================================
 *
 * Talks to this application's own BFF routes, never to the Laravel API
 * directly. The Sanctum token stays in an httpOnly cookie; the browser has no
 * access to it and no way to reach the upstream host.
 *
 * Data is already mapped by the time it arrives — the BFF ran the mappers
 * server-side — so this layer only handles transport and error shape.
 * ===========================================================================
 */

async function call<T>(path: string, init?: RequestInit): Promise<T> {
  const response = await fetch(path, {
    ...init,
    headers: { Accept: 'application/json', 'Content-Type': 'application/json', ...init?.headers },
    credentials: 'same-origin',
  });

  // 204 No Content (delete) has no body — parsing it would throw.
  const text = response.status === 204 ? '' : await response.text();
  const payload = text ? JSON.parse(text) : null;

  if (!response.ok) {
    const body = payload as { message?: string; errors?: unknown } | null;
    // The BFF already normalised Laravel's shape into ApiErrorItem[].
    const errors = Array.isArray(body?.errors)
      ? (body.errors as { code: string; message: string; field?: string }[])
      : [{ code: `http_${response.status}`, message: body?.message ?? 'Request failed.' }];
    throw new ApiError(response.status, errors, null);
  }

  return payload as T;
}

function toQueryString(query: ListQuery): string {
  const params = new URLSearchParams();
  params.set('page', String(query.page ?? 1));
  params.set('perPage', String(query.perPage ?? 20));
  for (const [key, value] of Object.entries(query.filters ?? {})) {
    if (value) params.set(key, value);
  }
  return params.toString();
}

const BASE = '/api/assets';

export const browserAssetRepository: AssetRepository = {
  listProperties: (query) =>
    call<ListResult<Property>>(`${BASE}/properties?${toQueryString(query)}`),
  getProperty: (id) => call<Property>(`${BASE}/properties/${id}`),
  createProperty: (values: PropertyFormValues) =>
    call<Property>(`${BASE}/properties`, { method: 'POST', body: JSON.stringify(values) }),
  updateProperty: (id, values: PropertyFormValues) =>
    call<Property>(`${BASE}/properties/${id}`, { method: 'PUT', body: JSON.stringify(values) }),

  deleteProperty: (id) =>
    call<void>(`${BASE}/properties/${id}`, { method: 'DELETE' }),

  listBuildings: (query) => call<ListResult<Building>>(`${BASE}/buildings?${toQueryString(query)}`),
  getBuilding: (id) => call<Building>(`${BASE}/buildings/${id}`),
  createBuilding: (values: BuildingFormValues) =>
    call<Building>(`${BASE}/buildings`, { method: 'POST', body: JSON.stringify(values) }),
  updateBuilding: (id, values: BuildingFormValues) =>
    call<Building>(`${BASE}/buildings/${id}`, { method: 'PUT', body: JSON.stringify(values) }),
  deleteBuilding: (id) => call<void>(`${BASE}/buildings/${id}`, { method: 'DELETE' }),
  listFloors: (buildingId) => call<Floor[]>(`${BASE}/buildings/${buildingId}?include=floors`),

  listUnits: (query) => call<ListResult<Unit>>(`${BASE}/units?${toQueryString(query)}`),
  getUnit: (id) => call<Unit>(`${BASE}/units/${id}`),
  createUnit: (values: UnitFormValues) =>
    call<Unit>(`${BASE}/units`, { method: 'POST', body: JSON.stringify(values) }),
  updateUnit: (id, values: UnitFormValues) =>
    call<Unit>(`${BASE}/units/${id}`, { method: 'PUT', body: JSON.stringify(values) }),
  deleteUnit: (id) => call<void>(`${BASE}/units/${id}`, { method: 'DELETE' }),
};
