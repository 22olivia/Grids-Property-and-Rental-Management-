# Pushing GPMS frontend to GitHub

Exact commands. **Run these yourself** — nothing here has been pushed, and no
credentials are needed by anyone but you.

---

## Before you start

- Git installed — check with `git --version`
- A GitHub account you can sign into
- The project open in a terminal (VS Code: `` Ctrl + ` `` / `` Cmd + ` ``)
- You are **inside** the `gpms-web` folder — check with `pwd` (macOS/Linux) or
  `cd` (Windows). The path must end in `gpms-web`.

---

## Step 1 — Confirm nothing private will be committed

```bash
# Should list .env.example ONLY. If it also lists .env or .env.local, stop.
ls -a | grep env
```

`.gitignore` already excludes `.env`, `.env.local`, `node_modules`, `.next`,
build output and editor folders. `.env.example` **is** meant to be committed —
it contains variable names and safe defaults, no secrets.

---

## Step 2 — Create the repository on GitHub

1. Go to <https://github.com/new>
2. **Repository name:** `gpms-web` (or `gpms-frontend`)
3. **Description:** `GPMS — Grids Property Management System frontend (Next.js, bilingual EN/AR)`
4. Choose **Private** unless you specifically want it public
5. **Do not** tick "Add a README", "Add .gitignore" or "Choose a license" —
   the project already has them, and adding them here causes a conflict on the
   first push
6. Click **Create repository**
7. Copy the HTTPS URL shown, e.g.
   `https://github.com/YOUR-USERNAME/gpms-web.git`

---

## Step 3 — Initialise and push

Run these in order, from inside the `gpms-web` folder.

```bash
# 1. Start a new Git repository
git init

# 2. Set your identity (skip if already configured globally)
git config user.name "Your Name"
git config user.email "your.email@example.com"

# 3. Stage everything (respecting .gitignore)
git add .

# 4. Check what will be committed — see the verification below
git status

# 5. Create the first commit
git commit -m "GPMS frontend: 35 screens, assets module live against the API"

# 6. Name the main branch
git branch -M main

# 7. Point at your GitHub repository (use YOUR url from step 2)
git remote add origin https://github.com/YOUR-USERNAME/gpms-web.git

# 8. Push
git push -u origin main
```

On the first push, GitHub will ask you to authenticate. In a browser-capable
terminal this opens a sign-in window. Otherwise GitHub asks for a **personal
access token** rather than your password — create one at
**GitHub → Settings → Developer settings → Personal access tokens**.

---

## Step 4 — Verify before you push (do this at step 4 above)

`git status` should show roughly **233 files**. Confirm:

```bash
# Must return NOTHING. If it prints a filename, remove it before committing.
git status --porcelain | grep -E "\.env$|\.env\.local|node_modules|\.next"

# Should print only: .env.example
git status --porcelain | grep env
```

If `node_modules` appears, `.gitignore` is not being applied — check you are in
the right folder and that `.gitignore` exists.

---

## Step 5 — Share it

Add the backend developer and any reviewers:

**GitHub → your repository → Settings → Collaborators → Add people**

Then point them at:

| Who | Start here |
|---|---|
| CEO / product | [`docs/DEMO-STATUS.md`](./DEMO-STATUS.md) |
| Anyone running it | [`docs/SETUP-VS-CODE.md`](./SETUP-VS-CODE.md) |
| Backend developer | [`docs/BACKEND-DEFECT-REPORT.md`](./BACKEND-DEFECT-REPORT.md) and [`docs/BACKEND-CONTRACT-REQUEST.md`](./BACKEND-CONTRACT-REQUEST.md) |

> The defect report contains a **critical** finding: `GET /properties` returns
> every organisation's properties to any staff user. Flag it explicitly rather
> than leaving it to be found in a document.

---

## Later: pushing further changes

```bash
git add .
git commit -m "Describe what changed"
git push
```

## Working on a branch instead of `main`

```bash
git checkout -b feature/my-change
# ... make changes ...
git add .
git commit -m "Describe what changed"
git push -u origin feature/my-change
```

Then open a Pull Request on GitHub.

---

## Troubleshooting

| Problem | Fix |
|---|---|
| `remote origin already exists` | `git remote remove origin`, then repeat step 7 |
| `failed to push some refs` | The GitHub repo is not empty. Either delete and recreate it without a README, or run `git pull --rebase origin main` and push again |
| `Authentication failed` | Use a personal access token, not your account password |
| `src refspec main does not match any` | You have not committed yet — run steps 3–5 |
| Accidentally committed `.env` | `git rm --cached .env`, commit again. **Rotate any secret that was in it** — it stays in the history |
| Repository is huge (>100 MB) | `node_modules` was committed. `git rm -r --cached node_modules`, confirm `.gitignore` lists it, commit again |
