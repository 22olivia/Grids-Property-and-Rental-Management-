'use client';

import { useTranslations } from 'next-intl';
import { Button, Card } from '@/design-system/ui';
import { MockDataNotice } from '@/domain/components/mock-data-notice';
import { CRM_IS_MOCK } from '@/features/crm/api';
import { ScheduleCalendar, type ScheduleEntry } from '@/domain/components/schedule-calendar';
import { DataTable, type DataTableColumn } from '@/domain/components/data-table';
import { FilterBar } from '@/domain/components/filter-bar';
import { StatusPill } from '@/domain/components/status-pill';
import { DateTimeDisplay } from '@/domain/components/date-time-display';
import { useTableState } from '@/lib/tables/use-table-state';
import { toListQuery } from '@/lib/tables/to-list-query';
import { toDisplayError } from '@/lib/api/display-error';
import { useViewings } from '@/features/crm/api/queries';
import { VIEWING_STATUSES, type Viewing } from '@/features/crm/types';
import { viewingTone, viewingStatusLabelKey } from '@/features/crm/constants';

/**
 * Screen #112 — Viewings. FR-CRM-006.
 *
 * Two views over one dataset: a schedule (grouped by day) and a table. The
 * view lives in the URL like every other list preference, so a colleague can
 * be sent either one.
 */
export default function ViewingsPage() {
  const t = useTranslations('crm');
  const tc = useTranslations('common');
  // `view` is a layout choice, not a filter — see displayParams.
  const table = useTableState({ sort: 'scheduledFor', displayParams: ['view'] });
  const query = useViewings(toListQuery(table.state));

  const view = table.displayParam('view') === 'table' ? 'table' : 'schedule';

  const entries: ScheduleEntry[] = (query.data?.items ?? []).map((viewing) => ({
    id: viewing.id,
    startsAt: viewing.scheduledFor,
    title: viewing.leadName,
    subtitle: viewing.listingTitle,
    status: {
      label: t(viewingStatusLabelKey(viewing.status)),
      tone: viewingTone(viewing.status),
    },
    href: `/console/crm/viewings/${viewing.id}`,
  }));

  const columns: DataTableColumn<Viewing>[] = [
    { id: 'leadName', header: t('field.lead'), priority: 'primary', cell: (r) => <span className="font-medium">{r.leadName}</span> },
    { id: 'listingTitle', header: t('field.listing'), priority: 'secondary', cell: (r) => r.listingTitle ?? '—' },
    { id: 'scheduledFor', header: t('field.scheduledFor'), sortable: true, priority: 'primary', cell: (r) => <DateTimeDisplay value={r.scheduledFor} withTime /> },
    { id: 'agentName', header: t('field.agent'), priority: 'meta', cell: (r) => r.agentName ?? '—' },
    { id: 'status', header: t('field.status'), priority: 'secondary', cell: (r) => <StatusPill label={t(viewingStatusLabelKey(r.status))} tone={viewingTone(r.status)} /> },
  ];

  return (
    <div className="flex flex-col gap-4">
      <MockDataNotice active={CRM_IS_MOCK} />
      <div className="flex flex-wrap items-center gap-3">
        <h1 className="text-xl font-semibold">{t('viewings.title')}</h1>
        {/* aria-pressed communicates which view is active to screen readers —
            visual emphasis alone does not. */}
        <div className="ms-auto flex gap-2">
          <Button
            variant={view === 'schedule' ? 'primary' : 'secondary'}
            size="sm"
            aria-pressed={view === 'schedule'}
            onClick={() => table.setDisplayParam('view', null)}
          >
            {t('viewings.scheduleView')}
          </Button>
          <Button
            variant={view === 'table' ? 'primary' : 'secondary'}
            size="sm"
            aria-pressed={view === 'table'}
            onClick={() => table.setDisplayParam('view', 'table')}
          >
            {t('viewings.tableView')}
          </Button>
        </div>
      </div>

      <Card className="flex flex-col gap-4">
        <FilterBar
          state={table.state}
          filters={[
            { id: 'status', labelKey: 'crm.field.status', options: VIEWING_STATUSES.map((v) => ({ value: v, labelKey: `crm.viewingStatus.${v}` })) },
          ]}
          onChange={table.update}
          onClear={table.clearFilters}
          hasFilters={table.hasFilters}
          resultCount={query.data?.total ?? null}
          searchLabel={t('viewings.search')}
        />

        {view === 'schedule' ? (
          <ScheduleCalendar entries={entries} isLoading={query.isLoading} />
        ) : (
          <DataTable
            columns={columns}
            rows={query.data?.items ?? []}
            rowKey={(r) => r.id}
            caption={t('viewings.tableCaption')}
            state={table.state}
            hasFilters={table.hasFilters}
            onSort={table.toggleSort}
            onPageChange={(page) => table.update({ page })}
            onClearFilters={table.clearFilters}
            total={query.data?.total ?? null}
            isLoading={query.isLoading}
            isFetching={query.isFetching}
            error={toDisplayError(query.error, tc('unexpectedError'))}
            onRetry={query.refetch}
            rowHref={(r) => `/console/crm/viewings/${r.id}`}
            record="party"
            emptyNoData={{ title: t('viewings.emptyTitle'), description: t('viewings.emptyDescription') }}
          />
        )}
      </Card>
    </div>
  );
}
