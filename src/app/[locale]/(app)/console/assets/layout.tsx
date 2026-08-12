import type { ReactNode } from 'react';

/**
 * Assets section shell.
 *
 * Deliberately structural only.
 *
 * An earlier version rendered a section-level breadcrumb here. That produced
 * TWO <nav aria-label="Breadcrumb"> landmarks on every detail screen — a
 * duplicated landmark is a real navigation defect for screen-reader users, not
 * just a visual repeat. Each screen owns its own trail, so a deep link renders
 * a complete one rather than a partial one.
 */
export default function AssetsLayout({ children }: { children: ReactNode }) {
  return <div className="flex flex-col gap-4">{children}</div>;
}
