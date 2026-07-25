"""Reception QR scan and check-in with visit increment."""
from __future__ import annotations

from datetime import datetime
from typing import Any, Optional

from app.config.db import db
from app.models import appointment_model
from app.services import appointment_lifecycle_service, audit_service
from app.utils.booking_id import is_valid_booking_id, normalize_booking_id


async def scan_and_checkin(
    booking_id: str,
    *,
    scanner_id: Optional[int] = None,
    scanner_role: Optional[str] = None,
    hospital_id: Optional[int] = None,
    doctor_id: Optional[int] = None,
    scan_method: str = "QR",
) -> dict[str, Any]:
    code = normalize_booking_id(booking_id)
    if not is_valid_booking_id(code):
        return {"success": False, "message": "Invalid booking ID format"}

    appointment = await appointment_model.get_appointment_by_booking_id(code)
    if not appointment:
        return {"success": False, "message": "Appointment not found"}

    ls = (appointment.get("lifecycle_status") or "BOOKED").upper()
    if ls in appointment_lifecycle_service.TERMINAL_STATUSES:
        return {"success": False, "message": "Appointment is no longer active."}

    apt_hospital = appointment.get("hospital_id")
    if hospital_id is not None and apt_hospital is not None:
        if int(apt_hospital) != int(hospital_id):
            return {"success": False, "message": "Hospital does not match this appointment."}

    if doctor_id is not None and int(appointment["doctor_id"]) != int(doctor_id):
        return {"success": False, "message": "Doctor does not match this appointment."}

    valid_until = appointment.get("valid_until")
    if valid_until and isinstance(valid_until, datetime):
        if datetime.utcnow() > valid_until:
            await appointment_lifecycle_service.transition(
                int(appointment["id"]),
                "EXPIRED",
                actor_id=scanner_id,
                actor_role=scanner_role,
                reason="Validity expired",
            )
            return {"success": False, "message": "Appointment has expired."}

    visit_count = int(appointment.get("visit_count") or 0)
    max_visits = int(appointment.get("max_visits") or 3)
    if visit_count >= max_visits:
        await appointment_lifecycle_service.transition(
            int(appointment["id"]),
            "EXPIRED",
            actor_id=scanner_id,
            actor_role=scanner_role,
            reason="Visit limit reached",
        )
        return {
            "success": False,
            "message": "Maximum visits reached. Patient must book again.",
        }

    new_visit = visit_count + 1
    if not db.pool:
        await db.connect()
    async with db.pool.acquire() as conn:
        async with conn.transaction():
            updated = await conn.fetchrow(
                """
                UPDATE appointments SET
                    visit_count = $2,
                    updated_at = CURRENT_TIMESTAMP
                WHERE id = $1
                RETURNING *
                """,
                int(appointment["id"]),
                new_visit,
            )
            await conn.execute(
                """
                INSERT INTO appointment_visit_log (
                    appointment_id, visit_number, scanned_by_id, scanned_by_role,
                    hospital_id, doctor_id, scan_method, metadata
                ) VALUES ($1,$2,$3,$4,$5,$6,$7,$8::jsonb)
                """,
                int(appointment["id"]),
                new_visit,
                scanner_id,
                scanner_role,
                apt_hospital,
                appointment.get("doctor_id"),
                scan_method,
                '{"source":"reception_scan"}',
            )

    if ls in ("BOOKED", "CONFIRMED", "RESCHEDULED_ONCE"):
        await appointment_lifecycle_service.transition(
            int(appointment["id"]),
            "CHECKED_IN",
            actor_id=scanner_id,
            actor_role=scanner_role,
        )

    await audit_service.log_access(
        action="APPOINTMENT_CHECKIN",
        resource="appointment",
        resource_id=appointment["id"],
        actor_id=scanner_id,
        actor_role=scanner_role,
        metadata={"visitNumber": new_visit, "bookingId": code},
    )

    apt_dict = dict(updated) if updated else dict(appointment)
    return {
        "success": True,
        "message": f"Check-in successful. Visit {new_visit} of {max_visits}.",
        "visitNumber": new_visit,
        "maxVisits": max_visits,
        "appointment": appointment_lifecycle_service.lifecycle_payload(apt_dict),
    }
