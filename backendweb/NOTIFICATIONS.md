# Notification System (In-App, Email & WhatsApp)

GPMS event-driven notification centre for multi-tenant property management.

## Channels (3 only)

| Channel | Behaviour |
|---------|-----------|
| **In-app** | Real-time bell, unread badge, mark read / archive / delete, search, filters, deep links |
| **Email** | Branded HTML via Laravel `MAIL_*` SMTP (e.g. Gmail App Password). CTA buttons, attachments, retry |
| **WhatsApp Business** | Twilio templates when `TWILIO_*` is set; otherwise auditable **simulated** delivery logs |

SMS and Push are **not** part of this product surface.

## How a notification is generated

Example: **you raise a support ticket**

1. `POST /support/tickets` creates the ticket.
2. System creates **In-app** notifications for:
   - the submitter (confirmation)
   - the assignee role (Super Admin / Manager / Owner depending on routing)
3. System queues **Email** to the submitter + assignee.
4. System queues **WhatsApp** when a phone number is available and WhatsApp channel is enabled.
5. System may POST **n8n** `support_ticket_created` with `{ ticket: { id } }` when `N8N_WEBHOOK_TICKET_URL` is set (see [N8N.md](./N8N.md)). Slack/Sheets are not part of GPMS.
6. Super Admin → **Notification Admin → Delivery logs** shows each channel attempt (`sent` / `simulated` / `failed`).

**n8n:** assign a maintainer by calling `POST /support/tickets/{id}/assign` with a login Bearer token (see [N8N.md](./N8N.md)). Skip close/resolve in n8n — use Help & Support. Create maintainers in GPMS **Maintainers / Users** first.

### Why nothing arrives in Gmail on Vercel demo

The live Vercel app uses the **built-in demo API**. It creates In-app rows and **simulates** email/WhatsApp in Delivery logs — it cannot open an SMTP connection to Gmail.

For real Gmail / WhatsApp:

```env
# Laravel .env
MAIL_MAILER=smtp
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=you@gmail.com
MAIL_PASSWORD=your-16-char-app-password
MAIL_FROM_ADDRESS=you@gmail.com
MAIL_FROM_NAME=GPMS

TWILIO_ACCOUNT_SID=
TWILIO_AUTH_TOKEN=
TWILIO_WHATSAPP_FROM=whatsapp:+14155238886
```

Point the frontend at Laravel:

```env
NEXT_PUBLIC_API_URL=http://127.0.0.1:8000/api/v1
```

Then ticket emails go to the ticket `email` field and assignee user email via `EmailService` + `NotificationService`.

## Role map

| Spec role | App role |
|-----------|----------|
| Super Admin | `super_admin` |
| Tenant (Company / Organisation) | `owner` |
| Manager | `manager` |
| Property Owner | `owner` |
| Residential renter | `tenant` |

## Delivery pipeline (Laravel)

1. Code calls `NotificationService::notify($user, 'event.key', [...])` or `EmailService::queue(...)`.
2. Inbox row in `app_notifications` + `notification_deliveries` per channel.
3. Jobs deliver:
   - **in_app** — already in inbox
   - **email** — SMTP
   - **whatsapp** — Twilio or simulated
4. Scheduler retries failed deliveries.

## UI

- `/notifications` — inbox
- `/notifications/preferences` — In-app / Email / WhatsApp preferences
- `/notifications/admin` — channels (3), event catalog, templates, delivery logs, how-it-works

## API

- `GET /notifications` — filters include `search`
- `GET/PUT /notification-preferences`
- `GET /notifications/catalog` — `events_by_role`, `rules`, channels = `in_app|email|whatsapp`
- `GET/PUT /notification-channels` · templates · delivery logs (Super Admin)
