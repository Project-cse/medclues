from datetime import datetime, timezone

from fastapi import APIRouter
from fastapi.responses import JSONResponse

from app.config.config import settings
from app.config.db import db

router = APIRouter(tags=["Health"])


@router.get("/health")
async def health_liveness():
    """Liveness probe — process is up."""
    return {
        "status": "ok",
        "service": "medclues-api",
        "version": "1.0.0",
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }


@router.get("/ready")
async def health_readiness():
    """Readiness probe — checks PostgreSQL connectivity."""
    checks: dict[str, str] = {"api": "ok"}
    db_ok = False
    try:
        if not db.pool:
            await db.connect()
        if db.pool:
            row = await db.fetch_row("SELECT 1 AS ok")
            db_ok = row is not None
        checks["database"] = "ok" if db_ok else "error"
    except Exception:
        checks["database"] = "error"

    ready = db_ok
    body = {
        "status": "ready" if ready else "not_ready",
        "checks": checks,
        "debug": settings.DEBUG,
        "timestamp": datetime.now(timezone.utc).isoformat(),
    }
    if not ready:
        return JSONResponse(status_code=503, content=body)
    return body
