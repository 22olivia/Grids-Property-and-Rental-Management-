import { describe, expect, it } from 'vitest';
import en from '../messages/en.json';
import ar from '../messages/ar.json';
import { locales, getDirection, intlLocale, isLocale } from '@/lib/i18n/config';

function flatten(object: Record<string, unknown>, prefix = ''): string[] {
  return Object.entries(object).flatMap(([key, value]) => {
    const path = prefix ? `${prefix}.${key}` : key;
    return value && typeof value === 'object' && !Array.isArray(value)
      ? flatten(value as Record<string, unknown>, path)
      : [path];
  });
}

describe('i18n configuration', () => {
  it('maps every locale to a direction', () => {
    for (const locale of locales) {
      expect(['ltr', 'rtl']).toContain(getDirection(locale));
    }
  });

  it('marks Arabic as right-to-left', () => {
    expect(getDirection('ar')).toBe('rtl');
    expect(getDirection('en')).toBe('ltr');
  });

  it('rejects unknown locales', () => {
    expect(isLocale('fr')).toBe(false);
    expect(isLocale('ar')).toBe(true);
  });

  it('resolves an Intl tag for every locale', () => {
    for (const locale of locales) {
      expect(() => new Intl.NumberFormat(intlLocale[locale])).not.toThrow();
    }
  });
});

describe('translation catalogues', () => {
  it('has identical key sets in every locale', () => {
    const englishKeys = flatten(en).sort();
    const arabicKeys = flatten(ar).sort();
    expect(arabicKeys).toEqual(englishKeys);
  });

  it('has no empty strings', () => {
    for (const [name, catalogue] of Object.entries({ en, ar })) {
      const empties = flatten(catalogue).filter((key) => {
        const value = key
          .split('.')
          .reduce<unknown>((acc, part) => (acc as Record<string, unknown>)?.[part], catalogue);
        return typeof value === 'string' && value.trim() === '';
      });
      expect(empties, `empty strings in ${name}.json`).toEqual([]);
    }
  });
});
