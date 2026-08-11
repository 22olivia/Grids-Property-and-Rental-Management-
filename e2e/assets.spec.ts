import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

/**
 * Property Assets module — both locales, both directions.
 * Business assertions are limited to behaviour the SRS specifies.
 */
const LOCALES = ['en', 'ar'] as const;

for (const locale of LOCALES) {
  test.describe(`assets (${locale})`, () => {
    test('properties list renders with a caption and pagination @a11y', async ({ page }) => {
      await page.goto(`/${locale}/console/assets/properties`);
      await expect(page.getByRole('table')).toBeVisible();
      await expect(page.getByRole('navigation', { name: /pagination|ترقيم/i })).toBeVisible();
    });

    test('filters write to the URL so the view is shareable', async ({ page }) => {
      await page.goto(`/${locale}/console/assets/units`);
      await page.getByRole('searchbox').fill('Unit 1');
      await expect(page).toHaveURL(/q=Unit\+1/);
    });

    test('over-filtering shows no-results, not no-data', async ({ page }) => {
      await page.goto(`/${locale}/console/assets/units?q=zzzz-no-match`);
      // The distinction matters: telling a user their records are gone when
      // they have merely over-filtered is alarming and false.
      await expect(page.locator('[data-empty-kind="no-results"]')).toBeVisible();
    });

    test('unit detail exposes the availability timeline as a list @a11y', async ({ page }) => {
      await page.goto(`/${locale}/console/assets/units/unit-1/timeline`);
      // The visual band is aria-hidden; the list is the accessible source.
      await expect(page.getByRole('list')).toBeVisible();
    });

    test('no accessibility violations on the units list @a11y', async ({ page }) => {
      await page.goto(`/${locale}/console/assets/units`);
      const results = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
        .analyze();
      expect(results.violations).toEqual([]);
    });

    test('create form reports validation errors accessibly @a11y', async ({ page }) => {
      await page.goto(`/${locale}/console/assets/properties/new`);
      await page.getByRole('button', { name: /add property|إضافة عقار/i }).click();
      await expect(page.getByRole('alert').first()).toBeVisible();
    });

    test('units table becomes a card list on a narrow viewport', async ({ page }) => {
      await page.setViewportSize({ width: 375, height: 800 });
      await page.goto(`/${locale}/console/assets/units`);
      await expect(page.getByRole('table')).toBeHidden();
      await expect(page.getByRole('list').first()).toBeVisible();
    });
  });
}
