import type { ListQuery, ListResult } from '@/lib/data/repository';
import type {
  Activity, AssignmentRule, Commission, CommissionRule, Deal, Lead, Offer,
  PipelineStage, Viewing,
} from '../types';
import type {
  ActivityFormValues, CounterofferFormValues, LeadFormValues,
} from '../schemas/crm-schemas';

/** FR-CRM-005 — a match, with the server's own score and reason. */
export interface MatchedListing {
  listingId: string;
  title: string;
  city: string;
  price: { amount: string; currency: string } | null;
  areaSqm: number | null;
  /** Server-computed. The client never scores matches itself. */
  matchScore: number;
  matchReason: string;
}

/** CRM data access contract. Method set derived from FR-CRM-001…008 only. */
export interface CrmRepository {
  listLeads(query: ListQuery): Promise<ListResult<Lead>>;
  getLead(id: string): Promise<Lead>;
  createLead(values: LeadFormValues): Promise<Lead>;
  updateLead(id: string, values: LeadFormValues): Promise<Lead>;
  /** FR-CRM-003 — the server validates the stage move. */
  moveLeadStage(id: string, stage: PipelineStage): Promise<Lead>;
  listPipeline(): Promise<Record<PipelineStage, Lead[]>>;

  listActivities(leadId: string): Promise<Activity[]>;
  createActivity(leadId: string, values: ActivityFormValues): Promise<Activity>;
  completeActivity(activityId: string): Promise<Activity>;
  listTasks(query: ListQuery): Promise<ListResult<Activity>>;

  /** FR-CRM-005 — matching is computed server-side from the lead's criteria. */
  listMatches(leadId: string): Promise<ListResult<MatchedListing>>;

  listViewings(query: ListQuery): Promise<ListResult<Viewing>>;
  getViewing(id: string): Promise<Viewing>;

  listOffers(query: ListQuery): Promise<ListResult<Offer>>;
  getOffer(id: string): Promise<Offer>;
  addCounteroffer(offerId: string, values: CounterofferFormValues): Promise<Offer>;

  listDeals(query: ListQuery): Promise<ListResult<Deal>>;
  listCommissions(query: ListQuery): Promise<ListResult<Commission>>;

  listAssignmentRules(): Promise<AssignmentRule[]>;
  listCommissionRules(): Promise<CommissionRule[]>;
}
