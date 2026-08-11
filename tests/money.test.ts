import { describe, expect, it } from 'vitest';
import { formatMoney, formatNumber, formatPercent } from '@/domain/money/money';

describe('money formatting', () => {
  it('formats an amount with its currency', () => {
    const output = formatMoney({ amount: '1500.00', currency: 'AED' }, { locale: 'en' });
    expect(output).toContain('1,500');
  });

  it('formats the same amount in Arabic without changing the value', () => {
    const english = formatMoney({ amount: '1500.00', currency: 'AED' }, { locale: 'en' });
    const arabic = formatMoney({ amount: '1500.00', currency: 'AED' }, { locale: 'ar' });
    // Presentation differs; the underlying value must not.
    expect(english).not.toBe('');
    expect(arabic).not.toBe('');
  });

  it('renders a placeholder rather than zero for a malformed amount', () => {
    // A wrong number on a financial screen is worse than an obvious gap.
    expect(formatMoney({ amount: 'not-a-number', currency: 'AED' }, { locale: 'en' })).toBe('—');
    expect(formatMoney({ amount: '', currency: 'AED' }, { locale: 'en' })).not.toContain('0.00');
  });

  it('does not lose precision on values that break float arithmetic', () => {
    const output = formatMoney({ amount: '0.10', currency: 'USD' }, { locale: 'en' });
    expect(output).toContain('0.10');
  });

  it('formats numbers and percentages', () => {
    expect(formatNumber(1234.5, 'en')).toContain('1,234');
    expect(formatPercent(0.075, 'en')).toContain('7.5');
  });
});
