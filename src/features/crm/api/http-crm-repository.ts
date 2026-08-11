import { MissingApiContractError } from '@/lib/api/endpoints';
import type { CrmRepository } from './crm-repository';

/** The real repository — intentionally unimplemented until the contract lands. */
function unavailable(operation: string): never {
  throw new MissingApiContractError(`crm.${operation}`);
}

export const httpCrmRepository: CrmRepository = {
  listLeads: () => unavailable('listLeads'),
  getLead: () => unavailable('getLead'),
  createLead: () => unavailable('createLead'),
  updateLead: () => unavailable('updateLead'),
  moveLeadStage: () => unavailable('moveLeadStage'),
  listPipeline: () => unavailable('listPipeline'),
  listActivities: () => unavailable('listActivities'),
  createActivity: () => unavailable('createActivity'),
  completeActivity: () => unavailable('completeActivity'),
  listTasks: () => unavailable('listTasks'),
  listMatches: () => unavailable('listMatches'),
  listViewings: () => unavailable('listViewings'),
  getViewing: () => unavailable('getViewing'),
  listOffers: () => unavailable('listOffers'),
  getOffer: () => unavailable('getOffer'),
  addCounteroffer: () => unavailable('addCounteroffer'),
  listDeals: () => unavailable('listDeals'),
  listCommissions: () => unavailable('listCommissions'),
  listAssignmentRules: () => unavailable('listAssignmentRules'),
  listCommissionRules: () => unavailable('listCommissionRules'),
};
