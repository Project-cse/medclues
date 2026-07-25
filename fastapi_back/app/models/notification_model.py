from typing import Any, Dict, List, Optional

from app.config.db import db


async def ensure_notifications_table():
    await db.execute(
        """
        CREATE TABLE IF NOT EXISTS notifications (
            id SERIAL PRIMARY KEY,
            user_id INTEGER NOT NULL,
            title TEXT NOT NULL,
            body TEXT,
            type VARCHAR(48) NOT NULL DEFAULT 'system',
            appointment_id INTEGER,
            is_read BOOLEAN NOT NULL DEFAULT FALSE,
            created_at TIMESTAMPTZ NOT NULL DEFAULT NOW()
        )
        """
    )
    await db.execute(
        """
        CREATE INDEX IF NOT EXISTS idx_notifications_user_created
            ON notifications (user_id, created_at DESC)
        """
    )


async def create(
    user_id: int,
    title: str,
    body: str = "",
    type: str = "system",
    appointment_id: Optional[int] = None,
) -> Optional[Dict[str, Any]]:
    row = await db.fetch_row(
        """
        INSERT INTO notifications (user_id, title, body, type, appointment_id)
        VALUES ($1, $2, $3, $4, $5)
        RETURNING *
        """,
        int(user_id),
        title,
        body or "",
        (type or "system")[:48],
        int(appointment_id) if appointment_id is not None else None,
    )
    return dict(row) if row else None


async def list_for_user(user_id: int, limit: int = 50, offset: int = 0) -> List[Dict[str, Any]]:
    rows = await db.query(
        """
        SELECT id, user_id, title, body, type, appointment_id, is_read, created_at
        FROM notifications
        WHERE user_id = $1
        ORDER BY created_at DESC
        LIMIT $2 OFFSET $3
        """,
        int(user_id),
        int(limit),
        int(offset),
    )
    return [dict(r) for r in rows]


async def unread_count(user_id: int) -> int:
    row = await db.fetch_row(
        "SELECT COUNT(*) AS c FROM notifications WHERE user_id = $1 AND is_read = FALSE",
        int(user_id),
    )
    return int(row["c"]) if row else 0


async def mark_read(user_id: int, notification_id: int) -> None:
    await db.execute(
        "UPDATE notifications SET is_read = TRUE WHERE id = $1 AND user_id = $2",
        int(notification_id),
        int(user_id),
    )


async def mark_all_read(user_id: int) -> None:
    await db.execute(
        "UPDATE notifications SET is_read = TRUE WHERE user_id = $1 AND is_read = FALSE",
        int(user_id),
    )
