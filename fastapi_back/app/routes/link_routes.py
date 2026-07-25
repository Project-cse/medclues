"""Public HTTPS bridges for email/SMS links → native app & maps."""
from __future__ import annotations

from typing import Optional

from fastapi import APIRouter, Query
from fastapi.responses import HTMLResponse

router = APIRouter(tags=["links"])


@router.get("/link/appointment/{appointment_id}")
async def link_open_appointment(appointment_id: int):
    from app.utils.mobile_links import appointment_open_html

    return HTMLResponse(appointment_open_html(appointment_id))


@router.get("/link/maps")
async def link_open_maps(
    q: str = Query("", description="Hospital name and address"),
    lat: Optional[float] = None,
    lng: Optional[float] = None,
):
    from app.utils.mobile_links import maps_open_html

    parts = [p.strip() for p in q.split(",", 1)] if q else []
    hospital_name = parts[0] if parts else "Hospital"
    full_address = parts[1] if len(parts) > 1 else (q or hospital_name)
    return HTMLResponse(maps_open_html(hospital_name, full_address, lat, lng))
