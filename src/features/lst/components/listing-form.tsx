'use client';

import { useState } from 'react';
import { useTranslations } from 'next-intl';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import {
  Alert,
  Button,
  Card,
  CardHeader,
  CardTitle,
  Checkbox,
  Field,
  Input,
  SelectRoot,
  SelectTrigger,
  SelectValue,
  SelectContent,
  SelectItem,
} from '@/design-system/ui';
import { DynamicFields } from '@/domain/components/dynamic-fields';
import { FormErrorSummary } from '@/domain/components/form-error-summary';
import { bindServerErrors } from '@/lib/forms/bind-server-errors';
import { validationKey } from '@/lib/forms/zod-helpers';
import { listingFormSchema, type ListingFormValues } from '../schemas/listing-schemas';
import { LISTING_TYPES } from '../types';
import { listingTypeLabelKey } from '../constants';
import { AMENITIES } from '../reference-data';
import { useProperties, useUnits } from '@/features/ast/api/queries';

/**
 * Listing create / edit form.
 *
 * FR-LST-001 — binds to a canonical property asset and an optional unit. The
 * unit list is scoped to the chosen property, which is the interface
 * expression of the same constraint.
 *
 * Deliberately NOT enforced here: the FR-LST-008 availability guard. A client
 * check on unit occupancy would be a business rule in the client (SRS §6), and
 * would disagree with the server the moment occupancy changed between load and
 * save. The guard applies at publish, where the server owns it.
 */
export function ListingForm({
  defaultValues,
  onSubmit,
  isSubmitting,
  submitLabel,
}: {
  defaultValues: Partial<ListingFormValues>;
  onSubmit: (values: ListingFormValues) => Promise<void>;
  isSubmitting: boolean;
  submitLabel: string;
}) {
  const t = useTranslations('lst');
  const tc = useTranslations('common');
  const [formErrors, setFormErrors] = useState<string[]>([]);
  const [correlationId, setCorrelationId] = useState<string | null>(null);

  const { register, handleSubmit, watch, setValue, setError, formState: { errors } } =
    useForm<ListingFormValues>({
      resolver: zodResolver(listingFormSchema),
      defaultValues: {
        type: 'sale',
        amenities: [],
        unitId: null,
        priceAmount: null,
        priceCurrency: null,
        areaSqm: null,
        bedrooms: null,
        bathrooms: null,
        neighborhood: null,
        landmark: null,
        legalStatus: null,
        availableFrom: null,
        ...defaultValues,
      } as ListingFormValues,
    });

  const propertyId = watch('propertyId');
  const amenities = watch('amenities') ?? [];

  const { data: properties } = useProperties({ page: 1, perPage: 50 });
  // Units are scoped to the selected property — FR-LST-001.
  const { data: units } = useUnits({
    page: 1,
    perPage: 100,
    filters: propertyId ? { propertyId } : undefined,
  });

  // validationKey guards against a schema surfacing a message with no
  // catalogue entry — see the note in zod-helpers.
  const errorMessage = (message: string | undefined) => {
    const key = validationKey(message);
    return key ? t(`validation.${key}`) : undefined;
  };

  async function submit(values: ListingFormValues) {
    setFormErrors([]);
    setCorrelationId(null);
    try {
      await onSubmit(values);
    } catch (error) {
      const bound = bindServerErrors(error, setError, [
        'title', 'reference', 'propertyId', 'unitId', 'priceAmount', 'areaSqm', 'city',
      ]);
      setCorrelationId(bound.correlationId);
      setFormErrors(bound.formErrors.length ? bound.formErrors : [tc('unexpectedError')]);
    }
  }

  function toggleAmenity(value: string, checked: boolean) {
    setValue(
      'amenities',
      checked ? [...amenities, value] : amenities.filter((item) => item !== value),
      { shouldDirty: true },
    );
  }

  return (
    <form onSubmit={handleSubmit(submit)} noValidate className="flex flex-col gap-6">
      <FormErrorSummary messages={formErrors} correlationId={correlationId} />

      <Card record="listing">
        <CardHeader><CardTitle>{t('form.details')}</CardTitle></CardHeader>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label={t('field.title')} required error={errorMessage(errors.title?.message)}>
            <Input {...register('title')} autoComplete="off" />
          </Field>
          <Field label={t('field.reference')} required error={errorMessage(errors.reference?.message)}>
            <Input {...register('reference')} contentDirection="ltr" autoComplete="off" />
          </Field>
          <Field label={t('field.type')} required>
            <SelectRoot
              value={watch('type')}
              onValueChange={(value) => setValue('type', value as ListingFormValues['type'])}
            >
              <SelectTrigger><SelectValue /></SelectTrigger>
              <SelectContent>
                {LISTING_TYPES.map((value) => (
                  <SelectItem key={value} value={value}>{t(listingTypeLabelKey(value))}</SelectItem>
                ))}
              </SelectContent>
            </SelectRoot>
          </Field>
          <Field
            label={t('field.legalStatus')}
            description={t('field.legalStatusHelp')}
            error={errorMessage(errors.legalStatus?.message)}
          >
            {/* MI-25: "legal status" is required by FR-LST-003 but never
                defined — free text rather than an invented vocabulary. */}
            <Input {...register('legalStatus')} autoComplete="off" />
          </Field>
        </div>
      </Card>

      <Card record="asset">
        <CardHeader><CardTitle>{t('form.linkedAsset')}</CardTitle></CardHeader>
        <Alert tone="info" className="mb-4">{t('form.assetSeparationNote')}</Alert>
        <div className="grid gap-4 sm:grid-cols-2">
          <Field label={t('field.property')} required error={errorMessage(errors.propertyId?.message)}>
            <SelectRoot
              value={watch('propertyId') || undefined}
              onValueChange={(value) => {
                setValue('propertyId', value, { shouldValidate: true });
                // Clearing the unit is correct: a unit from the previous
                // property would violate the FR-LST-001 binding.
                setValue('unitId', null);
              }}
            >
              <SelectTrigger><SelectValue placeholder={tc('select')} /></SelectTrigger>
              <SelectContent>
                {(properties?.items ?? []).map((property) => (
                  <SelectItem key={property.id} value={property.id}>{property.name}</SelectItem>
                ))}
              </SelectContent>
            </SelectRoot>
          </Field>

          <Field label={t('field.unit')} description={t('field.unitHelp')}>
            <SelectRoot
              value={watch('unitId') || undefined}
              onValueChange={(value) => setValue('unitId', value)}
              disabled={!propertyId}
            >
              <SelectTrigger><SelectValue placeholder={tc('select')} /></SelectTrigger>
              <SelectContent>
                {(units?.items ?? []).map((unit) => (
                  <SelectItem key={unit.id} value={unit.id}>{unit.name}</SelectItem>
                ))}
              </SelectContent>
            </SelectRoot>
          </Field>
        </div>
      </Card>

      <Card record="money">
        <CardHeader><CardTitle>{t('form.pricing')}</CardTitle></CardHeader>
        <div className="grid gap-4 sm:grid-cols-3">
          <Field label={t('field.price')} description={t('field.priceHelp')} error={errorMessage(errors.priceAmount?.message)}>
            {/* Decimal string throughout — never parsed to a number. */}
            <Input {...register('priceAmount')} inputMode="decimal" contentDirection="ltr" />
          </Field>
          <Field label={t('field.currency')}>
            <Input {...register('priceCurrency')} maxLength={3} contentDirection="ltr" placeholder="AED" />
          </Field>
          <Field label={t('field.areaSqm')} error={errorMessage(errors.areaSqm?.message)}>
            <Input {...register('areaSqm')} inputMode="decimal" contentDirection="ltr" />
          </Field>
          <Field label={t('field.bedrooms')}>
            <Input {...register('bedrooms')} inputMode="numeric" contentDirection="ltr" />
          </Field>
          <Field label={t('field.bathrooms')}>
            <Input {...register('bathrooms')} inputMode="numeric" contentDirection="ltr" />
          </Field>
        </div>
      </Card>

      <Card record="listing">
        <CardHeader><CardTitle>{t('form.location')}</CardTitle></CardHeader>
        <div className="grid gap-4 sm:grid-cols-3">
          <Field label={t('field.city')} required error={errorMessage(errors.city?.message)}>
            <Input {...register('city')} autoComplete="address-level2" />
          </Field>
          <Field label={t('field.neighborhood')}>
            <Input {...register('neighborhood')} autoComplete="off" />
          </Field>
          <Field label={t('field.landmark')}>
            <Input {...register('landmark')} autoComplete="off" />
          </Field>
        </div>
      </Card>

      <Card record="listing">
        <CardHeader><CardTitle>{t('field.amenities')}</CardTitle></CardHeader>
        {/* fieldset/legend gives the checkbox group a programmatic name —
            WCAG 1.3.1. A bare div of checkboxes has no group semantics. */}
        <fieldset className="border-0 p-0">
          <legend className="sr-only">{t('field.amenities')}</legend>
          <div className="grid gap-3 sm:grid-cols-3">
            {AMENITIES.map((amenity) => {
              const inputId = `amenity-${amenity}`;
              return (
                <span key={amenity} className="flex items-center gap-2">
                  <Checkbox
                    id={inputId}
                    checked={amenities.includes(amenity)}
                    onCheckedChange={(checked) => toggleAmenity(amenity, checked === true)}
                  />
                  <label htmlFor={inputId} className="text-sm">{t(`amenity.${amenity}`)}</label>
                </span>
              );
            })}
          </div>
        </fieldset>
      </Card>

      <DynamicFields entity="listing" variant={watch('type')} values={{}} onChange={() => {}} />

      <div className="flex flex-col-reverse gap-2 sm:flex-row sm:justify-end">
        <Button type="submit" loading={isSubmitting} loadingLabel={submitLabel}>{submitLabel}</Button>
      </div>
    </form>
  );
}
