'use client';

import { use } from 'react';
import { useTranslations } from 'next-intl';
import { Pencil, Images } from 'lucide-react';
import { Alert, Button, Card, CardBody, CardHeader, CardTitle, toast } from '@/design-system/ui';
import { Link } from '@/lib/i18n/routing';
import { ResourceDetailScreen } from '@/domain/screens/resource-detail-screen';
import { MoneyDisplay } from '@/domain/components/money-display';
import { DateTimeDisplay } from '@/domain/components/date-time-display';
import { WorkflowStepper } from '@/domain/components/workflow-stepper';
import { useListing, useListingEvents, useApplyTransition } from '@/features/lst/api/queries';
import { LISTING_STATES } from '@/features/lst/types';
import { listingStateTone, listingStateLabelKey, listingTypeLabelKey } from '@/features/lst/constants';
import { LISTINGS_ARE_MOCK } from '@/features/lst/api';

/** Screen #100 — Listing detail. FR-LST-003, FR-LST-006, FR-LST-008. */
export default function ListingDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('lst');
  const tc = useTranslations('common');

  const { data: listing, isLoading, error, refetch } = useListing(id);
  const { data: events, isLoading: eventsLoading } = useListingEvents(id);
  const transition = useApplyTransition(id);

  return (
    <ResourceDetailScreen
      isMock={LISTINGS_ARE_MOCK}
      breadcrumbLabel={t('breadcrumbLabel')}
      breadcrumb={[
        { label: t('listings.title'), href: '/console/listings' },
        { label: listing?.title ?? '' },
      ]}
      title={listing?.title ?? ''}
      reference={listing?.reference}
      status={
        listing
          ? {
              label: t(listingStateLabelKey(listing.state)),
              tone: listingStateTone(listing.state),
            }
          : undefined
      }
      actions={
        listing ? (
          <>
            <Button variant="secondary" asChild>
              <Link href={`/console/listings/${id}/media`}>
                <Images className="size-4" aria-hidden="true" />
                {t('media.title')}
              </Link>
            </Button>
            <Button variant="secondary" asChild>
              <Link href={`/console/listings/${id}/edit`}>
                <Pencil className="size-4" aria-hidden="true" />
                {tc('edit')}
              </Link>
            </Button>
          </>
        ) : undefined
      }
      isLoading={isLoading}
      error={error}
      onRetry={() => refetch()}
      notFoundCopy={{ title: t('detail.notFoundTitle'), description: t('detail.notFoundDescription') }}
      history={{
        label: t('tabs.history'),
        entries: events,
        isLoading: eventsLoading,
        categoryLabel: (category) => t(`history.category.${category}`),
      }}
      tabs={
        listing
          ? [
              {
                id: 'overview',
                label: t('tabs.overview'),
                content: (
                  <div className="grid gap-4 lg:grid-cols-2">
                    <Card record="listing">
                      <CardHeader><CardTitle>{t('form.details')}</CardTitle></CardHeader>
                      <CardBody>
                        <dl className="grid grid-cols-2 gap-3 text-sm">
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.type')}</dt>
                            <dd>{t(listingTypeLabelKey(listing.type))}</dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.price')}</dt>
                            <dd><MoneyDisplay value={listing.price} /></dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.areaSqm')}</dt>
                            <dd className="tabular">{listing.areaSqm ?? '—'}</dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.bedrooms')}</dt>
                            <dd className="tabular">{listing.bedrooms ?? '—'}</dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.bathrooms')}</dt>
                            <dd className="tabular">{listing.bathrooms ?? '—'}</dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.updatedAt')}</dt>
                            <dd><DateTimeDisplay value={listing.updatedAt} withTime /></dd>
                          </div>
                        </dl>
                        {listing.amenities.length > 0 && (
                          <p className="mt-3 text-sm">
                            <span className="text-xs text-[var(--color-text-muted)]">{t('field.amenities')}: </span>
                            {listing.amenities.map((a) => t(`amenity.${a}`)).join('، ')}
                          </p>
                        )}
                      </CardBody>
                    </Card>

                    {/* SRS §11 — the listing REFERENCES the asset. Kept as a
                        link rather than embedded data so the separation stays
                        visible in the interface too. */}
                    <Card record="asset">
                      <CardHeader><CardTitle>{t('form.linkedAsset')}</CardTitle></CardHeader>
                      <CardBody>
                        <dl className="flex flex-col gap-2 text-sm">
                          <div className="flex justify-between">
                            <dt className="text-[var(--color-text-muted)]">{t('field.property')}</dt>
                            <dd>
                              <Link
                                href={`/console/assets/properties/${listing.propertyId}`}
                                className="text-[var(--color-action)] underline-offset-4 hover:underline"
                              >
                                {listing.propertyName}
                              </Link>
                            </dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-[var(--color-text-muted)]">{t('field.unit')}</dt>
                            <dd>
                              {listing.unitId ? (
                                <Link
                                  href={`/console/assets/units/${listing.unitId}`}
                                  className="text-[var(--color-action)] underline-offset-4 hover:underline"
                                >
                                  {listing.unitName}
                                </Link>
                              ) : (
                                '—'
                              )}
                            </dd>
                          </div>
                        </dl>
                      </CardBody>
                    </Card>
                  </div>
                ),
              },
              {
                id: 'workflow',
                label: t('tabs.workflow'),
                content: (
                  <Card record="listing">
                    <CardHeader><CardTitle>{t('workflow.title')}</CardTitle></CardHeader>
                    {/* FR-LST-008 — the guard is server-decided; this displays
                        the reason so the approver knows why publish is off. */}
                    {listing.publishBlockedReason && (
                      <Alert tone="warning" title={t('workflow.blockedTitle')} className="mb-4">
                        {listing.publishBlockedReason}
                      </Alert>
                    )}
                    <WorkflowStepper
                      states={LISTING_STATES.map((state) => ({
                        id: state,
                        label: t(listingStateLabelKey(state)),
                      }))}
                      current={listing.state}
                      transitionsLabel={t('workflow.available')}
                      isPending={transition.isPending}
                      transitions={listing.availableTransitions.map((item) => ({
                        id: item.id,
                        label: t('workflow.moveTo', {
                          state: t(listingStateLabelKey(item.targetState)),
                        }),
                        targetState: item.targetState,
                        blockedReason: item.blockedReason,
                        tone: item.targetState === 'archived' ? 'danger' : undefined,
                      }))}
                      onTransition={async (item) => {
                        try {
                          await transition.mutateAsync(item.targetState as never);
                          toast.success(t('workflow.updated'));
                        } catch {
                          toast.error(t('workflow.failed'));
                        }
                      }}
                    />
                  </Card>
                ),
              },
            ]
          : []
      }
    />
  );
}
