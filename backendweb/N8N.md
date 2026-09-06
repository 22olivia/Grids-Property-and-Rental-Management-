# n8n + GPMS (support tickets → assign maintainers)

GPMS → n8n on ticket create. n8n can **assign a maintainer** by calling GPMS back with a login Bearer token.

Skip Slack/Sheets. Skip close/resolve in n8n — those stay in Help & Support.

## Built

| Direction | What |
|-----------|------|
| **GPMS → n8n** | After ticket save, POST `{ event: support_ticket_created, source: gpms, ticket: { id } }` to `N8N_WEBHOOK_TICKET_URL` |
| **n8n → GPMS** | `GET /support/maintainers` + `POST /support/tickets/{id}/assign` with Sanctum login token |
| **close / resolve** | Not the n8n path — use GPMS Help & Support |

## Your Railway API

```text
https://zippy-reverence-production-edea.up.railway.app/api/v1
```

Set on Railway:

```env
APP_URL=https://zippy-reverence-production-edea.up.railway.app
N8N_ENABLED=true
N8N_WEBHOOK_TICKET_URL=https://gridsgpms.app.n8n.cloud/webhook/gpms-ticket
```

## n8n workflow (maintainers only)

### 1. Webhook (already)

- Path `gpms-ticket`, workflow **Active**
- Receives `{ event, source, ticket: { id } }` when someone creates a ticket in GPMS.

### 2. Login

- **HTTP Request** `POST`
- URL: `https://zippy-reverence-production-edea.up.railway.app/api/v1/login`
- Body:

```json
{
  "email": "owner@grids.test",
  "password": "password"
}
```

Use a real staff account on Railway (`owner` / `super_admin`). Store password in n8n credentials.

### 3. List maintainers (optional)

- **HTTP Request** `GET`
- URL: `https://zippy-reverence-production-edea.up.railway.app/api/v1/support/maintainers`
- Header: `Authorization: Bearer {{ $('Login').item.json.token }}`

Response `data[]` has `id`, `name`, `email` (manager-role users).

### 4. Assign maintainer

- **HTTP Request** `POST`
- URL:  
  `https://zippy-reverence-production-edea.up.railway.app/api/v1/support/tickets/{{ $('Webhook').item.json.ticket.id }}/assign`
- Headers:
  - `Authorization: Bearer {{ $('Login').item.json.token }}`
  - `Accept: application/json`
  - `Content-Type: application/json`
- Body (pick one):

```json
{ "maintainer_email": "manager@grids.test" }
```

or

```json
{ "maintainer_id": 2 }
```

Maintainer must be role `manager` (GPMS Maintainers) and usually same organization.

## Create maintainers in GPMS first

n8n only **assigns** existing maintainers to tickets. To add people:

1. Open **Maintainers** (or Users) in GPMS  
2. Create users with maintainer / `manager` role  
3. Then n8n can list + assign them

## Outbound payload (exact)

```json
{
  "event": "support_ticket_created",
  "source": "gpms",
  "ticket": {
    "id": "<actual-created-ticket-uuid>"
  }
}
```

`ticket.id` is the persisted `support_tickets.id` (UUID). Never a ping / hardcoded value.

## Outbound payload excerpt (legacy note)

Older docs mentioned a richer body; production now sends only the structure above.
