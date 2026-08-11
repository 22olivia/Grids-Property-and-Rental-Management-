# Backend contract request — GPMS frontend

**Purpose:** the exact information the frontend needs in order to switch from
mock repositories to the real API. Ordered by what unblocks the most screens.

**Status of the repository review (9 Aug 2026):** the repository at
`github.com/22olivia/Grids-Property-and-Rental-Management-` could not be read.
Its file contents are behind GitHub's automated-access restrictions. **No
endpoint, field, role or format below has been inferred** — every item is still
an open question.

**How to answer:** one file per section is fine. An OpenAPI document, a Postman
collection export, or the Laravel `routes/api.php` file plus one example
request/response per resource would answer most of this at once.

---

## Section 0 — Fastest path

If any of the following exist, send them and most of this document is answered:

1. `routes/api.php` (or equivalent route file)
2. An OpenAPI / Swagger document
3. A Postman collection export
4. One real HTTP response body per resource, copied verbatim including headers

---

## Section 1 — BLOCKING. Nothing authenticated can be connected without these.

| # | Question | Why it blocks | Frontend file waiting |
|---|---|---|---|
| B1 | **Auth endpoints**: paths and methods for login, logout, refresh, and the current-user lookup. | Every authenticated screen. | `src/lib/api/endpoints.ts` |
| B1a | **Login request body** — exact field names. Is the identifier `email`, `username`, `login`? | Login form field names. | `(auth)/login` |
| B1b | **Login response body** — verbatim. Are tokens returned? Named what? Is there an expiry field, and is it seconds or a timestamp? | Token handling. | `src/lib/auth/session.ts` |
| B2 | **Current-user response** — verbatim. Does it include a permission list? A role list? An organisation/company id? A branch id? A timezone? A locale? | Route guards, navigation, `<Can>`. | `src/lib/auth/types.ts` |
| B3 | **Permission strings** — the actual list, or confirmation that none exists yet. **This is the single most blocking item after auth.** | Nothing in the app can gate on permissions today; `PERMISSIONS` is deliberately empty. | `src/lib/permissions/types.ts` |
| B4 | **Response envelope** — is there a wrapper? SRS §12 specifies `data` / `meta` / `links` / `errors` / `correlation_id`. Does the implementation match, or does it return bare objects/arrays? | The API client parses this once at its core. | `src/lib/api/client.ts` |
| B5 | **Error body** — verbatim, for a 422 validation failure and for a 500. Are field errors keyed by field name? Is there a stable machine code? | Server errors are bound onto form fields today. | `src/lib/forms/bind-server-errors.ts` |
| B6 | **Money representation** — how is an amount sent and received? Integer minor units (150000), decimal string ("1500.00"), or float (1500.0)? Where does the currency code live? | The frontend carries money as a decimal string throughout and never converts it. A float answer needs discussion before any finance screen is built. | `src/domain/money/money.ts` |
| B7 | **Date/time representation** — ISO-8601 UTC? A different format? Is there a timezone field on the company or the user, and which one wins? | Every timestamp on every screen. | `src/domain/datetime/datetime.ts` |
| B8 | **Pagination** — page-number or cursor? What are the parameter names (`page`, `per_page`, `limit`, `offset`, `cursor`)? Where do the totals live in the response? | ~45 list screens. Both styles are currently supported, which costs more than either alone. | `src/lib/data/repository.ts` |
| B9 | **Filter, sort and search syntax** — how is a filter passed? `?status=active`, `?filter[status]=active`, something else? How is sort direction expressed? | Every list screen's URL state maps to these. | `src/lib/tables/to-list-query.ts` |
| B10 | **Tenancy** — how does the API know which company a request belongs to? A token claim, a header, a path segment? | Attaches to every request. | `src/lib/api/client.ts` |
| B11 | **Base URLs** per environment, and whether the API is versioned (`/api/v1`). | Configuration only. Keys and secrets should be sent separately, never in the repository. | `.env.example` |

---

## Section 2 — Per module. Needed before that module can be connected.

### Property assets (9 screens built)
- Endpoints for properties, buildings, floors, units — paths and methods.
- One verbatim response for a property and for a unit.
- Are `floors` a real resource or a computed attribute of a building?
- Unit **status values** — the exact strings. The frontend currently uses
  `available` / `reserved` / `occupied` / `unavailable`, each attested in the
  SRS, but the SRS never enumerates them (MI-17).
- Is there a duplicate-detection endpoint (FR-AST-007), or is duplication
  rejected only on save?
- Is there a change-history / audit endpoint (FR-AST-008)?
- **Custom fields** (FR-AST-006) — is there a field-definition endpoint? What
  shape? This blocks three forms (MI-H1).

### Listings (8 screens built)
- Endpoints for listings, listing media, projects.
- Listing **state values** and — separately — the **legal transitions** between
  them, including who may perform each. The eight states are enumerated in
  `FR-LST-006`; the transition matrix is not (MI-24).
- How is the FR-LST-008 guard surfaced? Does the API return a reason when a
  listing cannot be published, or does it only fail on attempt?
- **"Legal status"** (FR-LST-003) — what values? The SRS never says (MI-25).
- **Amenity list** — where does it come from? (MI-26)
- **Media upload** — signed URL, multipart, or something else? Is resumable
  upload supported? (MI-28) This is the only reason the media screen is partial.

### CRM (15 screens built)
- Endpoints for leads, activities, viewings, offers, deals, commissions.
- **Viewing statuses** and whether a viewing can be **cancelled** — the SRS
  never mentions cancellation (MI-29).
- **Offer states** and whether an offer can be **rejected or withdrawn** — again
  absent from the SRS (MI-30).
- **Rule conditions** (FR-CRM-002, FR-CRM-008) — is there a rule format, or are
  rules configured outside the API? Rules are read-only in the UI today (MI-31).
- **Agent directory** — how does the frontend list assignable agents? (MI-32)
- **Lead import** — is there an upload endpoint and a background-job status
  endpoint? (MI-33)
- Does the API compute **match scores** (FR-CRM-005), or is matching a frontend
  concern? The frontend assumes the former, because SRS §6 forbids
  reimplementing business rules in clients.

---

## Section 3 — Things that must NOT come through the repository

- API keys, tokens, database credentials, payment gateway secrets.
- Send environment values through the agreed secret channel. The frontend reads
  everything from environment variables and holds no secret in source.

---

## Section 4 — What the frontend will do on receipt

For each module, connecting to the real API is a three-step change with **no
screen rewrites**:

1. Implement `http<Module>Repository` against the published endpoints.
2. Add request/response schemas to `src/types/api/`.
3. Set `NEXT_PUBLIC_DATA_SOURCE=http`.

The repositories, the interfaces and the binding points already exist and are
exercised by 32 screens running on mocks.
