# Unresolved role assumptions

**No role name is hardcoded anywhere in this codebase.** `ROLES` in
`src/lib/permissions/types.ts` is intentionally empty, and all UI checks go
through permission strings supplied by the API. This document records why, and
what must be resolved.

## Three vocabularies

| Source | Role names |
|---|---|
| SRS §5 (stakeholders) | 11 |
| `FR-IAM-005` (configurable roles) | 8: super admin, company admin, manager, agent, accountant, owner, tenant, maintainer |
| Backlog epic "Primary Actors" | Adds ~10 more: Seller, Marketing Manager, Listing Manager, Customer Service, Leasing Officer, Compliance Officer, **Vendor** (listed separately from Maintainer in E10), Support Administrator, Business Manager, Executive |

Roughly **21 distinct actor names against 8 configurable roles.**

## Unresolved, in order of consequence

### 1. Developer / Agency — BLOCKING
SRS §5 describes them as publishing projects and listings and managing agents,
leads, inventory and commercial performance. `FR-MKT-001` (Must) requires
public **agency and developer pages**. SRS §11 defines `Project / Developer` as
a first-class entity.

**Nothing in the backlog builds any of it** — no epic, no story, no points, no
endpoint, no role in `FR-IAM-005`.

Either they are managed *by company staff* (no new role; §5's description is
then inaccurate), or they log in (an unbuilt module of ~8–12 screens plus an
authorization scope that is neither company-wide nor branch-scoped). The
permission model cannot be finalised without the answer, because a third scope
changes the shape of `/me`, the navigation config and every route guard.

### 2. Vendor vs Maintainer — HIGH
`E10` lists them as **two separate actors**. `FR-MNT-003` distinguishes
"internal maintainers or external vendors"; `FR-MNT-004` says vendors submit
quotations. If external vendors authenticate, a vendor portal is needed
(assignments, quotations, evidence, invoicing) — approximately 6–8 screens that
appear in no inventory.

### 3. Support / Auditor — MEDIUM
SRS §5: "investigates issues and reviews logs under controlled, time-bound
access". `FR-ADM-005` covers impersonation with consent, reason, expiry and
audit. Needs a **read-only permission profile**, which is not expressible if
permissions are purely action-based — this constrains the taxonomy itself, so
it should be settled before `MI-11` is answered.

### 4. Buyer / Renter / Public User — MEDIUM
Probably self-registration rather than an assigned role. Confirmation
determines whether public users appear in company user administration and
whether they count against plan user limits (`FR-ADM-003`).

### 5. The remaining backlog actor names — LOW
Listing Manager, Leasing Officer, Customer Service, Marketing Manager,
Compliance Officer, Business Manager, Executive, Seller. Most are probably job
titles mapping onto permission sets. One line of confirmation closes this.

## Engineering position

Because `FR-IAM-005` makes roles **configurable**, role names are data, not
code. This is a settled engineering decision and does **not** need the CEO:

- No component branches on a role name.
- `<Can do={...}>` and `useCan()` evaluate permission strings only.
- Navigation entries declare required permissions; the tree is filtered per
  session and empty sections are dropped.
- UI checks are **usability only**. SRS §16: "hiding interface controls is not
  sufficient." The API remains the security boundary (`FR-SEC-004`, `AC-01`).
