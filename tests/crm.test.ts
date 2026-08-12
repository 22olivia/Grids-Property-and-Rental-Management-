import { describe, expect, it } from 'vitest';
import en from '../messages/en.json';
import ar from '../messages/ar.json';
import { mockCrmRepository } from '@/features/crm/api/mock-crm-repository';
import { leadFormSchema, counterofferFormSchema } from '@/features/crm/schemas/crm-schemas';
import {
  ACTIVITY_TYPES, ASSIGNMENT_BASES, COMMISSION_PARTIES, LEAD_SOURCES,
  OFFER_STATES, PIPELINE_STAGES, VIEWING_STATUSES,
} from '@/features/crm/types';
import { stageTone, viewingTone, offerTone } from '@/features/crm/constants';

describe('CRM — every enumerated vocabulary is labelled in both locales', () => {
  const cases: [string, readonly string[], Record<string, unknown>, Record<string, unknown>][] = [
    ['source', LEAD_SOURCES, en.crm.source, ar.crm.source],
    ['stage', PIPELINE_STAGES, en.crm.stage, ar.crm.stage],
    ['activityType', ACTIVITY_TYPES, en.crm.activityType, ar.crm.activityType],
    ['viewingStatus', VIEWING_STATUSES, en.crm.viewingStatus, ar.crm.viewingStatus],
    ['offerState', OFFER_STATES, en.crm.offerState, ar.crm.offerState],
    ['basis', ASSIGNMENT_BASES, en.crm.basis, ar.crm.basis],
    ['party', COMMISSION_PARTIES, en.crm.party, ar.crm.party],
  ];
  for (const [name, values, enMap, arMap] of cases) {
    it(`labels every ${name}`, () => {
      for (const value of values) {
        expect(enMap, `en ${name}.${value}`).toHaveProperty(value);
        expect(arMap, `ar ${name}.${value}`).toHaveProperty(value);
      }
    });
  }
  it('falls back to neutral for unknown values', () => {
    expect(stageTone('future-stage')).toBe('neutral');
    expect(viewingTone('future-status')).toBe('neutral');
    expect(offerTone('future-state')).toBe('neutral');
  });
});

describe('CRM — lead validation', () => {
  const base = {
    name: 'Sample', source: 'manual', stage: 'qualification',
    email: 'a@example.invalid', phone: null,
    budgetAmount: '450000.00', budgetCurrency: 'AED',
    preferredCity: null, preferredType: null, minAreaSqm: null, nextActionNote: null,
  };

  it('accepts a lead with an email only', () => {
    expect(leadFormSchema.safeParse(base).success).toBe(true);
  });

  it('accepts a lead with a phone only', () => {
    expect(leadFormSchema.safeParse({ ...base, email: null, phone: '+971500000000' }).success).toBe(true);
  });

  it('rejects a lead with no way to reach it', () => {
    const result = leadFormSchema.safeParse({ ...base, email: null, phone: null });
    expect(result.success).toBe(false);
    if (!result.success) {
      expect(result.error.issues.some((i) => i.message === 'contactRequired')).toBe(true);
    }
  });

  it('preserves the budget as a decimal string', () => {
    const result = leadFormSchema.safeParse(base);
    if (result.success) {
      expect(result.data.budgetAmount).toBe('450000.00');
      expect(typeof result.data.budgetAmount).toBe('string');
    }
  });

  it('treats cleared optional fields as null, not zero', () => {
    const result = leadFormSchema.safeParse({
      ...base, minAreaSqm: '', budgetAmount: '', budgetCurrency: '',
    });
    expect(result.success).toBe(true);
    if (result.success) {
      expect(result.data.minAreaSqm).toBeNull();
      expect(result.data.budgetAmount).toBeNull();
    }
  });

  it('surfaces the inner message, not a union error', () => {
    // Regression: z.union discarded custom messages, so every optional-field
    // error resolved to an unknown translation key.
    const result = leadFormSchema.safeParse({ ...base, email: 'not-an-email' });
    expect(result.success).toBe(false);
    if (!result.success) {
      const messages = result.error.issues.map((i) => i.message);
      expect(messages).toContain('email');
      expect(messages).not.toContain('Invalid input');
    }
  });

  it('rejects a malformed counteroffer amount', () => {
    expect(counterofferFormSchema.safeParse({ amount: '1,500', currency: 'AED', note: null }).success).toBe(false);
    expect(counterofferFormSchema.safeParse({ amount: '1500.00', currency: 'AED', note: null }).success).toBe(true);
  });
});

describe('CRM — mock repository', () => {
  it('groups the pipeline by every stage', async () => {
    const pipeline = await mockCrmRepository.listPipeline();
    for (const stage of PIPELINE_STAGES) {
      expect(pipeline, `missing stage ${stage}`).toHaveProperty(stage);
      expect(Array.isArray(pipeline[stage])).toBe(true);
    }
  });

  it('moves a lead to the requested stage', async () => {
    const moved = await mockCrmRepository.moveLeadStage('lead-1', 'negotiation');
    expect(moved.stage).toBe('negotiation');
  });

  it('filters leads by stage and source', async () => {
    const byStage = await mockCrmRepository.listLeads({ page: 1, perPage: 100, filters: { stage: 'won' } });
    expect(byStage.items.every((l) => l.stage === 'won')).toBe(true);
    const bySource = await mockCrmRepository.listLeads({ page: 1, perPage: 100, filters: { source: 'chat' } });
    expect(bySource.items.every((l) => l.source === 'chat')).toBe(true);
  });

  it('returns only dated items from the task list', async () => {
    const tasks = await mockCrmRepository.listTasks({ page: 1, perPage: 100 });
    expect(tasks.items.every((a) => a.dueAt !== null)).toBe(true);
  });

  it('returns server-computed match scores', async () => {
    const matches = await mockCrmRepository.listMatches('lead-3');
    expect(matches.items.length).toBeGreaterThan(0);
    expect(matches.items.every((m) => typeof m.matchScore === 'number')).toBe(true);
    expect(matches.items.every((m) => m.matchReason.length > 0)).toBe(true);
  });

  it('appends a counteroffer and marks the offer countered', async () => {
    const before = await mockCrmRepository.getOffer('offer-2');
    const after = await mockCrmRepository.addCounteroffer('offer-2', {
      amount: '425000.00', currency: 'AED', note: null,
    });
    expect(after.counteroffers.length).toBe(before.counteroffers.length + 1);
    expect(after.state).toBe('countered');
    expect(after.counteroffers.at(-1)?.amount?.amount).toBe('425000.00');
  });

  it('keeps every monetary value as a decimal string', async () => {
    const offers = await mockCrmRepository.listOffers({ page: 1, perPage: 20 });
    for (const offer of offers.items) {
      if (offer.amount) expect(typeof offer.amount.amount).toBe('string');
      if (offer.depositAmount) expect(typeof offer.depositAmount.amount).toBe('string');
    }
    const commissions = await mockCrmRepository.listCommissions({ page: 1, perPage: 20 });
    for (const c of commissions.items) {
      if (c.amount) expect(typeof c.amount.amount).toBe('string');
    }
  });

  it('returns rules in priority order with no condition grammar', async () => {
    const rules = await mockCrmRepository.listAssignmentRules();
    expect(rules.map((r) => r.priority)).toEqual([...rules.map((r) => r.priority)].sort((a, b) => a - b));
    // MI-31: no rule expression exists, so no condition is fabricated.
    expect(rules.every((r) => r.condition === null)).toBe(true);
  });
});
