# Schema source of truth

- **Canonical:** `fastapi_back/migrations/*.sql` (apply in order).
- **`medclues_schema_before.sql`:** stale pre-migration dump — **not** canonical; do not use for new environments.
- **Runtime `ensure_*` helpers:** transitional only; prefer migrations when adding columns/tables.

See also `docs/backend/DB_AUDIT_REPORT.md`.
