import { z } from 'zod';
import { LEAD_SOURCES, PIPELINE_STAGES, ACTIVITY_TYPES } from '../types';
import { optionalNumber, optionalString } from '@/lib/forms/zod-helpers';

/**
 * @provisional — proposed contract, replaced by generated types when the
 * OpenAPI spec is published.
 *
 * Not validated here: lead assignment (FR-CRM-002), stage transition legality
 * (FR-CRM-003) and commission amounts (FR-CRM-008). All are server-owned
 * business rules — SRS §6.
 */

export const leadFormSchema = z
  .object({
    name: z.string().min(1, 'required'),
    email: optionalString(z.string().email('email')),
    phone: optionalString(z.string().min(4, 'phone')),
    source: z.enum(LEAD_SOURCES),
    stage: z.enum(PIPELINE_STAGES),
    // FR-CRM-005 matching criteria: budget, location, type, area.
    budgetAmount: optionalString(z.string().regex(/^\d+(\.\d{1,4})?$/, 'amount')),
    budgetCurrency: optionalString(z.string().length(3)),
    preferredCity: optionalString(z.string().min(1)),
    preferredType: optionalString(z.string().min(1)),
    minAreaSqm: optionalNumber(z.number().positive('positive')),
    nextActionNote: optionalString(z.string().min(1)),
  })
  // A lead with no way to reach it is not actionable. This is a FORM rule
  // (completeness of input), not a business rule about lead validity — which
  // remains the server's to enforce.
  .refine((values) => Boolean(values.email) || Boolean(values.phone), {
    message: 'contactRequired',
    path: ['email'],
  });

export type LeadFormValues = z.infer<typeof leadFormSchema>;

export const activityFormSchema = z.object({
  type: z.enum(ACTIVITY_TYPES),
  summary: z.string().min(1, 'required'),
  detail: optionalString(z.string().min(1)),
  dueAt: optionalString(z.string().min(1)),
});
export type ActivityFormValues = z.infer<typeof activityFormSchema>;

export const counterofferFormSchema = z.object({
  // Decimal string end to end. Never coerced to a number — MI-02.
  amount: z.string().regex(/^\d+(\.\d{1,4})?$/, 'amount'),
  currency: z.string().length(3),
  note: optionalString(z.string().min(1)),
});
export type CounterofferFormValues = z.infer<typeof counterofferFormSchema>;
