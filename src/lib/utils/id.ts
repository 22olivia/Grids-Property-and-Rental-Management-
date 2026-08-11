/**
 * Stable client-side identifier generation.
 * Used for Idempotency-Key values (FR-API-005) and for associating form
 * controls with their labels and error messages (WCAG 3.3.1 / 1.3.1).
 */
export function uuid(): string {
  if (typeof crypto !== 'undefined' && 'randomUUID' in crypto) {
    return crypto.randomUUID();
  }
  // Deterministic fallback for older runtimes; not cryptographically strong,
  // and only ever used for correlation, never for security decisions.
  return 'xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx'.replace(/[xy]/g, (c) => {
    const r = (Math.random() * 16) | 0;
    const v = c === 'x' ? r : (r & 0x3) | 0x8;
    return v.toString(16);
  });
}
