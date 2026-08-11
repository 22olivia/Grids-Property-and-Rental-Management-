import { describe, expect, it } from 'vitest';
import { formatMoney } from '@/domain/money/money';

describe('money precision', () => {
  it('does not round a value beyond IEEE-754 integer precision', () => {
    // Regression: formatting used to go through Number(), which turned
    // 12345678901234567.89 into 12,345,678,901,234,568.00 on screen.
    const output = formatMoney(
      { amount: '12345678901234567.89', currency: 'AED' },
      { locale: 'en' },
    );
    expect(output).toContain('12,345,678,901,234,567.89');
    expect(output).not.toContain('568.00');
  });

  it('preserves trailing decimal places exactly', () => {
    expect(formatMoney({ amount: '0.10', currency: 'USD' }, { locale: 'en' })).toContain('0.10');
  });

  it('shows a placeholder for a malformed amount rather than zero', () => {
    expect(formatMoney({ amount: '1,500', currency: 'AED' }, { locale: 'en' })).toBe('—');
    expect(formatMoney({ amount: '', currency: 'AED' }, { locale: 'en' })).toBe('—');
  });
});
