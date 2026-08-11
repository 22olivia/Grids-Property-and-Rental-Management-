import { redirect } from 'next/navigation';

/**
 * Console index.
 *
 * Sends the user to the only module currently implemented. This is NOT the
 * executive dashboard (derived screen #72, FR-RPT-001) — that is a business
 * screen in an unapproved module.
 */
export default async function ConsoleIndexPage({
  params,
}: {
  params: Promise<{ locale: string }>;
}) {
  const { locale } = await params;
  redirect(`/${locale}/console/assets/properties`);
}
