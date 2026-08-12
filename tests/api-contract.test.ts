import { describe, expect, it } from 'vitest';
import { endpoints, isEndpointAvailable, resolveEndpoint, MissingApiContractError } from '@/lib/api/endpoints';
import { ApiError } from '@/lib/api/types';

describe('endpoint registry reflects the verified backend', () => {
  it('has verified paths for the integrated resources', () => {
    for (const key of [
      'auth.login', 'auth.me', 'auth.logout',
      'properties.index', 'properties.show', 'properties.store', 'properties.update',
      'buildings.index', 'buildings.show', 'units.index', 'units.show',
    ] as const) {
      expect(isEndpointAvailable(key), key).toBe(true);
    }
  });

  it('keeps capabilities the backend lacks unavailable', () => {
    // These must stay null. A stub here would let a screen call a URL that
    // does not exist and fail at runtime instead of at the seam.
    for (const key of [
      'auth.refresh', 'assets.statusTimeline', 'assets.changeEvents',
      'assets.duplicates', 'assets.customFields', 'listings.index', 'crm.leads',
    ] as const) {
      expect(isEndpointAvailable(key), key).toBe(false);
      expect(() => resolveEndpoint(key)).toThrow(MissingApiContractError);
    }
  });

  it('substitutes path parameters', () => {
    expect(resolveEndpoint('properties.show', { id: 42 })).toBe('/properties/42');
    expect(resolveEndpoint('buildings.storeFloor', { id: 7 })).toBe('/buildings/7/floors');
  });

  it('refuses to emit a path with unresolved parameters', () => {
    expect(() => resolveEndpoint('properties.show')).toThrow(/unresolved/);
  });

  it('every registered path is relative to the versioned base', () => {
    for (const [key, definition] of Object.entries(endpoints)) {
      if (definition.path) expect(definition.path.startsWith('/'), key).toBe(true);
    }
  });
});

describe('Laravel error conversion', () => {
  it('converts field-keyed validation errors into flat items', () => {
    const error = ApiError.fromLaravel(422, {
      message: 'The given data was invalid.',
      errors: { email: ['No account found with this email.'], password: ['Incorrect password.'] },
    });
    expect(error.isValidation).toBe(true);
    expect(error.fieldErrors.email).toBe('No account found with this email.');
    expect(error.fieldErrors.password).toBe('Incorrect password.');
  });

  it('falls back to the message when no field errors are present', () => {
    const error = ApiError.fromLaravel(403, { message: 'You do not have permission for this action.' });
    expect(error.isForbidden).toBe(true);
    expect(error.message).toBe('You do not have permission for this action.');
  });

  it('never invents a correlation id — the backend returns none', () => {
    expect(ApiError.fromLaravel(500, {}).correlationId).toBeNull();
  });
});
