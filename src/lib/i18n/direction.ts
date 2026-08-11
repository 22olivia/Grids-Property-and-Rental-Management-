import type { Locale } from './config';
import { getDirection } from './config';

/**
 * Direction helpers.
 *
 * These exist ONLY for the few cases that logical CSS genuinely cannot
 * express: charting libraries that compute pixel coordinates, drag-and-drop
 * deltas, and carousel/scroll maths. Layout, spacing, borders and alignment
 * must use logical CSS properties instead — see the lint rule in
 * eslint.config.mjs.
 *
 * If you are reaching for this to position an element, that is the wrong
 * tool. Use ms-/me-/ps-/pe-/start-/end-.
 */
export type Direction = 'ltr' | 'rtl';

export function isRtl(locale: Locale): boolean {
  return getDirection(locale) === 'rtl';
}

/**
 * Sign multiplier for horizontal pixel maths (scroll offsets, drag deltas,
 * chart axis direction). Returns -1 in RTL so callers can write
 * `x * horizontalSign(dir)` instead of branching.
 */
export function horizontalSign(direction: Direction): 1 | -1 {
  return direction === 'rtl' ? -1 : 1;
}

/**
 * Maps an arrow key to a logical intent. In RTL, ArrowRight moves toward the
 * start of the reading order. Needed for roving-tabindex widgets (menus,
 * tabs, grids) to behave correctly in Arabic — WCAG 2.1.1.
 */
export function arrowKeyIntent(
  key: string,
  direction: Direction,
): 'start' | 'end' | 'up' | 'down' | null {
  switch (key) {
    case 'ArrowLeft':
      return direction === 'rtl' ? 'end' : 'start';
    case 'ArrowRight':
      return direction === 'rtl' ? 'start' : 'end';
    case 'ArrowUp':
      return 'up';
    case 'ArrowDown':
      return 'down';
    default:
      return null;
  }
}
