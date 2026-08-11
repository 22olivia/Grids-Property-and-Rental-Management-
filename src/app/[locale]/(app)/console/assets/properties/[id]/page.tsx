'use client';

import { use } from 'react';
import { useTranslations } from 'next-intl';
import { Pencil } from 'lucide-react';
import { Alert, Button, Card, CardBody, CardHeader, CardTitle, toast } from '@/design-system/ui';
import { Link, useRouter } from '@/lib/i18n/routing';
import { ResourceDetailScreen } from '@/domain/screens/resource-detail-screen';
import { DeleteAction } from '@/domain/components/delete-action';
import { DateTimeDisplay } from '@/domain/components/date-time-display';
import { useProperty, useDeleteProperty } from '@/features/ast/api/queries';
import { propertyStatusTone, propertyStatusLabelKey, propertyTypeLabelKey } from '@/features/ast/constants';
import { ASSETS_ARE_MOCK } from '@/features/ast/api';

/**
 * Screen #82 — Property detail. LIVE against GET /api/v1/properties/{id}.
 *
 * The History tab is GONE. FR-AST-008 requires change traceability, but the
 * backend exposes no endpoint (the ActivityLog model exists with no route).
 * A tab fed by mock data next to real property data would make invented
 * history indistinguishable from audited history — the one place a placeholder
 * is genuinely unsafe. A notice states the gap instead.
 */
export default function PropertyDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('ast');
  const tc = useTranslations('common');
  const router = useRouter();

  const remove = useDeleteProperty();
  const { data: property, isLoading, error, refetch } = useProperty(id);

  return (
    <ResourceDetailScreen
      isMock={ASSETS_ARE_MOCK}
      breadcrumbLabel={t('breadcrumbLabel')}
      breadcrumb={[
        { label: t('properties.title'), href: '/console/assets/properties' },
        { label: property?.name ?? '' },
      ]}
      title={property?.name ?? ''}
      status={
        property
          ? {
              label: t(propertyStatusLabelKey(property.status)),
              tone: propertyStatusTone(property.status),
            }
          : undefined
      }
      actions={
        property ? (
          <>
          <Button variant="secondary" asChild>
            <Link href={`/console/assets/properties/${id}/edit`}>
              <Pencil className="size-4" aria-hidden="true" />
              {tc('edit')}
            </Link>
          </Button>
          <DeleteAction
            label={tc('delete')}
            title={t('properties.deleteTitle')}
            description={t('properties.deleteDescription')}
            confirmLabel={t('properties.deleteConfirm')}
            onDelete={() => remove.mutateAsync(id)}
            onDeleted={() => {
              toast.success(t('properties.deleted'));
              router.push('/console/assets/properties');
            }}
          />
          </>
        ) : undefined
      }
      isLoading={isLoading}
      error={error}
      onRetry={() => refetch()}
      notFoundCopy={{ title: t('detail.notFoundTitle'), description: t('detail.notFoundDescription') }}
      tabs={
        property
          ? [
              {
                id: 'overview',
                label: t('tabs.overview'),
                content: (
                  <div className="grid gap-4 lg:grid-cols-2">
                    <Card record="asset">
                      <CardHeader><CardTitle>{t('form.location')}</CardTitle></CardHeader>
                      <CardBody>
                        <address className="not-italic">
                          {property.address.line1}
                          {property.address.line2 && <><br />{property.address.line2}</>}
                          <br />
                          {property.address.city}
                          {property.address.state && `, ${property.address.state}`}
                          <br />
                          {property.address.country} {property.address.postalCode}
                        </address>
                        {property.coordinates && (
                          <p className="mt-3 text-sm">
                            {/* Latin-numeric: pinned LTR inside an Arabic page. */}
                            <span dir="ltr" className="reference">
                              {property.coordinates.latitude}, {property.coordinates.longitude}
                            </span>
                          </p>
                        )}
                      </CardBody>
                    </Card>

                    <Card record="asset">
                      <CardHeader><CardTitle>{t('detail.inventory')}</CardTitle></CardHeader>
                      <CardBody>
                        <dl className="grid grid-cols-2 gap-3">
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.propertyType')}</dt>
                            <dd>{property.type ? t(propertyTypeLabelKey(property.type)) : '—'}</dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.unitCount')}</dt>
                            <dd className="tabular text-lg">{property.unitCount}</dd>
                          </div>
                          <div>
                            {/* total_units is a separate manually-maintained
                                column and can disagree with the relation
                                count. Both are shown rather than reconciled. */}
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.totalUnits')}</dt>
                            <dd className="tabular text-lg">{property.totalUnits ?? '—'}</dd>
                          </div>
                        </dl>
                        <Link
                          href={`/console/assets/units?property_id=${property.id}`}
                          className="mt-3 inline-block text-[var(--color-action)] underline-offset-4 hover:underline"
                        >
                          {t('detail.viewUnits')}
                        </Link>
                      </CardBody>
                    </Card>

                    <Card record="party">
                      <CardHeader><CardTitle>{t('field.owner')}</CardTitle></CardHeader>
                      <CardBody>
                        <p className="text-sm">{property.owner?.fullName ?? '—'}</p>
                        {property.owner?.email && (
                          <p dir="ltr" className="text-sm text-[var(--color-text-muted)]">
                            {property.owner.email}
                          </p>
                        )}
                      </CardBody>
                    </Card>

                    <Card record="asset">
                      <CardHeader><CardTitle>{t('detail.record')}</CardTitle></CardHeader>
                      <CardBody>
                        <dl className="flex flex-col gap-2 text-sm">
                          <div className="flex justify-between">
                            <dt className="text-[var(--color-text-muted)]">{t('field.createdAt')}</dt>
                            <dd><DateTimeDisplay value={property.createdAt} /></dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-[var(--color-text-muted)]">{t('field.updatedAt')}</dt>
                            <dd><DateTimeDisplay value={property.updatedAt} withTime /></dd>
                          </div>
                        </dl>
                        <Alert tone="info" className="mt-4" title={t('detail.historyUnavailableTitle')}>
                          {t('detail.historyUnavailableBody')}
                        </Alert>
                      </CardBody>
                    </Card>
                  </div>
                ),
              },
            ]
          : []
      }
    />
  );
}
