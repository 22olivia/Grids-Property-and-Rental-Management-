#!/usr/bin/env node
/**
 * Verifies that every literal message key used in code exists in en.json.
 *
 * Catches the failure mode that i18n parity does not: a key that is missing
 * from BOTH catalogues. Parity only proves the two files agree, not that they
 * contain what the code asks for.
 *
 * Only literal keys are checked — dynamically composed keys (e.g.
 * `ast.unitStatus.${status}`) are verified by unit tests instead.
 */
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, extname } from 'node:path';

const catalogue = JSON.parse(readFileSync('messages/en.json', 'utf8'));

function flatten(object, prefix = '', keys = new Set()) {
  for (const [key, value] of Object.entries(object)) {
    const path = prefix ? `${prefix}.${key}` : key;
    if (value && typeof value === 'object') flatten(value, path, keys);
    else keys.add(path);
  }
  return keys;
}
const keys = flatten(catalogue);

function walk(dir, files = []) {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) walk(full, files);
    else if (['.ts', '.tsx'].includes(extname(full))) files.push(full);
  }
  return files;
}

let missing = 0;
for (const file of walk('src')) {
  // Strip comments first. Doc comments legitimately contain code samples such
  // as `t('validation.' + message)`, and flagging documentation as a missing
  // key trains people to ignore the check.
  const source = readFileSync(file, 'utf8')
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/(^|[^:])\/\/.*$/gm, '$1');
  // Namespaces declared via useTranslations('x') or getTranslations('x')
  const namespaces = [...source.matchAll(/(?:use|get)Translations\('([\w.]+)'\)/g)].map((m) => m[1]);

  for (const match of source.matchAll(/\bt[a-z]?\('([\w.\-]+)'/g)) {
    const raw = match[1];
    const candidates = [raw, 'common.' + raw, ...namespaces.map((ns) => `${ns}.${raw}`)];
    if (!candidates.some((candidate) => keys.has(candidate))) {
      console.error(`  ${file}: missing message key "${raw}"`);
      missing++;
    }
  }
  for (const match of source.matchAll(/labelKey:\s*'([\w.\-]+)'/g)) {
    if (!keys.has(match[1])) {
      console.error(`  ${file}: missing labelKey "${match[1]}"`);
      missing++;
    }
  }
}

if (missing > 0) {
  console.error(`\n${missing} missing message key(s).`);
  process.exit(1);
}
console.log(`Message key check passed: all literal keys resolve against ${keys.size} entries.`);
