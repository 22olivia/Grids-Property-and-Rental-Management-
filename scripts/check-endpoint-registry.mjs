#!/usr/bin/env node
/**
 * Guards the API boundary.
 *
 * Two rules, both learned the hard way on this project:
 *
 * 1. No source file may contain a hardcoded upstream URL. Every call must go
 *    through the endpoint registry, so "which endpoints do we depend on?" has
 *    one answer.
 * 2. No `server-only` module may be reachable from a `'use client'` file.
 *    That is what keeps the Sanctum token out of the browser.
 */
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, extname } from 'node:path';

function walk(dir, files = []) {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) walk(full, files);
    else if (['.ts', '.tsx'].includes(extname(full))) files.push(full);
  }
  return files;
}

const files = walk('src');
let failures = 0;

// Rule 1 — no hardcoded upstream hosts outside comments.
for (const file of files) {
  const code = readFileSync(file, 'utf8')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/(^|[^:])\/\/.*$/gm, '$1');
  const match = code.match(/['"`]https?:\/\/(?!localhost:3000)[^'"`]+/);
  if (match) {
    console.error(`  ${file}: hardcoded URL ${match[0].slice(0, 60)}`);
    failures++;
  }
}

// Rule 2 — server-only isolation.
const serverOnly = new Set(
  files
    .filter((f) => readFileSync(f, 'utf8').includes("import 'server-only'"))
    .map((f) => '@/' + f.replace(/^src\//, '').replace(/\.tsx?$/, '')),
);
for (const file of files) {
  const source = readFileSync(file, 'utf8');
  if (!source.startsWith("'use client'")) continue;
  for (const match of source.matchAll(/from '(@\/[^']+)'/g)) {
    if (serverOnly.has(match[1])) {
      console.error(`  ${file}: client component imports server-only ${match[1]}`);
      failures++;
    }
  }
}

if (failures > 0) {
  console.error(`\n${failures} API-boundary violation(s).`);
  process.exit(1);
}
console.log(
  `Contract check passed: no hardcoded URLs, ${serverOnly.size} server-only module(s) isolated.`,
);

// Rule 3 — no duplicate keys in the endpoint registry. A duplicated object key
// is silently legal in JS: the last wins, so a stale definition can shadow a
// corrected one with no error anywhere.
{
  const registry = readFileSync('src/lib/api/endpoints.ts', 'utf8');
  const keys = [...registry.matchAll(/^\s{2}'?([\w.]+)'?:\s*\{ path:/gm)].map((m) => m[1]);
  const seen = new Set();
  const duplicates = keys.filter((key) => (seen.has(key) ? true : (seen.add(key), false)));
  if (duplicates.length > 0) {
    console.error(`  duplicate endpoint key(s): ${[...new Set(duplicates)].join(', ')}`);
    process.exit(1);
  }
  console.log(`Registry check passed: ${keys.length} unique endpoint keys.`);
}

// Rule 4 — every console SCREEN declares whether it is showing fixtures.
// A screen that silently omits the banner is the failure mode this whole
// mechanism exists to prevent: sample data presented as real.
{
  const screens = walk('src/app').filter(
    (f) => /page\.tsx$/.test(f) && f.includes('/console/'),
  );
  const missing = screens.filter((f) => {
    const source = readFileSync(f, 'utf8');
    // Redirect-only routes render no UI and need no banner.
    if (/^\s*redirect\(/m.test(source) && !/return \(/.test(source)) return false;
    return !/isMock=|MockDataNotice/.test(source);
  });
  if (missing.length > 0) {
    for (const file of missing) console.error(`  ${file}: no mock-data declaration`);
    process.exit(1);
  }
  console.log(`Demo check passed: all ${screens.length} console screens declare their data source.`);
}
