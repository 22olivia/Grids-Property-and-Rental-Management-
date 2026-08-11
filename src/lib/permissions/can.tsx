'use client';

import type { ReactNode } from 'react';
import type { Permission, PermissionMode } from './types';
import { useCan } from './permission-provider';

interface CanProps {
  do: Permission | Permission[];
  mode?: PermissionMode;
  children: ReactNode;
  /**
   * Rendered instead of `children` when the check fails.
   *
   * Prefer a disabled control with an explanation over hiding entirely where
   * the user could reasonably expect the action to exist — a control that
   * silently vanishes reads as a bug, whereas "you don't have permission to
   * approve leases" is information.
   */
  fallback?: ReactNode;
}

export function Can({ do: required, mode = 'all', children, fallback = null }: CanProps) {
  const can = useCan();
  return <>{can(required, mode) ? children : fallback}</>;
}
