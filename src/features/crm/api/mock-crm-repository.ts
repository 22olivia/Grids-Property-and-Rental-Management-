import type { ListQuery, ListResult } from '@/lib/data/repository';
import type {
  Activity, AssignmentRule, Commission, CommissionRule, Deal, Lead, Offer,
  PipelineStage, Viewing,
} from '../types';
import {
  ACTIVITY_TYPES, ASSIGNMENT_BASES, COMMISSION_PARTIES, LEAD_SOURCES,
  OFFER_STATES, PIPELINE_STAGES, VIEWING_STATUSES,
} from '../types';
import type {
  ActivityFormValues, CounterofferFormValues, LeadFormValues,
} from '../schemas/crm-schemas';
import type { CrmRepository, MatchedListing } from './crm-repository';

/**
 * ===========================================================================
 * MOCK DATA — UI development only. Never ships enabled.
 * ===========================================================================
 * Fixtures use deliberately obvious values. The `condition` strings on rules
 * are opaque summaries, NOT a rule grammar — see MI-31.
 * ===========================================================================
 */

const LATENCY_MS = 300;
const delay = () => new Promise((resolve) => setTimeout(resolve, LATENCY_MS));
const CURRENCY = 'AED';

/** Fixture vocabulary — see the note in the asset mock repository. */
const PEOPLE = [
  'Layla Haddad', 'Omar Nasser', 'Maya Rahman', 'Yousef Karim', 'Nadia Sabbagh',
  'Tariq Aziz', 'Hana Darwish', 'Samir Fadel', 'Rania Khoury', 'Bilal Mansour',
];
const AGENTS = ['Dana Mroueh', 'Karim Haddad', 'Sara Nasr', 'Ali Rahal'];
const LISTING_TITLES = [
  'Sea-view apartment — Marina Heights', 'Family villa — Jasmine Villas',
  'Office suite — Falcon Business Park', 'Studio — Lantern Quarter',
];

function makeLead(index: number): Lead {
  const stage = PIPELINE_STAGES[index % PIPELINE_STAGES.length] as PipelineStage;
  return {
    id: `lead-${index}`,
    reference: `LEA-${String(index).padStart(4, '0')}`,
    name: PEOPLE[index % PEOPLE.length] + (index > PEOPLE.length ? ` ${Math.ceil(index / PEOPLE.length)}` : ''),
    email: index % 4 === 0 ? null : `lead${index}@example.invalid`,
    phone: index % 4 === 0 ? `+9715000000${index % 10}` : null,
    source: LEAD_SOURCES[index % LEAD_SOURCES.length]!,
    stage,
    assignedAgentId: index % 5 === 0 ? null : `agent-${(index % 4) + 1}`,
    assignedAgentName: index % 5 === 0 ? null : AGENTS[index % AGENTS.length]!,
    budget: { amount: `${(index % 10) * 50000 + 400000}.00`, currency: CURRENCY },
    preferredCity: ['Dubai', 'Abu Dhabi', 'Sharjah'][index % 3]!,
    preferredType: ['Apartment', 'Villa', 'Office'][index % 3] ?? null,
    minAreaSqm: 60 + (index % 5) * 20,
    nextActionAt: index % 3 === 0 ? '2026-08-14T09:00:00Z' : null,
    nextActionNote: index % 3 === 0 ? 'Follow up on viewing feedback' : null,
    interestedListingId: index % 2 === 0 ? `lst-${index}` : null,
    interestedListingTitle: index % 2 === 0 ? LISTING_TITLES[index % LISTING_TITLES.length]! : null,
    customFields: {},
    createdAt: '2026-06-01T10:00:00Z',
    updatedAt: '2026-07-28T12:00:00Z',
  };
}

const leads = Array.from({ length: 74 }, (_, i) => makeLead(i + 1));

const activities: Activity[] = leads.slice(0, 30).flatMap((lead, i) =>
  Array.from({ length: (i % 3) + 2 }, (_, j) => ({
    id: `${lead.id}-act-${j}`,
    leadId: lead.id,
    type: ACTIVITY_TYPES[(i + j) % ACTIVITY_TYPES.length]!,
    summary: ['Intro call', 'Sent shortlist', 'Viewing arranged', 'Follow-up scheduled', 'Budget discussed'][(i + j) % 5]!,
    detail: j === 0 ? 'Discussed budget and preferred areas.' : null,
    actorName: AGENTS[i % AGENTS.length]!,
    occurredAt: `2026-0${(j % 7) + 1}-1${j % 9}T09:30:00Z`,
    dueAt: ['task', 'reminder'].includes(ACTIVITY_TYPES[(i + j) % ACTIVITY_TYPES.length]!)
      ? '2026-08-20T09:00:00Z'
      : null,
    completed: j % 3 === 0,
  })),
);

const viewings: Viewing[] = leads.slice(0, 40).map((lead, i) => ({
  id: `view-${i + 1}`,
  reference: `VW-${String(i + 1).padStart(4, '0')}`,
  leadId: lead.id,
  leadName: lead.name,
  listingId: `lst-${i + 1}`,
  listingTitle: LISTING_TITLES[i % LISTING_TITLES.length]!,
  agentName: AGENTS[i % AGENTS.length]!,
  // Spread across the coming weeks so the calendar has something to show.
  scheduledFor: new Date(Date.now() + (i - 8) * 86400000).toISOString(),
  status: VIEWING_STATUSES[i % VIEWING_STATUSES.length]!,
  feedback: i % 3 === 0 ? 'Liked the layout, concerned about the price.' : null,
}));

const offers: Offer[] = leads.slice(0, 26).map((lead, i) => ({
  id: `offer-${i + 1}`,
  reference: `OFR-${String(i + 1).padStart(4, '0')}`,
  leadId: lead.id,
  leadName: lead.name,
  listingId: `lst-${i + 1}`,
  listingTitle: LISTING_TITLES[i % LISTING_TITLES.length]!,
  amount: { amount: `${(i % 8) * 25000 + 400000}.00`, currency: CURRENCY },
  depositAmount: { amount: `${(i % 5) * 5000 + 10000}.00`, currency: CURRENCY },
  state: OFFER_STATES[i % OFFER_STATES.length]!,
  expiresAt: new Date(Date.now() + (i % 10) * 86400000).toISOString(),
  createdAt: '2026-07-10T08:00:00Z',
  counteroffers:
    i % 3 === 0
      ? [
          {
            id: `offer-${i + 1}-c1`,
            byParty: 'seller',
            amount: { amount: `${(i % 8) * 25000 + 430000}.00`, currency: CURRENCY },
            note: 'Counter from the seller.',
            createdAt: '2026-07-12T09:00:00Z',
          },
        ]
      : [],
}));

const deals: Deal[] = leads.slice(0, 18).map((lead, i) => ({
  id: `deal-${i + 1}`,
  reference: `DEA-${String(i + 1).padStart(4, '0')}`,
  leadName: lead.name,
  listingTitle: LISTING_TITLES[i % LISTING_TITLES.length]!,
  value: { amount: `${(i % 9) * 30000 + 450000}.00`, currency: CURRENCY },
  stage: i % 4 === 0 ? 'lost' : 'won',
  closedAt: '2026-07-25T15:00:00Z',
  closeReason: i % 4 === 0 ? 'Budget not met' : null,
}));

const commissions: Commission[] = deals.flatMap((deal, i) =>
  COMMISSION_PARTIES.map((party, j) => ({
    id: `${deal.id}-com-${j}`,
    dealId: deal.id,
    dealReference: deal.reference,
    party,
    partyName: party === 'company' ? 'Grids Property Management'
      : party === 'agency' ? 'Northshore Partners'
      : AGENTS[(i + COMMISSION_PARTIES.indexOf(party)) % AGENTS.length]!,
    // Server-calculated in reality (FR-CRM-008). Fixture values only.
    amount: { amount: `${(j + 1) * 2500}.00`, currency: CURRENCY },
    ruleLabel: `${party.charAt(0).toUpperCase() + party.slice(1)} share`,
    settled: (i + j) % 3 === 0,
  })),
);

const assignmentRules: AssignmentRule[] = ASSIGNMENT_BASES.map((basis, i) => ({
  id: `arule-${i + 1}`,
  name: `Route by ${basis.replace('-', ' ')}`,
  basis,
  // Opaque summary. NOT a grammar — see MI-31.
  condition: null,
  priority: i + 1,
  enabled: i % 4 !== 3,
}));

const commissionRules: CommissionRule[] = COMMISSION_PARTIES.map((party, i) => ({
  id: `crule-${i + 1}`,
  name: `${party.charAt(0).toUpperCase() + party.slice(1)} share`,
  party,
  condition: null,
  priority: i + 1,
  enabled: true,
}));

function paginate<T>(all: T[], query: ListQuery): ListResult<T> {
  const page = query.page ?? 1;
  const perPage = query.perPage ?? 20;
  const start = (page - 1) * perPage;
  return { items: all.slice(start, start + perPage), total: all.length, page, perPage };
}

export const mockCrmRepository: CrmRepository = {
  async listLeads(query) {
    await delay();
    let result = leads;
    if (query.search) {
      const needle = query.search.toLowerCase();
      result = result.filter(
        (l) => l.name.toLowerCase().includes(needle) || l.reference.toLowerCase().includes(needle),
      );
    }
    if (query.filters?.stage) result = result.filter((l) => l.stage === query.filters?.stage);
    if (query.filters?.source) result = result.filter((l) => l.source === query.filters?.source);
    return paginate(result, query);
  },

  async getLead(id) {
    await delay();
    const found = leads.find((l) => l.id === id);
    if (!found) throw new Error('NOT_FOUND');
    return found;
  },

  async createLead(values: LeadFormValues) {
    await delay();
    return { ...makeLead(leads.length + 1), ...values } as unknown as Lead;
  },

  async updateLead(id, values: LeadFormValues) {
    await delay();
    const existing = leads.find((l) => l.id === id);
    if (!existing) throw new Error('NOT_FOUND');
    return { ...existing, ...values } as unknown as Lead;
  },

  async moveLeadStage(id, stage) {
    await delay();
    const existing = leads.find((l) => l.id === id);
    if (!existing) throw new Error('NOT_FOUND');
    return { ...existing, stage };
  },

  async listPipeline() {
    await delay();
    const grouped = Object.fromEntries(
      PIPELINE_STAGES.map((stage) => [stage, leads.filter((l) => l.stage === stage)]),
    ) as Record<PipelineStage, Lead[]>;
    return grouped;
  },

  async listActivities(leadId) {
    await delay();
    return activities
      .filter((a) => a.leadId === leadId)
      .sort((a, b) => b.occurredAt.localeCompare(a.occurredAt));
  },

  async createActivity(leadId, values: ActivityFormValues) {
    await delay();
    return {
      id: `${leadId}-act-new`,
      leadId,
      type: values.type,
      summary: values.summary,
      detail: values.detail ?? null,
      actorName: 'Demo User',
      occurredAt: new Date().toISOString(),
      dueAt: values.dueAt ?? null,
      completed: false,
    };
  },

  async completeActivity(activityId) {
    await delay();
    const found = activities.find((a) => a.id === activityId);
    if (!found) throw new Error('NOT_FOUND');
    return { ...found, completed: true };
  },

  async listTasks(query) {
    await delay();
    const tasks = activities.filter((a) => a.dueAt !== null);
    const filtered = query.filters?.completed
      ? tasks.filter((a) => String(a.completed) === query.filters?.completed)
      : tasks;
    return paginate(filtered, query);
  },

  async listMatches(leadId) {
    await delay();
    // FR-CRM-005: matching is server-computed. These scores are fixtures, not
    // an algorithm — the client must never rank matches itself.
    const seed = Number(leadId.split('-')[1] ?? 1);
    const items: MatchedListing[] = Array.from({ length: 6 }, (_, i) => ({
      listingId: `lst-${seed + i}`,
      title: LISTING_TITLES[(seed + i) % LISTING_TITLES.length]!,
      city: ['Dubai', 'Abu Dhabi', 'Sharjah'][(seed + i) % 3]!,
      price: { amount: `${(i % 6) * 30000 + 420000}.00`, currency: CURRENCY },
      areaSqm: 70 + i * 15,
      matchScore: 95 - i * 7,
      matchReason: 'Budget and area within the stated criteria.',
    }));
    return { items, total: items.length, page: 1, perPage: items.length };
  },

  async listViewings(query) {
    await delay();
    let result = viewings;
    if (query.filters?.status) result = result.filter((v) => v.status === query.filters?.status);
    if (query.search) {
      const needle = query.search.toLowerCase();
      result = result.filter((v) => v.leadName.toLowerCase().includes(needle));
    }
    return paginate(result, query);
  },

  async getViewing(id) {
    await delay();
    const found = viewings.find((v) => v.id === id);
    if (!found) throw new Error('NOT_FOUND');
    return found;
  },

  async listOffers(query) {
    await delay();
    let result = offers;
    if (query.filters?.state) result = result.filter((o) => o.state === query.filters?.state);
    return paginate(result, query);
  },

  async getOffer(id) {
    await delay();
    const found = offers.find((o) => o.id === id);
    if (!found) throw new Error('NOT_FOUND');
    return found;
  },

  async addCounteroffer(offerId, values: CounterofferFormValues) {
    await delay();
    const existing = offers.find((o) => o.id === offerId);
    if (!existing) throw new Error('NOT_FOUND');
    return {
      ...existing,
      state: 'countered',
      counteroffers: [
        ...existing.counteroffers,
        {
          id: `${offerId}-c-new`,
          byParty: 'buyer',
          amount: { amount: values.amount, currency: values.currency },
          note: values.note ?? null,
          createdAt: new Date().toISOString(),
        },
      ],
    };
  },

  async listDeals(query) {
    await delay();
    const result = query.filters?.stage
      ? deals.filter((d) => d.stage === query.filters?.stage)
      : deals;
    return paginate(result, query);
  },

  async listCommissions(query) {
    await delay();
    const result = query.filters?.party
      ? commissions.filter((c) => c.party === query.filters?.party)
      : commissions;
    return paginate(result, query);
  },

  async listAssignmentRules() {
    await delay();
    return [...assignmentRules].sort((a, b) => a.priority - b.priority);
  },

  async listCommissionRules() {
    await delay();
    return [...commissionRules].sort((a, b) => a.priority - b.priority);
  },
};
