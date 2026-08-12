'use client';

import { useTranslations } from 'next-intl';
import { Card, toast } from '@/design-system/ui';
import { MockDataNotice } from '@/domain/components/mock-data-notice';
import { CRM_IS_MOCK } from '@/features/crm/api';
import { PipelineBoard, type BoardColumn } from '@/domain/components/pipeline-board';
import { MoneyDisplay } from '@/domain/components/money-display';
import { usePipeline, useMoveStage } from '@/features/crm/api/queries';
import { PIPELINE_STAGES, type Lead, type PipelineStage } from '@/features/crm/types';
import { stageLabelKey } from '@/features/crm/constants';

/** Screen #106 — Pipeline board. FR-CRM-003. */
export default function PipelinePage() {
  const t = useTranslations('crm');
  const { data, isLoading } = usePipeline();
  const move = useMoveStage();

  const columns: BoardColumn<Lead>[] = PIPELINE_STAGES.map((stage) => ({
    id: stage,
    label: t(stageLabelKey(stage)),
    items: data?.[stage] ?? [],
  }));

  return (
    <div className="flex flex-col gap-4">
      <MockDataNotice active={CRM_IS_MOCK} />
      <h1 className="text-xl font-semibold">{t('pipeline.title')}</h1>

      <Card className="overflow-hidden">
        <PipelineBoard
          columns={columns}
          isLoading={isLoading}
          isPending={move.isPending}
          boardLabel={t('pipeline.boardLabel')}
          emptyColumnLabel={t('pipeline.emptyColumn')}
          itemKey={(lead) => lead.id}
          itemHref={(lead) => `/console/crm/leads/${lead.id}`}
          renderItem={(lead) => (
            <>
              <span className="block text-sm font-medium">{lead.name}</span>
              <span className="block text-xs text-[var(--color-text-muted)]">
                <MoneyDisplay value={lead.budget} />
              </span>
            </>
          )}
          moveLabel={(lead, target) => t('pipeline.moveLabel', { name: lead.name, stage: target })}
          noMoveLabel={(direction) => t(`pipeline.noMove.${direction}`)}
          onMove={async (lead, targetColumnId) => {
            try {
              await move.mutateAsync({ id: lead.id, stage: targetColumnId as PipelineStage });
              toast.success(t('pipeline.moved'));
            } catch {
              toast.error(t('pipeline.moveFailed'));
            }
          }}
        />
      </Card>
    </div>
  );
}
