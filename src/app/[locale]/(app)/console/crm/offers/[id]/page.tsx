'use client';

import { use, useState } from 'react';
import { useTranslations } from 'next-intl';
import { useForm } from 'react-hook-form';
import { zodResolver } from '@hookform/resolvers/zod';
import {
  Alert, Button, Card, CardBody, CardHeader, CardTitle, Field, Input, Textarea, toast,
} from '@/design-system/ui';
import { Link } from '@/lib/i18n/routing';
import { ResourceDetailScreen } from '@/domain/screens/resource-detail-screen';
import { MoneyDisplay } from '@/domain/components/money-display';
import { DateTimeDisplay } from '@/domain/components/date-time-display';
import { FormErrorSummary } from '@/domain/components/form-error-summary';
import { useOffer, useAddCounteroffer } from '@/features/crm/api/queries';
import { counterofferFormSchema, type CounterofferFormValues } from '@/features/crm/schemas/crm-schemas';
import { offerTone, offerStateLabelKey } from '@/features/crm/constants';
import { CRM_IS_MOCK } from '@/features/crm/api';

/**
 * Screen #116 — Offer detail and negotiation. FR-CRM-007.
 *
 * ---------------------------------------------------------------------------
 * MONEY: presentational only, per the standing instruction.
 *
 * Every amount here is SERVER-RECORDED and only formatted. The counteroffer
 * form captures a decimal STRING and submits it unchanged — no arithmetic, no
 * totals, no comparison against the original offer. Deposit handling
 * (FR-CRM-007) is displayed but not managed: deposits are financial postings
 * and belong to FIN, which is blocked on the money wire format (B7).
 * ---------------------------------------------------------------------------
 */
export default function OfferDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('crm');
  const tc = useTranslations('common');
  const [formErrors, setFormErrors] = useState<string[]>([]);

  const { data: offer, isLoading, error, refetch } = useOffer(id);
  const counter = useAddCounteroffer(id);

  const { register, handleSubmit, reset, formState: { errors } } = useForm<CounterofferFormValues>({
    resolver: zodResolver(counterofferFormSchema),
    defaultValues: { amount: '', currency: 'AED', note: null },
  });

  return (
    <ResourceDetailScreen
      isMock={CRM_IS_MOCK}
      breadcrumbLabel={t('breadcrumbLabel')}
      breadcrumb={[
        { label: t('offers.title'), href: '/console/crm/offers' },
        { label: offer?.reference ?? '' },
      ]}
      title={offer?.leadName ?? ''}
      reference={offer?.reference}
      status={
        offer ? { label: t(offerStateLabelKey(offer.state)), tone: offerTone(offer.state) } : undefined
      }
      isLoading={isLoading}
      error={error}
      onRetry={() => refetch()}
      notFoundCopy={{ title: t('detail.notFoundTitle'), description: t('detail.notFoundDescription') }}
      tabs={
        offer
          ? [
              {
                id: 'overview',
                label: t('tabs.overview'),
                content: (
                  <div className="grid gap-4 lg:grid-cols-2">
                    <Card record="money">
                      <CardHeader><CardTitle>{t('offers.terms')}</CardTitle></CardHeader>
                      <CardBody>
                        <dl className="flex flex-col gap-2 text-sm">
                          <div className="flex justify-between gap-3">
                            <dt className="text-[var(--color-text-muted)]">{t('field.amount')}</dt>
                            <dd><MoneyDisplay value={offer.amount} /></dd>
                          </div>
                          <div className="flex justify-between gap-3">
                            <dt className="text-[var(--color-text-muted)]">{t('field.deposit')}</dt>
                            <dd><MoneyDisplay value={offer.depositAmount} /></dd>
                          </div>
                          <div className="flex justify-between gap-3">
                            <dt className="text-[var(--color-text-muted)]">{t('field.expiresAt')}</dt>
                            <dd>{offer.expiresAt ? <DateTimeDisplay value={offer.expiresAt} withTime /> : '—'}</dd>
                          </div>
                          <div className="flex justify-between gap-3">
                            <dt className="text-[var(--color-text-muted)]">{t('field.listing')}</dt>
                            <dd>
                              {offer.listingId ? (
                                <Link
                                  href={`/console/listings/${offer.listingId}`}
                                  className="text-[var(--color-action)] underline-offset-4 hover:underline"
                                >
                                  {offer.listingTitle}
                                </Link>
                              ) : '—'}
                            </dd>
                          </div>
                        </dl>
                        <Alert tone="info" className="mt-4" title={t('offers.approvalBlockedTitle')}>
                          {t('offers.approvalBlockedBody')}
                        </Alert>
                      </CardBody>
                    </Card>

                    <Card record="money">
                      <CardHeader><CardTitle>{t('offers.negotiation')}</CardTitle></CardHeader>
                      <CardBody>
                        {offer.counteroffers.length === 0 ? (
                          <p className="text-sm text-[var(--color-text-muted)]">
                            {t('offers.noCounteroffers')}
                          </p>
                        ) : (
                          <ol className="flex flex-col gap-2">
                            {offer.counteroffers.map((item) => (
                              <li
                                key={item.id}
                                className="rounded-[var(--radius-md)] border border-[var(--color-border)] p-3"
                              >
                                <div className="flex items-center justify-between gap-3">
                                  <span className="text-sm font-medium">
                                    {t(`offers.party.${item.byParty}`)}
                                  </span>
                                  <MoneyDisplay value={item.amount} />
                                </div>
                                {item.note && (
                                  <p className="mt-1 text-sm text-[var(--color-text-muted)]">{item.note}</p>
                                )}
                                <p className="mt-1 text-xs text-[var(--color-text-subtle)]">
                                  <DateTimeDisplay value={item.createdAt} withTime />
                                </p>
                              </li>
                            ))}
                          </ol>
                        )}

                        <form
                          noValidate
                          className="mt-4 flex flex-col gap-3"
                          onSubmit={handleSubmit(async (values) => {
                            setFormErrors([]);
                            try {
                              await counter.mutateAsync(values);
                              toast.success(t('offers.counterAdded'));
                              reset();
                            } catch {
                              setFormErrors([tc('unexpectedError')]);
                            }
                          })}
                        >
                          <FormErrorSummary messages={formErrors} />
                          <div className="grid gap-3 sm:grid-cols-2">
                            <Field
                              label={t('field.counterAmount')}
                              required
                              error={errors.amount ? t('validation.amount') : undefined}
                            >
                              {/* Decimal string, submitted unchanged. */}
                              <Input {...register('amount')} inputMode="decimal" contentDirection="ltr" />
                            </Field>
                            <Field label={t('field.currency')} required>
                              <Input {...register('currency')} maxLength={3} contentDirection="ltr" />
                            </Field>
                          </div>
                          <Field label={t('field.note')}>
                            <Textarea {...register('note')} rows={2} />
                          </Field>
                          <div className="flex justify-end">
                            <Button
                              type="submit"
                              size="sm"
                              loading={counter.isPending}
                              loadingLabel={t('offers.addCounter')}
                            >
                              {t('offers.addCounter')}
                            </Button>
                          </div>
                        </form>
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
