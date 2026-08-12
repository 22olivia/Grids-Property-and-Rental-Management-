'use client';

import { use } from 'react';
import { useTranslations } from 'next-intl';
import {
  Breadcrumb, Card, CardHeader, CardTitle, EmptyState, ErrorState, LoadingState,
  TableContainer, Table, TableCaption, TableHead, TableBody, TableRow,
  TableHeaderCell, TableCell, VisuallyHidden,
} from '@/design-system/ui';
import { MockDataNotice } from '@/domain/components/mock-data-notice';
import { ASSETS_ARE_MOCK } from '@/features/ast/api';
import { useBuilding, useFloors } from '@/features/ast/api/queries';

/**
 * Screen #85 — Building detail and floors.
 * LIVE against GET /api/v1/buildings/{id} (floors arrive eagerly loaded).
 *
 * Floors are read-only here. The backend has POST /buildings/{id}/floors but
 * no update or delete, so an editor would offer actions that cannot complete.
 */
export default function BuildingDetailPage({ params }: { params: Promise<{ id: string }> }) {
  const { id } = use(params);
  const t = useTranslations('ast');
  const tc = useTranslations('common');

  const { data: building, isLoading, error, refetch } = useBuilding(id);
  const { data: floors, isLoading: floorsLoading } = useFloors(id);

  if (isLoading) return <LoadingState label={tc('loading')} />;
  if (error || !building) {
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
      <MockDataNotice active={ASSETS_ARE_MOCK} />
      <Breadcrumb
        label={t('breadcrumbLabel')}
        items={[
          { label: t('buildings.title'), href: '/console/assets/buildings' },
          { label: building.name },
        ]}
      />
      <h1 className="text-xl font-semibold">{building.name}</h1>

      <Card record="asset">
        <CardHeader><CardTitle>{t('buildings.floors')}</CardTitle></CardHeader>

        {floorsLoading ? (
          <LoadingState label={tc('loading')} />
        ) : !floors || floors.length === 0 ? (
          <EmptyState
            kind="no-data"
            title={t('buildings.noFloorsTitle')}
            description={t('buildings.noFloorsDescription')}
          />
        ) : (
          <TableContainer>
            <Table>
              <TableCaption>
                <VisuallyHidden>{t('buildings.floorsCaption')}</VisuallyHidden>
              </TableCaption>
              <TableHead>
                <TableRow>
                  <TableHeaderCell>{t('field.name')}</TableHeaderCell>
                  <TableHeaderCell numeric>{t('field.level')}</TableHeaderCell>
                </TableRow>
              </TableHead>
              <TableBody>
                {floors.map((floor) => (
                  <TableRow key={floor.id}>
                    <TableCell>{floor.name}</TableCell>
                    <TableCell numeric>{floor.level}</TableCell>
                  </TableRow>
                ))}
              </TableBody>
            </Table>
          </TableContainer>
        )}
      </Card>
    </div>
  );
}
