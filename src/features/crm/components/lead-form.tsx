'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import {
  Button, Card, CardHeader, CardTitle, Field, Input, Textarea,
  SelectRoot, SelectTrigger, SelectValue, SelectContent, SelectItem,
} from '@/design-system/ui';
import { DynamicFields } from '@/domain/components/dynamic-fields';
import { FormErrorSummary } from '@/domain/components/form-error-summary';
import { bindServerErrors } from '@/lib/forms/bind-server-errors';
import { validationKey } from '@/lib/forms/zod-helpers';
import { leadFormSchema, type LeadFormValues } from '../schemas/crm-schemas';
import { LEAD_SOURCES, PIPELINE_STAGES } from '../types';
import { sourceLabelKey, stageLabelKey } from '../constants';

/**
 * Lead create / edit.
 *
 * FR-CRM-001 sources and FR-CRM-003 stages are both enumerated verbatim in the
 * requirements, so both are real select vocabularies.
 *
 * FR-CRM-002 assignment is deliberately ABSENT from this form: assignment is
 * decided by configurable server-side rules (territory, branch, workload,
 * property, campaign) and a manual override needs the agent directory, which
 * belongs to IAM and has no contract. Adding a free-text agent field here
 * would invent both a rule bypass and a data source.
 */
export function LeadForm({
  defaultValues,
  onSubmit,
  isSubmitting,
  submitLabel,
}: {
  defaultValues: Partial<LeadFormValues>;
  onSubmit: (values: LeadFormValues) => Promise<void>;
  isSubmitting: boolean;
  submitLabel: string;
}) {
  const t = useTranslations('crm');
  const tc = useTranslations('common');
  const [formErrors, setFormErrors] = useState<string[]>([]);
  const [correlationId, setCorrelationId] = useState<string | null>(null);

  const { register, handleSubmit, watch, setValue, setError, formState: { errors } } =
    useForm<LeadFormValues>({
      resolver: zodResolver(leadFormSchema),
      defaultValues: {
        source: 'manual',
        stage: 'qualification',
        email: null, phone: null, budgetAmount: null, budgetCurrency: null,
        preferredCity: null, preferredType: null, minAreaSqm: null, nextActionNote: null,
        ...defaultValues,
      } as LeadFormValues,
    });

  // validationKey guards against a schema surfacing a message with no
  // catalogue entry — see the note in zod-helpers.
  const errorMessage = (message: string | undefined) => {
    const key = validationKey(message);
    return key ? t(`validation.${key}`) : undefined;
  };

  async function submit(values: LeadFormValues) {
    setFormErrors([]);
    setCorrelationId(null);
    try {
      await onSubmit(values);
    } catch (error) {
      const bound = bindServerErrors(error, setError, ['name', 'email', 'phone', 'budgetAmount']);
      setCorrelationId(bound.correlationId);
      setFormErrors(bound.formErrors.length ? bound.formErrors : [tc('unexpectedError')]);
    }
  }

  return (
    <form onSubmit={handleSubmit(submit)} noValidate className="flex flex-col gap-6">
      <FormErrorSummary messages={formErrors} correlationId={correlationId} />

      <Card record="party">
        <CardHeader><CardTitle>{t('form.contact')}</CardTitle></CardHeader>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label={t('field.name')} required error={errorMessage(errors.name?.message)}>
            <Input {...register('name')} autoComplete="name" />
          </Field>
          <Field
            label={t('field.email')}
            description={t('field.contactHelp')}
            error={errorMessage(errors.email?.message)}
          >
            {/* Email is Latin-script: pinned LTR so it does not render
                scrambled inside an Arabic form. */}
            <Input {...register('email')} type="email" contentDirection="ltr" autoComplete="email" />
          </Field>
          <Field label={t('field.phone')} error={errorMessage(errors.phone?.message)}>
            <Input {...register('phone')} type="tel" contentDirection="ltr" autoComplete="tel" />
          </Field>
          <Field label={t('field.source')} required>
            <SelectRoot
              value={watch('source')}
              onValueChange={(value) => setValue('source', value as LeadFormValues['source'])}
            >
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                {LEAD_SOURCES.map((value) => (
                  <SelectItem key={value} value={value}>{t(sourceLabelKey(value))}</SelectItem>
                ))}
              </SelectContent>
            </SelectRoot>
          </Field>
          <Field label={t('field.stage')} required>
            <SelectRoot
              value={watch('stage')}
              onValueChange={(value) => setValue('stage', value as LeadFormValues['stage'])}
            >
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                {PIPELINE_STAGES.map((value) => (
                  <SelectItem key={value} value={value}>{t(stageLabelKey(value))}</SelectItem>
                ))}
              </SelectContent>
            </SelectRoot>
          </Field>
        </div>
      </Card>

      <Card record="party">
        {/* FR-CRM-005 — the criteria the server matches against. */}
        <CardHeader><CardTitle>{t('form.criteria')}</CardTitle></CardHeader>
        <div className="grid gap-4 sm:grid-cols-3">
          <Field label={t('field.budget')} description={t('field.budgetHelp')} error={errorMessage(errors.budgetAmount?.message)}>
            <Input {...register('budgetAmount')} inputMode="decimal" contentDirection="ltr" />
          </Field>
          <Field label={t('field.currency')}>
            <Input {...register('budgetCurrency')} maxLength={3} contentDirection="ltr" placeholder="AED" />
          </Field>
          <Field label={t('field.minArea')} error={errorMessage(errors.minAreaSqm?.message)}>
            <Input {...register('minAreaSqm')} inputMode="decimal" contentDirection="ltr" />
          </Field>
          <Field label={t('field.preferredCity')}>
            <Input {...register('preferredCity')} autoComplete="address-level2" />
          </Field>
          <Field label={t('field.preferredType')}>
            <Input {...register('preferredType')} autoComplete="off" />
          </Field>
        </div>
      </Card>

      <Card record="party">
        <CardHeader><CardTitle>{t('form.nextAction')}</CardTitle></CardHeader>
        <Field label={t('field.nextActionNote')}>
          <Textarea {...register('nextActionNote')} rows={3} />
        </Field>
      </Card>

      <DynamicFields entity="lead" values={{}} onChange={() => {}} />

      <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <Button type="submit" loading={isSubmitting} loadingLabel={submitLabel}>{submitLabel}</Button>
      </div>
    </form>
  );
}
