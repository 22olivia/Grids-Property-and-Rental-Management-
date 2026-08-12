'use client';

import { useTranslations } from 'next-intl';
import { Alert } from '@/design-system/ui';

/**
 * Form-level error summary.
 *
 * Every long form needs one: WCAG 3.3.1 wants errors identified, and on a
 * 40-field form an inline message below the fold is not identification.
 * Field-level errors stay on their fields; this carries what could not be
 * attached to one.
 *
 * `role="alert"` via Alert tone="danger" means it is announced when it
 * appears after a failed submit, not only when focus reaches it.
 */
export function FormErrorSummary({
  messages,
  correlationId,
}: {
  messages: string[];
  correlationId?: string | null;
}) {
  const t = useTranslations('common');
  if (messages.length === 0) return null;

  return (
    <Alert tone="danger" live="assertive" title={t('unexpectedError')}>
      <ul className="flex flex-col gap-1">
        {messages.map((message) => (
          <li key={message}>{message}</li>
        ))}
      </ul>
      {correlationId && (
        <p className="mt-1 text-xs">
          {t('reference')} <code className="reference select-all">{correlationId}</code>
        </p>
      )}
    </Alert>
  );
}
