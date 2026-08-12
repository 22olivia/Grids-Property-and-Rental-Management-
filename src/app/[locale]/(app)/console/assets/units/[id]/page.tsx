'use client';

import { use } from 'react';
import { useTranslations } from 'next-intl';
import { Pencil } from 'lucide-react';
import { Alert, Badge, Button, Card, CardBody, CardHeader, CardTitle, toast } from '@/design-system/ui';
import { Link, useRouter } from '@/lib/i18n/routing';
import { ResourceDetailScreen } from '@/domain/screens/resource-detail-screen';
import { DeleteAction } from '@/domain/components/delete-action';
import { MoneyDisplay } from '@/domain/components/money-display';
import { DateTimeDisplay } from '@/domain/components/date-time-display';
import { useUnit, useDeleteUnit } from '@/features/ast/api/queries';
import { unitStatusLabelKey, unitStatusTone } from '@/features/ast/constants';
import { ASSETS_ARE_MOCK } from '@/features/ast/api';

/**
 * Screen #87 — Unit detail. LIVE against GET /api/v1/rental-units/{id}.
 *
 * Two tabs were REMOVED during integration:
 *   Availability timeline (FR-AST-003) — no endpoint exists
 *   Change history (FR-AST-008)        — no endpoint exists
 *
 * Both are recorded in the backend contract request. They are not stubbed with
 * mock data, for the reason given on the property detail screen.
 */
export default function UnitDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('ast');
  const tc = useTranslations('common');
  const router = useRouter();

  const remove = useDeleteUnit();
  const { data: unit, isLoading, error, refetch } = useUnit(id);

  return (
    <ResourceDetailScreen
      isMock={ASSETS_ARE_MOCK}
      breadcrumbLabel={t('breadcrumbLabel')}
      breadcrumb={[
        { label: t('units.title'), href: '/console/assets/units' },
        { label: unit?.unitNumber ?? '' },
      ]}
      title={unit?.unitNumber ?? ''}
      status={
        unit ? { label: t(unitStatusLabelKey(unit.status)), tone: unitStatusTone(unit.status) } : undefined
      }
      actions={
        unit ? (
          <>
          <Button variant="secondary" asChild>
            <Link href={`/console/assets/units/${id}/edit`}>
              <Pencil className="size-4" aria-hidden="true" />
              {tc('edit')}
            </Link>
          </Button>
          <DeleteAction
            label={tc('delete')}
            title={t('units.deleteTitle')}
            description={t('units.deleteDescription')}
            confirmLabel={t('units.deleteConfirm')}
            onDelete={() => remove.mutateAsync(id)}
            onDeleted={() => {
              toast.success(t('units.deleted'));
              router.push('/console/assets/units');
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
        unit
          ? [
              {
                id: 'overview',
                label: t('tabs.overview'),
                content: (
                  <div className="grid gap-4 lg:grid-cols-2">
                    <Card record="asset">
                      <CardHeader><CardTitle>{t('form.attributes')}</CardTitle></CardHeader>
                      <CardBody>
                        <dl className="grid grid-cols-2 gap-3 text-sm">
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.unitType')}</dt>
                            <dd>{unit.unitType ?? '—'}</dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.furnishingStatus')}</dt>
                            <dd>{unit.furnishingStatus ?? '—'}</dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.bedrooms')}</dt>
                            <dd className="tabular">{unit.bedrooms ?? '—'}</dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.bathrooms')}</dt>
                            <dd className="tabular">{unit.bathrooms ?? '—'}</dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.squareFeet')}</dt>
                            <dd className="tabular">{unit.squareFeet ?? '—'}</dd>
                          </div>
                          <div>
                            <dt className="text-xs text-[var(--color-text-muted)]">{t('field.areaSqm')}</dt>
                            <dd className="tabular">{unit.areaSqm ?? '—'}</dd>
                          </div>
                        </dl>
                        {unit.amenities.length > 0 && (
                          <p className="mt-3 flex flex-wrap gap-1">
                            {unit.amenities.map((amenity) => (
                              <Badge key={amenity} tone="neutral">{amenity}</Badge>
                            ))}
                          </p>
                        )}
                      </CardBody>
                    </Card>

                    <Card record="money">
                      <CardHeader><CardTitle>{t('form.money')}</CardTitle></CardHeader>
                      <CardBody>
                        <dl className="flex flex-col gap-2 text-sm">
                          <div className="flex justify-between">
                            <dt className="text-[var(--color-text-muted)]">{t('field.rent')}</dt>
                            <dd><MoneyDisplay value={unit.monthlyRent} /></dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-[var(--color-text-muted)]">{t('field.maintenanceChargeShort')}</dt>
                            <dd><MoneyDisplay value={unit.maintenanceCharge} /></dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-[var(--color-text-muted)]">{t('field.depositShort')}</dt>
                            <dd><MoneyDisplay value={unit.depositAmount} /></dd>
                          </div>
                        </dl>
                        <p className="mt-3 text-xs text-[var(--color-text-muted)]">
                          {t('field.currencyNote')}
                        </p>
                      </CardBody>
                    </Card>

                    <Card record="asset">
                      <CardHeader><CardTitle>{t('form.placement')}</CardTitle></CardHeader>
                      <CardBody>
                        <dl className="flex flex-col gap-2 text-sm">
                          <div className="flex justify-between">
                            <dt className="text-[var(--color-text-muted)]">{t('field.property')}</dt>
                            <dd>
                              <Link
                                href={`/console/assets/properties/${unit.propertyId}`}
                                className="text-[var(--color-action)] underline-offset-4 hover:underline"
                              >
                                {unit.propertyName ?? unit.propertyId}
                              </Link>
                            </dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-[var(--color-text-muted)]">{t('field.building')}</dt>
                            <dd>{unit.buildingName ?? '—'}</dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-[var(--color-text-muted)]">{t('field.floor')}</dt>
                            <dd>{unit.floorName ?? '—'}</dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-[var(--color-text-muted)]">{t('field.isListed')}</dt>
                            <dd>{unit.isListed ? tc('yes') : tc('no')}</dd>
                          </div>
                          <div className="flex justify-between">
                            <dt className="text-[var(--color-text-muted)]">{t('field.updatedAt')}</dt>
                            <dd><DateTimeDisplay value={unit.updatedAt} withTime /></dd>
                          </div>
                        </dl>
                        <Alert tone="info" className="mt-4" title={t('detail.timelineUnavailableTitle')}>
                          {t('detail.timelineUnavailableBody')}
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
