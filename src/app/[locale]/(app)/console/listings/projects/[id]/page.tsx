'use client';

import { use } from 'react';
import { useTranslations } from 'next-intl';
import {
  Breadcrumb, Card, CardHeader, CardTitle, ErrorState, LoadingState,
  TableContainer, Table, TableCaption, TableHead, TableBody, TableRow,
  TableHeaderCell, TableCell, VisuallyHidden,
} from '@/design-system/ui';
import { MockDataNotice } from '@/domain/components/mock-data-notice';
import { LISTINGS_ARE_MOCK } from '@/features/lst/api';
import { MoneyDisplay } from '@/domain/components/money-display';
import { useProject } from '@/features/lst/api/queries';

/** Screen #104 — Project inventory management. FR-LST-002. */
export default function ProjectDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('lst');
  const tc = useTranslations('common');
  const { data: project, isLoading, error, refetch } = useProject(id);

  if (isLoading) return <LoadingState label={tc('loading')} />;
  if (error || !project) {
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
          { label: t('projects.title'), href: '/console/listings/projects' },
          { label: project.name },
        ]}
      />
      <h1 className="text-xl font-semibold">{project.name}</h1>

      <Card record="listing">
        <CardHeader><CardTitle>{t('projects.inventory')}</CardTitle></CardHeader>
        <TableContainer>
          <Table>
            <TableCaption>
              <VisuallyHidden>{t('projects.inventoryCaption')}</VisuallyHidden>
            </TableCaption>
            <TableHead>
              <TableRow>
                <TableHeaderCell>{t('field.unitType')}</TableHeaderCell>
                <TableHeaderCell numeric>{t('field.totalUnits')}</TableHeaderCell>
                <TableHeaderCell numeric>{t('field.availableUnits')}</TableHeaderCell>
                <TableHeaderCell numeric>{t('field.areaRange')}</TableHeaderCell>
                <TableHeaderCell numeric>{t('field.priceRange')}</TableHeaderCell>
              </TableRow>
            </TableHead>
            <TableBody>
              {project.unitTypes.map((type) => (
                <TableRow key={type.id}>
                  <TableCell>{type.name}</TableCell>
                  <TableCell numeric>{type.totalUnits}</TableCell>
                  <TableCell numeric>{type.availableUnits}</TableCell>
                  <TableCell numeric>
                    {type.areaSqmFrom ?? '—'} – {type.areaSqmTo ?? '—'}
                  </TableCell>
                  <TableCell numeric>
                    <span className="inline-flex items-center gap-1">
                      <MoneyDisplay value={type.priceFrom} />
                      <span aria-hidden="true">–</span>
                      <MoneyDisplay value={type.priceTo} />
                    </span>
                  </TableCell>
                </TableRow>
              ))}
            </TableBody>
          </Table>
        </TableContainer>
      </Card>
    </div>
  );
}
