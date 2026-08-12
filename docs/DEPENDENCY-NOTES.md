# Dependency compatibility notes

Why certain versions are pinned or ranged the way they are. Read this before
upgrading — each entry records a failure that was actually observed.

---

## next-intl — pinned to `3.26.3` (v3 line)

**Do not import `hasLocale`.** It is a **next-intl v4** export. On v3 the build
fails with:

```
Attempted import error: 'hasLocale' is not exported from 'next-intl'
```

Use the project's own `isLocale` type guard from `src/lib/i18n/config.ts`
instead — same locale list, same behaviour.

APIs used from v3 and confirmed available on 3.26:
`defineRouting`, `createNavigation`, `setRequestLocale`, `getTranslations`,
`getMessages`, `getRequestConfig`, `NextIntlClientProvider`.

**If upgrading to next-intl v4:** the routing and navigation APIs changed. Plan
it as a deliberate migration, not a version bump.

---

## Tailwind CSS — `^4.1.0` on BOTH packages

`tailwindcss` and `@tailwindcss/postcss` must resolve to the **same minor
line**. They were previously pinned to an exact `4.0.0`, but
`@tailwindcss/postcss` depends on `@tailwindcss/oxide` with a caret range, so
npm installed the 4.1.x scanner against the 4.0.0 core. The 4.1 scanner expects
a field the 4.0 core never sends:

```
Error: Missing field `negated` on ScannerOptions.sources
```

Caret ranges on both keep them in lockstep. **If you pin one, pin the other to
the same version.**

---

## Next.js — `15.1.6`

**`typedRoutes` is not a top-level config key** in 15.1. It lives under
`experimental.typedRoutes`. As a root key it is ignored and warns:

```
Unrecognized key(s) in object: 'typedRoutes'
```

It is currently not set at all (the default is off, which is what we want).

**Route `params` and `searchParams` are Promises in Next 15.** Every page and
route handler must type them as `Promise<...>` and `await` them. Typing them
synchronously compiles but throws at request time — this caused a 500 on `/en`.

**`cookies()` and `headers()` are async.** Always `await` them.

**Hooks cannot be used in `async` Server Components.** If a component must
`await params`, it must use `getTranslations` from `next-intl/server` rather
than the `useTranslations` hook.

---

## ESLint — flat config via `FlatCompat`

`eslint-config-next@15.1` is an eslintrc-style config with **no flat export**,
so it cannot be spread into a flat config array. `@eslint/eslintrc`'s
`FlatCompat` bridges it:

```js
const compat = new FlatCompat({ baseDirectory: import.meta.dirname });
// ...
...compat.extends('next/core-web-vitals'),
```

`@eslint/eslintrc` is therefore a required devDependency.

---

## Do not run `npm audit fix --force`

It will bump majors across next, next-intl and Tailwind simultaneously and
reintroduce every incompatibility above. Address advisories individually.
