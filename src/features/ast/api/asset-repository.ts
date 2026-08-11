import type { ListQuery, ListResult } from '@/lib/data/repository';
import type { Building, Floor, Property, Unit } from '../types';
import type { BuildingFormValues, PropertyFormValues, UnitFormValues } from '../schemas/asset-schemas';

/**
 * Asset data access contract.
 *
 * Reduced to what the GPMS backend actually implements. Four methods were
 * removed because the backend has no route for them — keeping them would mean
 * screens calling capabilities that cannot exist:
 *
 *   listStatusPeriods       FR-AST-003 — no endpoint
 *   listChangeEvents        FR-AST-008 — ActivityLog model exists, no route
 *   findDuplicateCandidates FR-AST-007 — no endpoint
 *   (custom fields)         FR-AST-006 — no endpoint
 *
 * All four are recorded in the backend contract request. The UI for them is
 * retained where it degrades gracefully and removed where it would lie.
 */
export interface AssetRepository {
  listProperties(query: ListQuery): Promise<ListResult<Property>>;
  getProperty(id: string): Promise<Property>;
  createProperty(values: PropertyFormValues): Promise<Property>;
  updateProperty(id: string, values: PropertyFormValues): Promise<Property>;
  deleteProperty(id: string): Promise<void>;

  listBuildings(query: ListQuery): Promise<ListResult<Building>>;
  getBuilding(id: string): Promise<Building>;
  createBuilding(values: BuildingFormValues): Promise<Building>;
  updateBuilding(id: string, values: BuildingFormValues): Promise<Building>;
  deleteBuilding(id: string): Promise<void>;
  listFloors(buildingId: string): Promise<Floor[]>;
  /** POST /buildings/{id}/floors — the only floor mutation the backend has. */

  listUnits(query: ListQuery): Promise<ListResult<Unit>>;
  getUnit(id: string): Promise<Unit>;
  createUnit(values: UnitFormValues): Promise<Unit>;
  updateUnit(id: string, values: UnitFormValues): Promise<Unit>;
  deleteUnit(id: string): Promise<void>;
}
