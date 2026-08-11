'use client';

import { use } from 'react';
import { useTranslations } from 'next-intl';
import { Breadcrumb, ErrorState, LoadingState, toast } from '@/design-system/ui';
import { useRouter } from '@/lib/i18n/routing';
import { MockDataNotice } from '@/domain/components/mock-data-notice';
import { LISTINGS_ARE_MOCK } from '@/features/lst/api';
import { ListingForm } from '@/features/lst/components/listing-form';
import { useListing, useUpdateListing } from '@/features/lst/api/queries';

/** Screen #101b — Listing edit. FR-LST-003. */
export default function EditListingPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('lst');
  const tc = useTranslations('common');
  const router = useRouter();

  const { data: listing, isLoading, error, refetch } = useListing(id);
  const update = useUpdateListing(id);

  if (isLoading) return <LoadingState label={tc('loading')} />;
  if (error || !listing) {
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
    <div className="flex flex-col gap-4">
      <MockDataNotice active={LISTINGS_ARE_MOCK} />
      <Breadcrumb
        label={t('breadcrumbLabel')}
        items={[
          { label: t('listings.title'), href: '/console/listings' },
          { label: listing.title, href: `/console/listings/${id}` },
          { label: tc('edit') },
        ]}
      />
      <h1 className="text-xl font-semibold">{listing.title}</h1>
      <ListingForm
        defaultValues={{
          title: listing.title,
          reference: listing.reference,
          type: listing.type,
          propertyId: listing.propertyId,
          unitId: listing.unitId,
          priceAmount: listing.price?.amount ?? null,
          priceCurrency: listing.price?.currency ?? null,
          areaSqm: listing.areaSqm,
          bedrooms: listing.bedrooms,
          bathrooms: listing.bathrooms,
          amenities: listing.amenities,
          city: listing.location.city,
          neighborhood: listing.location.neighborhood,
          landmark: listing.location.landmark,
          legalStatus: listing.legalStatus,
          availableFrom: listing.availableFrom,
        }}
        isSubmitting={update.isPending}
        submitLabel={tc('save')}
        onSubmit={async (values) => {
          await update.mutateAsync(values);
          toast.success(t('listings.updated'));
          router.push(`/console/listings/${id}`);
        }}
      />
    </div>
  );
}
