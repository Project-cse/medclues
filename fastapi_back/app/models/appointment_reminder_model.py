"""Tracks 24h appointment reminder pushes (FCM / Telegram)."""
from typing import Any, Dict, List

from app.config.db import db


async def ensure_reminder_schema() -> None:
    await db.execute(
        """
        CREATE TABLE IF NOT EXISTS appointment_reminder_sent (
            appointment_id INTEGER PRIMARY KEY REFERENCES appointments(id) ON DELETE CASCADE,
            reminder_24h_sent_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """
    )


async def mark_reminder_sent(appointment_id: int) -> None:
    await db.execute(
        """
        INSERT INTO appointment_reminder_sent (appointment_id)
        VALUES ($1)
        ON CONFLICT (appointment_id) DO NOTHING
        """,
        int(appointment_id),
    )


async def get_upcoming_for_24h_reminder() -> List[Dict[str, Any]]:
    """Appointments starting in ~24 hours (23h–25h window), not cancelled/completed."""
    sql = """
        SELECT a.id, a.user_id, a.slot_date, a.slot_time, a.doctor_data, a.token_number,
               u.name AS patient_name
        FROM appointments a
        JOIN users u ON u.id = a.user_id
        LEFT JOIN appointment_reminder_sent r ON r.appointment_id = a.id
        WHERE a.cancelled = false
          AND COALESCE(a.is_completed, false) = false
          AND r.appointment_id IS NULL
          AND a.slot_date IS NOT NULL
          AND a.slot_time IS NOT NULL
        ORDER BY a.id ASC
        LIMIT 200
    """
    rows = await db.query(sql)
    return rows or []
