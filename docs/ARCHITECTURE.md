# FE-0 architecture

## Layering

```
routes  →  features  →  domain  →  design-system
              ↓            ↓
            lib (api, auth, permissions, i18n, forms)
```

Enforced by lint: **no feature imports another feature.** Shared needs are
promoted to `src/domain` or `src/lib`. This mirrors the backend dependency
rule in `EN-ARC-004`, and it is what keeps a large screen count navigable.

`src/features/` does not exist yet — creating empty module folders before the
scope decision would be speculative. The import rule is already active.

## What this layer does not do

Three deliberate absences, all from SRS §6: *"financial and authorization
rules shall not be independently reimplemented in clients."*

1. **No money computation.** `src/domain/money` formats; it has no `add()`,
   no `total()`. Totals, allocations, aging, settlements, commissions and tax
   arrive computed.
2. **No authorization enforcement.** Permission checks prevent showing a
   button that would 403. SRS §16: "hiding interface controls is not
   sufficient."
3. **No workflow state machines.** Listing states (`FR-LST-006`) and
   maintenance states (`FR-MNT-002`) are configurable server-side; the client
   renders transitions the API returns.

## Rendering strategy per surface

| Surface | Density | Strategy | Basis |
|---|---|---|---|
| Marketplace | comfortable | SSG / ISR, streamed search | FR-MKT-007, NFR-PERF-002 |
| Auth | comfortable | SSR, uncached | session establishment |
| Portals | comfortable | SSR shell + client fetch | personal, uncacheable |
| Console | compact | client SPA behind SSR shell | dense, mutation-heavy |

Density is one token set with two settings (`data-density`), not two design
systems. An accountant reconciling 400 payments needs rows; a renter browsing
flats needs cards.

## The BFF

`src/app/api/auth/[action]` does exactly four things: hold the refresh token
in an httpOnly cookie, run single-flight refresh/rotation, resolve
organisation context, and sign uploads. It does **not** transform business
data or aggregate endpoints — every such addition is a place where the
frontend and the system of record can disagree.

## Single-flight refresh

The most consequential detail in the auth layer. With rotation enabled
(`FR-API-002`), a console page firing eight parallel queries against an
expired token produces eight 401s. If each triggers its own refresh, seven
present an already-rotated token and the session is destroyed. `refreshInFlight`
in `src/lib/auth/session.ts` collapses them into one.

## Record spine

SRS §11 states that asset, listing and contract "shall be separate concepts…
This separation is mandatory to prevent availability, occupancy and billing
conflicts." That distinction is what users conflate — "is this unit occupied"
is an asset question, "is it advertised" a listing question, "who owes rent" a
contract question.

The design encodes it: a 3px `border-inline-start` in the record-class hue on
cards, rows and detail surfaces. It mirrors automatically, costs nothing at any
density, and survives per-company branding because record hues are a separate
token family from `--brand-*`. It is reinforcement, never the sole carrier of
meaning (WCAG 1.4.1) — content always names what it is.
