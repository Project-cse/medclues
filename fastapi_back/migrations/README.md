# Database migrations

Numbered SQL files applied in order by `schema_migrations` tracking.

## Apply manually

```bash
cd fastapi_back
python scripts/run_migrations.py
```

Migrations also run automatically on API startup when PostgreSQL is connected.

## Files

| Version | Purpose |
|---------|---------|
| `001_refresh_tokens` | Refresh token store |
| `002_user_onboarding` | Onboarding columns on users |
| `003_payment_transactions` | Persistent Razorpay orders |
| `004_emergency_events` | Emergency SOS audit |
| `005_audit_logs` | PHI / compliance audit trail |
| `006_performance_indexes` | Query indexes |
| `007_foreign_keys` | FK hardening (via `schema_hardening.py`) |
| `008_drop_deans_password_text` | Remove plaintext dean passwords |

## Foreign keys

`007` triggers `app/db/schema_hardening.py`, which adds FKs only when no orphan rows exist. Check server logs for skipped constraints.
