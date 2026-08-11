# GPMS API — Grids Property Management System

Standalone **Laravel 13 + Sanctum** backend for GPMS.  
This folder is designed to live in its **own GitHub repo** and deploy separately from any frontend.

## Stack

- PHP 8.3+, Laravel 13, Sanctum tokens
- MySQL 8+ (SQLite works for local tests)
- Role-based access: `super_admin`, `owner`, `manager`, `tenant`
- Modules: users, properties, units, leases, invoices, payments, maintenance, automation, role dashboards

## Quick start (local)

```bash
composer install
cp .env.example .env
php artisan key:generate

# MySQL (or switch DB_CONNECTION=sqlite for quick local)
php artisan migrate --seed
php artisan serve
```

API base: `http://127.0.0.1:8000/api/v1`  
Health: `GET /api/v1/health`

## Demo logins (after seed)

| Role | Email | Password |
|------|-------|----------|
| Super Admin | `admin@rental.test` | `password` |
| Owner | `owner@grids.test` | `password` |
| Manager | `manager@grids.test` | `password` |
| Tenant | `tenant@grids.test` | `password` |

## Auth

```http
POST /api/v1/login
Content-Type: application/json

{ "email": "admin@rental.test", "password": "password" }
```

Response includes `token`. Send on later calls:

```http
Authorization: Bearer {token}
```

## Main endpoints

| Area | Base path |
|------|-----------|
| Auth / profile | `/login`, `/signup`, `/me`, `/logout`, `/notifications` |
| Dashboard (role-scoped) | `GET /dashboard` |
| Users / roles | `/users`, `/users/stats`, `/roles` |
| Owners / tenants | `/owners`, `/tenants` |
| Properties / units | `/properties`, `/rental-units` |
| Leases | `/leases`, `/leases/{id}/activate|terminate|renew|timeline` |
| Invoices | `/invoices`, `POST /invoices/generate` |
| Payments / txns | `/payments`, `/transactions`, approve/reject/refund |
| Online checkout | `POST /payments/orders`, confirm, `POST /payments/webhook` |
| Maintenance | `/maintenance-requests` |
| Public listings | `GET /listings` |
| Demo automation | `POST /automation/run` |

See **[INTEGRATION.md](./INTEGRATION.md)** for frontend wiring.  
See **[PAYMENTS.md](./PAYMENTS.md)** for online checkout (demo + Paytm).

## Env (production)

```env
APP_NAME="Grids GPMS API"
APP_URL=https://your-api.example.com
FRONTEND_URL=https://your-frontend.example.com
DB_CONNECTION=mysql
QUEUE_CONNECTION=sync
MAIL_MAILER=log
```

`FRONTEND_URL` is used for password-reset links. CORS currently allows all origins (tighten in `config/cors.php` for production).

## Deploy (Railway)

This package includes `Dockerfile`, `railway.toml`, and `start.sh`.

Suggested Railway vars:

- `APP_KEY` (generate once)
- `APP_URL` = `https://your-service.up.railway.app`
- `FRONTEND_URL` = your Vercel / frontend URL
- MySQL plugin → `DB_*`
- `QUEUE_CONNECTION=sync` on free tier

## Tests

```bash
php artisan test
```

## Publish this folder as its own repo

From the monorepo root (or use the script):

```bash
# Option A — script
bash scripts/export-backend-repo.sh

# Option B — manual split into a new empty GitHub repo
git subtree split -P backend -b gpms-api-export
# create empty repo on GitHub, then:
git push https://github.com/YOU/gpms-api.git gpms-api-export:main
```

Or unzip the artifact `gpms-api-backend.tar.gz`, then:

```bash
cd gpms-api
git init
git add .
git commit -m "Initial GPMS API"
gh repo create YOU/gpms-api --private --source=. --push
```
