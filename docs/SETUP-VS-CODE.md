# Running the GPMS frontend in VS Code

Step-by-step, assuming no prior setup. Roughly 10 minutes.

---

## 1. Prerequisites

Install these once.

### Node.js — required

Download the **LTS** version from <https://nodejs.org> and install it.
Version **20.11 or newer** is required (22 is fine).

Check it worked — open a terminal and run:

```bash
node --version
npm --version
```

You should see something like `v22.11.0` and `10.9.0`. If you see
"command not found", restart your computer and try again.

### VS Code — required

Download from <https://code.visualstudio.com> and install.

### Git — only needed for pushing to GitHub

Download from <https://git-scm.com/downloads>. Check with:

```bash
git --version
```

---

## 2. Download the project

Download the `gpms-web` folder and put it somewhere sensible, for example:

- **Windows:** `C:\Projects\gpms-web`
- **macOS / Linux:** `~/Projects/gpms-web`

If it arrived as a `.zip`, unzip it first. Make sure you end up with a folder
containing `package.json` directly inside it — not a folder containing another
folder.

---

## 3. Open it in VS Code

1. Open VS Code.
2. **File → Open Folder…**
3. Select the `gpms-web` folder and click **Open**.
4. If VS Code asks "Do you trust the authors of the files in this folder?",
   choose **Yes, I trust the authors**.

You should see `src`, `docs`, `messages`, `package.json` and others in the
sidebar.

---

## 4. Open the terminal inside VS Code

Press:

- **Windows / Linux:** `` Ctrl + ` `` (the backtick key, above Tab)
- **macOS:** `` Cmd + ` ``

Or use the menu: **Terminal → New Terminal**.

A panel opens at the bottom. The path shown should end in `gpms-web`.

---

## 5. Install the dependencies

In that terminal:

```bash
npm install
```

This downloads everything the project needs. It takes 1–3 minutes the first
time and creates a `node_modules` folder. That folder is intentionally not
shared — it is rebuilt by this command on every machine.

> **Note:** dependencies have never been installed for this project before, so
> this is the first real test of the setup. If `npm install` reports errors,
> copy the output and send it over rather than trying to fix it blind.

---

## 6. Create your `.env.local`

The project reads configuration from a file called `.env.local`, which is
never shared because it can hold private values.

**macOS / Linux:**

```bash
cp .env.example .env.local
```

**Windows (PowerShell):**

```powershell
Copy-Item .env.example .env.local
```

Open `.env.local` in VS Code (click it in the sidebar). It already defaults to
demo mode, so you can skip straight to step 7 if that is what you want.

### Mode A — demo mode, no backend needed

Best for a first run and for showing the CEO.

```env
NEXT_PUBLIC_DATA_SOURCE=mock
```

Everything works with sample data. No Laravel backend required.

### Mode B — real backend

Only if the GPMS Laravel API is running on your machine.

```env
NEXT_PUBLIC_DATA_SOURCE=http
GPMS_API_BASE_URL=http://127.0.0.1:8000/api/v1
```

Property, building and unit screens then use real data. Listings and CRM stay
on sample data because the backend has no endpoints for them.

Save the file (`Ctrl + S` / `Cmd + S`).

---

## 7. Start the project

```bash
npm run dev
```

Wait for a line like:

```
▲ Next.js 15.1.6
- Local:  http://localhost:3000
✓ Ready in 2.1s
```

Open <http://localhost:3000> in your browser. In VS Code you can
`Ctrl`-click (or `Cmd`-click) the link in the terminal.

### Signing in — demo mode

Use any password with one of:

| Role | Email |
|---|---|
| Super Admin | `admin@rental.test` |
| Owner | `owner@grids.test` |
| Manager | `manager@grids.test` |
| Tenant | `tenant@grids.test` |

These accounts exist **only** in demo mode. In real-backend mode you need real
credentials from the backend developer.

---

## 8. Check the main routes

Visit these after signing in. Each also works with `/ar/` instead of `/en/`
for Arabic.

**Live backend data (in Mode B):**

| Screen | URL |
|---|---|
| Properties | <http://localhost:3000/en/console/assets/properties> |
| Buildings | <http://localhost:3000/en/console/assets/buildings> |
| Units | <http://localhost:3000/en/console/assets/units> |
| Add a unit | <http://localhost:3000/en/console/assets/units/new> |

**Sample data:**

| Screen | URL |
|---|---|
| Listings | <http://localhost:3000/en/console/listings> |
| Approval queue | <http://localhost:3000/en/console/listings/approvals> |
| Leads | <http://localhost:3000/en/console/crm/leads> |
| Sales pipeline | <http://localhost:3000/en/console/crm/pipeline> |
| Viewings | <http://localhost:3000/en/console/crm/viewings> |
| Offers | <http://localhost:3000/en/console/crm/offers> |

**Try Arabic:** <http://localhost:3000/ar/console/assets/units> — or use the
language button in the header, which keeps you on the same page.

Screens on sample data show an amber banner saying so. Screens using the real
API do not.

---

## 9. Stop the project

In the terminal running it, press:

```
Ctrl + C
```

on **all** platforms — including macOS, where it is `Ctrl`, not `Cmd`.

---

## 10. Run the quality checks

Optional but recommended before pushing.

```bash
npm run verify
```

That runs, in order: RTL safety, English/Arabic parity, message keys, API
boundary, TypeScript, ESLint and unit tests.

To check the production build compiles:

```bash
npm run build
```

> **Expect some first-run errors.** TypeScript, ESLint and the build have never
> been executed against this code — the environment it was written in had no
> internet access, so dependencies could not be installed. Any errors will be
> ordinary type mismatches, most likely in the API mapping files.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `npm: command not found` | Node.js is not installed, or you need to restart after installing |
| `Port 3000 is already in use` | Another app is using it. Run `npm run dev -- -p 3001` and use port 3001 |
| Blank page or "Cannot connect" | Check the terminal for errors; make sure `npm run dev` is still running |
| Sign-in fails in demo mode | Check `.env.local` says `NEXT_PUBLIC_DATA_SOURCE=mock`, then stop and restart `npm run dev` |
| Sign-in fails in backend mode | The Laravel API is not running, or `GPMS_API_BASE_URL` is wrong |
| Changes to `.env.local` do nothing | Environment variables load at startup — stop with `Ctrl + C` and run `npm run dev` again |
| Everything looks unstyled | Stop the server, delete the `.next` folder, run `npm run dev` again |
