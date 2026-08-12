'use client';

import { useTranslations } from 'next-intl';
import { Alert, Badge, EmptyState, LoadingState, Switch } from '@/design-system/ui';

/**
 * ===========================================================================
 * Configurable rule list — LIST ONLY. The rule EDITOR is not built.
 * ===========================================================================
 *
 * FR-CRM-002 enumerates the assignment BASES (territory, branch, workload,
 * property, campaign, manual) and FR-CRM-008 enumerates the commission PARTIES
 * (agent, agency, referral, company). Those vocabularies are real, so the list
 * is real: name, basis/party, priority order, enabled state.
 *
 * MISSING INFORMATION (MI-31): no requirement describes the rule EXPRESSION —
 * what a condition looks like, which operators exist, what value types are
 * permitted, or how ties break. FR-ADM-004 says approval rules are
 * configurable without saying how.
 *
 * Building an editor would mean inventing a grammar, then a parser, then a
 * serialiser — three things to unpick rather than one. `condition` is rendered
 * as an opaque server-supplied summary, and the editor slot shows an explicit
 * notice instead of a guess.
 * ===========================================================================
 */

export interface ConfigurableRule {
  id: string;
  name: string;
  /** Basis (assignment) or party (commission) — the module supplies the label. */
  kind: string;
  /** Opaque summary from the server. Never parsed or constructed client-side. */
  condition: string | null;
  priority: number;
  enabled: boolean;
}

export function RuleList({
  rules,
  isLoading,
  kindLabel,
  editorNotice,
}: {
  rules: ConfigurableRule[] | undefined;
  isLoading: boolean;
  kindLabel: (kind: string) => string;
  editorNotice: { title: string; body: string };
}) {
  const t = useTranslations('crm');
  const tc = useTranslations('common');

  if (isLoading) return <LoadingState label={tc('loading')} />;

  return (
    <div className="flex flex-col gap-4">
      <Alert tone="info" title={editorNotice.title}>{editorNotice.body}</Alert>

      {!rules || rules.length === 0 ? (
        <EmptyState
          kind="no-data"
          title={t('rules.emptyTitle')}
          description={t('rules.emptyDescription')}
        />
      ) : (
        <ol className="flex flex-col gap-2">
          {rules.map((rule) => (
            <li
              key={rule.id}
              className="flex flex-wrap items-center gap-3 rounded-[var(--radius-md)] border border-[var(--color-border)] p-3"
            >
              {/* Priority is meaningful — rules are evaluated in order. */}
              <span className="tabular text-xs text-[var(--color-text-muted)]">
                {t('rules.priority', { value: rule.priority })}
              </span>
              <span className="text-sm font-medium">{rule.name}</span>
              <Badge tone="neutral">{kindLabel(rule.kind)}</Badge>
              <span className="text-xs text-[var(--color-text-muted)]">
                {rule.condition ?? t('rules.conditionUnavailable')}
              </span>
              <span className="ms-auto flex items-center gap-2">
                <label htmlFor={`rule-${rule.id}`} className="text-xs">
                  {t('rules.enabled')}
                </label>
                {/* Read-only until the rule contract exists — toggling would
                    write a rule shape nobody has agreed. */}
                <Switch id={`rule-${rule.id}`} checked={rule.enabled} disabled />
              </span>
            </li>
          ))}
        </ol>
      )}
    </div>
  );
}
