'use client';

import { useTranslations } from 'next-intl';
import { Check } from 'lucide-react';
import { Badge, Button, EmptyState, LoadingState } from '@/design-system/ui';
import { DateTimeDisplay } from './date-time-display';

/**
 * Activity log.
 *
 * FR-CRM-004 (Must): "record calls, notes, meetings, tasks, reminders,
 * messages and next actions".
 *
 * Generic over the activity vocabulary — the module supplies labels — because
 * tenants (FR-TEN-003) and maintenance (FR-MNT-002) need the same shape later.
 */
export interface TimelineActivity {
  id: string;
  type: string;
  summary: string;
  detail: string | null;
  actorName: string;
  occurredAt: string;
  dueAt: string | null;
  completed: boolean;
}

export function ActivityTimeline({
  activities,
  isLoading,
  typeLabel,
  onComplete,
}: {
  activities: TimelineActivity[] | undefined;
  isLoading: boolean;
  typeLabel: (type: string) => string;
  onComplete?: (id: string) => void;
}) {
  const t = useTranslations('crm');
  const tc = useTranslations('common');

  if (isLoading) return <LoadingState label={tc('loading')} />;
  if (!activities || activities.length === 0) {
    return (
      <EmptyState
        kind="no-data"
        title={t('activities.emptyTitle')}
        description={t('activities.emptyDescription')}
      />
    );
  }

  return (
    <ol className="flex flex-col gap-3">
      {activities.map((activity) => (
        <li
          key={activity.id}
          className="rounded-[var(--radius-md)] border border-[var(--color-border)] p-3"
        >
          <div className="flex flex-wrap items-center gap-2">
            <Badge tone="info">{typeLabel(activity.type)}</Badge>
            <span className="text-sm font-medium">{activity.summary}</span>
            {activity.dueAt && (
              <Badge tone={activity.completed ? 'success' : 'warning'}>
                {activity.completed ? t('activities.done') : t('activities.due')}
              </Badge>
            )}
            <span className="ms-auto text-xs text-[var(--color-text-muted)]">
              <DateTimeDisplay value={activity.occurredAt} withTime />
            </span>
          </div>

          {activity.detail && (
            <p className="mt-2 text-sm text-[var(--color-text-muted)]">{activity.detail}</p>
          )}

          <div className="mt-2 flex items-center gap-3">
            <span className="text-xs text-[var(--color-text-muted)]">
              {t('activities.by', { actor: activity.actorName })}
            </span>
            {activity.dueAt && !activity.completed && onComplete && (
              <Button
                variant="ghost"
                size="sm"
                className="ms-auto"
                onClick={() => onComplete(activity.id)}
              >
                <Check className="size-4" aria-hidden="true" />
                {t('activities.markDone')}
              </Button>
            )}
          </div>
        </li>
      ))}
    </ol>
  );
}
