import { Badge } from '@/design-system/ui';

export type StatusTone = 'neutral' | 'success' | 'warning' | 'danger' | 'info';

/**
 * Status rendering, in one place.
 *
 * Two rules, both from WCAG 1.4.1 (use of colour):
 *  - the label is always rendered, so colour is reinforcement not signal;
 *  - the tone mapping lives with the module that owns the status vocabulary,
 *    passed in rather than guessed here.
 */
export function StatusPill({ label, tone = 'neutral' }: { label: string; tone?: StatusTone }) {
  return <Badge tone={tone}>{label}</Badge>;
}
