# Backend defect report — GPMS API

**From:** frontend team
**Date:** 10 August 2026
**Reviewed commit:** `Grids-Property-and-Rental-Management--main.zip` → `backend/`

No backend code has been modified. This document describes what we found and the fix we would suggest, for the backend developer to apply and verify.

---

## DEFECT 1 — CRITICAL — Cross-organisation data exposure on `GET /api/v1/properties`

### Severity
**Critical.** Any authenticated staff user of any organisation receives every property in the database, with owner and unit records eagerly loaded.

### Location
`app/Http/Controllers/Api/PropertyController.php`, `index()`

```php
public function index(): JsonResponse
{
    $properties = Property::with(['owner', 'rentalUnits'])->latest()->paginate(15);

    return response()->json($properties);
}
```

The method takes no `Request` and applies no scoping. The route sits behind
`role:super_admin,owner,manager,accountant,agent` (`routes/api.php`), so
authentication is enforced — but **tenancy is not**. A `manager` in
organisation A receives organisation B's portfolio, including
`owner` (name, email, phone) and every `rentalUnit` with `monthly_rent`.

### Requirements violated
- `GPMS-FR-IAM-003` (Must) — "isolate every company's operational data using an organization/company identifier and scoped queries"
- `AC-01` — "a user cannot reach another company's record through UI, API or identifier manipulation"
- `GPMS-FR-SEC-004` (Must) — "authorization tests shall verify isolation between companies"

### Why we are confident this is a miss, not a design decision
`RentalUnitController::index()` (lines 32–35) already implements the correct
pattern in the same codebase:

```php
->when(
    ! $user->isSuperAdmin() && ! $user->isTenant() && $user->organization_id,
    fn ($q) => $q->where('organization_id', $user->organization_id)
)
```

The intent exists. `PropertyController` was not given the same treatment.

### Suggested fix
Mirror the `RentalUnitController` pattern. Illustrative only — please apply
whatever matches your conventions:

```php
public function index(Request $request): JsonResponse
{
    $user = $request->user();

    $properties = Property::with(['owner', 'rentalUnits'])
        ->when(
            ! $user->isSuperAdmin() && $user->organization_id,
            fn ($q) => $q->where('organization_id', $user->organization_id)
        )
        ->latest()
        ->paginate((int) $request->get('per_page', 15));

    return response()->json($properties);
}
```

**Note on the `null` case.** If a staff user has `organization_id === null`,
the condition above is skipped and they see everything. `SearchController`
already handles this more safely — it applies `whereRaw('1 = 0')` for a
non-super-admin with no organisation. We would suggest the same conservative
default here: **no organisation means no rows**, not all rows.

### Verification suggestion
An automated test asserting that a `manager` in organisation A receives zero
properties belonging to organisation B would close this permanently and
satisfies the `FR-SEC-004` requirement for isolation tests.

---

## DEFECT 2 — HIGH — Client-controlled scoping on `GET /api/v1/buildings`

### Location
`app/Http/Controllers/Api/BuildingController.php`, `index()`

```php
->when($request->organization_id, fn ($q) => $q->where('organization_id', $request->organization_id))
```

### Issue
The organisation filter is applied **only when the client sends it**, and the
value comes from the request. A client-supplied filter is a convenience, not
an authorisation boundary: omitting the parameter returns all buildings across
all organisations, and supplying another organisation's id returns that
organisation's buildings.

Same requirements as Defect 1.

### Suggested fix
Keep `organization_id` as an optional *narrowing* filter, but apply the user's
own organisation as a *mandatory* scope underneath it — the same shape as
`RentalUnitController`.

---

## OBSERVATION 3 — MEDIUM — Four roles cannot log in but are used for authorisation

`AuthController::login()` (line 108) restricts sign-in to `super_admin`,
`owner`, `manager`, `tenant`.

`app/Support/Roles.php` also defines `accountant`, `agent`, `vendor` and
`technician`, and these appear in route middleware — `Roles::staff()` grants
`accountant` and `agent` access to properties, units, tenants, contracts,
invoices and payments.

**Effect:** those grants are unreachable. An accountant cannot obtain a token,
so the accountant permissions never apply. Maintenance routes reference
`vendor`/`technician` similarly.

Not a security hole — the restriction fails closed. Flagging it because
`FR-IAM-005` requires all eight roles, and the frontend cannot build
role-specific screens for roles that cannot authenticate.

**Question for you:** is the login restriction temporary, or are those four
roles not yet in scope?

---

## OBSERVATION 4 — MEDIUM — No sorting on any index endpoint

All 19 `paginate()` call sites use a hardcoded `->latest()`. No controller
reads a sort parameter.

The frontend has sortable columns built on properties, units, buildings,
invoices, leases and payments. They currently have nothing to call.

**Suggested minimum:** accept `?sort=<column>&direction=asc|desc` on index
endpoints, validated against an allowlist of sortable columns per resource.
We are happy to align with whatever parameter names you prefer — we only need
them to be consistent across resources.

---

## OBSERVATION 5 — LOW — No `search` parameter on properties, buildings or rental units

`InvoiceController`, `LeaseController`, `UserController` and
`NotificationCentreController` all accept `?search=`. Properties, buildings and
rental units do not, though the frontend has search inputs on all three.

`/admin/search` exists but is a global cross-entity search, not a per-list
filter.

---

## OBSERVATION 6 — LOW — Currency column is missing outside payments

`currency char(3) default 'AED'` exists on `payments` and `payment_orders`
only. `rental_units.monthly_rent`, `contracts.monthly_rent` and
`invoices.total_amount` have no currency column.

`FR-FIN-002` (Must) requires multi-currency. Until then the frontend falls back
to a single configured currency for unit prices, which is correct for a
single-market deployment and wrong for the multi-currency requirement.

---

## OBSERVATION 8 — MEDIUM — `GET /properties` ignores `per_page`

`PropertyController::index` hardcodes `->paginate(15)`. Every other index
reads it: `->paginate((int) $request->get('per_page', 20))`.

Two effects we hit during integration:

1. **Pagination maths.** The frontend requested 20 per page and received 15, so
   the computed page count was wrong and a "next" control could be offered past
   the last page. We fixed this on our side by deriving paging from the
   response's own `per_page` rather than the request — but the endpoint is still
   the odd one out.
2. **A property picker cannot list more than 15.** The unit form needs to offer
   every property in the organisation. With `per_page` ignored there is no way
   to widen the page, so a user whose organisation has more than 15 properties
   cannot select the 16th without paging manually.

Suggested fix: accept `per_page` here as the other controllers already do.

---

## OBSERVATION 9 — LOW — `PUT /properties/{id}` returns a partially loaded record

`update()` returns `$property->fresh('owner')`, which reloads `owner` but not
`rentalUnits`. `index()` and `show()` both load `rentalUnits`.

A client that derives a unit count from the eagerly-loaded relation — as ours
does — sees zero immediately after an update. We work around it by refetching,
so nothing is broken; loading the same relations on `update` as on `show` would
remove the inconsistency.

---

## OBSERVATION 7 — INFORMATIONAL — Response envelope varies by endpoint

Four shapes are in use: raw Laravel paginator (index), `{message, data}`
(store/update), `{data}` (show), and `{message, user, token, role_label}`
(login). SRS §12 specifies a single envelope with `data`, `meta`, `links`,
`errors` and `correlation_id`.

**We have adapted the frontend to the shapes as they actually are** — no
backend change is required for us to integrate. Raising it only because
`correlation_id` is absent, and SRS §12 intends it for support traceability.
If you add it later, our error surfaces will display it automatically; nothing
breaks in the meantime.

---

## What we changed on our side (no backend impact)

- The frontend now speaks Sanctum bearer tokens, page/`per_page` pagination,
  Laravel's `{message, errors:{field:[...]}}` validation format, decimal-string
  money and UTC ISO-8601 dates — all as the API actually implements them.
- **We did not bypass or weaken organisation scoping anywhere.** The frontend
  sends no `organization_id` of its own choosing on list requests; it relies on
  the server to scope, which is why Defect 1 matters.
