"""Public appointment lookup routes (staff QR scan)."""
from fastapi import APIRouter
from app.controllers import user_controller

router = APIRouter(prefix="/api/appointments", tags=["Appointments"])


@router.get("/{booking_id}")
async def get_appointment_by_booking_id(booking_id: str):
    """Staff scans QR → fetch full appointment by Booking ID (e.g. BK8X4P2)."""
    return await user_controller.get_appointment_by_booking_id(booking_id)
