import time
from typing import Any, Dict, Tuple

from app.models import doctor_model
from app.services import doctor_slot_service

# Short in-process TTL so booking screen polls / prefetch stay cheap.
_SLOTS_TTL_SEC = 20.0
_slots_cache: Dict[str, Tuple[float, Dict[str, Any]]] = {}


def _cache_key(doc_id: str, mode: str) -> str:
    from datetime import date

    return f"{doc_id}:{(mode or 'offline').lower()}:{date.today().isoformat()}"


def invalidate_slots_cache(doc_id: str | None = None) -> None:
    if not doc_id:
        _slots_cache.clear()
        return
    prefix = f"{doc_id}:"
    for key in list(_slots_cache.keys()):
        if key.startswith(prefix):
            _slots_cache.pop(key, None)


async def get_doctor_slots(doc_id: str, mode: str = "offline"):
    key = _cache_key(doc_id, mode)
    now = time.monotonic()
    hit = _slots_cache.get(key)
    if hit and (now - hit[0]) < _SLOTS_TTL_SEC:
        return hit[1]

    doctor = await doctor_model.get_doctor_by_id(doc_id)
    if not doctor:
        return {"success": False, "message": "Doctor not found"}

    doctor_ref, _ = doctor_slot_service.normalize_doctor_ref(doc_id)
    data = await doctor_slot_service.get_public_slots(doctor_ref, mode)
    if data.get("success"):
        _slots_cache[key] = (now, data)
        # Bound memory if many doctors are hit in one process.
        if len(_slots_cache) > 200:
            oldest = sorted(_slots_cache.items(), key=lambda kv: kv[1][0])[:50]
            for k, _ in oldest:
                _slots_cache.pop(k, None)
    return data
