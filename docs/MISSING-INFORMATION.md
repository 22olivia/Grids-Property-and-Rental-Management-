# MISSING INFORMATION register

Every item is a place where the source documents do not decide something the
frontend must decide. Nothing here is invented; each is a genuine silence in
the SRS, the backlog PDF or the bilingual workbook.

Each entry names the file(s) where the gap is marked in code.

---

## Blocking — FE-0 cannot be completed against a real backend without these

| ID | Gap | Where it bites | Source |
|---|---|---|---|
| **MI-01** | **No API contract.** `US-API-006` (publish OpenAPI + Postman) is scheduled for **Sprint 12**. SRS §12's *"Example Endpoints"* table gives ten path groups with no methods, schemas, field names, status codes or filter grammar. | `src/lib/api/endpoints.ts` — all entries `null`; `resolveEndpoint()` throws | §12 |
| **MI-01a** | **`/me` response shape unknown** — permissions, roles, organisation, branch, locale, timezone. | `src/lib/auth/types.ts` | FR-IAM-002 |
| **MI-02** | **Money wire representation undecided** — minor-unit integer vs decimal string. Floating point is excluded (risk R-04). `Money.amount` is typed `string` because a decimal string survives either decision without precision loss. | `src/domain/money/money.ts` | FR-FIN-002 |
| **MI-03** | **Pagination convention undecided.** §12 says "cursor or page pagination according to resource characteristics". Supporting both costs materially more than either. | `src/lib/api/types.ts`, `src/design-system/ui/pagination.tsx` | §12 |
| **MI-04** | **Arabic numeral system undecided** — Western `123` vs Eastern Arabic `١٢٣`. Affects money, dates, invoice numbers, phone numbers and every table; some markets have legal expectations for financial documents. Single point of change is `intlLocale.ar`. | `src/lib/i18n/config.ts` | NFR-I18N-001 |
| **MI-11** | **No permission taxonomy exists in any document.** Roles are named; permission strings, granularity and naming convention are undefined. `Permission` is a branded string rather than a union for exactly this reason. | `src/lib/permissions/types.ts`, `src/config/navigation.ts` | FR-IAM-002 |

## High — blocks the relevant module

| ID | Gap | Source |
|---|---|---|
| **MI-05** | Whether one user may belong to **multiple companies** is not stated. Determines whether an organisation switcher and a post-login selection screen exist, and whether `X-Organisation-Id` is needed at all. | FR-IAM-003 / FR-IAM-004 |
| **MI-06** | Whether additional languages are **per-company or platform-wide**, and whether a company may disable a launch language. | FR-ADM-002 |
| **MI-07** | **Password reset is absent from the documents entirely.** `FR-SEC-003` covers password *policy*; no requirement describes the forgot/reset flow. The route exists because a login screen without it is unusable. | — |
| **MI-08** | `NFR-DATA-001` says "company/user timezone" without stating **which wins** when they differ. `timeZone` is a required argument so the choice is explicit at each call site. | NFR-DATA-001 |
| **MI-09** | Whether **Hijri** display is required alongside Gregorian for `ar`. Affects every date picker and schedule. | — |
| **MI-10** | **Idempotency header name and replay semantics** unspecified. `Idempotency-Key` used as a placeholder. | FR-API-005, FR-FIN-010 |
| **MI-12** | **Refresh-token rotation semantics** unpublished — grace period, reuse detection, whether a multi-instance deployment needs a shared lock alongside the in-process single-flight guard. | FR-API-002 |
| **MI-13** | **Content-Security-Policy cannot be authored** until the map, analytics and payment providers are chosen (baseline decision #4). Deliberately not set in `next.config.ts`. | FR-API-008 |
| **MI-14** | **Week start** (Saturday / Sunday / Monday) is market-dependent and undefined. Affects every calendar surface. | — |
| **MI-15** | **Custom domain provisioning** — DNS verification and TLS issuance responsibility undefined. Host→organisation rewriting is therefore absent from `src/middleware.ts`. | FR-MKT-008 |
| **MI-16** | **No frontend error-reporting provider selected.** `EN-DEV-004` covers backend observability; there is no frontend equivalent. | EN-DEV-004 |

## Discovered while building the Property Assets module (E05)

| ID | Gap | Where it bites | Source |
|---|---|---|---|
| **MI-17** | **Unit status vocabulary and transitions.** FR-AST-003 names availability, occupancy and reservation; FR-LST-008 names "occupied or unavailable". Each of the four values used is attested in the requirement text, but the SRS gives **no definitive enumeration, no permitted transitions and no rule for who may change status**. FR-ADM-004 makes statuses configurable, which implies the vocabulary is server-supplied. | `features/ast/types.ts`, `constants.ts` — `unitStatusTone()` falls back to neutral so a new server status cannot break a list screen | FR-AST-003, FR-LST-008, FR-ADM-004 |
| **MI-18** | **Lifecycle status values not enumerated.** FR-AST-002 requires "lifecycle status" but never lists its values. Two are used for UI development. | `features/ast/types.ts` | FR-AST-002 |
| **MI-19** | **Address component fields not specified.** FR-AST-002 requires "address" without naming its parts. The six fields used are a conventional set, not a documented one. | `features/ast/schemas/asset-schemas.ts` | FR-AST-002 |
| **MI-20** | **Classification vocabulary is reference data with no endpoint.** FR-ADM-004 covers "reference data, custom fields, statuses, categories" but §12 has no endpoint group for it. Passed in from one constant per screen so it becomes an API call without touching the forms. | asset create/edit routes | FR-ADM-004 |
| **MI-21** | **Duplicate matching rules are configurable and undefined.** FR-AST-007 requires prevention "using configurable matching rules"; nothing describes the rules or where they are configured. The client warns and never blocks — the server must reject on commit. | `mock-asset-repository.findDuplicateCandidates` | FR-AST-007 |
| **MI-22** | **Floor as an entity is under-specified.** FR-AST-001 lists "floor" in the hierarchy, but no requirement gives floors attributes, a lifecycle or CRUD. Floors are read-only within a building for now. | `buildings/[id]` | FR-AST-001 |
| **MI-23** | **Ownership editing has no home.** FR-AST-004 (Should) requires multi-owner assets and percentages, but owner records belong to E06 (not built). Ownership renders read-only; building an editor here would pre-empt the OWN module's design. | `properties/[id]` ownership tab | FR-AST-004, FR-OWN-001 |

## Resolved

| ID | Was | Resolution | Date |
|---|---|---|---|
| **Scope boundary** | Option A / B / C undecided; "suitable administration surfaces" (SRS §6) undefined | **CEO decision: FULL SCOPE derived from the SRS.** All browser surfaces are Next.js; Laravel is API-only. This is Option B (227 derived screens). | 2026-08-09 |
| **API ownership** | Unclear who integrates | Backend developer confirmed he owns API integration. **Note: this does not resolve MI-01** — no contract has been published yet, so the repository adapters stay in place. | 2026-08-09 |

## Discovered while building the Listings module (E03)

| ID | Gap | Where it bites | Source |
|---|---|---|---|
| **MI-24** | **Listing state TRANSITIONS are unspecified.** FR-LST-006 enumerates the eight states verbatim, so the states are real — but nothing says which moves are legal, who may perform them, or what preconditions apply. Transitions are therefore modelled as **data returned by the repository**, never derived in the client. The mock's forward-only rule is a placeholder for UI development and is not a proposal. | `WorkflowStepper`, listing detail workflow tab | FR-LST-006, FR-ADM-004 |
| **MI-25** | **"Legal status" is named but never defined.** FR-LST-003 requires it in the listing field set; no vocabulary, values or meaning appear anywhere. Modelled as an opaque server-supplied string and entered as free text rather than inventing an enumeration. | `features/lst/types.ts`, listing form | FR-LST-003 |
| **MI-26** | **Amenity vocabulary not enumerated.** FR-LST-003 requires "amenities" without listing any. Declared once in `features/lst/reference-data.ts` so it becomes an API call in one place. | listing form | FR-LST-003, FR-ADM-004 |
| **MI-27** | **Saved searches and search alerts have no delivery model.** FR-LST-005 (Must) requires "saved searches and search alerts"; no requirement states cadence, channel or opt-out. Not built — the UI shape depends entirely on the answer. | not implemented | FR-LST-005 |
| **MI-28** | **Media upload transport undecided** (was MI-H5, now blocking real work). SRS §12 offers signed URLs *or* multipart; FR-MOB-008 implies resumable transfer. `MediaManager` implements ordering, removal, classification and watermark display; upload is explicitly disabled with a visible banner. | `MediaManager`, listing media screen | FR-LST-007, §12 |

## Discovered while building the CRM module (E04)

| ID | Gap | Where it bites | Source |
|---|---|---|---|
| **MI-29** | **Viewing statuses and transitions unspecified.** FR-CRM-006 names "attendance, feedback, rescheduling and no-show tracking" but enumerates no statuses and no transition rules. The four values used are each attested in the requirement text; **cancellation is not mentioned anywhere and is deliberately not modelled.** Recording attendance is therefore display-only. | viewing detail | FR-CRM-006 |
| **MI-30** | **Offer states unspecified.** FR-CRM-007 names offers, counteroffers, approval, expiry and deposits. Only four states are attested; **rejection and withdrawal appear nowhere** and are not modelled. Offer approval is not built — it is a financial action. | offer detail | FR-CRM-007 |
| **MI-31** | **Rule expression grammar does not exist.** FR-CRM-002 enumerates the assignment BASES and FR-CRM-008 the commission PARTIES — both real. Neither describes what a rule CONDITION looks like: no operators, no value types, no tie-breaking. FR-ADM-004 says rules are configurable without saying how. Rules are therefore **listed read-only**; the editor is not built and `condition` is an opaque server string. | assignment rules, commission rules | FR-CRM-002, FR-CRM-008, FR-ADM-004 |
| **MI-32** | **Lead assignment cannot be performed from the UI.** FR-CRM-002 assignment is decided by server rules, and a manual override needs the agent directory — which belongs to IAM and has no contract (MI-01a). No agent selector is offered rather than a free-text field that bypasses the rules. | lead form | FR-CRM-002, FR-IAM-004 |
| **MI-33** | **Lead import blocked on two dependencies at once** — the upload transport (MI-28) and the async job contract (MI-H13, FR-API-009: "background jobs, validation reports and resumable processing"). Column mapping is also blocked, because the mapping targets are lead field names in an unpublished contract. | lead import screen | FR-CRM-001, FR-API-009 |

## Documented inconsistencies (unchanged from the FE-0 analysis)

- **~110 screens appears in no document.** It was an external scope assumption and is now superseded by the CEO's full-scope decision.
- **SRS §5 names 11 stakeholder roles; `FR-IAM-005` names 8.** Backlog epic
  actor fields add ~10 more names. See `UNRESOLVED-ROLES.md`.
- **CMS has four functional requirements and zero endpoints** in §12.
- **OpenAPI (S12) lands six sprints after Next.js work starts (S6).**
- **No Next.js capacity is allocated in S3–S5**, yet the foundation must exist
  before the S6 marketplace work.
