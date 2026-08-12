'use client';

import { useTranslations } from 'next-intl';
import { toast } from '@/design-system/ui';
import { useRouter } from '@/lib/i18n/routing';
import { ResourceFormScreen } from '@/domain/screens/resource-form-screen';
import { LeadForm } from '@/features/crm/components/lead-form';
import { useCreateLead } from '@/features/crm/api/queries';
import { CRM_IS_MOCK } from '@/features/crm/api';

/** Screen #108a — Lead create. FR-CRM-001. */
export default function NewLeadPage() {
  const t = useTranslations('crm');
  const router = useRouter();
  const create = useCreateLead();

  return (
    <ResourceFormScreen
      isMock={CRM_IS_MOCK}
      breadcrumbLabel={t('breadcrumbLabel')}
      breadcrumb={[
        { label: t('leads.title'), href: '/console/crm/leads' },
        { label: t('leads.create') },
      ]}
      title={t('leads.create')}
    >
      <LeadForm
        defaultValues={{}}
        isSubmitting={create.isPending}
        submitLabel={t('leads.create')}
        onSubmit={async (values) => {
          const created = await create.mutateAsync(values);
          toast.success(t('leads.created'));
          router.push(`/console/crm/leads/${created.id}`);
        }}
      />
    </ResourceFormScreen>
  );
}
