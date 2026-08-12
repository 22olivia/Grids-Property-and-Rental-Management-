import type { Metadata } from 'next';
import { notFound } from 'next/navigation';
import { NextIntlClientProvider } from 'next-intl';
import { getMessages, setRequestLocale } from 'next-intl/server';
import { IBM_Plex_Sans, IBM_Plex_Sans_Arabic, IBM_Plex_Mono } from 'next/font/google';
import { locales, isLocale, getDirection } from '@/lib/i18n/config';
import { Providers } from '@/shell/providers';
import { SkipLink } from '@/shell/skip-link';
import '../globals.css';

/**
 * Typography.
 *
 * IBM Plex Sans and IBM Plex Sans Arabic are one superfamily with shared
 * metrics — they were designed together. That matters more than taste here:
 * the dominant typographic problem in this product is Latin and Arabic
 * sitting side by side at matched optical weight on every bilingual screen,
 * and pairing a fashionable Latin face with an unrelated Arabic face produces
 * mismatched colour that no amount of styling fixes later.
 *
 * Plex Mono carries machine-generated identifiers — invoice numbers,
 * correlation_id, coordinates — so a support agent reading a reference aloud
 * can tell it apart from prose.
 */
const plexSans = IBM_Plex_Sans({
  subsets: ['latin'],
  weight: ['400', '500', '600'],
  variable: '--font-plex-sans',
  display: 'swap',
});

const plexArabic = IBM_Plex_Sans_Arabic({
  subsets: ['arabic'],
  weight: ['400', '500', '600'],
  variable: '--font-plex-arabic',
  display: 'swap',
});

const plexMono = IBM_Plex_Mono({
  subsets: ['latin'],
  weight: ['400', '500'],
  variable: '--font-plex-mono',
  display: 'swap',
});

export function generateStaticParams() {
  return locales.map((locale) => ({ locale }));
}

export const metadata: Metadata = {
  // Product name only. No marketing copy — that is CMS content (FR-CMS-001)
  // and is not the frontend's to author.
  title: 'GPMS',
};

export default async function LocaleLayout({
  children,
  params,
}: {
  children: React.ReactNode;
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  if (!isLocale(locale)) notFound();

  setRequestLocale(locale);
  const messages = await getMessages();
  const direction = getDirection(locale);

  return (
    // lang and dir are set here and nowhere else in the application.
    // Every mirroring behaviour downstream derives from this one attribute.
    <html
      lang={locale}
      dir={direction}
      className={`${plexSans.variable} ${plexArabic.variable} ${plexMono.variable}`}
      suppressHydrationWarning
    >
      <body>
        <NextIntlClientProvider messages={messages}>
          {/* The session is loaded from the BFF, which reads the Sanctum
              token from an httpOnly cookie. The browser never holds a token. */}
          <Providers direction={direction}>
            <SkipLink />
            {children}
          </Providers>
        </NextIntlClientProvider>
      </body>
    </html>
  );
}
