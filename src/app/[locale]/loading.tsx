import { getTranslations } from 'next-intl/server';
import { LoadingState } from '@/design-system/ui';

export default async function Loading() {
  const t = await getTranslations('common');
  return <LoadingState label={t('loading')} />;
}
