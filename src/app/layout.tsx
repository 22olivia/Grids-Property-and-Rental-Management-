import type { ReactNode } from 'react';

/**
 * Root layout.
 *
 * Intentionally minimal: <html> and <body> are emitted by the locale layout,
 * because lang and dir cannot be known until the locale segment is resolved.
 */
export default function RootLayout({ children }: { children: ReactNode }) {
  return children;
}
