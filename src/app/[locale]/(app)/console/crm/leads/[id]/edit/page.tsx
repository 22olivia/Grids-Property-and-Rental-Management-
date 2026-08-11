'use client';

import { use } from 'react';
import { useTranslations } from 'next-intl';
import { ErrorState, LoadingState, toast } from '@/design-system/ui';
import { useRouter } from '@/lib/i18n/routing';
import { ResourceFormScreen } from '@/domain/screens/resource-form-screen';
import { LeadForm } from '@/features/crm/components/lead-form';
import { useLead, useUpdateLead } from '@/features/crm/api/queries';
import { CRM_IS_MOCK } from '@/features/crm/api';

/** Screen #108b — Lead edit. FR-CRM-001, FR-CRM-005. */
export default function EditLeadPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('crm');
  const tc = useTranslations('common');
  const router = useRouter();

  const { data: lead, isLoading, error, refetch } = useLead(id);
  const update = useUpdateLead(id);

  if (isLoading) return <LoadingState label={tc('loading')} />;
  if (error || !lead) {
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
      isMock={CRM_IS_MOCK}
      breadcrumbLabel={t('breadcrumbLabel')}
      breadcrumb={[
        { label: t('leads.title'), href: '/console/crm/leads' },
        { label: lead.name, href: `/console/crm/leads/${id}` },
        { label: tc('edit') },
      ]}
      title={lead.name}
    >
      <LeadForm
        defaultValues={{
          name: lead.name,
          email: lead.email,
          phone: lead.phone,
          source: lead.source,
          stage: lead.stage,
          budgetAmount: lead.budget?.amount ?? null,
          budgetCurrency: lead.budget?.currency ?? null,
          preferredCity: lead.preferredCity,
          preferredType: lead.preferredType,
          minAreaSqm: lead.minAreaSqm,
          nextActionNote: lead.nextActionNote,
        }}
        isSubmitting={update.isPending}
        submitLabel={tc('save')}
        onSubmit={async (values) => {
          await update.mutateAsync(values);
          toast.success(t('leads.updated'));
          router.push(`/console/crm/leads/${id}`);
        }}
      />
    </ResourceFormScreen>
  );
}
