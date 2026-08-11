import { defineConfig, devices } from '@playwright/test';

/**
 * Both locales run as separate projects. Every visual and a11y assertion is
 * therefore executed in Arabic RTL as well as English LTR — SRS AC-09 requires
 * both to work, and RTL breakage is silent unless it is asserted.
 */
export default defineConfig({
  testDir: './e2e',
  fullyParallel: true,
  forbidOnly: !!process.env.CI,
  retries: process.env.CI ? 2 : 0,
  reporter: process.env.CI ? 'github' : 'html',
  use: {
    baseURL: process.env.NEXT_PUBLIC_APP_URL ?? 'http://localhost:3000',
    trace: 'on-first-retry',
  },
  projects: [
    { name: 'en-desktop', use: { ...devices['Desktop Chrome'], locale: 'en' } },
    { name: 'ar-desktop', use: { ...devices['Desktop Chrome'], locale: 'ar' } },
    { name: 'en-mobile', use: { ...devices['Pixel 7'], locale: 'en' } },
    { name: 'ar-mobile', use: { ...devices['Pixel 7'], locale: 'ar' } },
  ],
  webServer: {
    command: 'npm run dev',
    url: 'http://localhost:3000',
    reuseExistingServer: !process.env.CI,
  },
});
