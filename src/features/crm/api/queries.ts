'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import type { ListQuery } from '@/lib/data/repository';
import { crmRepository } from './index';
import type { ActivityFormValues, CounterofferFormValues, LeadFormValues } from '../schemas/crm-schemas';
import type { PipelineStage } from '../types';

export const crmKeys = {
  leads: (q?: ListQuery) => ['crm', 'leads', q] as const,
  lead: (id: string) => ['crm', 'lead', id] as const,
  pipeline: () => ['crm', 'pipeline'] as const,
  activities: (leadId: string) => ['crm', 'activities', leadId] as const,
  tasks: (q?: ListQuery) => ['crm', 'tasks', q] as const,
  matches: (leadId: string) => ['crm', 'matches', leadId] as const,
  viewings: (q?: ListQuery) => ['crm', 'viewings', q] as const,
  viewing: (id: string) => ['crm', 'viewing', id] as const,
  offers: (q?: ListQuery) => ['crm', 'offers', q] as const,
  offer: (id: string) => ['crm', 'offer', id] as const,
  deals: (q?: ListQuery) => ['crm', 'deals', q] as const,
  commissions: (q?: ListQuery) => ['crm', 'commissions', q] as const,
  assignmentRules: () => ['crm', 'assignment-rules'] as const,
  commissionRules: () => ['crm', 'commission-rules'] as const,
};

const keepPrevious = { placeholderData: (previous: unknown) => previous } as const;

export const useLeads = (q: ListQuery) =>
  useQuery({ queryKey: crmKeys.leads(q), queryFn: () => crmRepository.listLeads(q), ...keepPrevious });
export const useLead = (id: string) =>
  useQuery({ queryKey: crmKeys.lead(id), queryFn: () => crmRepository.getLead(id) });
export const usePipeline = () =>
  useQuery({ queryKey: crmKeys.pipeline(), queryFn: () => crmRepository.listPipeline() });
export const useActivities = (leadId: string) =>
  useQuery({ queryKey: crmKeys.activities(leadId), queryFn: () => crmRepository.listActivities(leadId) });
export const useTasks = (q: ListQuery) =>
  useQuery({ queryKey: crmKeys.tasks(q), queryFn: () => crmRepository.listTasks(q), ...keepPrevious });
export const useMatches = (leadId: string) =>
  useQuery({ queryKey: crmKeys.matches(leadId), queryFn: () => crmRepository.listMatches(leadId) });
export const useViewings = (q: ListQuery) =>
  useQuery({ queryKey: crmKeys.viewings(q), queryFn: () => crmRepository.listViewings(q), ...keepPrevious });
export const useViewing = (id: string) =>
  useQuery({ queryKey: crmKeys.viewing(id), queryFn: () => crmRepository.getViewing(id) });
export const useOffers = (q: ListQuery) =>
  useQuery({ queryKey: crmKeys.offers(q), queryFn: () => crmRepository.listOffers(q), ...keepPrevious });
export const useOffer = (id: string) =>
  useQuery({ queryKey: crmKeys.offer(id), queryFn: () => crmRepository.getOffer(id) });
export const useDeals = (q: ListQuery) =>
  useQuery({ queryKey: crmKeys.deals(q), queryFn: () => crmRepository.listDeals(q), ...keepPrevious });
export const useCommissions = (q: ListQuery) =>
  useQuery({ queryKey: crmKeys.commissions(q), queryFn: () => crmRepository.listCommissions(q), ...keepPrevious });
export const useAssignmentRules = () =>
  useQuery({ queryKey: crmKeys.assignmentRules(), queryFn: () => crmRepository.listAssignmentRules() });
export const useCommissionRules = () =>
  useQuery({ queryKey: crmKeys.commissionRules(), queryFn: () => crmRepository.listCommissionRules() });

export function useCreateLead() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (values: LeadFormValues) => crmRepository.createLead(values),
    onSuccess: () => {
      client.invalidateQueries({ queryKey: ['crm', 'leads'] });
      client.invalidateQueries({ queryKey: crmKeys.pipeline() });
    },
  });
}

export function useUpdateLead(id: string) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (values: LeadFormValues) => crmRepository.updateLead(id, values),
    onSuccess: () => {
      client.invalidateQueries({ queryKey: crmKeys.lead(id) });
      client.invalidateQueries({ queryKey: ['crm', 'leads'] });
      client.invalidateQueries({ queryKey: crmKeys.pipeline() });
    },
  });
}

/**
 * Stage move.
 *
 * NOT optimistic. FR-CRM-003 stages gate downstream work — a reservation or
 * contract stage has consequences — so a card that appears to move and then
 * snaps back is worse than a brief pending state.
 */
export function useMoveStage() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: ({ id, stage }: { id: string; stage: PipelineStage }) =>
      crmRepository.moveLeadStage(id, stage),
    onSuccess: (lead) => {
      client.invalidateQueries({ queryKey: crmKeys.pipeline() });
      client.invalidateQueries({ queryKey: crmKeys.lead(lead.id) });
      client.invalidateQueries({ queryKey: ['crm', 'leads'] });
    },
  });
}

export function useCreateActivity(leadId: string) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (values: ActivityFormValues) => crmRepository.createActivity(leadId, values),
    onSuccess: () => {
      client.invalidateQueries({ queryKey: crmKeys.activities(leadId) });
      client.invalidateQueries({ queryKey: ['crm', 'tasks'] });
      client.invalidateQueries({ queryKey: crmKeys.lead(leadId) });
    },
  });
}

export function useAddCounteroffer(offerId: string) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (values: CounterofferFormValues) => crmRepository.addCounteroffer(offerId, values),
    onSuccess: () => {
      client.invalidateQueries({ queryKey: crmKeys.offer(offerId) });
      client.invalidateQueries({ queryKey: ['crm', 'offers'] });
    },
  });
}
