'use client';

import { useTranslations } from 'next-intl';
import { Alert } from '@/design-system/ui';

/**
 * ===========================================================================
 * CUSTOM FIELD RENDERER — ADAPTER ONLY, NOT IMPLEMENTED
 * ===========================================================================
 *
 * FR-AST-006 (Must): "support custom fields and property-type-specific
 * attributes without source-code changes"
 * FR-ADM-004 (Must): "manage reference data, custom fields, statuses,
 * categories, templates and approval rules"
 *
 * Building this needs a metadata contract: a field-type vocabulary, a
 * validation-rule expression format, a conditional-visibility model, and an
 * ordering scheme. NONE of these exist in the SRS, the backlog PDF or the
 * workbook, and SRS §12 has no endpoint for them.
 *
 * This is a bigger design problem than it first appears and it is easy to
 * under-scope. Guessing a shape now would mean building a renderer, a form
 * binder and a validator against an invented schema — three things to unpick
 * rather than one.
 *
 * So: the seam exists and every form that will need custom fields already
 * calls it. When the contract is published, this component is the only file
 * that changes.
 * ===========================================================================
 */

export interface DynamicFieldsProps {
  /** Entity the fields belong to, e.g. 'property' | 'unit'. */
  entity: string;
  /** Type-specific variant, e.g. the classification. */
  variant?: string;
  values: Record<string, unknown>;
  onChange: (values: Record<string, unknown>) => void;
}

export function DynamicFields({ entity }: DynamicFieldsProps) {
  const t = useTranslations('data');

  // Renders a visible, honest placeholder rather than nothing. A silently
  // absent section is indistinguishable from a bug during review.
  return (
    <Alert tone="info" title={t('customFieldsTitle')}>
      {t('customFieldsUnavailable', { entity })}
    </Alert>
  );
}
