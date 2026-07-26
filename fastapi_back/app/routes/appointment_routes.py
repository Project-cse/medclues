"""Public appointment lookup by Booking ID (staff QR scan).

Shares prefix `/api/appointments` with Super Admin CRUD
(`super_appointment_routes.py`). Public GET `/{booking_id}` is for
reception BK lookup; admin list/create/update use auth_admin on the
same prefix. Do not merge blindly — OpenAPI tags differ.
"""
from fastapi import APIRouter
from app.controllers import user_controller

router = APIRouter(prefix="/api/appointments", tags=["Appointments — public BK lookup"])


@router.get("/{booking_id}")
async def get_appointment_by_booking_id(booking_id: str):
    """Staff scans QR → fetch full appointment by Booking ID (e.g. BK8X4P2)."""
    return await user_controller.get_appointment_by_booking_id(booking_id)
