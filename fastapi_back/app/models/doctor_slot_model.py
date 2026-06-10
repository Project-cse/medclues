from datetime import date, time, datetime
from typing import Any, Dict, List, Optional, Union

from app.config.db import db


async def ensure_doctor_slots_schema():
    await db.execute(
        """
        CREATE TABLE IF NOT EXISTS doctor_slots (
            id SERIAL PRIMARY KEY,
            slot_code VARCHAR(40) UNIQUE,
            doctor_ref VARCHAR(32) NOT NULL,
            doctor_numeric_id INTEGER NOT NULL,
            slot_date DATE NOT NULL,
            start_time TIME NOT NULL,
            end_time TIME NOT NULL,
            mode VARCHAR(16) NOT NULL,
            slot_type VARCHAR(24) NOT NULL,
            status VARCHAR(16) NOT NULL DEFAULT 'available',
            created_at TIMESTAMPTZ DEFAULT NOW(),
            updated_at TIMESTAMPTZ DEFAULT NOW(),
            CONSTRAINT doctor_slots_status_check
                CHECK (status IN ('available', 'booked', 'cancelled', 'completed')),
            CONSTRAINT doctor_slots_mode_check
                CHECK (mode IN ('offline', 'online'))
        )
        """
    )
    await db.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_doctor_slots_lookup
            ON doctor_slots (doctor_ref, slot_date, mode, status)
        """
    )
    await db.execute(
        """
        CREATE UNIQUE INDEX IF NOT EXISTS idx_doctor_slots_unique_window
            ON doctor_slots (doctor_ref, slot_date, start_time, mode)
            WHERE status IN ('available', 'booked')
        """
    )
    await db.execute(
        """
        ALTER TABLE doctors
        ADD COLUMN IF NOT EXISTS video_consultation_fee NUMERIC(10,2) DEFAULT 450
        """
    )
    await db.execute(
        """
        ALTER TABLE doctors
        ADD COLUMN IF NOT EXISTS followup_video_fee NUMERIC(10,2) DEFAULT 250
        """
    )
    await db.execute(
        """
        UPDATE doctors SET fees = 600 WHERE fees IS NULL OR fees = 0
        """
    )
    await db.execute(
        """
        UPDATE doctors SET video_consultation_fee = 450
        WHERE video_consultation_fee IS NULL
        """
    )
    await db.execute(
        """
        UPDATE doctors SET followup_video_fee = 250
        WHERE followup_video_fee IS NULL
        """
    )
    await db.execute(
        """
        ALTER TABLE appointments ADD COLUMN IF NOT EXISTS slot_id INTEGER
        """
    )


async def ensure_appointment_slot_id_column():
    await db.execute(
        """
        ALTER TABLE appointments ADD COLUMN IF NOT EXISTS slot_id INTEGER
        """
    )


async def day_has_slots(doctor_ref: str, slot_date: date) -> bool:
    row = await db.fetch_row(
        "SELECT 1 FROM doctor_slots WHERE doctor_ref = $1 AND slot_date = $2 LIMIT 1",
        doctor_ref,
        slot_date,
    )
    return row is not None


async def schedule_covers_range(
    doctor_ref: str,
    from_date: date,
    to_date: date,
    min_days: int,
) -> bool:
    row = await db.fetch_row(
        """
        SELECT COUNT(DISTINCT slot_date)::int AS cnt
        FROM doctor_slots
        WHERE doctor_ref = $1 AND slot_date >= $2 AND slot_date <= $3
        """,
        doctor_ref,
        from_date,
        to_date,
    )
    return row is not None and int(row["cnt"]) >= min_days


async def insert_slot(row: Dict[str, Any]):
    sql = """
        INSERT INTO doctor_slots (
            slot_code, doctor_ref, doctor_numeric_id, slot_date,
            start_time, end_time, mode, slot_type, status
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'available')
        ON CONFLICT DO NOTHING
        RETURNING *
    """
    return await db.fetch_row(
        sql,
        row["slot_code"],
        row["doctor_ref"],
        row["doctor_numeric_id"],
        row["slot_date"],
        row["start_time"],
        row["end_time"],
        row["mode"],
        row["slot_type"],
    )


async def insert_slots_bulk(rows: List[Dict[str, Any]]):
    if not rows:
        return
    sql = """
        INSERT INTO doctor_slots (
            slot_code, doctor_ref, doctor_numeric_id, slot_date,
            start_time, end_time, mode, slot_type, status
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, 'available')
        ON CONFLICT DO NOTHING
    """
    args = [
        (
            row["slot_code"],
            row["doctor_ref"],
            row["doctor_numeric_id"],
            row["slot_date"],
            row["start_time"],
            row["end_time"],
            row["mode"],
            row["slot_type"],
        )
        for row in rows
    ]
    await db.executemany(sql, args)


async def get_offline_block_summary(
    doctor_ref: str,
    from_date: date,
    to_date: date,
) -> List[Dict[str, Any]]:
    """OPD block totals + remaining capacity (includes full blocks with 0 available)."""
    return await db.query(
        """
        SELECT
          slot_date,
          slot_type,
          COUNT(*) FILTER (WHERE status = 'available')::int AS available_count,
          COUNT(*)::int AS total_count,
          MIN(id) FILTER (WHERE status = 'available') AS representative_slot_id
        FROM doctor_slots
        WHERE doctor_ref = $1
          AND mode = 'offline'
          AND slot_date >= $2
          AND slot_date <= $3
          AND slot_type IN ('morning_opd', 'evening_opd')
        GROUP BY slot_date, slot_type
        ORDER BY slot_date,
          CASE slot_type
            WHEN 'morning_opd' THEN 0
            WHEN 'evening_opd' THEN 1
            ELSE 2
          END
        """,
        doctor_ref,
        from_date,
        to_date,
    )


async def get_slots_for_doctor(
    doctor_ref: str,
    mode: str,
    from_date: date,
    to_date: date,
) -> List[Dict[str, Any]]:
    return await db.query(
        """
        SELECT * FROM doctor_slots
        WHERE doctor_ref = $1
          AND mode = $2
          AND slot_date >= $3
          AND slot_date <= $4
          AND status = 'available'
        ORDER BY slot_date ASC, start_time ASC
        """,
        doctor_ref,
        mode,
        from_date,
        to_date,
    )


async def get_slot_by_id(slot_id: int) -> Optional[Dict[str, Any]]:
    return await db.fetch_row("SELECT * FROM doctor_slots WHERE id = $1", int(slot_id))


async def get_slot_by_id_for_update(slot_id: int) -> Optional[Dict[str, Any]]:
    return await db.fetch_row(
        "SELECT * FROM doctor_slots WHERE id = $1 FOR UPDATE",
        int(slot_id),
    )


async def find_first_available_in_block(
    doctor_ref: str,
    slot_date: date,
    slot_type: str,
) -> Optional[Dict[str, Any]]:
    return await db.fetch_row(
        """
        SELECT * FROM doctor_slots
        WHERE doctor_ref = $1
          AND slot_date = $2
          AND slot_type = $3
          AND mode = 'offline'
          AND status = 'available'
        ORDER BY start_time ASC
        LIMIT 1
        FOR UPDATE SKIP LOCKED
        """,
        doctor_ref,
        slot_date,
        slot_type,
    )


async def count_available_in_block(
    doctor_ref: str,
    slot_date: date,
    slot_type: str,
) -> int:
    row = await db.fetch_row(
        """
        SELECT COUNT(*)::int AS cnt FROM doctor_slots
        WHERE doctor_ref = $1
          AND slot_date = $2
          AND slot_type = $3
          AND mode = 'offline'
          AND status = 'available'
        """,
        doctor_ref,
        slot_date,
        slot_type,
    )
    return int(row["cnt"]) if row else 0


async def mark_slot_booked(slot_id: int):
    return await db.fetch_row(
        """
        UPDATE doctor_slots
        SET status = 'booked', updated_at = NOW()
        WHERE id = $1 AND status = 'available'
        RETURNING *
        """,
        int(slot_id),
    )


async def release_slot(slot_id: int):
    return await db.fetch_row(
        """
        UPDATE doctor_slots
        SET status = 'available', updated_at = NOW()
        WHERE id = $1 AND status IN ('booked', 'cancelled')
        RETURNING *
        """,
        int(slot_id),
    )


async def complete_slot(slot_id: int):
    return await db.fetch_row(
        """
        UPDATE doctor_slots
        SET status = 'completed', updated_at = NOW()
        WHERE id = $1
        RETURNING *
        """,
        int(slot_id),
    )
