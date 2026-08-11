'use client';

import { use } from 'react';
import { useTranslations } from 'next-intl';
import { useQueryClient } from '@tanstack/react-query';
import { Breadcrumb, Card, CardHeader, CardTitle } from '@/design-system/ui';
import { MockDataNotice } from '@/domain/components/mock-data-notice';
import { LISTINGS_ARE_MOCK } from '@/features/lst/api';
import { MediaManager } from '@/domain/components/media-manager';
import { useListing, useListingMedia, lstKeys } from '@/features/lst/api/queries';
import { listingRepository } from '@/features/lst/api';
import { mediaKindLabelKey } from '@/features/lst/constants';

/**
 * Screen #102 — Listing media manager. FR-LST-007.
 *
 * Ordering and removal are complete. Upload is not — the transport is
 * undecided (MI-H5) and guessing it would mean a chunking, progress and retry
 * design that has to be unpicked. See MediaManager.
 */
export default function ListingMediaPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('lst');
  const client = useQueryClient();

  const { data: listing } = useListing(id);
  const { data: media, isLoading } = useListingMedia(id);

  return (
    <div className="flex flex-col gap-4">
      <MockDataNotice active={LISTINGS_ARE_MOCK} />
      <Breadcrumb
        label={t('breadcrumbLabel')}
        items={[
          { label: t('listings.title'), href: '/console/listings' },
          { label: listing?.title ?? '', href: `/console/listings/${id}` },
          { label: t('media.title') },
        ]}
      />
      <h1 className="text-xl font-semibold">{t('media.title')}</h1>

      <Card record="listing">
        <CardHeader><CardTitle>{listing?.title ?? ''}</CardTitle></CardHeader>
        <MediaManager
          items={media}
          isLoading={isLoading}
          kindLabel={(kind) => t(mediaKindLabelKey(kind))}
          onReorder={async (orderedIds) => {
            await listingRepository.reorderMedia(id, orderedIds);
            client.invalidateQueries({ queryKey: lstKeys.media(id) });
          }}
          onRemove={async (mediaId) => {
            await listingRepository.removeMedia(id, mediaId);
            client.invalidateQueries({ queryKey: lstKeys.media(id) });
          }}
        />
      </Card>
    </div>
  );
}
