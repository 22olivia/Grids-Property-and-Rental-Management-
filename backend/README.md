# Rental API (Laravel)

Backend API for the rental management system.

## Requirements

- PHP 8.3+
- Composer
- MySQL 8+

## Setup

```bash
composer install
cp .env.example .env
php artisan key:generate
```

### MySQL

Create the database and user (example):

```sql
CREATE DATABASE rental CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE USER 'rental'@'localhost' IDENTIFIED BY 'rental_secret';
GRANT ALL PRIVILEGES ON rental.* TO 'rental'@'localhost';
FLUSH PRIVILEGES;
```

`.env.example` defaults:

```
DB_CONNECTION=mysql
DB_HOST=127.0.0.1
DB_PORT=3306
DB_DATABASE=rental
DB_USERNAME=rental
DB_PASSWORD=rental_secret
```

```bash
php artisan migrate --seed
php artisan serve
```

## Authentication

Uses **Laravel Sanctum** personal access tokens + email password reset.

| Method | Endpoint | Auth | Purpose |
|--------|----------|------|---------|
| POST | `/api/v1/signup` | Public | Create account |
| POST | `/api/v1/register` | Public | Alias of signup |
| POST | `/api/v1/login` | Public | Log in (guides to signup if email missing) |
| POST | `/api/v1/forgot-password` | Public | Email a reset link |
| POST | `/api/v1/reset-password` | Public | Set new password with token |
| GET | `/api/v1/me` | Bearer token | Current user |
| POST | `/api/v1/logout` | Bearer token | Revoke token |

Login / signup response includes `token`. Send it as:

```
Authorization: Bearer {token}
```

### Forgot password flow

1. `POST /api/v1/forgot-password` with `{ "email": "user@example.com" }`
2. User receives email (via your `MAIL_*` settings) with a link like:
   `http://localhost:3000/reset-password?token=...&email=...`
3. Frontend page collects new password and calls:
   `POST /api/v1/reset-password` with `token`, `email`, `password`, `password_confirmation`

### Mail setup (your keys)

Put your provider credentials in `backend/.env`:

```env
MAIL_MAILER=smtp
MAIL_SCHEME=tls
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USERNAME=your-email@gmail.com
MAIL_PASSWORD=your-app-password-or-smtp-key
MAIL_FROM_ADDRESS="your-email@gmail.com"
MAIL_FROM_NAME="${APP_NAME}"
FRONTEND_URL=http://localhost:3000
```

Gmail needs an [App Password](https://myaccount.google.com/apppasswords). For local testing without real email, use `MAIL_MAILER=log` (emails go to `storage/logs/laravel.log`).

Seeded admin: `admin@rental.test` / `password`

## API resources (auth required)

| Resource | Endpoint |
|----------|----------|
| Dashboard stats | `GET /api/v1/dashboard` |
| Owners | `/api/v1/owners` |
| Tenants | `/api/v1/tenants` |
| Properties | `/api/v1/properties` |
| Rental units | `/api/v1/rental-units` |
| Contracts | `/api/v1/contracts` |
| Payments | `/api/v1/payments` |
| Maintenance requests | `/api/v1/maintenance-requests` |

All resource endpoints support standard REST verbs: `GET` (index/show), `POST`, `PUT/PATCH`, `DELETE`.

Health check (public): `GET /api/v1/health`

## Database entities

```
users ──┬── owners ──── properties ──── rental_units ─┬── contracts ──── payments
        │                                              └── maintenance_requests
        └── tenants ───────────────────────────────────────┘
```

| Table | Purpose |
|-------|---------|
| `users` | Auth accounts (`role`: admin, owner, tenant, staff) |
| `owners` | Property owners |
| `tenants` | Renters |
| `properties` | Buildings / sites owned by an owner |
| `rental_units` | Individual units within a property |
| `contracts` | Lease agreements (tenant ↔ unit) |
| `payments` | Rent / deposit payments on a contract |
| `maintenance_requests` | Repair tickets for a unit |
