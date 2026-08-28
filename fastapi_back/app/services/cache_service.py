"""Cache-aside helpers over optional Redis + in-process TTL fallback.

PostgreSQL remains source of truth. When REDIS_URL is unset or Redis is down,
an in-process dict keeps public list endpoints fast across requests.
"""
from __future__ import annotations

import json
import time
from typing import Any, Awaitable, Callable, Optional

from app.services import cache_keys as keys
from app.services.redis_client import get_redis
from app.utils.app_logger import get_logger

log = get_logger(__name__)

_hits = 0
_misses = 0

# key -> (expires_at_epoch, value)
_LOCAL: dict[str, tuple[float, Any]] = {}
_LOCAL_MAX_KEYS = 256


def stats() -> dict:
    total = _hits + _misses
    return {
        "hits": _hits,
        "misses": _misses,
        "hit_ratio": round(_hits / total, 4) if total else None,
        "local_keys": len(_LOCAL),
    }


def _local_get(key: str) -> Optional[Any]:
    hit = _LOCAL.get(key)
    if not hit:
        return None
    expires_at, value = hit
    if time.monotonic() >= expires_at:
        _LOCAL.pop(key, None)
        return None
    return value


def _local_set(key: str, value: Any, ttl: int) -> None:
    if len(_LOCAL) >= _LOCAL_MAX_KEYS:
        # Drop oldest ~25% by expiry time
        ordered = sorted(_LOCAL.items(), key=lambda kv: kv[1][0])
        for k, _ in ordered[: max(1, _LOCAL_MAX_KEYS // 4)]:
            _LOCAL.pop(k, None)
    _LOCAL[key] = (time.monotonic() + max(1, int(ttl)), value)


def _local_delete_prefix(prefix: str) -> int:
    if not prefix:
        return 0
    doomed = [k for k in _LOCAL if k.startswith(prefix)]
    for k in doomed:
        _LOCAL.pop(k, None)
    return len(doomed)


async def get_json(key: str) -> Optional[Any]:
    global _hits, _misses
    local = _local_get(key)
    if local is not None:
        _hits += 1
        return local

    r = await get_redis()
    if not r:
        _misses += 1
        return None
    try:
        raw = await r.get(key)
        if raw is None:
            _misses += 1
            return None
        _hits += 1
        value = json.loads(raw)
        # Mirror into process so subsequent hits stay cheap even mid-request storms.
        _local_set(key, value, 60)
        return value
    except Exception as exc:
        log.debug("cache get failed %s: %s", key, exc)
        _misses += 1
        return None


async def set_json(key: str, value: Any, ttl: int) -> bool:
    _local_set(key, value, ttl)
    r = await get_redis()
    if not r:
        return True
    try:
        await r.set(key, json.dumps(value, default=str), ex=max(1, int(ttl)))
        return True
    except Exception as exc:
        log.debug("cache set failed %s: %s", key, exc)
        return True  # local cache still holds


async def delete(*cache_key: str) -> int:
    deleted = 0
    for k in cache_key:
        if k in _LOCAL:
            _LOCAL.pop(k, None)
            deleted += 1
    r = await get_redis()
    if not r or not cache_key:
        return deleted
    try:
        return deleted + int(await r.delete(*cache_key))
    except Exception:
        return deleted


async def delete_prefix(prefix: str, count: int = 200) -> int:
    """Best-effort SCAN + DELETE for key prefixes (invalidation)."""
    deleted = _local_delete_prefix(prefix)
    r = await get_redis()
    if not r or not prefix:
        return deleted
    try:
        cursor = 0
        while True:
            cursor, batch = await r.scan(cursor=cursor, match=f"{prefix}*", count=count)
            if batch:
                deleted += int(await r.delete(*batch))
            if cursor == 0:
                break
        return deleted
    except Exception as exc:
        log.debug("cache delete_prefix %s failed: %s", prefix, exc)
        return deleted


async def cache_aside(
    key: str,
    ttl: int,
    loader: Callable[[], Awaitable[Any]],
    *,
    skip_cache: bool = False,
) -> Any:
    """Cache-aside: local/Redis → miss → load Postgres → set both."""
    if not skip_cache:
        cached = await get_json(key)
        if cached is not None:
            return cached
    data = await loader()
    if data is not None and not skip_cache:
        if isinstance(data, dict) and data.get("success") is False:
            return data
        await set_json(key, data, ttl)
    return data


# --- Domain invalidation helpers ---

async def invalidate_doctors() -> None:
    await delete_prefix(keys.PREFIX_DOCTOR)
    await delete_prefix(keys.PREFIX_DASHBOARD)
    await delete_prefix(keys.PREFIX_SEARCH)


async def invalidate_hospitals() -> None:
    await delete_prefix(keys.PREFIX_HOSPITAL)
    await delete_prefix(keys.PREFIX_DASHBOARD)
    await delete_prefix(keys.PREFIX_SEARCH)


async def invalidate_specialties() -> None:
    await delete(keys.specialty_list())
    await delete_prefix(keys.PREFIX_SEARCH)
    await delete_prefix(keys.PREFIX_DOCTOR)


async def invalidate_system_config() -> None:
    await delete(keys.config_system())


async def invalidate_community() -> None:
    await delete_prefix(keys.PREFIX_COMMUNITY)


async def invalidate_labs() -> None:
    await delete(keys.lab_list())


async def invalidate_partner_catalog() -> None:
    await delete(keys.partner_catalog())


async def invalidate_queue(doctor_id: int | str, slot_date: str) -> None:
    await delete(keys.queue_snapshot(doctor_id, slot_date))


async def invalidate_dashboards() -> None:
    await delete_prefix(keys.PREFIX_DASHBOARD)
