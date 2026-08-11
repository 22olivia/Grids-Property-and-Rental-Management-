import { describe, expect, it } from 'vitest';
import { arrowKeyIntent, horizontalSign, isRtl } from '@/lib/i18n/direction';

describe('direction helpers', () => {
  it('identifies Arabic as RTL', () => {
    expect(isRtl('ar')).toBe(true);
    expect(isRtl('en')).toBe(false);
  });

  it('inverts horizontal maths in RTL', () => {
    expect(horizontalSign('ltr')).toBe(1);
    expect(horizontalSign('rtl')).toBe(-1);
  });

  it('maps arrow keys to logical intent per direction', () => {
    // In Arabic, ArrowRight moves toward the START of the reading order.
    expect(arrowKeyIntent('ArrowRight', 'ltr')).toBe('end');
    expect(arrowKeyIntent('ArrowRight', 'rtl')).toBe('start');
    expect(arrowKeyIntent('ArrowLeft', 'ltr')).toBe('start');
    expect(arrowKeyIntent('ArrowLeft', 'rtl')).toBe('end');
  });

  it('leaves vertical keys unchanged', () => {
    expect(arrowKeyIntent('ArrowUp', 'rtl')).toBe('up');
    expect(arrowKeyIntent('ArrowDown', 'rtl')).toBe('down');
    expect(arrowKeyIntent('Enter', 'rtl')).toBeNull();
  });
});
