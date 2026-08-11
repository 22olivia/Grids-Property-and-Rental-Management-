import js from '@eslint/js';
import tseslint from 'typescript-eslint';
import { FlatCompat } from '@eslint/eslintrc';

/**
 * eslint-config-next 15.1 is an eslintrc-style config with no flat export, so
 * it cannot be spread into a flat config array directly. FlatCompat is the
 * supported bridge and keeps Next's rules (including the React and a11y sets)
 * active alongside our own.
 */
const compat = new FlatCompat({ baseDirectory: import.meta.dirname });

/**
 * Physical CSS direction utilities are banned project-wide.
 *
 * SRS NFR-I18N-001 (Must) requires Arabic RTL and English LTR "without
 * duplicated business logic". The mechanism that makes that achievable is
 * logical CSS properties: a layout written with `ms-4` mirrors automatically,
 * one written with `ml-4` does not. Catching this at lint time costs nothing;
 * auditing it across 130+ screens at FE-6 is expensive and unreliable.
 *
 * Escape hatch: // eslint-disable-next-line gpms/no-physical-direction
 * plus a comment explaining why the element must not mirror.
 */
const PHYSICAL_UTILITY_PATTERN =
  '/(^|\\s)-?(ml|mr|pl|pr|left|right|border-l|border-r|rounded-l|rounded-r|rounded-tl|rounded-tr|rounded-bl|rounded-br|float-left|float-right|text-left|text-right|origin-left|origin-right|inset-l|inset-r)(-|$|\\s)/';

export default tseslint.config(
  js.configs.recommended,
  ...tseslint.configs.recommended,
  ...compat.extends('next/core-web-vitals'),
  {
    ignores: ['.next/**', 'node_modules/**', 'coverage/**', 'playwright-report/**'],
  },
  {
    files: ['**/*.{ts,tsx}'],
    rules: {
      '@typescript-eslint/no-unused-vars': [
        'error',
        { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
      ],
      '@typescript-eslint/no-explicit-any': 'error',
      '@typescript-eslint/consistent-type-imports': 'error',
      'no-restricted-syntax': [
        'error',
        {
          selector: `Literal[value=${PHYSICAL_UTILITY_PATTERN}]`,
          message:
            'Physical direction utility detected. Use logical equivalents (ms-/me-/ps-/pe-/start-/end-/text-start/text-end/border-s/border-e) so the layout mirrors in Arabic RTL. See NFR-I18N-001. Run `npm run lint:rtl` for the authoritative check.',
        },
        {
          selector: `TemplateElement[value.raw=${PHYSICAL_UTILITY_PATTERN}]`,
          message:
            'Physical direction utility detected in a template literal. Use logical equivalents. See NFR-I18N-001.',
        },
        {
          selector: "MemberExpression[property.name='dir'][object.name='document']",
          message:
            'Do not read direction from the DOM. Direction is set once on <html> from the locale; components must mirror via logical CSS properties, not JavaScript branching.',
        },
        {
          selector:
            "BinaryExpression[operator='==='] > Identifier[name='locale'] ~ Literal[value='ar']",
          message:
            'Do not branch on locale to change behaviour. NFR-I18N-001 requires no duplicated business logic between languages. Locale may affect formatting and message lookup only.',
        },
      ],
      // Money must never be a bare number in this codebase — see src/domain/money.
      'no-restricted-imports': [
        'error',
        {
          patterns: [
            {
              group: ['../../features/*', '../../../features/*'],
              message:
                'Features must not import from other features. Promote shared code to src/domain or src/lib. Mirrors the backend dependency rule in EN-ARC-004.',
            },
          ],
        },
      ],
    },
  },
  {
    // The i18n and formatting layers are the only places allowed to know about
    // locale semantics. The direction utility is allowed to name directions.
    files: ['src/lib/i18n/**', 'src/domain/money/**', 'src/domain/datetime/**'],
    rules: { 'no-restricted-syntax': 'off' },
  },
);
