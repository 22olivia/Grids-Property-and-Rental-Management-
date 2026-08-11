import { test, expect } from '@playwright/test';
import AxeBuilder from '@axe-core/playwright';

const LOCALES = ['en', 'ar'] as const;

for (const locale of LOCALES) {
  test.describe(`crm (${locale})`, () => {
    test('pipeline is operable by keyboard, not drag-only @a11y', async ({ page }) => {
      await page.goto(`/${locale}/console/crm/pipeline`);
      // Every card carries named move buttons; there is no drag-only path.
      const moveButtons = page.getByRole('button', { name: /move|نقل/i });
      await expect(moveButtons.first()).toBeVisible();
      await expect(moveButtons.first()).toBeEnabled();
    });

    test('lead form requires a contact method', async ({ page }) => {
      await page.goto(`/${locale}/console/crm/leads/new`);
      await page.getByRole('button', { name: /add lead|إضافة عميل/i }).click();
      await expect(page.getByRole('alert').first()).toBeVisible();
    });

    test('viewings view toggle survives clearing filters', async ({ page }) => {
      await page.goto(`/${locale}/console/crm/viewings?view=table&status=attended`);
      await page.getByRole('button', { name: /clear filters|مسح عوامل التصفية/i }).click();
      // The view is a layout choice, not a filter — it must persist.
      await expect(page).toHaveURL(/view=table/);
    });

    test('no accessibility violations on the leads list @a11y', async ({ page }) => {
      await page.goto(`/${locale}/console/crm/leads`);
      const results = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
        .analyze();
      expect(results.violations).toEqual([]);
    });

    test('no accessibility violations on the pipeline @a11y', async ({ page }) => {
      await page.goto(`/${locale}/console/crm/pipeline`);
      const results = await new AxeBuilder({ page })
        .withTags(['wcag2a', 'wcag2aa', 'wcag21a', 'wcag21aa'])
        .analyze();
      expect(results.violations).toEqual([]);
    });

    test('leads table collapses to cards on a narrow viewport', async ({ page }) => {
      await page.setViewportSize({ width: 375, height: 800 });
      await page.goto(`/${locale}/console/crm/leads`);
      await expect(page.getByRole('table')).toBeHidden();
    });
  });
}
