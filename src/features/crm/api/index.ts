import type { CrmRepository } from './crm-repository';
import { mockCrmRepository } from './mock-crm-repository';

/**
 * CRM data binding — ALWAYS mock.
 *
 * The GPMS backend contains no CRM at all: zero migrations and zero
 * controllers for leads, offers, deals, viewings or commissions. As with
 * listings, this ignores NEXT_PUBLIC_DATA_SOURCE so that enabling the real API
 * for assets cannot break the fifteen CRM screens.
 */
export const crmRepository: CrmRepository = mockCrmRepository;

/** Drives the on-screen sample-data banner. */
export const CRM_IS_MOCK = true;

export type { CrmRepository, MatchedListing } from './crm-repository';
