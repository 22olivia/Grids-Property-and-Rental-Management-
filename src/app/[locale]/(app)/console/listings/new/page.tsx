'use client';

import { useTranslations } from 'next-intl';
import { Breadcrumb, toast } from '@/design-system/ui';
import { useRouter } from '@/lib/i18n/routing';
import { MockDataNotice } from '@/domain/components/mock-data-notice';
import { LISTINGS_ARE_MOCK } from '@/features/lst/api';
import { ListingForm } from '@/features/lst/components/listing-form';
import { useCreateListing } from '@/features/lst/api/queries';

/** Screen #101a — Listing create. FR-LST-001, FR-LST-002, FR-LST-003. */
export default function NewListingPage() {
  const t = useTranslations('lst');
  const router = useRouter();
  const create = useCreateListing();

  return (
    <div className="flex flex-col gap-4">
      <MockDataNotice active={LISTINGS_ARE_MOCK} />
      <Breadcrumb
        label={t('breadcrumbLabel')}
        items={[
          { label: t('listings.title'), href: '/console/listings' },
          { label: t('listings.create') },
        ]}
      />
      <h1 className="text-xl font-semibold">{t('listings.create')}</h1>
      <ListingForm
        defaultValues={{}}
        isSubmitting={create.isPending}
        submitLabel={t('listings.create')}
        onSubmit={async (values) => {
          const created = await create.mutateAsync(values);
          toast.success(t('listings.created'));
          router.push(`/console/listings/${created.id}`);
        }}
      />
    </div>
  );
}
