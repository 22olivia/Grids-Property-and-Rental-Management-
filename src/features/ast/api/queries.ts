'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import type { ListQuery } from '@/lib/data/repository';
import { assetRepository } from './index';
import type { BuildingFormValues, PropertyFormValues, UnitFormValues } from '../schemas/asset-schemas';

/**
 * Asset queries.
 *
 * Four hooks were REMOVED during backend integration, because the GPMS API has
 * no route for them:
 *   useStatusPeriods       FR-AST-003 availability timeline
 *   useChangeEvents        FR-AST-008 change history
 *   useDuplicateCandidates FR-AST-007 duplicate detection
 *   (custom fields)        FR-AST-006
 *
 * They are not stubbed. A hook returning mock data beside real data would make
 * fabricated history indistinguishable from audited history on the same screen
 * — which on an asset record is a genuinely dangerous kind of wrong.
 */
export const astKeys = {
  all: ['ast'] as const,
  properties: (query?: ListQuery) => ['ast', 'properties', query] as const,
  property: (id: string) => ['ast', 'property', id] as const,
  buildings: (query?: ListQuery) => ['ast', 'buildings', query] as const,
  building: (id: string) => ['ast', 'building', id] as const,
  floors: (buildingId: string) => ['ast', 'floors', buildingId] as const,
  units: (query?: ListQuery) => ['ast', 'units', query] as const,
  unit: (id: string) => ['ast', 'unit', id] as const,
};

export function useProperties(query: ListQuery) {
  return useQuery({
    queryKey: astKeys.properties(query),
    queryFn: () => assetRepository.listProperties(query),
    placeholderData: (previous) => previous,
  });
}

export const useProperty = (id: string) =>
  useQuery({ queryKey: astKeys.property(id), queryFn: () => assetRepository.getProperty(id) });

export function useBuildings(query: ListQuery) {
  return useQuery({
    queryKey: astKeys.buildings(query),
    queryFn: () => assetRepository.listBuildings(query),
    placeholderData: (previous) => previous,
  });
}

export const useBuilding = (id: string) =>
  useQuery({ queryKey: astKeys.building(id), queryFn: () => assetRepository.getBuilding(id) });

export const useFloors = (buildingId: string) =>
  useQuery({ queryKey: astKeys.floors(buildingId), queryFn: () => assetRepository.listFloors(buildingId) });

export function useUnits(query: ListQuery) {
  return useQuery({
    queryKey: astKeys.units(query),
    queryFn: () => assetRepository.listUnits(query),
    placeholderData: (previous) => previous,
  });
}

export const useUnit = (id: string) =>
  useQuery({ queryKey: astKeys.unit(id), queryFn: () => assetRepository.getUnit(id) });

export function useCreateProperty() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (values: PropertyFormValues) => assetRepository.createProperty(values),
    onSuccess: () => client.invalidateQueries({ queryKey: ['ast', 'properties'] }),
  });
}

export function useUpdateProperty(id: string) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (values: PropertyFormValues) => assetRepository.updateProperty(id, values),
    onSuccess: () => {
      client.invalidateQueries({ queryKey: astKeys.property(id) });
      client.invalidateQueries({ queryKey: ['ast', 'properties'] });
    },
  });
}

export function useCreateBuilding() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (values: BuildingFormValues) => assetRepository.createBuilding(values),
    onSuccess: (building) => {
      client.invalidateQueries({ queryKey: ['ast', 'buildings'] });
      client.invalidateQueries({ queryKey: astKeys.property(String(building.propertyId)) });
    },
  });
}

export function useUpdateBuilding(id: string) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (values: BuildingFormValues) => assetRepository.updateBuilding(id, values),
    onSuccess: () => {
      client.invalidateQueries({ queryKey: astKeys.building(id) });
      client.invalidateQueries({ queryKey: astKeys.floors(id) });
      client.invalidateQueries({ queryKey: ['ast', 'buildings'] });
    },
  });
}

export function useCreateUnit() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (values: UnitFormValues) => assetRepository.createUnit(values),
    onSuccess: (unit) => {
      client.invalidateQueries({ queryKey: ['ast', 'units'] });
      client.invalidateQueries({ queryKey: astKeys.property(String(unit.propertyId)) });
    },
  });
}

export function useUpdateUnit(id: string) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (values: UnitFormValues) => assetRepository.updateUnit(id, values),
    onSuccess: (unit) => {
      client.invalidateQueries({ queryKey: astKeys.unit(id) });
      client.invalidateQueries({ queryKey: ['ast', 'units'] });
      client.invalidateQueries({ queryKey: astKeys.property(String(unit.propertyId)) });
    },
  });
}

/**
 * Delete mutations.
 *
 * Never optimistic. A row that disappears and comes back — because the API
 * refused, or a foreign key blocked it — is worse than a brief pending state,
 * and on an asset record it looks like data loss.
 */
export function useDeleteProperty() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => assetRepository.deleteProperty(id),
    onSuccess: (_result, id) => {
      client.invalidateQueries({ queryKey: ['ast', 'properties'] });
      client.removeQueries({ queryKey: astKeys.property(id) });
      // Units and buildings reference the property, so their lists may change.
      client.invalidateQueries({ queryKey: ['ast', 'units'] });
      client.invalidateQueries({ queryKey: ['ast', 'buildings'] });
    },
  });
}

export function useDeleteBuilding() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => assetRepository.deleteBuilding(id),
    onSuccess: (_result, id) => {
      client.invalidateQueries({ queryKey: ['ast', 'buildings'] });
      client.removeQueries({ queryKey: astKeys.building(id) });
      client.invalidateQueries({ queryKey: ['ast', 'units'] });
    },
  });
}

export function useDeleteUnit() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => assetRepository.deleteUnit(id),
    onSuccess: (_result, id) => {
      client.invalidateQueries({ queryKey: ['ast', 'units'] });
      client.removeQueries({ queryKey: astKeys.unit(id) });
      client.invalidateQueries({ queryKey: ['ast', 'properties'] });
    },
  });
}
