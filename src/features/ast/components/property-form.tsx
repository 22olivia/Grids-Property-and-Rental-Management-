'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import {
  Alert, Button, Card, CardHeader, CardTitle, Field, Input, Textarea,
  SelectRoot, SelectTrigger, SelectValue, SelectContent, SelectItem,
} from '@/design-system/ui';
import { FormErrorSummary } from '@/domain/components/form-error-summary';
import { bindServerErrors } from '@/lib/forms/bind-server-errors';
import { validationKey } from '@/lib/forms/zod-helpers';
import { propertyFormSchema, type PropertyFormValues } from '../schemas/asset-schemas';
import { PROPERTY_TYPES, PROPERTY_STATUSES } from '../types';
import { propertyTypeLabelKey, propertyStatusLabelKey } from '../constants';

/**
 * Property create / edit — fields match PropertyController's validation rules.
 *
 * `owner_id` is REQUIRED by the backend. There is an `/owners` endpoint but no
 * owners module in this frontend yet, so the field is a numeric id entry
 * rather than a picker. Ugly but honest: inventing an owner selector against
 * an unmapped response shape would be worse, and the constraint is real —
 * a property cannot be created without one.
 */
export function PropertyForm({
  defaultValues,
  onSubmit,
  isSubmitting,
  submitLabel,
}: {
  defaultValues: Partial<PropertyFormValues>;
  onSubmit: (values: PropertyFormValues) => Promise<void>;
  isSubmitting: boolean;
  submitLabel: string;
}) {
  const t = useTranslations('ast');
  const tc = useTranslations('common');
  const [formErrors, setFormErrors] = useState<string[]>([]);
  const [correlationId, setCorrelationId] = useState<string | null>(null);

  const { register, handleSubmit, watch, setValue, setError, formState: { errors } } =
    useForm<PropertyFormValues>({
      resolver: zodResolver(propertyFormSchema),
      defaultValues: {
        type: 'apartment',
        status: 'active',
        coordinates: null,
        description: null,
        totalUnits: null,
        ...defaultValues,
      } as PropertyFormValues,
    });

  const errorMessage = (message: string | undefined) => {
    const key = validationKey(message);
    return key ? t(`validation.${key}`) : undefined;
  };

  async function submit(values: PropertyFormValues) {
    setFormErrors([]);
    setCorrelationId(null);
    try {
      await onSubmit(values);
    } catch (error) {
      // Backend field name → form path. PropertyController validates
      // owner_id / address_line1 / postal_code; the form uses ownerId and
      // address.*. Without this map every server error missed its control.
      const bound = bindServerErrors(error, setError, {
        name: 'name',
        owner_id: 'ownerId',
        type: 'type',
        status: 'status',
        total_units: 'totalUnits',
        address_line1: 'address.line1',
        address_line2: 'address.line2',
        city: 'address.city',
        state: 'address.state',
        postal_code: 'address.postalCode',
        country: 'address.country',
        latitude: 'coordinates.latitude',
        longitude: 'coordinates.longitude',
        description: 'description',
      });
      setCorrelationId(bound.correlationId);
      setFormErrors(bound.formErrors.length ? bound.formErrors : [tc('unexpectedError')]);
    }
  }

  return (
    <form onSubmit={handleSubmit(submit)} noValidate className="flex flex-col gap-6">
      <FormErrorSummary messages={formErrors} correlationId={correlationId} />

      <Card record="asset">
        <CardHeader><CardTitle>{t('form.identification')}</CardTitle></CardHeader>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label={t('field.name')} required error={errorMessage(errors.name?.message)}>
            <Input {...register('name')} autoComplete="off" />
          </Field>

          <Field
            label={t('field.ownerId')}
            description={t('field.ownerIdHelp')}
            required
            error={errorMessage(errors.ownerId?.message)}
          >
            <Input {...register('ownerId')} inputMode="numeric" contentDirection="ltr" />
          </Field>

          <Field label={t('field.propertyType')} required>
            <SelectRoot
              value={watch('type')}
              onValueChange={(value) => setValue('type', value as PropertyFormValues['type'])}
            >
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                {PROPERTY_TYPES.map((value) => (
                  <SelectItem key={value} value={value}>{t(propertyTypeLabelKey(value))}</SelectItem>
                ))}
              </SelectContent>
            </SelectRoot>
          </Field>

          <Field label={t('field.propertyStatus')} required>
            <SelectRoot
              value={watch('status')}
              onValueChange={(value) => setValue('status', value as PropertyFormValues['status'])}
            >
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                {PROPERTY_STATUSES.map((value) => (
                  <SelectItem key={value} value={value}>{t(propertyStatusLabelKey(value))}</SelectItem>
                ))}
              </SelectContent>
            </SelectRoot>
          </Field>

          <Field label={t('field.totalUnits')} error={errorMessage(errors.totalUnits?.message)}>
            <Input {...register('totalUnits')} inputMode="numeric" contentDirection="ltr" />
          </Field>
        </div>
      </Card>

      <Card record="asset">
        <CardHeader><CardTitle>{t('form.location')}</CardTitle></CardHeader>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label={t('field.line1')} required error={errorMessage(errors.address?.line1?.message)}>
            <Input {...register('address.line1')} autoComplete="address-line1" />
          </Field>
          <Field label={t('field.line2')}>
            <Input {...register('address.line2')} autoComplete="address-line2" />
          </Field>
          <Field label={t('field.city')} required error={errorMessage(errors.address?.city?.message)}>
            <Input {...register('address.city')} autoComplete="address-level2" />
          </Field>
          <Field label={t('field.state')}>
            <Input {...register('address.state')} autoComplete="address-level1" />
          </Field>
          <Field label={t('field.country')}>
            <Input {...register('address.country')} autoComplete="country-name" />
          </Field>
          <Field label={t('field.postalCode')}>
            <Input {...register('address.postalCode')} contentDirection="ltr" autoComplete="postal-code" />
          </Field>
        </div>

        {/* FR-AST-002 requires coordinates; the backend stores latitude and
            longitude. No map provider is configured (MI-H6), so they are
            entered numerically. A map picker drops in behind the same two
            values without changing the contract. */}
        <Alert tone="info" className="mt-4" title={t('map.title')}>{t('map.unavailable')}</Alert>
        <div className="mt-4 grid gap-4 sm:grid-cols-2">
          <Field label={t('field.latitude')}>
            <Input {...register('coordinates.latitude')} inputMode="decimal" contentDirection="ltr" />
          </Field>
          <Field label={t('field.longitude')}>
            <Input {...register('coordinates.longitude')} inputMode="decimal" contentDirection="ltr" />
          </Field>
        </div>
      </Card>

      <Card record="asset">
        <CardHeader><CardTitle>{t('field.description')}</CardTitle></CardHeader>
        <Field label={t('field.description')}>
          <Textarea {...register('description')} rows={3} />
        </Field>
      </Card>

      {/* The custom-fields seam is GONE, not hidden: FR-AST-006 has no backend
          endpoint, so there is nothing to render or submit. It returns when
          the backend provides a field-definition contract. */}

      <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <Button type="submit" loading={isSubmitting} loadingLabel={submitLabel}>{submitLabel}</Button>
      </div>
    </form>
  );
}
