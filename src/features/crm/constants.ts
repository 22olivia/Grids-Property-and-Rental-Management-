import type { StatusTone } from '@/domain/components/status-pill';
import type { OfferState, PipelineStage, ViewingStatus } from './types';

const STAGE_TONES: Record<PipelineStage, StatusTone> = {
  qualification: 'neutral',
  matching: 'info',
  viewing: 'info',
  offer: 'warning',
  negotiation: 'warning',
  reservation: 'info',
  contract: 'info',
  won: 'success',
  lost: 'danger',
};

const VIEWING_TONES: Record<ViewingStatus, StatusTone> = {
  scheduled: 'info',
  attended: 'success',
  'no-show': 'danger',
  rescheduled: 'warning',
};

const OFFER_TONES: Record<OfferState, StatusTone> = {
  submitted: 'info',
  countered: 'warning',
  approved: 'success',
  expired: 'neutral',
};

/** Unknown values fall back to neutral so a server-side addition cannot break a screen. */
export const stageTone = (stage: string): StatusTone =>
  STAGE_TONES[stage as PipelineStage] ?? 'neutral';
export const viewingTone = (status: string): StatusTone =>
  VIEWING_TONES[status as ViewingStatus] ?? 'neutral';
export const offerTone = (state: string): StatusTone =>
  OFFER_TONES[state as OfferState] ?? 'neutral';

export const stageLabelKey = (stage: string) => `crm.stage.${stage}`;
export const sourceLabelKey = (source: string) => `crm.source.${source}`;
export const activityLabelKey = (type: string) => `crm.activityType.${type}`;
export const viewingStatusLabelKey = (status: string) => `crm.viewingStatus.${status}`;
export const offerStateLabelKey = (state: string) => `crm.offerState.${state}`;
export const basisLabelKey = (basis: string) => `crm.basis.${basis}`;
export const partyLabelKey = (party: string) => `crm.party.${party}`;
