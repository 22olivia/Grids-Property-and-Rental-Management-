import type { StatusTone } from '@/domain/components/status-pill';
import { UNIT_STATUSES, LEGACY_UNIT_STATUSES, PROPERTY_STATUSES } from './types';

/**
 * Status → tone. Colour is reinforcement only; the label always renders
 * (WCAG 1.4.1). Unknown values fall back to neutral so a backend addition
 * cannot break a list screen.
 */
const UNIT_STATUS_TONES: Record<string, StatusTone> = {
  vacant: 'success',
  available: 'success', // legacy alias, normalised to vacant on write
  reserved: 'warning',
  application_pending: 'warning',
  occupied: 'info',
  notice_period: 'warning',
  under_maintenance: 'neutral',
  maintenance: 'neutral', // legacy alias
  blocked: 'danger',
};

const PROPERTY_STATUS_TONES: Record<string, StatusTone> = {
  active: 'success',
  inactive: 'neutral',
  under_maintenance: 'warning',
};

export function unitStatusTone(status: string): StatusTone {
  return UNIT_STATUS_TONES[status] ?? 'neutral';
}

export function propertyStatusTone(status: string): StatusTone {
  return PROPERTY_STATUS_TONES[status] ?? 'neutral';
}

/** Selectable on a form. Legacy aliases are renderable but not offered. */
export const SELECTABLE_UNIT_STATUSES = UNIT_STATUSES;
export const ALL_UNIT_STATUSES = [...UNIT_STATUSES, ...LEGACY_UNIT_STATUSES];
export const SELECTABLE_PROPERTY_STATUSES = PROPERTY_STATUSES;

export const unitStatusLabelKey = (status: string) => `ast.unitStatus.${status}`;
export const propertyTypeLabelKey = (type: string) => `ast.propertyType.${type}`;
export const propertyStatusLabelKey = (status: string) => `ast.propertyStatus.${status}`;

/**
 * Currency for unit money values.
 *
 * The backend stores no currency on rental_units, contracts or invoices — only
 * on payments (`char(3) default 'AED'`, `config/payments.php`). Until
 * FR-FIN-002 multi-currency exists server-side, the display currency comes
 * from configuration rather than being guessed per record.
 */
export const UNIT_CURRENCY_FALLBACK = process.env.NEXT_PUBLIC_DEFAULT_CURRENCY ?? 'AED';
