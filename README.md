# GPMS Web — Grids Property Management System

Frontend for GPMS. Next.js 15, TypeScript, Tailwind CSS.
Bilingual: English (LTR) and Arabic (RTL).

> **Status — 35 screens implemented.**
> 11 run against the real GPMS API · 22 run on sample data because the backend
> has no endpoints for them yet · 2 are partial with the reason shown on screen.
>
> Full breakdown: **[docs/DEMO-STATUS.md](./docs/DEMO-STATUS.md)**

---

## Quick start

**New to this? Follow [docs/SETUP-VS-CODE.md](./docs/SETUP-VS-CODE.md) instead —
it assumes nothing.**

### 1. Prerequisites

- **Node.js 20.11 or newer** — <https://nodejs.org> (LTS)
- **VS Code** — <https://code.visualstudio.com>
- **Git** — only if you are pushing to GitHub

Check: `node --version` should print v20.11 or higher.

### 2. Install

```bash
npm install
```

### 3. Configure

```bash
cp .env.example .env.local        # macOS / Linux
# Copy-Item .env.example .env.local   (Windows PowerShell)
```

Open `.env.local` and pick a mode.

**Demo mode — no backend needed** (use this for the CEO demo):

```env
NEXT_PUBLIC_DATA_SOURCE=mock
```

**Real backend mode** (the Laravel API must be running):

```env
NEXT_PUBLIC_DATA_SOURCE=http
GPMS_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

### 4. Run

```bash
npm run dev
```

Open <http://localhost:3000>. Stop with `Ctrl + C`.

---

## Demo credentials

**Demo mode only.** Any password works.

| Role | Email |
|---|---|
| Super Admin | `admin@rental.test` |
| Owner | `owner@grids.test` |
| Manager | `manager@grids.test` |
| Tenant | `tenant@grids.test` |

These accounts are a local fixture and grant no permissions — the real `/me`
returns none either. In real-backend mode you need credentials from the backend
developer.

---

## Which screens use real data

### Real backend — 11

Sign in · session/sign out · Properties (list, detail, create, edit, delete) ·
Buildings (list, detail with floors, delete) · Units (list, detail, create,
edit, delete).

### Sample data — 22

**Listings (8)** — list, detail with lifecycle workflow, create, edit, media,
approval queue, projects, project detail.

**CRM (14)** — leads list/detail/create/edit, property matching, pipeline
board, activities, viewings, viewing detail, offers, offer negotiation, deals,
commissions, assignment rules.

Every sample-data screen displays an amber banner saying so. Real-API screens
do not.

### Partial — 2

| Screen | Disabled | Why |
|---|---|---|
| Listing media | Upload | Upload transport undecided (signed URL vs multipart) |
| Lead import | The importer | Needs upload transport and background-job contract |

---

## Known limitations

**Waiting on backend endpoints:**

- No sorting on any list — no endpoint reads a sort parameter
- No search on properties, buildings or units
- No availability timeline, change history, duplicate detection, custom fields
  or ownership percentages — no endpoints exist, and none is faked
- Listings and CRM have no backend at all

**Backend defects to fix** — see [docs/BACKEND-DEFECT-REPORT.md](./docs/BACKEND-DEFECT-REPORT.md):

1. **Critical:** `GET /properties` applies no organisation scoping — any staff
   user receives every organisation's properties
2. `GET /buildings` scopes only on a client-supplied parameter
3. `GET /properties` ignores `per_page`

**Requirement conflicts:** no permission list in `/me` (role-based only);
Sanctum issues one long-lived token with no refresh rotation; currency is
stored only on payments; the backend is English-only, so server validation
messages appear in English inside the Arabic interface.

---

## Commands

```bash
npm run dev            # start development server
npm run build          # production build
npm run verify         # all quality checks
npm run lint:rtl       # physical CSS direction properties (breaks Arabic)
npm run lint:i18n      # English / Arabic message parity
npm run lint:keys      # every message key used in code exists
npm run lint:contract  # no hardcoded URLs; server-only modules isolated
npm run typecheck
npm run lint
npm run test:unit
npm run test:e2e       # both locales, both directions, includes accessibility
```

The four `lint:*` checks run on plain Node with no dependencies, so they work
in CI before `npm install`.

> **Not yet verified.** `npm install`, TypeScript, ESLint, the Next.js build,
> Vitest and Playwright have **never been executed** against this code — it was
> written in an environment without internet access, so dependencies were never
> installed. Run `npm install && npm run verify && npm run build` first and
> expect a small number of first-compile type errors.

---

## Project structure

```
src/app/[locale]/          routes, grouped by surface (marketing / auth / app)
src/app/api/               BFF — holds the auth token server-side
src/design-system/         design tokens + 28 UI primitives
src/domain/                money, dates, shared components, screen kits
src/features/ast/          property assets — LIVE against the API
src/features/lst/          listings — sample data
src/features/crm/          CRM — sample data
src/lib/                   api client, auth, permissions, i18n, forms, tables
messages/                  en.json, ar.json
docs/                      status, setup, handoff, backend reports
scripts/                   dependency-free CI checks
tests/  e2e/               unit and end-to-end tests
```

**Data access is a repository per module** with mock and HTTP implementations
behind one interface. Connecting a module to a real API is a one-line binding
change — no screen is rewritten.

**The auth token never reaches the browser.** It lives in an httpOnly cookie;
every API call passes through a BFF route handler that attaches it server-side.
A CI rule enforces that no `server-only` module can be imported by client code.

---

## Rules for contributors

1. **Logical CSS only** — `ms-*`, `me-*`, `ps-*`, `pe-*`, `start-*`, `end-*`.
   Never `ml-*`, `left-*`, `text-left`. Enforced by lint; this is what makes
   Arabic work.
2. **No hard-coded user-facing text.** Every string is a key in `messages/`.
   CI fails if Arabic falls behind.
3. **Never branch on role name.** Roles are configurable data.
4. **Never compute money.** Format server-computed decimal strings; never call
   `Number()` on an amount.
5. **Never invent an endpoint.** Add it to `src/lib/api/endpoints.ts` once the
   backend publishes it. Unimplemented keys throw rather than guess a URL.

---

## Documentation

| Document | For |
|---|---|
| [docs/DEMO-STATUS.md](./docs/DEMO-STATUS.md) | CEO and product — what can be shown today |
| [docs/SETUP-VS-CODE.md](./docs/SETUP-VS-CODE.md) | Anyone running it locally |
| [docs/GITHUB-HANDOFF.md](./docs/GITHUB-HANDOFF.md) | Pushing to GitHub |
| [docs/BACKEND-DEFECT-REPORT.md](./docs/BACKEND-DEFECT-REPORT.md) | Backend developer — defects found |
| [docs/BACKEND-CONTRACT-REQUEST.md](./docs/BACKEND-CONTRACT-REQUEST.md) | Backend developer — what the frontend needs |
| [docs/SCREEN-STATUS.md](./docs/SCREEN-STATUS.md) | Per-screen register |
| [docs/MISSING-INFORMATION.md](./docs/MISSING-INFORMATION.md) | Open product questions |
| [docs/UNRESOLVED-ROLES.md](./docs/UNRESOLVED-ROLES.md) | Role model conflicts |
| [docs/ARCHITECTURE.md](./docs/ARCHITECTURE.md) | Technical decisions |
| [docs/DEPENDENCY-NOTES.md](./docs/DEPENDENCY-NOTES.md) | Version compatibility — read before upgrading |
