import { getTranslations } from 'next-intl/server';
import { TableSkeleton, VisuallyHidden } from '@/design-system/ui';

/**
 * Section-level loading state.
 * Skeleton shaped like the table it replaces, so the layout does not shift
 * when content arrives.
 */
export default async function AssetsLoading() {
  const t = await getTranslations('common');
  return (
    <div role="status" aria-busy="true" aria-live="polite">
      <VisuallyHidden>{t('loading')}</VisuallyHidden>
      <TableSkeleton rows={8} columns={5} />
    </div>
  );
}
