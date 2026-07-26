"""Unauthenticated visit-summary APIs for post-appointment QR scans."""
from __future__ import annotations

from fastapi import APIRouter, Query

from app.services import appointment_summary_service

router = APIRouter(prefix="/api/public", tags=["public-appointment"])


@router.get("/appointment-summary/{booking_id}")
async def appointment_summary(
    booking_id: str,
    sig: str | None = Query(None, description="HMAC signature from Visit Summary QR"),
):
    return await appointment_summary_service.get_public_appointment_summary(booking_id, sig)
