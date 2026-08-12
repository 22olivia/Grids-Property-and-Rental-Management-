'use client';

import { useMutation, useQuery, useQueryClient } from '@tanstack/react-query';
import type { ListQuery } from '@/lib/data/repository';
import { listingRepository } from './index';
import type { ListingFormValues } from '../schemas/listing-schemas';
import type { ListingState } from '../types';

export const lstKeys = {
  all: ['lst'] as const,
  listings: (query?: ListQuery) => ['lst', 'listings', query] as const,
  listing: (id: string) => ['lst', 'listing', id] as const,
  approvals: (query?: ListQuery) => ['lst', 'approvals', query] as const,
  media: (id: string) => ['lst', 'media', id] as const,
  projects: (query?: ListQuery) => ['lst', 'projects', query] as const,
  project: (id: string) => ['lst', 'project', id] as const,
  events: (id: string) => ['lst', 'events', id] as const,
};

export function useListings(query: ListQuery) {
  return useQuery({
    queryKey: lstKeys.listings(query),
    queryFn: () => listingRepository.listListings(query),
    placeholderData: (previous) => previous,
  });
}

export function useListing(id: string) {
  return useQuery({ queryKey: lstKeys.listing(id), queryFn: () => listingRepository.getListing(id) });
}

export function useApprovalQueue(query: ListQuery) {
  return useQuery({
    queryKey: lstKeys.approvals(query),
    queryFn: () => listingRepository.listApprovalQueue(query),
    placeholderData: (previous) => previous,
  });
}

export function useListingMedia(id: string) {
  return useQuery({ queryKey: lstKeys.media(id), queryFn: () => listingRepository.listMedia(id) });
}

export function useProjects(query: ListQuery) {
  return useQuery({
    queryKey: lstKeys.projects(query),
    queryFn: () => listingRepository.listProjects(query),
    placeholderData: (previous) => previous,
  });
}

export function useProject(id: string) {
  return useQuery({ queryKey: lstKeys.project(id), queryFn: () => listingRepository.getProject(id) });
}

export function useListingEvents(id: string) {
  return useQuery({
    queryKey: lstKeys.events(id),
    queryFn: () => listingRepository.listChangeEvents(id),
  });
}

export function useCreateListing() {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (values: ListingFormValues) => listingRepository.createListing(values),
    onSuccess: () => client.invalidateQueries({ queryKey: ['lst', 'listings'] }),
  });
}

export function useUpdateListing(id: string) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (values: ListingFormValues) => listingRepository.updateListing(id, values),
    onSuccess: () => {
      client.invalidateQueries({ queryKey: lstKeys.listing(id) });
      client.invalidateQueries({ queryKey: ['lst', 'listings'] });
      client.invalidateQueries({ queryKey: lstKeys.events(id) });
    },
  });
}

/**
 * State transition.
 *
 * Never optimistic. A listing that appears published and then reverts is worse
 * than a spinner — and publication has downstream consequences (FR-MKT-007
 * indexing, FR-LST-008 availability), so the server's answer is the only one
 * that counts.
 */
export function useApplyTransition(id: string) {
  const client = useQueryClient();
  return useMutation({
    mutationFn: (targetState: ListingState) => listingRepository.applyTransition(id, targetState),
    onSuccess: () => {
      client.invalidateQueries({ queryKey: lstKeys.listing(id) });
      client.invalidateQueries({ queryKey: ['lst', 'listings'] });
      client.invalidateQueries({ queryKey: ['lst', 'approvals'] });
      client.invalidateQueries({ queryKey: lstKeys.events(id) });
    },
  });
}
