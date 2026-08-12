'use client';

import { Check } from 'lucide-react';
import { cn } from '@/lib/utils/cn';
import { Button } from '@/design-system/ui';
import type { StatusTone } from './status-pill';

/**
 * ===========================================================================
 * Workflow stepper — renders SERVER-SUPPLIED states and transitions.
 * ===========================================================================
 *
 * FR-LST-006, FR-MNT-002 and FR-LSE-004 all describe configurable lifecycles,
 * and FR-ADM-004 makes statuses and approval rules configurable. So this
 * component NEVER hard-codes a state graph. It receives:
 *
 *   states       the ordered lifecycle, for orientation
 *   current      where the record is now
 *   transitions  what this user may do next — decided by the server
 *
 * MISSING INFORMATION (MI-24): the transition matrix itself is not published.
 * FR-LST-006 enumerates the eight listing states verbatim, but nothing
 * specifies which transitions are legal, who may perform them, or what
 * preconditions apply. Modelling transitions as DATA means the real matrix
 * plugs in without touching this component or any screen using it.
 *
 * `blockedReason` exists for FR-LST-008: a listing may not advertise an
 * occupied or unavailable unit. The server decides; this displays the reason.
 * ===========================================================================
 */

export interface WorkflowState {
  id: string;
  label: string;
}

export interface WorkflowTransition {
  id: string;
  label: string;
  targetState: string;
  tone?: StatusTone;
  /** Server-supplied explanation when the action is unavailable. */
  blockedReason?: string | null;
}

export function WorkflowStepper({
  states,
  current,
  transitions,
  onTransition,
  isPending,
  transitionsLabel,
}: {
  states: WorkflowState[];
  current: string;
  transitions: WorkflowTransition[];
  onTransition: (transition: WorkflowTransition) => void;
  isPending?: boolean;
  transitionsLabel: string;
}) {
  const currentIndex = states.findIndex((state) => state.id === current);

  return (
    <div className="flex flex-col gap-4">
      {/* Ordered list, not a row of divs: the sequence is meaningful and a
          screen reader needs to hear it as a list with a marked current step. */}
      <ol className="flex flex-wrap items-center gap-x-2 gap-y-3">
        {states.map((state, index) => {
          const isDone = index < currentIndex;
          const isCurrent = index === currentIndex;
          return (
            <li key={state.id} className="flex items-center gap-2">
              <span
                aria-current={isCurrent ? 'step' : undefined}
                className={cn(
                  'flex items-center gap-1.5 rounded-[var(--radius-full)] px-3 py-1 text-xs',
                  isCurrent && 'bg-[var(--color-action)] text-[var(--color-text-on-brand)]',
                  isDone && 'bg-[var(--color-success-surface)] text-[var(--color-success)]',
                  !isCurrent && !isDone && 'bg-[var(--color-surface-sunken)] text-[var(--color-text-muted)]',
                )}
              >
                {isDone && <Check className="size-3" aria-hidden="true" />}
                {state.label}
              </span>
              {index < states.length - 1 && (
                // Logical border so the connector sits on the correct side in
                // Arabic without any direction branching.
                <span
                  aria-hidden="true"
                  className="h-px w-4 border-t border-[var(--color-border)]"
                />
              )}
            </li>
          );
        })}
      </ol>

      {transitions.length > 0 && (
        <div className="flex flex-col gap-2">
          <p className="text-xs font-medium text-[var(--color-text-muted)]">{transitionsLabel}</p>
          <div className="flex flex-wrap gap-2">
            {transitions.map((transition) => (
              <span key={transition.id} className="flex flex-col gap-1">
                <Button
                  variant={transition.tone === 'danger' ? 'danger' : 'secondary'}
                  size="sm"
                  disabled={Boolean(transition.blockedReason) || isPending}
                  onClick={() => onTransition(transition)}
                >
                  {transition.label}
                </Button>
                {transition.blockedReason && (
                  // Disabled-with-reason, not hidden. A control that silently
                  // vanishes reads as a bug; an explanation is information.
                  <span role="note" className="max-w-56 text-xs text-[var(--color-text-muted)]">
                    {transition.blockedReason}
                  </span>
                )}
              </span>
            ))}
          </div>
        </div>
      )}
    </div>
  );
}
