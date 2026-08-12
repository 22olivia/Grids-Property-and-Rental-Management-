'use client';

import { use } from 'react';
import { useTranslations } from 'next-intl';
import { ErrorState, LoadingState, toast } from '@/design-system/ui';
import { useRouter } from '@/lib/i18n/routing';
import { ResourceFormScreen } from '@/domain/screens/resource-form-screen';
import { UnitForm } from '@/features/ast/components/unit-form';
import { useUnit, useUpdateUnit } from '@/features/ast/api/queries';
import { ASSETS_ARE_MOCK } from '@/features/ast/api';

/** Screen #88b — Unit edit. LIVE against PUT /api/v1/rental-units/{id}. */
export default function EditUnitPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('ast');
  const tc = useTranslations('common');
  const router = useRouter();

  const { data: unit, isLoading, error, refetch } = useUnit(id);
  const update = useUpdateUnit(id);

  if (isLoading) return <LoadingState label={tc('loading')} />;
  if (error || !unit) {
    return (
      <ErrorState
        title={t('detail.notFoundTitle')}
        description={t('detail.notFoundDescription')}
        retryLabel={tc('retry')}
        onRetry={() => refetch()}
      />
    );
  }

  return (
    <ResourceFormScreen
      isMock={ASSETS_ARE_MOCK}
      breadcrumbLabel={t('breadcrumbLabel')}
      breadcrumb={[
        { label: t('units.title'), href: '/console/assets/units' },
        { label: unit.unitNumber, href: `/console/assets/units/${id}` },
        { label: tc('edit') },
      ]}
      title={unit.unitNumber}
    >
      <UnitForm
        defaultValues={{
          unitNumber: unit.unitNumber,
          propertyId: unit.propertyId,
          buildingId: unit.buildingId,
          floorId: unit.floorId,
          unitType: unit.unitType,
          furnishingStatus: unit.furnishingStatus,
          status: unit.status as never,
          bedrooms: unit.bedrooms,
          bathrooms: unit.bathrooms,
          squareFeet: unit.squareFeet,
          areaSqm: unit.areaSqm,
          // Decimal strings preserved exactly — never parsed.
          monthlyRent: unit.monthlyRent?.amount ?? '',
          maintenanceCharge: unit.maintenanceCharge?.amount ?? null,
          depositAmount: unit.depositAmount?.amount ?? null,
          availabilityDate: unit.availabilityDate,
          description: unit.description,
          isListed: unit.isListed,
        }}
        isSubmitting={update.isPending}
        submitLabel={tc('save')}
        onSubmit={async (values) => {
          await update.mutateAsync(values);
          toast.success(t('units.updated'));
          router.push(`/console/assets/units/${id}`);
        }}
      />
    </ResourceFormScreen>
  );
}
