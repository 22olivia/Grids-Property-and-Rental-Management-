'use client';

import { useTranslations } from 'next-intl';
import { ChevronDown, ChevronUp, Trash2, FileImage, FileText, Video, Box } from 'lucide-react';
import { Alert, Badge, Button, EmptyState, LoadingState, ConfirmDialog } from '@/design-system/ui';
import { useState } from 'react';

/**
 * ===========================================================================
 * Media manager — reordering and removal only. NO UPLOAD.
 * ===========================================================================
 *
 * FR-LST-007 (Should): "image galleries, video, floor plans, 360 tours,
 * documents and watermarking".
 *
 * Upload is NOT implemented, and that is deliberate. SRS §12 offers signed
 * upload URLs *or* multipart without choosing (MI-H5), and FR-MOB-008 implies
 * resumable transfer for large files — video and 360 tours. Building against a
 * guess would mean writing a chunking strategy, a progress model and a retry
 * policy that all have to be unpicked.
 *
 * Everything that does NOT depend on the transport is built: ordering,
 * removal, kind classification, watermark indication, empty and loading
 * states. Reordering uses buttons rather than drag-and-drop so it is keyboard
 * operable (WCAG 2.1.1) — drag can be added on top later, never instead.
 * ===========================================================================
 */

export interface MediaItem {
  id: string;
  kind: string;
  url: string | null;
  caption: string | null;
  position: number;
  watermarked: boolean;
}

const KIND_ICON: Record<string, typeof FileImage> = {
  image: FileImage,
  'floor-plan': FileText,
  video: Video,
  'tour-360': Box,
  document: FileText,
};

export function MediaManager({
  items,
  isLoading,
  onReorder,
  onRemove,
  kindLabel,
}: {
  items: MediaItem[] | undefined;
  isLoading: boolean;
  onReorder: (orderedIds: string[]) => void;
  onRemove: (id: string) => void;
  kindLabel: (kind: string) => string;
}) {
  const t = useTranslations('lst');
  const tc = useTranslations('common');
  const [pendingRemoval, setPendingRemoval] = useState<string | null>(null);

  if (isLoading) return <LoadingState label={tc('loading')} />;

  const ordered = [...(items ?? [])].sort((a, b) => a.position - b.position);

  function move(index: number, offset: number) {
    const next = [...ordered];
    const target = index + offset;
    if (target < 0 || target >= next.length) return;
    const moved = next[index];
    const displaced = next[target];
    if (!moved || !displaced) return;
    next[index] = displaced;
    next[target] = moved;
    onReorder(next.map((item) => item.id));
  }

  return (
    <div className="flex flex-col gap-4">
      <Alert tone="info" title={t('media.uploadUnavailableTitle')}>
        {t('media.uploadUnavailableBody')}
      </Alert>

      {ordered.length === 0 ? (
        <EmptyState
          kind="no-data"
          title={t('media.emptyTitle')}
          description={t('media.emptyDescription')}
        />
      ) : (
        <ol className="flex flex-col gap-2">
          {ordered.map((item, index) => {
            const Icon = KIND_ICON[item.kind] ?? FileImage;
            return (
              <li
                key={item.id}
                className="flex items-center gap-3 rounded-[var(--radius-md)] border border-[var(--color-border)] p-3"
              >
                <span className="tabular text-xs text-[var(--color-text-muted)]">{index + 1}</span>
                <Icon className="size-5 shrink-0 text-[var(--color-text-muted)]" aria-hidden="true" />
                <span className="text-sm">{item.caption ?? kindLabel(item.kind)}</span>
                <Badge tone="neutral">{kindLabel(item.kind)}</Badge>
                {item.watermarked && <Badge tone="info">{t('media.watermarked')}</Badge>}

                <span className="ms-auto flex items-center gap-1">
                  <Button
                    variant="ghost"
                    size="icon"
                    aria-label={t('media.moveEarlier', { position: index + 1 })}
                    disabled={index === 0}
                    onClick={() => move(index, -1)}
                  >
                    <ChevronUp className="size-4" aria-hidden="true" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="icon"
                    aria-label={t('media.moveLater', { position: index + 1 })}
                    disabled={index === ordered.length - 1}
                    onClick={() => move(index, 1)}
                  >
                    <ChevronDown className="size-4" aria-hidden="true" />
                  </Button>
                  <Button
                    variant="ghost"
                    size="icon"
                    aria-label={t('media.remove', { position: index + 1 })}
                    onClick={() => setPendingRemoval(item.id)}
                  >
                    <Trash2 className="size-4 text-[var(--color-danger)]" aria-hidden="true" />
                  </Button>
                </span>
              </li>
            );
          })}
        </ol>
      )}

      <ConfirmDialog
        open={pendingRemoval !== null}
        onOpenChange={(open) => !open && setPendingRemoval(null)}
        title={t('media.removeTitle')}
        description={t('media.removeDescription')}
        confirmLabel={t('media.removeConfirm')}
        cancelLabel={tc('cancel')}
        closeLabel={tc('close')}
        destructive
        onConfirm={() => {
          if (pendingRemoval) onRemove(pendingRemoval);
          setPendingRemoval(null);
        }}
      />
    </div>
  );
}
