'use client';

import { createContext, useContext, useMemo, type ReactNode } from 'react';
import type { SessionState } from '@/lib/auth/types';
import { ANONYMOUS_SESSION } from '@/lib/auth/types';
import type { Permission, PermissionMode } from './types';
import { checkPermissions } from './check';

interface SessionContextValue {
  session: SessionState;
  can: (required: Permission | Permission[], mode?: PermissionMode) => boolean;
}

const SessionContext = createContext<SessionContextValue>({
  session: ANONYMOUS_SESSION,
  can: () => false,
});

export function SessionProvider({
  session,
  children,
}: {
  session: SessionState;
  children: ReactNode;
}) {
  const value = useMemo<SessionContextValue>(() => {
    const granted = session.user?.permissions ?? [];
    return {
      session,
      can: (required, mode = 'all') =>
        checkPermissions(granted, Array.isArray(required) ? required : [required], mode),
    };
  }, [session]);

  return <SessionContext.Provider value={value}>{children}</SessionContext.Provider>;
}

export function useSession(): SessionState {
  return useContext(SessionContext).session;
}

export function useCan(): SessionContextValue['can'] {
  return useContext(SessionContext).can;
}
