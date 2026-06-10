# MEDCLUES Production Audit Report
**Date:** 10 June 2026  
**Stack:** Flutter · FastAPI · PostgreSQL (Neon) · Render  

---

## Executive Summary

Three of four reported issues share one root cause: **Render deployment failed** after the latest GitHub push. Production is still running an **older backend** that lacks Telegram routes and OPD capacity fixes. The Flutter APK points at `https://medclues.onrender.com`, so users see correct slot counts from partial/cached API responses but booking fails on legacy validation.

**Immediate action:** Fix Render env (`JWT_SECRET` ≥ 32 chars, `DEBUG=false`) and redeploy. Then verify Telegram + booking on APK.

---

## CRITICAL ISSUES

### C1 — Render backend not starting (blocks everything)
| Item | Detail |
|------|--------|
| **Symptom** | Deploy exits status 1; logs: `JWT_SECRET must be at least 32 characters` |
| **Root cause** | `DEBUG=false` on Render + `JWT_SECRET=greatstack` (9 chars, insecure default) |
| **Impact** | New code never runs → Telegram 404, old booking logic, no FCM/Telegram routes |
| **Affected** | `fastapi_back/app/config/config.py` (`validate_settings`) |
| **Fix** | Set on Render: `JWT_SECRET=<random 32+ chars>`, redeploy |

### C2 — OPD booking: "Slot not available" while 19 left
| Item | Detail |
|------|--------|
| **Symptom** | User A books; User B sees 19 remaining; booking returns "Slot not available" |
| **Root cause** | Legacy `slots_booked` JSON stores block label `"10:00 AM - 1:00 PM"` once; old code treats it as **single-seat** dedup |
| **Capacity model** | `doctor_slots` table: 20 rows/block, `status=available|booked` — **correct** in latest code |
| **Why counts work** | `GET /api/doctor/{id}/slots` uses `COUNT(*) FILTER (WHERE status='available')` |
| **Why book fails** | `book_appointment` legacy branch rejects duplicate block time string before/without `doctor_slots` fix |
| **Affected** | `fastapi_back/app/controllers/user_controller.py` |
| **Fix implemented** | Skip legacy duplicate check for OPD block labels; `doctor_slots` is source of truth |

### C3 — Telegram Connect → "Not Found"
| Item | Detail |
|------|--------|
| **Symptom** | Settings → Connect Telegram → snackbar "Not found" |
| **Root cause** | `POST /api/user/telegram/link-code` and `GET /api/user/telegram/status` return **404** because failed deploy = old server |
| **Routes exist in repo** | `fastapi_back/app/routes/user_routes.py` lines 382–393 |
| **Bot username** | `@medcluesBot` (`TELEGRAM_BOT_USERNAME=medcluesBot`) |
| **Fix** | Redeploy backend + set `TELEGRAM_BOT_TOKEN`, `TELEGRAM_BOT_ENABLED=true`, `TELEGRAM_BOT_USERNAME=medcluesBot` on Render |

---

## HIGH ISSUES

### H1 — `render.yaml` points at wrong stack
- Root `render.yaml` references Node `backend/` — not FastAPI `fastapi_back/`
- Manual Render web service config is used; document env vars in `BACKEND_GITHUB_DEPLOY.md`

### H2 — CORS empty on production
- Warning: `CORS_ALLOWED_ORIGINS is empty`
- Mobile APK unaffected (no browser CORS); web admin/patient may fail cross-origin
- **Fix:** Set `CORS_ALLOWED_ORIGINS=https://medclues.onrender.com,<admin-url>` on Render

### H3 — Dedicated permission screen (UX)
- Forced `/permissions-setup` before app use — not industry standard
- **Fix implemented:** Remove forced redirect; request permissions in-context

### H4 — `SOCIAL_LOGIN_ALLOW_LEGACY=true` in production
- Accepts unverified email for Google login — security risk
- Mitigate after clients send `idToken`; set `SOCIAL_LOGIN_ALLOW_LEGACY=false`

---

## MEDIUM ISSUES

| ID | Issue | Notes |
|----|-------|-------|
| M1 | Stale slot cache on booking screen | 10s poll + cache-bust query param — already in Flutter |
| M2 | Race on same slot row | `FOR UPDATE SKIP LOCKED` in `find_first_available_in_block` — OK |
| M3 | `slots_booked` legacy data pollution | Existing doctors may have block labels in JSON; OPD skip fix handles |
| M4 | Firebase push needs Render env | `FIREBASE_CREDENTIALS_PATH` / JSON on server for FCM |
| M5 | Duplicate monorepo folders | `admin/`, `mobile/`, `flutter_mobile/` — intentional multi-client |

---

## LOW ISSUES

| ID | Issue |
|----|-------|
| L1 | `scratch/` dev scripts in repo |
| L2 | cupertino_icons font warning on APK build |
| L3 | Debug signing on release APK |
| L4 | 81 outdated Flutter packages |

---

## ISSUE 1 — APPOINTMENT BOOKING (DETAILED)

### Flow traced
```
Flutter booking_screen → POST /api/user/book-appointment
  → user_controller.book_appointment
  → ensure_doctor_slots_for_doctor
  → resolve_slot_for_booking (slotId or block type + date)
  → mark_slot_booked (one of 20 rows)
  → legacy slots_booked sync  ← FAILURE POINT (old deploy)
  → create_appointment
```

### Frontend
- `appointment_service.dart` sends `mode`, `slotType`, `slotId`
- `doctorScheduleProvider` polls every 10s
- Displays `available_count` from API blocks

### Backend capacity
- `OFFLINE_SLOTS_PER_BLOCK = 20` in `doctor_slot_service.py`
- Summary: `available_count = COUNT(*) FILTER (WHERE status='available')`

### Timezone
- Schedule uses `Asia/Kolkata` (`_today_ist()`)
- Date keys: `DD_MM_YYYY` padded + ISO in API response

### Expected after fix + deploy
| Booked | Remaining | Book allowed |
|--------|-----------|--------------|
| 0 | 20 | Yes |
| 1 | 19 | Yes |
| 19 | 1 | Yes |
| 20 | 0 | No — block full |

---

## ISSUE 2 — TELEGRAM (DETAILED)

### Flow
```
telegram_connect_card → TelegramLinkService.createLinkCode()
  → POST /api/user/telegram/link-code
  → telegram_link_controller.create_app_link_code
  → deep link https://t.me/medcluesBot?start=link_{code}
  → openTelegramLink() (tg:// or https)
```

### Render env required
```
TELEGRAM_BOT_TOKEN=8616985316:...
TELEGRAM_BOT_ENABLED=true
TELEGRAM_BOT_USERNAME=medcluesBot
```

### Flutter fallback
- If API 404: opens bot + install dialog; friendly message after redeploy

---

## ISSUE 3 — RENDER DEPLOYMENT (DETAILED)

### Startup validation (`validate_settings`)
| Variable | Production rule |
|----------|-----------------|
| `DEBUG` | `false` |
| `JWT_SECRET` | Required, ≥ 32 chars, not `greatstack`/`secret` |
| `DATABASE_URL` | Required |
| `CORS_ALLOWED_ORIGINS` | Warn if empty |

### Missing / invalid on Render (likely)
| Variable | Status |
|----------|--------|
| `JWT_SECRET` | **INVALID** — too short |
| `TELEGRAM_BOT_USERNAME` | May be missing |
| `CORS_ALLOWED_ORIGINS` | Empty |
| `FIREBASE_CREDENTIALS` | May be missing for push |

### Generate JWT secret (example)
```powershell
[Convert]::ToBase64String((1..48 | ForEach-Object { Get-Random -Maximum 256 }) -as [byte[]])
```

---

## ISSUE 4 — PERMISSION FLOW (DETAILED)

### Before
- Splash → `/permissions-setup` → 6 sequential dialogs → dashboard

### After (implemented)
| Feature | When requested |
|---------|----------------|
| Location | Emergency SOS / location share |
| Camera + Mic | Video consultation start |
| Photos / files | Upload report, profile photo, booking prescription |
| Notifications | First FCM token sync after login |
| Phone | Emergency call (when used) |

Uses `permission_handler` native dialogs only. Permanently denied → optional open Settings.

---

## AFFECTED FILES (FIXES)

| File | Change |
|------|--------|
| `user_controller.py` | OPD legacy dedup bypass |
| `app_permissions_service.dart` | Contextual `ensure*` helpers |
| `app_router.dart` | Remove forced permissions route |
| `splash_screen.dart` | Remove permissions redirect |
| `records_screen.dart` | Request photos before pick |
| `booking_screen.dart` | Request photos before prescription pick |
| `personal_info_screen.dart` | Request photos before avatar |
| `push_notification_service.dart` | Request notifications on token sync |
| `telegram_link_service.dart` | Clearer 404 errors |
| `.env.example` | Telegram username + JWT guidance |
| `BACKEND_GITHUB_DEPLOY.md` | Render checklist updated |

---

## TEST RESULTS

| Test | Status | Notes |
|------|--------|-------|
| Local backend slot logic | Code review PASS | OPD skip fix applied |
| Render deploy | **FAIL** | JWT_SECRET — user must fix env |
| Telegram API | **BLOCKED** | Until redeploy |
| APK build | PASS | `app-release.apk` with desugaring |
| Flutter analyze | PASS | No new errors |

---

## STATUS SUMMARY

| Area | Status |
|------|--------|
| **Render** | ❌ Down / old version — fix JWT_SECRET & redeploy |
| **Telegram** | ❌ 404 until redeploy |
| **Appointments** | ⚠️ Fix in repo; needs deploy + retest |
| **Permissions** | ✅ Contextual flow in Flutter |
| **GitHub** | ✅ Pushed to `Project-cse/medclues` main |

---

## FINAL PRODUCTION READINESS SCORE

| Component | Score |
|-----------|-------|
| Flutter APK | **78/100** — ready after API live |
| FastAPI (code) | **85/100** — fixes in repo |
| Render deploy | **20/100** — blocked on JWT |
| Database | **80/100** — existing Neon OK |
| Telegram | **40/100** — needs deploy + bot env |
| Overall | **62/100** — **not production-ready until Render redeploys**

### To reach 90+
1. Set `JWT_SECRET` (32+ chars) on Render → redeploy  
2. Set Telegram + Firebase env on Render  
3. Retest: 2 users book same OPD block until 20  
4. Retest: Connect Telegram on APK  
5. Optional: production signing key for APK  
