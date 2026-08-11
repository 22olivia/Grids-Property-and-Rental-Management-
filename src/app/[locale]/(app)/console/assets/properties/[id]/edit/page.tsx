'use client';

import { use } from 'react';
import { useTranslations } from 'next-intl';
import { ErrorState, LoadingState, toast } from '@/design-system/ui';
import { useRouter } from '@/lib/i18n/routing';
import { ResourceFormScreen } from '@/domain/screens/resource-form-screen';
import { PropertyForm } from '@/features/ast/components/property-form';
import { useProperty, useUpdateProperty } from '@/features/ast/api/queries';
import { ASSETS_ARE_MOCK } from '@/features/ast/api';

/** Screen #83b — Property edit. LIVE against PUT /api/v1/properties/{id}. */
export default function EditPropertyPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('ast');
  const tc = useTranslations('common');
  const router = useRouter();

  const { data: property, isLoading, error, refetch } = useProperty(id);
  const update = useUpdateProperty(id);

  if (isLoading) return <LoadingState label={tc('loading')} />;
  if (error || !property) {
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
        { label: t('properties.title'), href: '/console/assets/properties' },
        { label: property.name, href: `/console/assets/properties/${id}` },
        { label: tc('edit') },
      ]}
      title={property.name}
    >
      <PropertyForm
        defaultValues={{
          name: property.name,
          ownerId: property.owner?.id ?? undefined,
          type: property.type as never,
          status: property.status as never,
          address: property.address,
          coordinates: property.coordinates,
          description: property.description,
          totalUnits: property.totalUnits,
        }}
        isSubmitting={update.isPending}
        submitLabel={tc('save')}
        onSubmit={async (values) => {
          await update.mutateAsync(values);
          toast.success(t('properties.updated'));
          router.push(`/console/assets/properties/${id}`);
        }}
      />
    </ResourceFormScreen>
  );
}
