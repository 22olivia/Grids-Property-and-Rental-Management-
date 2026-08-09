# Integrating GPMS API with a frontend

Point any frontend (Next.js, Flutter, mobile) at this API. No shared monorepo required.

## Base URL

```
NEXT_PUBLIC_API_URL=https://YOUR-API-HOST/api/v1
```

Do **not** append `/health` to the base URL. Health is a separate path: `GET /api/v1/health`.

## Auth flow

1. `POST /login` or `POST /signup` → store `token` + `user`
2. Send `Authorization: Bearer {token}` on every authenticated request
3. `GET /me` to refresh session
4. `POST /logout` to revoke token

### Example (fetch)

```ts
const API = process.env.NEXT_PUBLIC_API_URL!;

async function login(email: string, password: string) {
  const res = await fetch(`${API}/login`, {
    method: "POST",
    headers: { "Content-Type": "application/json", Accept: "application/json" },
    body: JSON.stringify({ email, password }),
  });
  if (!res.ok) throw new Error((await res.json()).message || "Login failed");
  return res.json(); // { token, user, message }
}

async function api(path: string, token: string, init: RequestInit = {}) {
  const res = await fetch(`${API}${path}`, {
    ...init,
    headers: {
      Accept: "application/json",
      "Content-Type": "application/json",
      Authorization: `Bearer ${token}`,
      ...(init.headers || {}),
    },
  });
  if (!res.ok) throw new Error((await res.json()).message || "Request failed");
  return res.json();
}

// Role dashboard
const dash = await api("/dashboard", token);
// dash.data.dashboard_variant === "super_admin" | "owner" | "manager" | "tenant"
```

## Roles

| `user.role` | Dashboard variant | Typical access |
|-------------|-------------------|----------------|
| `super_admin` | `super_admin` | Everything |
| `owner` | `owner` | Own portfolio |
| `manager` | `manager` | Assigned properties |
| `tenant` | `tenant` | Own lease / invoices / pay |

Normalize legacy aliases if needed: `admin` → `super_admin`, `staff` → `manager`.

## CORS / frontend origin

Set `FRONTEND_URL` on the API for password-reset emails.  
For browser apps, ensure `config/cors.php` allows your frontend origin (default is `*`).

## Minimal pages to wire first

1. Login / signup
2. Dashboard (`GET /dashboard`)
3. Leases / invoices / payments
4. Online pay: `POST /payments/orders` → confirm or webhook (see [PAYMENTS.md](./PAYMENTS.md))
5. Notifications (`GET /notifications`)

## Demo data

After `php artisan migrate --seed`, invoices, payments, leases, maintenance, and notifications exist for all four demo accounts — useful for UI testing without hand-entering data.
