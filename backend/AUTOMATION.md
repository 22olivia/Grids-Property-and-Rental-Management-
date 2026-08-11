# GPMS backend automation (SRS-aligned)

This backend implements the SRS automation baseline for Phase 2:

- Recurring rent generation (`GPMS-FR-LSE-003`, `FIN-001`)
- Overdue marking / collections aging
- Rent + overdue reminders (`GPMS-FR-NOT-005`)
- Lease expiry reminders (`GPMS-FR-LSE-005`)
- Laravel **scheduler** + **queued jobs/notifications** (SRS §19)

## Processes required in cloud (any device)

Do **not** rely on a laptop. Run these 3 processes on the host (Railway/Render/VPS):

1. **Web API**
   ```bash
   php artisan serve --host=0.0.0.0 --port=$PORT
   ```
2. **Queue worker** (emails/jobs)
   ```bash
   php artisan queue:work --sleep=1 --tries=3
   ```
3. **Scheduler**
   ```bash
   php artisan schedule:work
   ```

`Procfile` in this folder already defines `web`, `worker`, and `scheduler`.

## Queue / mail (SRS)

```env
QUEUE_CONNECTION=database
# Later production preference from SRS:
# QUEUE_CONNECTION=redis
# REDIS_HOST=...

MAIL_MAILER=smtp
MAIL_HOST=...
MAIL_USERNAME=...
MAIL_PASSWORD=...
MAIL_FROM_ADDRESS=...
```

For local demos without SMTP: `MAIL_MAILER=log`.

## Commands

```bash
# Run now (sync)
php artisan rental:automate

# Queue for worker (cloud)
php artisan rental:automate --queue
```

API:

```http
POST /api/v1/automation/run
POST /api/v1/automation/run?sync=0
```

`sync=0` queues work so any device’s API request is processed by the cloud worker.
