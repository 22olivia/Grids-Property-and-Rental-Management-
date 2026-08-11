import type { StatusTone } from '@/domain/components/status-pill';
import type { ListingState } from './types';

/**
 * State → tone. Colour is reinforcement; the label always renders (WCAG 1.4.1).
 * Unknown states fall back to neutral so a server-side addition cannot break a
 * list screen.
 */
const LISTING_STATE_TONES: Record<ListingState, StatusTone> = {
  draft: 'neutral',
  review: 'warning',
  approval: 'warning',
  published: 'success',
  paused: 'info',
  expired: 'neutral',
  closed: 'info',
  archived: 'neutral',
};

export function listingStateTone(state: string): StatusTone {
  return LISTING_STATE_TONES[state as ListingState] ?? 'neutral';
}

export const listingStateLabelKey = (state: string) => `lst.state.${state}`;
export const listingTypeLabelKey = (type: string) => `lst.type.${type}`;
export const mediaKindLabelKey = (kind: string) => `lst.mediaKind.${kind}`;
