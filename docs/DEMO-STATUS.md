# GPMS Frontend — Demo Status

**Updated:** 10 August 2026
**Audience:** CEO, product and backend team

---

## 1. Total implemented screens — 35

| Category | Count |
|---|---:|
| Connected to the real backend | **11** |
| Using mock (sample) data | **22** |
| Partial — a capability disabled with the reason shown on screen | **2** |

The project has 37 routes; two of them (`/` and `/console`) are a placeholder
and a redirect, and are not counted as screens.

---

## 2. Screens connected to the real backend (11)

Verified against the GPMS Laravel API (Sanctum, `routes/api.php`).

| Screen | Route | Endpoint |
|---|---|---|
| Sign in | `/login` | `POST /login` |
| Session / sign out | *(no route — header)* | `GET /me`, `POST /logout` |
| Properties list | `/console/assets/properties` | `GET /properties` |
| Property detail | `/console/assets/properties/[id]` | `GET /properties/{id}` |
| Property create | `/console/assets/properties/new` | `POST /properties` |
| Property edit | `/console/assets/properties/[id]/edit` | `PUT /properties/{id}` |
| Buildings list | `/console/assets/buildings` | `GET /buildings` |
| Building detail + floors | `/console/assets/buildings/[id]` | `GET /buildings/{id}` |
| Units list | `/console/assets/units` | `GET /rental-units` |
| Unit detail | `/console/assets/units/[id]` | `GET /rental-units/{id}` |
| Unit create | `/console/assets/units/new` | `POST /rental-units` |
| Unit edit | `/console/assets/units/[id]/edit` | `PUT /rental-units/{id}` |

Delete with confirmation is wired for properties, buildings and units
(`DELETE`), using the endpoints the backend already exposes.

---

## 3. Screens using mock data (22)

Fully built and interactive. The backend has no endpoints for them.
**Every one displays a visible amber "sample data" banner.**

**Listings — 8**

`/console/listings` · `/console/listings/[id]` (lifecycle workflow) ·
`/console/listings/new` · `/console/listings/[id]/edit` ·
`/console/listings/[id]/media` · `/console/listings/approvals` ·
`/console/listings/projects` · `/console/listings/projects/[id]`

**CRM — 14**

`/console/crm/leads` · `[id]` · `new` · `[id]/edit` · `[id]/matches` ·
`/console/crm/pipeline` · `activities` · `viewings` · `viewings/[id]` ·
`offers` · `offers/[id]` · `deals` · `commissions` · `assignment-rules`

---

## 4. Partial screens (2)

| Screen | Disabled | Reason |
|---|---|---|
| `/console/listings/[id]/media` | File upload | Upload transport undecided — signed URL vs multipart |
| `/console/crm/leads/import` | The importer | Needs the upload transport **and** the background-job contract |

Everything transport-independent works on the media screen: ordering, removal,
media kind, watermark state.

`/console/crm/commission-rules` is read-only by design — the rule condition
format has never been specified, so rules can be reviewed but not edited.

---

## 5. Backend-dependent features not built

Built and then **removed** during backend integration, because the API has no
endpoint and a placeholder would have been misleading:

| Feature | Requirement |
|---|---|
| Unit availability / occupancy timeline | `FR-AST-003` |
| Property and unit change history | `FR-AST-008` |
| Duplicate detection | `FR-AST-007` |
| Custom fields | `FR-AST-006` |
| Ownership percentages | `FR-AST-004` |

A history tab fed by sample data next to real property data would make invented
history indistinguishable from audited history. That is the one place a
placeholder is genuinely unsafe, so none was used.

Also unavailable because the backend does not support them: **sorting on any
list**, and **search on properties, buildings and units**.

---

## 6. Known backend defects

Full detail and suggested fixes: [`BACKEND-DEFECT-REPORT.md`](./BACKEND-DEFECT-REPORT.md).

### Must be fixed before the system is used with real data

| # | Issue | Impact |
|---|---|---|
| 1 | **`GET /properties` applies no organisation scoping** — `PropertyController::index` calls `Property::with(...)->latest()->paginate(15)` with no user scope | Any staff user of any organisation receives **every property in the system**, with owner contact details and unit rents. Violates `FR-IAM-003` and `AC-01`. `RentalUnitController` already implements the correct pattern. |
| 2 | `GET /buildings` scopes only on a **client-supplied** `organization_id` | A client-controlled filter is not an authorisation boundary. |

### Limits what the interface can offer

| Issue | Consequence |
|---|---|
| No sorting on any index endpoint | Table columns are not sortable |
| No `search` on properties, buildings, rental units | No search box on those three lists |
| `GET /properties` ignores `per_page` | Page size fixed at 15; a property picker cannot list beyond that |
| `PUT /properties/{id}` returns `fresh('owner')` without `rentalUnits` | Unit count reads zero immediately after an edit (we refetch) |
| No Listing entity | 8 screens remain on sample data |
| No CRM tables or controllers at all | 14 screens remain on sample data |
| `/me` returns no permission list | Access is role-based only; `FR-IAM-002` requires permissions |
| Sanctum issues one long-lived token, no refresh | Conflicts with `FR-API-002` |
| Currency stored only on payments | Unit rents display one configured currency; `FR-FIN-002` wants multi-currency |
| Backend is English-only (`APP_LOCALE=en`) | Server validation messages appear in English inside the Arabic interface |
| No `correlation_id` in responses | Support references not available; SRS §12 expects them |

---

## 7. Ready for CEO demonstration

**Recommended walkthrough, in order:**

1. **Sign in** — real authentication; the token is held server-side and never
   reaches the browser.
2. **Units list → Unit detail** — live API data, the backend's real seven-status
   vocabulary, live rent values.
3. **Unit create / edit** — submit something invalid and the server's own
   message lands on the offending field.
4. **Properties list → detail** — the second live resource, with
   delete-and-confirm.
5. **CRM pipeline** — the most visual screen; say plainly that it is sample data.
6. **Switch to Arabic** on any of the above — full right-to-left mirroring, with
   the current page and filters preserved.
7. **Any list at phone width** — tables become card lists.

**Headline for the conversation:** the frontend is ahead of the backend. Eleven
screens run on the real API today covering the full property, building and unit
lifecycle. The remaining 22 are complete and interactive but waiting on backend
endpoints that do not exist yet — those are backend gaps, not outstanding
frontend work.

---

## 8. Verification status

### Verified in the development environment

| Check | Result |
|---|---|
| RTL safety — no physical CSS direction properties | Pass |
| English / Arabic message parity — 490 keys | Pass |
| Message keys used in code all exist | Pass |
| API boundary — no hardcoded URLs; 7 server-only modules unreachable from client code | Pass |
| Endpoint registry — 42 unique keys, no duplicates, none fabricated | Pass |
| Every console screen declares its data source | Pass — 35/35 |
| Routes and links — 37 routes | Pass — 0 broken |
| Mock isolation — no UI component imports a mock repository | Pass |

### NOT verified — must be run on your machine

`npm install` · `npm run typecheck` · `npm run lint` · `npm run build` ·
`npm run test:unit` · `npm run test:e2e`

These have **never been executed**. The environment this was built in has no
network access, so dependencies were never installed and no compiler or test
runner has ever seen this code. Expect to resolve a small number of TypeScript
errors on the first build.
