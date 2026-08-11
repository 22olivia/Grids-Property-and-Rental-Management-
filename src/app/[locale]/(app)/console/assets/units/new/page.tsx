'use client';

import { useTranslations } from 'next-intl';
import { toast } from '@/design-system/ui';
import { useRouter } from '@/lib/i18n/routing';
import { ResourceFormScreen } from '@/domain/screens/resource-form-screen';
import { UnitForm } from '@/features/ast/components/unit-form';
import { useCreateUnit } from '@/features/ast/api/queries';
import { ASSETS_ARE_MOCK } from '@/features/ast/api';

/** Screen #88a — Unit create. LIVE against POST /api/v1/rental-units. */
export default function NewUnitPage() {
  const t = useTranslations('ast');
  const router = useRouter();
  const create = useCreateUnit();

  return (
    <ResourceFormScreen
      isMock={ASSETS_ARE_MOCK}
      breadcrumbLabel={t('breadcrumbLabel')}
      breadcrumb={[
        { label: t('units.title'), href: '/console/assets/units' },
        { label: t('units.create') },
      ]}
      title={t('units.create')}
    >
      <UnitForm
        defaultValues={{}}
        isSubmitting={create.isPending}
        submitLabel={t('units.create')}
        onSubmit={async (values) => {
          const created = await create.mutateAsync(values);
          toast.success(t('units.created'));
          router.push(`/console/assets/units/${created.id}`);
        }}
      />
    </ResourceFormScreen>
  );
}
