'use client';

import { useTranslations } from 'next-intl';
import { toast } from '@/design-system/ui';
import { useRouter } from '@/lib/i18n/routing';
import { ResourceFormScreen } from '@/domain/screens/resource-form-screen';
import { PropertyForm } from '@/features/ast/components/property-form';
import { useCreateProperty } from '@/features/ast/api/queries';
import { ASSETS_ARE_MOCK } from '@/features/ast/api';

/** Screen #83a — Property create. LIVE against POST /api/v1/properties. */
export default function NewPropertyPage() {
  const t = useTranslations('ast');
  const router = useRouter();
  const create = useCreateProperty();

  return (
    <ResourceFormScreen
      isMock={ASSETS_ARE_MOCK}
      breadcrumbLabel={t('breadcrumbLabel')}
      breadcrumb={[
        { label: t('properties.title'), href: '/console/assets/properties' },
        { label: t('properties.create') },
      ]}
      title={t('properties.create')}
    >
      <PropertyForm
        defaultValues={{}}
        isSubmitting={create.isPending}
        submitLabel={t('properties.create')}
        onSubmit={async (values) => {
          const created = await create.mutateAsync(values);
          toast.success(t('properties.created'));
          router.push(`/console/assets/properties/${created.id}`);
        }}
      />
    </ResourceFormScreen>
  );
}
