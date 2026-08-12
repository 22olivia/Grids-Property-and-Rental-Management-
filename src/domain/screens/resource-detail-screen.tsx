'use client';

import type { ReactNode } from 'react';
import {
  Breadcrumb,
  type BreadcrumbItem,
  ErrorState,
  LoadingState,
  Tabs,
  TabsContent,
  TabsList,
  TabsTrigger,
} from '@/design-system/ui';
import { useTranslations } from 'next-intl';
import { StatusPill, type StatusTone } from '@/domain/components/status-pill';
import { MockDataNotice } from '@/domain/components/mock-data-notice';
import { AuditTrail, type AuditEntry } from '@/domain/components/audit-trail';
import { useTabState } from '@/lib/tables/use-tab-state';
import { toDisplayError } from '@/lib/api/display-error';

/**
 * ===========================================================================
 * SCREEN ARCHETYPE B — resource detail
 * ===========================================================================
 *
 * Covers 34 of the 227 derived screens. Composes breadcrumb, record header
 * (title / reference / status / actions), URL-addressable tabs, and the
 * standard History tab.
 *
 * The History tab is built in because EVERY module has a history requirement —
 * FR-AST-008, FR-IAM-008, FR-LSE-004, FR-FIN-007, FR-DOC-002 — and writing it
 * once means the diff rendering and actor attribution cannot drift apart
 * between modules.
 *
 * Tab CONTENT stays entirely bespoke. This owns the frame, not the substance.
 * ===========================================================================
 */

export interface DetailTab {
  id: string;
  label: string;
  content: ReactNode;
}

export interface ResourceDetailScreenProps {
  breadcrumb: BreadcrumbItem[];
  breadcrumbLabel: string;
  title: string;
  /** Machine identifier, rendered in the mono face so it reads as a reference. */
  reference?: string;
  status?: { label: string; tone: StatusTone };
  actions?: ReactNode;
  tabs: DetailTab[];
  /** When supplied, a History tab is appended automatically. */
  history?: {
    label: string;
    entries: AuditEntry[] | undefined;
    isLoading: boolean;
    categoryLabel: (category: string) => string;
  };
  isLoading?: boolean;
  error?: unknown;
  onRetry?: () => void;
  notFoundCopy: { title: string; description: string };
  /** True when this screen's module is running on fixtures. */
  isMock: boolean;
}

export function ResourceDetailScreen({
  breadcrumb,
  breadcrumbLabel,
  title,
  reference,
  status,
  actions,
  tabs,
  history,
  isLoading,
  error,
  onRetry,
  notFoundCopy,
  isMock,
}: ResourceDetailScreenProps) {
  const tc = useTranslations('common');
  const allTabs: DetailTab[] = history
    ? [
        ...tabs,
        {
          id: 'history',
          label: history.label,
          content: (
            <AuditTrail
              entries={history.entries}
              isLoading={history.isLoading}
              categoryLabel={history.categoryLabel}
            />
          ),
        },
      ]
    : tabs;

  const { active, setTab } = useTabState(allTabs[0]?.id ?? 'overview');

  if (isLoading) return <LoadingState label={tc('loading')} />;

  const displayError = toDisplayError(error, notFoundCopy.description);
  if (displayError) {
    return (
      <ErrorState
        title={notFoundCopy.title}
        description={displayError.message}
        retryLabel={tc('retry')}
        onRetry={onRetry}
        correlationId={displayError.correlationId}
        correlationLabel={tc('reference')}
      />
    );
  }

  return (
    <div className="flex flex-col gap-4">
      <MockDataNotice active={isMock} />
      <Breadcrumb label={breadcrumbLabel} items={breadcrumb} />

      <div className="flex flex-wrap items-center gap-3">
        <h1 className="text-xl font-semibold">{title}</h1>
        {reference && (
          <code className="reference text-sm text-[var(--color-text-muted)]">{reference}</code>
        )}
        {status && <StatusPill label={status.label} tone={status.tone} />}
        {actions && <div className="ms-auto flex items-center gap-2">{actions}</div>}
      </div>

      <Tabs value={active} onValueChange={setTab}>
        <TabsList>
          {allTabs.map((tab) => (
            <TabsTrigger key={tab.id} value={tab.id}>
              {tab.label}
            </TabsTrigger>
          ))}
        </TabsList>
        {allTabs.map((tab) => (
          <TabsContent key={tab.id} value={tab.id}>
            {tab.content}
          </TabsContent>
        ))}
      </Tabs>
    </div>
  );
}
