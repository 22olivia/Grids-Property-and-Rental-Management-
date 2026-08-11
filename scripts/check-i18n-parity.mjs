#!/usr/bin/env node
/**
 * Translation parity check.
 *
 * Fails the build when a key exists in one locale and not the other.
 * Without this, Arabic degrades one screen at a time and nobody notices until
 * UAT — by which point it is spread across the codebase.
 */
import { readFileSync } from 'node:fs';

const LOCALES = ['en', 'ar'];

function flatten(object, prefix = '', keys = new Set()) {
  for (const [key, value] of Object.entries(object)) {
    const path = prefix ? `${prefix}.${key}` : key;
    if (value && typeof value === 'object' && !Array.isArray(value)) flatten(value, path, keys);
    else keys.add(path);
  }
  return keys;
}

const catalogues = Object.fromEntries(
  LOCALES.map((locale) => [
    locale,
    flatten(JSON.parse(readFileSync(`messages/${locale}.json`, 'utf8'))),
  ]),
);

let failed = false;
for (const locale of LOCALES) {
  for (const other of LOCALES) {
    if (locale === other) continue;
    const missing = [...catalogues[other]].filter((key) => !catalogues[locale].has(key));
    if (missing.length > 0) {
      failed = true;
      console.error(`Missing in ${locale}.json (present in ${other}.json):`);
      for (const key of missing) console.error(`  ${key}`);
    }
  }
}

if (failed) {
  console.error('\nTranslation catalogues are out of sync (AC-09).');
  process.exit(1);
}
console.log(
  `i18n parity passed: ${catalogues.en.size} keys present in all ${LOCALES.length} locales.`,
);
