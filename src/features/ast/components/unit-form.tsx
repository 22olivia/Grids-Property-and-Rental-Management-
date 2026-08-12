'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import {
  Button, Card, CardHeader, CardTitle, Field, Input, Switch, Textarea,
  SelectRoot, SelectTrigger, SelectValue, SelectContent, SelectItem,
} from '@/design-system/ui';
import { FormErrorSummary } from '@/domain/components/form-error-summary';
import { bindServerErrors } from '@/lib/forms/bind-server-errors';
import { validationKey } from '@/lib/forms/zod-helpers';
import { unitFormSchema, type UnitFormValues } from '../schemas/asset-schemas';
import { SELECTABLE_UNIT_STATUSES, unitStatusLabelKey, UNIT_CURRENCY_FALLBACK } from '../constants';
import { useProperties, useBuildings } from '../api/queries';

/**
 * Rental unit create / edit — fields match RentalUnitController::validatedPayload.
 *
 * Money fields are decimal STRINGS end to end. `monthly_rent` is required by
 * the backend; maintenance charge and deposit are nullable.
 *
 * Currency is not editable because the backend has no currency column on
 * rental_units — it is displayed from configuration. Offering a currency
 * selector that cannot be persisted would be a lie in the UI.
 */
export function UnitForm({
  defaultValues,
  onSubmit,
  isSubmitting,
  submitLabel,
}: {
  defaultValues: Partial<UnitFormValues>;
  onSubmit: (values: UnitFormValues) => Promise<void>;
  isSubmitting: boolean;
  submitLabel: string;
}) {
  const t = useTranslations('ast');
  const tc = useTranslations('common');
  const [formErrors, setFormErrors] = useState<string[]>([]);
  const [correlationId, setCorrelationId] = useState<string | null>(null);

  const { register, handleSubmit, watch, setValue, setError, formState: { errors } } =
    useForm<UnitFormValues>({
      resolver: zodResolver(unitFormSchema),
      defaultValues: {
        status: 'vacant',
        isListed: false,
        buildingId: null, floorId: null, unitType: null, furnishingStatus: null,
        bedrooms: null, bathrooms: null, squareFeet: null, areaSqm: null,
        maintenanceCharge: null, depositAmount: null,
        availabilityDate: null, description: null,
        ...defaultValues,
      } as UnitFormValues,
    });

  const propertyId = watch('propertyId');
  const { data: properties } = useProperties({ page: 1, perPage: 50 });
  // Buildings are scoped to the chosen property — the backend accepts
  // `property_id` as a filter on /buildings.
  const { data: buildings } = useBuildings({
    page: 1, perPage: 50,
    filters: propertyId ? { property_id: String(propertyId) } : undefined,
  });

  const errorMessage = (message: string | undefined) => {
    const key = validationKey(message);
    return key ? t(`validation.${key}`) : undefined;
  };

  async function submit(values: UnitFormValues) {
    setFormErrors([]);
    setCorrelationId(null);
    try {
      await onSubmit(values);
    } catch (error) {
      // RentalUnitController validates unit_number / monthly_rent /
      // maintenance_charge / deposit_amount / square_feet.
      const bound = bindServerErrors(error, setError, {
        unit_number: 'unitNumber',
        property_id: 'propertyId',
        building_id: 'buildingId',
        floor_id: 'floorId',
        unit_type: 'unitType',
        furnishing_status: 'furnishingStatus',
        status: 'status',
        bedrooms: 'bedrooms',
        bathrooms: 'bathrooms',
        square_feet: 'squareFeet',
        area: 'areaSqm',
        monthly_rent: 'monthlyRent',
        maintenance_charge: 'maintenanceCharge',
        deposit_amount: 'depositAmount',
        availability_date: 'availabilityDate',
        description: 'description',
        is_listed: 'isListed',
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
          <Field label={t('field.unitNumber')} required error={errorMessage(errors.unitNumber?.message)}>
            <Input {...register('unitNumber')} contentDirection="ltr" autoComplete="off" />
          </Field>
          <Field label={t('field.unitType')}>
            <Input {...register('unitType')} autoComplete="off" />
          </Field>
          <Field label={t('field.status')} required description={t('field.statusHelp')}>
            <SelectRoot
              value={watch('status')}
              onValueChange={(value) => setValue('status', value as UnitFormValues['status'])}
            >
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                {SELECTABLE_UNIT_STATUSES.map((value) => (
                  <SelectItem key={value} value={value}>{t(unitStatusLabelKey(value))}</SelectItem>
                ))}
              </SelectContent>
            </SelectRoot>
          </Field>
          <Field label={t('field.furnishingStatus')}>
            <Input {...register('furnishingStatus')} autoComplete="off" />
          </Field>
        </div>
      </Card>

      <Card record="asset">
        <CardHeader><CardTitle>{t('form.placement')}</CardTitle></CardHeader>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label={t('field.property')} required error={errorMessage(errors.propertyId?.message)}>
            <SelectRoot
              value={propertyId ? String(propertyId) : undefined}
              onValueChange={(value) => {
                setValue('propertyId', Number(value), { shouldValidate: true });
                // A building from the previous property would be invalid.
                setValue('buildingId', null);
              }}
            >
              <SelectTrigger><SelectValue placeholder={tc('select')} /></SelectTrigger>
              <SelectContent>
                {(properties?.items ?? []).map((property) => (
                  <SelectItem key={property.id} value={String(property.id)}>{property.name}</SelectItem>
                ))}
              </SelectContent>
            </SelectRoot>
          </Field>

          <Field label={t('field.building')}>
            <SelectRoot
              value={watch('buildingId') ? String(watch('buildingId')) : undefined}
              onValueChange={(value) => setValue('buildingId', Number(value))}
              disabled={!propertyId}
            >
              <SelectTrigger><SelectValue placeholder={tc('select')} /></SelectTrigger>
              <SelectContent>
                {(buildings?.items ?? []).map((building) => (
                  <SelectItem key={building.id} value={String(building.id)}>{building.name}</SelectItem>
                ))}
              </SelectContent>
            </SelectRoot>
          </Field>
        </div>
      </Card>

      <Card record="asset">
        <CardHeader><CardTitle>{t('form.attributes')}</CardTitle></CardHeader>
        <div className="grid gap-4 sm:grid-cols-3">
          <Field label={t('field.bedrooms')}>
            <Input {...register('bedrooms')} inputMode="numeric" contentDirection="ltr" />
          </Field>
          <Field label={t('field.bathrooms')}>
            <Input {...register('bathrooms')} inputMode="numeric" contentDirection="ltr" />
          </Field>
          <Field label={t('field.squareFeet')} error={errorMessage(errors.squareFeet?.message)}>
            <Input {...register('squareFeet')} inputMode="decimal" contentDirection="ltr" />
          </Field>
          <Field label={t('field.areaSqm')} error={errorMessage(errors.areaSqm?.message)}>
            <Input {...register('areaSqm')} inputMode="decimal" contentDirection="ltr" />
          </Field>
        </div>
      </Card>

      <Card record="money">
        <CardHeader><CardTitle>{t('form.money')}</CardTitle></CardHeader>
        <div className="grid gap-4 sm:grid-cols-3">
          <Field
            label={t('field.monthlyRent', { currency: UNIT_CURRENCY_FALLBACK })}
            description={t('field.moneyHelp')}
            required
            error={errorMessage(errors.monthlyRent?.message)}
          >
            {/* Decimal string. Never parsed to a number anywhere. */}
            <Input {...register('monthlyRent')} inputMode="decimal" contentDirection="ltr" />
          </Field>
          <Field
            label={t('field.maintenanceCharge', { currency: UNIT_CURRENCY_FALLBACK })}
            error={errorMessage(errors.maintenanceCharge?.message)}
          >
            <Input {...register('maintenanceCharge')} inputMode="decimal" contentDirection="ltr" />
          </Field>
          <Field
            label={t('field.depositAmount', { currency: UNIT_CURRENCY_FALLBACK })}
            error={errorMessage(errors.depositAmount?.message)}
          >
            <Input {...register('depositAmount')} inputMode="decimal" contentDirection="ltr" />
          </Field>
        </div>
        <p className="mt-3 text-xs text-[var(--color-text-muted)]">{t('field.currencyNote')}</p>
      </Card>

      <Card record="asset">
        <CardHeader><CardTitle>{t('form.publication')}</CardTitle></CardHeader>
        <div className="flex items-center gap-3">
          <Switch
            id="unit-is-listed"
            checked={watch('isListed')}
            onCheckedChange={(checked) => setValue('isListed', checked === true)}
          />
          <label htmlFor="unit-is-listed" className="text-sm">{t('field.isListed')}</label>
        </div>
        <Field label={t('field.description')} className="mt-4">
          <Textarea {...register('description')} rows={3} />
        </Field>
      </Card>

      <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <Button type="submit" loading={isSubmitting} loadingLabel={submitLabel}>{submitLabel}</Button>
      </div>
    </form>
  );
}
