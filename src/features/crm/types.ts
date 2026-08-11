import type { Money } from '@/domain/money/money';
import type { IsoInstant } from '@/domain/datetime/datetime';

/**
 * ===========================================================================
 * CRM domain types.
 * ===========================================================================
 *
 * Every vocabulary below is enumerated VERBATIM in the requirements. Where a
 * requirement names a capability without listing its values, that is recorded
 * as MISSING INFORMATION rather than filled in.
 *
 * FR-CRM-001 (Must) — "capture leads from website forms, mobile, chat, calls,
 *   imports, campaigns and manual entry"
 * FR-CRM-002 (Must) — "assigned by territory, branch, workload, property,
 *   campaign or manual selection"
 * FR-CRM-003 (Must) — "qualification, matching, viewing, offer, negotiation,
 *   reservation, contract and won/lost stages"
 * FR-CRM-004 (Must) — "record calls, notes, meetings, tasks, reminders,
 *   messages and next actions"
 * FR-CRM-008 (Must) — "agent, agency, referral and company commissions"
 * ===========================================================================
 */

/** FR-CRM-001 — the enumerated capture sources, verbatim. */
export const LEAD_SOURCES = [
  'website-form',
  'mobile',
  'chat',
  'call',
  'import',
  'campaign',
  'manual',
] as const;
export type LeadSource = (typeof LEAD_SOURCES)[number];

/**
 * FR-CRM-003 — the enumerated pipeline stages, verbatim.
 * "won/lost" is expressed as two terminal stages.
 */
export const PIPELINE_STAGES = [
  'qualification',
  'matching',
  'viewing',
  'offer',
  'negotiation',
  'reservation',
  'contract',
  'won',
  'lost',
] as const;
export type PipelineStage = (typeof PIPELINE_STAGES)[number];

/** FR-CRM-004 — the enumerated activity kinds, verbatim. */
export const ACTIVITY_TYPES = ['call', 'note', 'meeting', 'task', 'reminder', 'message'] as const;
export type ActivityType = (typeof ACTIVITY_TYPES)[number];

/** FR-CRM-002 — the enumerated assignment bases, verbatim. */
export const ASSIGNMENT_BASES = [
  'territory',
  'branch',
  'workload',
  'property',
  'campaign',
  'manual',
] as const;
export type AssignmentBasis = (typeof ASSIGNMENT_BASES)[number];

/** FR-CRM-008 — the enumerated commission parties, verbatim. */
export const COMMISSION_PARTIES = ['agent', 'agency', 'referral', 'company'] as const;
export type CommissionParty = (typeof COMMISSION_PARTIES)[number];

/**
 * FR-CRM-006 — "viewing appointments, attendance, feedback, rescheduling and
 * no-show tracking".
 *
 * MISSING INFORMATION (MI-29): the requirement names the capabilities but does
 * not enumerate viewing statuses or their transitions. The four values below
 * are each attested in the requirement text; cancellation is NOT mentioned and
 * is deliberately absent rather than assumed.
 */
export const VIEWING_STATUSES = ['scheduled', 'attended', 'no-show', 'rescheduled'] as const;
export type ViewingStatus = (typeof VIEWING_STATUSES)[number];

/**
 * FR-CRM-007 — "offers, counteroffers, approval, expiry, deposits and deal
 * documents".
 *
 * MISSING INFORMATION (MI-30): offer states are not enumerated. Only the four
 * below are attested in the requirement text. Rejection and withdrawal are not
 * mentioned anywhere and are therefore not modelled.
 */
export const OFFER_STATES = ['submitted', 'countered', 'approved', 'expired'] as const;
export type OfferState = (typeof OFFER_STATES)[number];

export interface Lead {
  id: string;
  reference: string;
  name: string;
  /** Contact fields are pinned LTR in the UI regardless of locale. */
  email: string | null;
  phone: string | null;
  source: LeadSource;
  stage: PipelineStage;
  /** FR-CRM-002 — the assigned agent. Assignment itself is server-side. */
  assignedAgentId: string | null;
  assignedAgentName: string | null;
  /** FR-CRM-005 — matching criteria: budget, location, type, area. */
  budget: Money | null;
  preferredCity: string | null;
  preferredType: string | null;
  minAreaSqm: number | null;
  /** FR-CRM-004 — "next actions". */
  nextActionAt: IsoInstant | null;
  nextActionNote: string | null;
  interestedListingId: string | null;
  interestedListingTitle: string | null;
  customFields: Record<string, unknown>;
  createdAt: IsoInstant;
  updatedAt: IsoInstant;
}

/** FR-CRM-004 — activity log entry. */
export interface Activity {
  id: string;
  leadId: string;
  type: ActivityType;
  summary: string;
  detail: string | null;
  actorName: string;
  occurredAt: IsoInstant;
  /** Tasks and reminders carry a due date; other kinds do not. */
  dueAt: IsoInstant | null;
  completed: boolean;
}

/** FR-CRM-006 — viewing appointment. */
export interface Viewing {
  id: string;
  reference: string;
  leadId: string;
  leadName: string;
  listingId: string | null;
  listingTitle: string | null;
  agentName: string | null;
  scheduledFor: IsoInstant;
  status: ViewingStatus;
  feedback: string | null;
}

/** FR-CRM-007 — offer with counteroffer history. */
export interface Offer {
  id: string;
  reference: string;
  leadId: string;
  leadName: string;
  listingId: string | null;
  listingTitle: string | null;
  amount: Money | null;
  depositAmount: Money | null;
  state: OfferState;
  expiresAt: IsoInstant | null;
  createdAt: IsoInstant;
  /** Ordered exchange. Amounts are server-recorded, never computed here. */
  counteroffers: Counteroffer[];
}

export interface Counteroffer {
  id: string;
  byParty: 'buyer' | 'seller';
  amount: Money | null;
  note: string | null;
  createdAt: IsoInstant;
}

/** FR-CRM-003 — won/lost outcome. */
export interface Deal {
  id: string;
  reference: string;
  leadName: string;
  listingTitle: string | null;
  value: Money | null;
  stage: Extract<PipelineStage, 'won' | 'lost'>;
  closedAt: IsoInstant | null;
  closeReason: string | null;
}

/**
 * FR-CRM-008 — commission split.
 *
 * Amounts are CALCULATED BY THE SERVER "according to configurable rules". The
 * client formats and displays them; it performs no monetary arithmetic
 * anywhere (SRS §6, risk R-04).
 */
export interface Commission {
  id: string;
  dealId: string;
  dealReference: string;
  party: CommissionParty;
  partyName: string;
  amount: Money | null;
  /** Human-readable rule reference supplied by the server. */
  ruleLabel: string | null;
  settled: boolean;
}

/**
 * FR-CRM-002 / FR-CRM-008 — a configurable rule.
 *
 * MISSING INFORMATION (MI-31): the requirements name the assignment BASES and
 * the commission PARTIES, but no requirement describes the rule expression
 * grammar — conditions, operators, value types, or how ties break. The
 * `condition` field is therefore an opaque server-supplied summary string, and
 * the rule editor is deliberately not built. See RuleConditionEditor.
 */
export interface AssignmentRule {
  id: string;
  name: string;
  basis: AssignmentBasis;
  /** Opaque summary from the server. Never parsed or constructed client-side. */
  condition: string | null;
  priority: number;
  enabled: boolean;
}

export interface CommissionRule {
  id: string;
  name: string;
  party: CommissionParty;
  condition: string | null;
  priority: number;
  enabled: boolean;
}
