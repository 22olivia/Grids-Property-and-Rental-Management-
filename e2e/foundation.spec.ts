import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

/**
 * FE-0 foundation checks. No business assertions — there are no business
 * screens. These verify the foundation itself holds in both directions.
 */

const LOCALES = [
  { code: 'en', direction: 'ltr' },
  { code: 'ar', direction: 'rtl' },
] as const;

for (const { code, direction } of LOCALES) {
  test.describe(`locale: ${code}`, () => {
    test('sets lang and dir on the document', async ({ page }) => {
      await page.goto(`/${code}`);
      const html = page.locator('html');
      await expect(html).toHaveAttribute('lang', code);
      await expect(html).toHaveAttribute('dir', direction);
    });

    test('skip link is the first focusable element @a11y', async ({ page }) => {
      await page.goto(`/${code}`);
      await page.keyboard.press('Tab');
      const focused = page.locator(':focus');
      await expect(focused).toHaveAttribute('href', '#main-content');
    });

    test('exposes a main landmark', async ({ page }) => {
      await page.goto(`/${code}`);
      await expect(page.locator('#main-content')).toBeVisible();
    });

    test('login form controls are programmatically labelled @a11y', async ({ page }) => {
      await page.goto(`/${code}/login`);
      // getByLabel resolves through the label/for association, so this fails
      // if Field ever stops wiring ids correctly.
      await expect(page.getByLabel(/.+/).first()).toBeVisible();
    });

    test('has no detectable accessibility violations @a11y', async ({ page }) => {
      await page.goto(`/${code}`);
      const results = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
        .analyze();
      expect(results.violations).toEqual([]);
    });

    test('does not scroll horizontally at the narrowest breakpoint', async ({ page }) => {
      // Arabic runs longer than English for the same content, so this is the
      // worst case and the reason both locales are asserted.
      await page.setViewportSize({ width: 320, height: 720 });
      await page.goto(`/${code}`);
      const overflow = await page.evaluate(
        () => document.documentElement.scrollWidth > document.documentElement.clientWidth,
      );
      expect(overflow).toBe(false);
    });
  });
}

test('language switcher preserves the query string', async ({ page }) => {
  await page.goto('/en?ref=test');
  await page.getByRole('button', { name: /change language|تغيير اللغة/i }).click();
  await page.getByRole('menuitem', { name: 'العربية' }).click();
  await expect(page).toHaveURL(/\/ar\?ref=test/);
});
