import asyncio
import os
from pathlib import Path
from typing import Any, Dict, List, Optional

from app.models import fcm_token_model

_initialized = False


def _credentials_path() -> Optional[Path]:
    raw = os.getenv("FIREBASE_CREDENTIALS_PATH", "").strip()
    if not raw:
        return None
    path = Path(raw)
    if not path.is_absolute():
        base = Path(__file__).resolve().parent.parent.parent
        path = base / raw
    return path if path.is_file() else None


def _ensure_firebase():
    global _initialized
    if _initialized:
        return True
    cred_path = _credentials_path()
    if not cred_path:
        print("[WARNING] FIREBASE_CREDENTIALS_PATH not set or file missing — push disabled")
        return False
    try:
        import firebase_admin
        from firebase_admin import credentials

        if not firebase_admin._apps:
            cred = credentials.Certificate(str(cred_path))
            firebase_admin.initialize_app(cred)
        _initialized = True
        return True
    except Exception as e:
        print(f"[WARNING] Firebase Admin init failed: {e}")
        return False


def _send_multicast_sync(tokens: List[str], title: str, body: str, data: Dict[str, Any]):
    from firebase_admin import messaging

    message = messaging.MulticastMessage(
        notification=messaging.Notification(title=title, body=body),
        data={k: str(v) for k, v in data.items()},
        tokens=tokens,
        android=messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                channel_id="medclues_appointments",
                sound="default",
            ),
        ),
    )
    return messaging.send_each_for_multicast(message)


async def send_to_user(
    user_id: int,
    title: str,
    body: str,
    data: Optional[Dict[str, Any]] = None,
) -> bool:
    if not _ensure_firebase():
        return False
    tokens = await fcm_token_model.get_tokens_for_user(int(user_id))
    if not tokens:
        return False
    payload = data or {}

    def _run():
        response = _send_multicast_sync(tokens, title, body, payload)
        stale: List[str] = []
        for idx, resp in enumerate(response.responses):
            if not resp.success and resp.exception:
                err = str(resp.exception)
                if "not-found" in err.lower() or "registration-token-not-registered" in err.lower():
                    stale.append(tokens[idx])
        return stale

    try:
        stale = await asyncio.to_thread(_run)
        if stale:
            await fcm_token_model.delete_tokens(int(user_id), stale)
        return True
    except Exception as e:
        print(f"[WARNING] FCM send failed for user {user_id}: {e}")
        return False


async def notify_appointment_booked(
    user_id: int,
    doctor_name: str,
    slot_date: str,
    slot_time: str,
    appointment_id: int,
):
    await send_to_user(
        user_id,
        title="Appointment confirmed",
        body=f"With Dr. {doctor_name} on {slot_date} at {slot_time}",
        data={
            "type": "appointment",
            "appointmentId": str(appointment_id),
        },
    )


async def notify_appointment_cancelled(user_id: int, doctor_name: str, appointment_id: int):
    await send_to_user(
        user_id,
        title="Appointment cancelled",
        body=f"Your appointment with Dr. {doctor_name} was cancelled.",
        data={
            "type": "appointment_cancelled",
            "appointmentId": str(appointment_id),
        },
    )
