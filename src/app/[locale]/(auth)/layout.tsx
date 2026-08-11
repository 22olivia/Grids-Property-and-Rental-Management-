import type { ReactNode } from 'react';
import { LanguageSwitcher } from '@/shell/language-switcher';

/** Minimal centred shell for session-establishing routes. */
export default function AuthLayout({ children }: { children: ReactNode }) {
  return (
    <div data-density="comfortable" className="flex min-h-dvh flex-col">
      <div className="flex justify-end p-4">
        <LanguageSwitcher />
      </div>
      <main id="main-content" className="flex flex-1 items-center justify-center px-4 pb-16">
        <div className="w-full max-w-sm">{children}</div>
      </main>
    </div>
  );
}
