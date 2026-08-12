'use client';

import type { ReactNode } from 'react';
import { Breadcrumb, type BreadcrumbItem } from '@/design-system/ui';
import { MockDataNotice } from '@/domain/components/mock-data-notice';

/**
 * ===========================================================================
 * SCREEN ARCHETYPE C — resource create / edit frame.
 * ===========================================================================
 *
 * Extracted once six create/edit routes existed (property, unit, listing, and
 * now lead) and all six repeated the same breadcrumb + notice + heading
 * wrapper verbatim.
 *
 * Frame only. Field layout stays in the feature's own form component, because
 * that is where the requirement-specific structure lives.
 * ===========================================================================
 */
export function ResourceFormScreen({
  breadcrumb,
  breadcrumbLabel,
  title,
  isMock,
  children,
}: {
  breadcrumb: BreadcrumbItem[];
  breadcrumbLabel: string;
  title: string;
  /** True when this screen's module is running on fixtures. */
  isMock: boolean;
  children: ReactNode;
}) {
  return (
    <div className="flex flex-col gap-4">
      <MockDataNotice active={isMock} />
      <Breadcrumb label={breadcrumbLabel} items={breadcrumb} />
      <h1 className="text-xl font-semibold">{title}</h1>
      {children}
    </div>
  );
}
