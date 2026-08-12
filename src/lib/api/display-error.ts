import { ApiError, NetworkError } from './types';
import { MissingApiContractError } from './endpoints';

/**
 * Maps any thrown value to something safe to render.
 *
 * Fixes a defect found in review: repository errors were rendered with
 * `(error as Error).message`, so a user could be shown the raw string
 * "NOT_FOUND". Internal codes are not user-facing copy, and they are not
 * translatable.
 *
 * `correlationId` is carried through so a user can quote a reference that
 * appears in the server logs (SRS §12 puts it in every envelope).
 */
export interface DisplayError {
  message: string;
  correlationId: string | null;
  /** True while the API contract is unpublished — surfaced verbatim, since
   *  it is a configuration fault the developer needs to see, not a user error. */
  isContractGap: boolean;
}

/** Internal codes look like SCREAMING_SNAKE and must never reach a user. */
const INTERNAL_CODE = /^[A-Z][A-Z0-9_]*$/;

export function toDisplayError(error: unknown, fallbackMessage: string): DisplayError | null {
  if (!error) return null;

  if (error instanceof MissingApiContractError) {
    return { message: error.message, correlationId: null, isContractGap: true };
  }

  if (error instanceof ApiError) {
    const first = error.errors[0]?.message;
    return {
      // Server messages arrive localised (the client sends Accept-Language),
      // so they are displayed as received — but a bare code is not a message.
      message: first && !INTERNAL_CODE.test(first) ? first : fallbackMessage,
      correlationId: error.correlationId,
      isContractGap: false,
    };
  }

  if (error instanceof NetworkError) {
    return { message: fallbackMessage, correlationId: null, isContractGap: false };
  }

  return { message: fallbackMessage, correlationId: null, isContractGap: false };
}
