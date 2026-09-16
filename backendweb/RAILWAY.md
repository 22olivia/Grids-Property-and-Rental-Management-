# Deploy GPMS API + Railway MySQL (free / trial friendly)

This backend already includes `Dockerfile`, `railway.toml`, and `start.sh`.
Use **MySQL** on Railway (not Postgres). Keep the stack tiny on free credits:
**1 MySQL + 1 API service only** (no Redis, no workers).

## 1) Create the Railway project

1. Open [railway.app](https://railway.app) → **New Project**.
2. **Add MySQL** (Database → MySQL).
3. **Add a service** from this GitHub repo (`22olivia/Grids-Property-and-Rental-Management-`).
4. Service settings:
   - **Root Directory:** `backendweb`
   - Builder: Dockerfile (auto from `backendweb/Dockerfile`)
5. Generate a public domain: service → **Settings → Networking → Generate Domain**.

## 2) API service variables (copy these)

Replace `MySQL` with your MySQL service name if Railway named it differently.

```env
APP_NAME=Grids GPMS API
APP_ENV=production
APP_DEBUG=false
APP_KEY=base64:REPLACE_ME
APP_URL=https://YOUR-API.up.railway.app
FRONTEND_URL=https://rental-phi-eight.vercel.app

DB_CONNECTION=mysql
DB_HOST=${{MySQL.MYSQLHOST}}
DB_PORT=${{MySQL.MYSQLPORT}}
DB_DATABASE=${{MySQL.MYSQLDATABASE}}
DB_USERNAME=${{MySQL.MYSQLUSER}}
DB_PASSWORD=${{MySQL.MYSQLPASSWORD}}
# Optional single URL instead of the five DB_* lines above:
# DB_URL=${{MySQL.MYSQL_URL}}

SESSION_DRIVER=database
CACHE_STORE=file
QUEUE_CONNECTION=sync
LOG_CHANNEL=stderr
MAIL_MAILER=log

# First deploy only — then set to 0 or the free tier will OOM / crash-loop on seed.
SEED_ON_BOOT=0
```

### If Railway keeps crashing / restarting

Check **API service → Deployments → View Logs**. Common causes:

| Log / symptom | Fix |
|---------------|-----|
| Out of memory / killed | Set `SEED_ON_BOOT=0`. Keep only MySQL + API. |
| SQLSTATE / Access denied | Fix `DB_*` on **API** service (reference MySQL vars). |
| Healthcheck failed | Redeploy this repo (binds `/up` before migrate finishes). |
| Credits / suspended | Free trial credit exhausted — upgrade or wait for monthly free credit. |
| Crash on every boot with seed | Set `SEED_ON_BOOT=0` immediately. |

Also set these on the API service for stability:

```env
SEED_ON_BOOT=0
SESSION_DRIVER=file
CACHE_STORE=file
QUEUE_CONNECTION=sync
LOG_CHANNEL=stderr
APP_DEBUG=false
PHP_MEMORY_LIMIT=128M
```

Health check path is `/up` (built into Laravel). Public API check remains `/api/v1/health`.

### Generate `APP_KEY`

Locally (once):

```bash
cd backendweb
php -r "echo 'base64:'.base64_encode(random_bytes(32)), PHP_EOL;"
```

Paste that value into Railway `APP_KEY`. Do not regenerate later or encrypted data breaks.

### First deploy seed

1. Deploy with `SEED_ON_BOOT=1` once (creates demo users).
2. Immediately set `SEED_ON_BOOT=0` and redeploy (or just change the var — next restart won’t re-seed).

Demo logins after seed (see `README.md`): `admin@rental.test` / `password`, etc.

## 3) Verify the API

```bash
curl -s https://YOUR-API.up.railway.app/api/v1/health
```

Expect JSON like `{ "status": "ok", ... }`.

Login test:

```bash
curl -s -X POST https://YOUR-API.up.railway.app/api/v1/login \
  -H 'Content-Type: application/json' -H 'Accept: application/json' \
  -d '{"email":"admin@rental.test","password":"password"}'
```

## 4) Vercel frontend — yes, you must set the API URL

The site stays on Vercel. To use Railway MySQL data (real Laravel API), add this on the **same Vercel project** that serves the site:

| Name | Value |
|------|--------|
| `NEXT_PUBLIC_API_URL` | `https://YOUR-API.up.railway.app/api/v1` |

Then **Redeploy** the frontend (env vars that start with `NEXT_PUBLIC_` are baked in at build time).

### What stays on Vercel

Keep these on Vercel (they are Next.js routes, not Laravel):

- `WHATSAPP_*` / Meta token (or paste token in Super Admin → Settings)
- `MAIL_*` for the Next mail helper (if you use it)

Laravel on Railway does **not** need Meta WhatsApp env for the current Vercel WhatsApp flow.

### Demo mode vs Railway mode

| `NEXT_PUBLIC_API_URL` | Behavior |
|-----------------------|----------|
| `/api/v1` (default) | Built-in browser demo API (localStorage). No Railway needed. |
| `https://….up.railway.app/api/v1` | Real Laravel + MySQL on Railway. |

## 5) Free / trial tips

- Only run **MySQL + API**. Extra services burn the ~$5 trial / $1 free credit quickly.
- `QUEUE_CONNECTION=sync` and `CACHE_STORE=file` — no Redis.
- `SEED_ON_BOOT=0` after the first seed.
- `APP_DEBUG=false`.
- If credits run out, Railway pauses services until next month or Hobby upgrade.
- Sleep/cold start: first request after idle may be slow; `start.sh` waits for MySQL.

## 6) Common failures

| Symptom | Fix |
|---------|-----|
| API 502 / migrate fail | Check `DB_HOST` references the MySQL service name exactly (`${{MySQL.MYSQLHOST}}`). |
| Frontend still demo data | `NEXT_PUBLIC_API_URL` missing or not redeployed on Vercel. |
| CORS issues | Backend allows `*` today; set `FRONTEND_URL` anyway for password-reset links. |
| Health URL pasted as API base | Use `…/api/v1` **without** `/health`. |
| Token expired Meta WhatsApp | Unrelated to Railway — paste token in Super Admin Settings on the site. |

## 7) Optional: keep demo until Railway is stable

1. Deploy Railway MySQL + API and confirm `/health` + `/login`.
2. Only then set `NEXT_PUBLIC_API_URL` on Vercel and redeploy.
3. If Railway pauses on free credits, set `NEXT_PUBLIC_API_URL` back to `/api/v1` and redeploy to use demo mode again.
