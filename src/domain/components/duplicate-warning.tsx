'use client';

import { useTranslations } from 'next-intl';
import { Alert } from '@/design-system/ui';
/**
 * A record the server considers a possible duplicate.
 * The `reason` is server-supplied — the client never computes it.
 */
export interface DuplicateCandidate {
  id: string;
  name: string;
  reference: string;
  reason: string;
}

/**
 * FR-AST-007 (Must): "prevent duplicate property and unit records using
 * configurable matching rules".
 *
 * The client WARNS; it does not decide. The matching rules are configurable
 * and live server-side, and SRS §6 forbids reimplementing business rules in
 * clients. So this never blocks submission — the server rejects on commit if
 * the record really is a duplicate. A client-side block that disagreed with
 * the server would stop legitimate work with no way past it.
 */
export function DuplicateWarning({ candidates }: { candidates: DuplicateCandidate[] | undefined }) {
  const t = useTranslations('data');
  if (!candidates || candidates.length === 0) return null;

  return (
    <Alert tone="warning" title={t('duplicateTitle')} live="polite">
      <p>{t('duplicateDescription')}</p>
      <ul className="mt-2 flex flex-col gap-1">
        {candidates.map((candidate) => (
          <li key={candidate.id} className="text-sm">
            <span className="font-medium">{candidate.name}</span>{' '}
            <code className="reference text-xs">{candidate.reference}</code>
          </li>
        ))}
      </ul>
    </Alert>
  );
}
