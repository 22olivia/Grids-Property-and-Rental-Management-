import { getTranslations, setRequestLocale } from 'next-intl/server';
import { Card, CardBody, CardHeader, CardTitle } from '@/design-system/ui';

/**
 * FOUNDATION PLACEHOLDER — not a business screen.
 *
 * This route exists so the shell, layout, typography, tokens and RTL
 * behaviour are reachable in a browser during FE-0. It contains no
 * marketplace content: the home page (derived screen #1, FR-MKT-001) is not
 * in FE-0 scope and the approved scope is still pending.
 */
export default async function FoundationPlaceholderPage({
  params,
}: {
  // Next 15 delivers route params as a Promise. Typing this synchronously
  // compiled but threw at request time, which is the second reason GET /en
  // returned 500.
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  // Required for static rendering with next-intl — without it this route opts
  // into dynamic rendering, which is exactly what the public marketplace
  // cannot afford (FR-MKT-007 SEO, NFR-PERF-002 2s search budget).
  setRequestLocale(locale);
  // getTranslations, not useTranslations: hooks cannot be called in an async
  // Server Component, and this one must await `params`.
  const t = await getTranslations('foundation');

  return (
    <div className="mx-auto max-w-3xl p-6">
      <Card>
        <CardHeader>
          <CardTitle>{t('title')}</CardTitle>
        </CardHeader>
        <CardBody>{t('description')}</CardBody>
      </Card>
    </div>
  );
}
