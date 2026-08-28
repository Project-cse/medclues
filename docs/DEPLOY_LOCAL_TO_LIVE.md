# Local → Live deploy parity (MEDCLUES / AGENTIC-AI)

Use this checklist so **production matches localhost** (`uvicorn` on `:5000`, admin on `:5174`, patient web on `:5173`).

## Repos & remotes

| Remote | GitHub | Use |
|--------|--------|-----|
| `agentic-ai` | [231fa04c77-crypto/AGENTIC-AI](https://github.com/231fa04c77-crypto/AGENTIC-AI) | Hackathon / agentic-ai deliverable |
| `medclues` / `origin` | [Project-cse/medclues](https://github.com/Project-cse/medclues) | **Render API auto-deploy** (typical) |

After changes, push **both**:

```powershell
git push agentic-ai main
git push medclues main
```

## Local run (reference — what live should mirror)

```powershell
# 1. Backend (run from THIS repo root — not an old Downloads copy)
cd fastapi_back
pip install -r requirements.txt
python scripts/run_migrations.py
python -m uvicorn main:app --host 0.0.0.0 --port 5000 --reload

# 2. Admin / doctor panel
cd admin
# admin/.env → VITE_BACKEND_URL=http://localhost:5000
npm install && npm run dev    # :5174

# 3. Patient web (optional)
cd frontend
# frontend/.env → VITE_BACKEND_URL=http://localhost:5000
npm install && npm run dev    # :5173
```

> **Important:** If you also have `Downloads\PMS FNL 2-1\...`, pull latest there or stop using it — stale copies cause “works locally but not on GitHub/live”.

## Live URLs (typical)

| Service | URL | Env var |
|---------|-----|---------|
| API (Render) | `https://medclues.onrender.com` | — |
| Admin (Vercel) | `https://medclues-admin.vercel.app` (or your project URL) | `VITE_BACKEND_URL=https://medclues.onrender.com` |
| Patient web (Vercel) | your Vercel frontend URL | `VITE_BACKEND_URL=https://medclues.onrender.com` |

## Render (FastAPI backend)

1. **Connect repo:** `Project-cse/medclues` (or `AGENTIC-AI` if that service is wired).
2. **Settings:**
   - **Root directory:** `fastapi_back`
   - **Build:** `pip install -r requirements.txt`
   - **Start:** `python -m uvicorn main:app --host 0.0.0.0 --port $PORT`
   - **Health check:** `/health`
3. **Environment** (same DB as local `.env` Neon URL):
   - `DATABASE_URL`, `JWT_SECRET` (≥32 chars), `DEBUG=false`
   - `CORS_ALLOWED_ORIGINS` — include admin + frontend Vercel URLs and `http://localhost:5173,http://localhost:5174`
4. **Deploy:** Push to `medclues/main` → auto-deploy, or Render → **Manual Deploy**.
5. **Migrations:** Run on startup automatically; or SSH/shell: `python scripts/run_migrations.py` (includes `067`, `068` journey fixes).

Verify:

```powershell
Invoke-RestMethod https://medclues.onrender.com/health
# Expect: status ok, service medclues-api
```

## Vercel (Admin + Patient web)

1. Connect same GitHub repo.
2. **Admin project:** root `admin`, build `npm run build`, output `dist`.
3. **Frontend project:** root `frontend`, build `npm run build`, output `dist`.
4. Set **`VITE_BACKEND_URL=https://medclues.onrender.com`** in Vercel env (Production + Preview).
5. Redeploy after every backend/API push.

## Parity checklist

- [ ] Code pushed to `agentic-ai` **and** `medclues` `main`
- [ ] Render service root = `fastapi_back`, start command matches local uvicorn
- [ ] Same `DATABASE_URL` (Neon) as local `fastapi_back/.env`
- [ ] Migrations `067_appointments_status_lifecycle`, `068_patient_journey_episodes` applied (check Render logs)
- [ ] Vercel `VITE_BACKEND_URL` points to Render, not `localhost`
- [ ] CORS includes your Vercel admin/frontend URLs
- [ ] Local server run from **Desktop repo**, not old Downloads copy

## Quick sync old Downloads copy

```powershell
cd "C:\Users\vemul\Downloads\PMS FNL 2-1\PMS FNL 2"
git fetch agentic
git reset --hard agentic/main
cd fastapi_back
python scripts/run_migrations.py
```

Then restart uvicorn from that folder **or** switch to Desktop `PMS FNL 2` only.
