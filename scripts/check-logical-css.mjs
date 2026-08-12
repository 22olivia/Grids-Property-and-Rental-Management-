#!/usr/bin/env node
/**
 * RTL safety check.
 *
 * SRS NFR-I18N-001 (Must) requires Arabic RTL and English LTR "without
 * duplicated business logic". Logical CSS properties are how that is achieved:
 * `ms-4` mirrors automatically, `ml-4` does not.
 *
 * This runs without any dependencies, so it works in CI before install and is
 * the authoritative gate. The matching ESLint rule gives editor feedback.
 *
 * Escape hatch: add `rtl-exempt` in a comment on the same line, with a reason.
 */
import { readdirSync, readFileSync, statSync } from 'node:fs';
import { join, extname } from 'node:path';

const ROOTS = ['src'];
const EXTENSIONS = new Set(['.ts', '.tsx', '.css']);

const BANNED = [
  { pattern: /(?:^|["'\s`])-?(ml|mr)-[\w./[\]-]+/g, hint: 'use ms-* / me-*' },
  { pattern: /(?:^|["'\s`])-?(pl|pr)-[\w./[\]-]+/g, hint: 'use ps-* / pe-*' },
  { pattern: /(?:^|["'\s`])(left|right)-[\w./[\]-]+/g, hint: 'use start-* / end-*' },
  { pattern: /(?:^|["'\s`])border-(l|r)(-|\b)/g, hint: 'use border-s / border-e' },
  { pattern: /(?:^|["'\s`])rounded-(l|r|tl|tr|bl|br)(-|\b)/g, hint: 'use logical radius utilities' },
  { pattern: /(?:^|["'\s`])text-(left|right)\b/g, hint: 'use text-start / text-end' },
  { pattern: /(?:^|["'\s`])float-(left|right)\b/g, hint: 'use float-start / float-end' },
  { pattern: /\bmargin-(left|right)\s*:/g, hint: 'use margin-inline-start / -end' },
  { pattern: /\bpadding-(left|right)\s*:/g, hint: 'use padding-inline-start / -end' },
  { pattern: /\bborder-(left|right)(-\w+)?\s*:/g, hint: 'use border-inline-start / -end' },
  { pattern: /(?<![-\w])(left|right)\s*:\s*(?!auto)/g, hint: 'use inset-inline-start / -end' },
];

function walk(dir, files = []) {
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isDirectory()) walk(full, files);
    else if (EXTENSIONS.has(extname(full))) files.push(full);
  }
  return files;
}

let violations = 0;
for (const root of ROOTS) {
  for (const file of walk(root)) {
    const lines = readFileSync(file, 'utf8').split('\n');
    let inBlockComment = false;
    lines.forEach((line, index) => {
      // Strip comments before matching. Prose legitimately contains words like
      // "get right:" and "left over", and flagging documentation as an RTL
      // defect trains people to ignore the check.
      const trimmed = line.trim();
      if (inBlockComment) {
        if (trimmed.includes('*/')) inBlockComment = false;
        return;
      }
      // JSX comments `{/* ... */}` count as block comments too — prose inside
      // them legitimately contains words like "right-clickable".
      if (trimmed.startsWith('/*') || trimmed.startsWith('{/*')) {
        if (!trimmed.includes('*/')) inBlockComment = true;
        return;
      }
      if (trimmed.startsWith('*') || trimmed.startsWith('//')) return;
      const code = line.split('//')[0];
      if (code.includes('rtl-exempt')) return;
      for (const { pattern, hint } of BANNED) {
        pattern.lastIndex = 0;
        const match = pattern.exec(code);
        if (match) {
          console.error(
            `${file}:${index + 1}  physical direction "${match[0].trim()}" — ${hint}`,
          );
          violations++;
          break;
        }
      }
    });
  }
}

if (violations > 0) {
  console.error(
    `\n${violations} physical direction usage(s) found. These break Arabic RTL (NFR-I18N-001).`,
  );
  process.exit(1);
}
console.log('RTL check passed: no physical direction properties found.');
