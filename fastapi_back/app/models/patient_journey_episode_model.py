"""Persisted My Care Journey episode snapshots (Past My Journey history)."""
from __future__ import annotations

import json
from typing import Any, Dict, List, Optional

from app.config.db import db


async def upsert_episode(
    *,
    patient_id: int,
    appointment_id: int,
    episode_label: Optional[str],
    journey_status: Optional[str],
    payload: Dict[str, Any],
) -> None:
    body = json.loads(json.dumps(payload, default=str))
    await db.execute(
        """
        INSERT INTO patient_journey_episodes (
            patient_id, appointment_id, episode_label, journey_status, payload, closed_at, updated_at
        ) VALUES ($1, $2, $3, $4, $5::jsonb, NOW(), NOW())
        ON CONFLICT (appointment_id) DO UPDATE SET
            patient_id = EXCLUDED.patient_id,
            episode_label = EXCLUDED.episode_label,
            journey_status = EXCLUDED.journey_status,
            payload = EXCLUDED.payload,
            closed_at = EXCLUDED.closed_at,
            updated_at = NOW()
        """,
        int(patient_id),
        int(appointment_id),
        episode_label,
        journey_status,
        json.dumps(body),
    )


async def list_for_patient(patient_id: int, *, limit: int = 50) -> List[Dict[str, Any]]:
    rows = await db.query(
        """
        SELECT id, patient_id, appointment_id, episode_label, journey_status, payload, closed_at, created_at
        FROM patient_journey_episodes
        WHERE patient_id = $1
        ORDER BY closed_at DESC
        LIMIT $2
        """,
        int(patient_id),
        int(limit),
    )
    out: List[Dict[str, Any]] = []
    for row in rows or []:
        r = dict(row)
        payload = r.get("payload")
        if isinstance(payload, str):
            try:
                payload = json.loads(payload)
            except json.JSONDecodeError:
                payload = {}
        r["payload"] = payload if isinstance(payload, dict) else {}
        for field in ("closed_at", "created_at"):
            val = r.get(field)
            if val and hasattr(val, "isoformat"):
                r[field] = val.isoformat()
        out.append(r)
    return out
