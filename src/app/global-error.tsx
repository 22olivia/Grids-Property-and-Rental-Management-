'use client';

/**
 * Last-resort boundary. Replaces the root layout, so it must render its own
 * <html> and <body> — and cannot use translations, because the i18n provider
 * lives inside the layout that has failed. English only, deliberately.
 */
export default function GlobalError({ reset }: { error: Error; reset: () => void }) {
  return (
    <html lang="en" dir="ltr">
      <body style={{ fontFamily: 'system-ui, sans-serif', padding: '2rem' }}>
        <main>
          <h1>Something went wrong</h1>
          <p>The application could not be loaded. Please try again.</p>
          <button type="button" onClick={reset}>
            Try again
          </button>
        </main>
      </body>
    </html>
  );
}
