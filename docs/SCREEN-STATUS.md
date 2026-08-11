# Screen status register

Updated after backend integration (10 Aug 2026).

**Backend:** GPMS Laravel 13 + Sanctum. Assets are LIVE; Listings and CRM have
no backend and remain on mocks.

| # | Screen | Module | Status | Notes |
|---|---|---|---|---|
| — | Login | IAM | **LIVE** | `POST /login`, Sanctum token in httpOnly cookie |
| — | Session / logout | IAM | **LIVE** | `GET /me`, `POST /logout` |
| 81 | Properties list | AST | **LIVE** | `GET /properties`. No sort, no search — backend lacks both |
| 82 | Property detail | AST | **LIVE (reduced)** | History tab removed — no endpoint |
| 83 | Property create / edit | AST | **LIVE** | `owner_id` is a numeric field; no owners module yet |
| 84 | Buildings list | AST | **LIVE** | `GET /buildings` |
| 85 | Building detail + floors | AST | **LIVE (read-only floors)** | Floors eagerly loaded; no update/delete route |
| 86 | Units list | AST | **LIVE** | `GET /rental-units`; status filter is backed |
| 87 | Unit detail | AST | **LIVE (reduced)** | Availability + history tabs removed — no endpoints |
| 88 | Unit create / edit | AST | **LIVE** | Decimal-string money verified end to end |
| 89 | Availability timeline | AST | **REMOVED** | No endpoint (FR-AST-003) |
| 99–104 | All Listings (8) | LST | **MOCK** | No Listing entity in backend |
| 105–119 | All CRM (15) | CRM | **MOCK** | Zero CRM migrations or controllers |

## Totals

| | Count |
|---|---:|
| Live on the real API | **9** |
| Mock (backend absent) | 23 |
| Removed as unbacked | 1 |

## Verified end to end (10 Aug 2026)

| Flow | Verified against |
|---|---|
| Login → token → cookie → `/me` → session | `AuthController` login/me/logout |
| Route protection | middleware cookie check + `RequireSession` on revoked/expired |
| Properties list / detail / create / edit / **delete** | `apiResource properties` |
| Buildings list / detail (+floors) / **delete** | `apiResource buildings`, `show` loads `floors` |
| Units list / detail / create / edit / **delete** | `apiResource rental-units` |
| Server validation → form fields | Laravel `errors:{field:[msg]}` mapped to form paths |
| Pagination | derived from the response, not the request |

## Capabilities removed rather than stubbed

`FR-AST-003` availability timeline · `FR-AST-006` custom fields ·
`FR-AST-007` duplicate detection · `FR-AST-008` change history ·
`FR-AST-004` ownership percentages.

None is faked. A history tab fed by mock data beside real property data would
make invented history indistinguishable from audited history — the one place a
placeholder is genuinely unsafe.

## Requirements the current backend does not satisfy

| Requirement | Conflict |
|---|---|
| `FR-API-002` (Must) | Short-lived tokens + refresh rotation. Sanctum issues one long-lived token; no refresh endpoint. |
| `FR-IAM-002` (Must) | Permission-based access. Backend authorises by role only; the `permissions` column is never read. |
| `FR-IAM-003` / `AC-01` | Company isolation. `PropertyController::index` applies no scoping — see the defect report. |
| `FR-FIN-002` (Must) | Multi-currency. Currency exists only on payments. |
| `FR-LST-001`–`008` | Listings lifecycle. No Listing entity. |
| `FR-CRM-001`–`008` | Entire CRM. Absent. |
| `NFR-I18N-001` | Backend is English-only; server validation messages appear in English inside the Arabic UI. |
| SRS §12 envelope | No `correlation_id`; four response shapes. Frontend adapted to reality. |
