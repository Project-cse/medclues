"""
Patient Telegram bot commands for MediChain+.

Commands:
  /start, /help
  /login <email> <password>
  /logout
  /my_appointments  (/appointments)
  /upcoming
  /profile
  /records
"""

import json
from datetime import datetime
from typing import Any, Dict, List, Optional, Tuple

from app.controllers.user_controller import verify_password
from app.models import appointment_model, health_record_model, telegram_model, user_model
from app.services.telegram_api import TelegramApi

BOT_NAME = "Medi-Chain Bot"


def _help_text() -> str:
    return (
        f"🏥 {BOT_NAME} — Patient commands\n\n"
        "Link account (recommended):\n"
        "MediChain+ app → Settings → Connect Telegram\n"
        "(works with Google sign-in — no password here)\n\n"
        "Account:\n"
        "/logout — Unlink this Telegram chat\n"
        "/profile — Your profile\n\n"
        "Appointments:\n"
        "/my_appointments — All appointments\n"
        "/upcoming — Upcoming visits only\n\n"
        "Health:\n"
        "/records — Your uploaded health records\n\n"
        "/help — Show this message"
    )


def _welcome_unlinked() -> str:
    return (
        f"Welcome to {BOT_NAME}! 🏥\n\n"
        "Your account is not linked yet.\n\n"
        "✅ Easy link (Google or email login in app):\n"
        "1. Open MediChain+ on your phone\n"
        "2. Go to Settings → Connect Telegram\n"
        "3. Tap Connect — Telegram opens automatically\n\n"
        "No password needed in this chat."
    )


def _welcome_linked(name: str, role: str) -> str:
    return (
        f"Welcome back, {name}! 👋\n"
        f"Linked as {role} on MediChain+.\n\n"
        "Type /help to see available commands."
    )


async def handle_update(api: TelegramApi, update: Dict[str, Any]) -> None:
    message = update.get("message") or update.get("edited_message")
    if not message:
        return
    chat = message.get("chat") or {}
    chat_id = chat.get("id")
    if chat_id is None:
        return
    text = (message.get("text") or "").strip()
    if not text:
        return
    username = (message.get("from") or {}).get("username")
    reply = await build_reply(int(chat_id), text, username)
    if reply:
        await api.send_message(int(chat_id), reply)


async def build_reply(
    chat_id: int,
    text: str,
    telegram_username: Optional[str] = None,
) -> Optional[str]:
    lower = text.lower()
    if lower.startswith("/start"):
        return await _cmd_start(chat_id, text, telegram_username)
    if lower.startswith("/help"):
        return _help_text()
    if lower.startswith("/login"):
        return await _cmd_login(chat_id, text, telegram_username)
    if lower.startswith("/logout"):
        return await _cmd_logout(chat_id)
    if lower.startswith("/my_appointments") or lower.startswith("/appointments"):
        return await _cmd_appointments(chat_id, upcoming_only=False)
    if lower.startswith("/upcoming"):
        return await _cmd_appointments(chat_id, upcoming_only=True)
    if lower.startswith("/profile"):
        return await _cmd_profile(chat_id)
    if lower.startswith("/records"):
        return await _cmd_records(chat_id)
    return (
        "Unknown command. Type /help for available commands.\n"
        "Example: /my_appointments"
    )


async def _cmd_start(
    chat_id: int,
    text: str,
    telegram_username: Optional[str] = None,
) -> str:
    parts = text.split(maxsplit=1)
    if len(parts) > 1 and parts[1].startswith("link_"):
        from app.controllers.telegram_link_controller import link_chat_with_code

        code = parts[1][5:].strip()
        ok, msg = await link_chat_with_code(chat_id, code, telegram_username)
        return msg

    link = await telegram_model.get_link_by_chat_id(chat_id)
    if link:
        return _welcome_linked(link["name"], link.get("role") or "patient")
    return _welcome_unlinked()


async def _cmd_login(
    chat_id: int,
    text: str,
    telegram_username: Optional[str],
) -> str:
    parts = text.split(maxsplit=2)
    if len(parts) < 3:
        return (
            "Usage: /login <your_email> <your_password>\n"
            "Example: /login patient@email.com MyPassword123"
        )
    email = parts[1].strip().lower()
    password = parts[2]

    user = await user_model.get_user_by_email(email)
    if not user:
        return "❌ User not found. Check your email or register on MediChain+ first."
    if not verify_password(password, user.get("password") or ""):
        return "❌ Invalid password."

    role = (user.get("role") or "patient").lower()
    if role != "patient":
        return f"❌ Only patient accounts can use this bot. Your role is: {role}."

    await telegram_model.link_chat_to_user(chat_id, int(user["id"]), telegram_username)
    return f"✅ Successfully linked to account: {user['name']} ({role})!"


async def _cmd_logout(chat_id: int) -> str:
    if await telegram_model.unlink_chat(chat_id):
        return "✅ Account unlinked. Use /login to connect again."
    return "You are not linked. Use /login <email> <password>"


async def _require_link(chat_id: int) -> Optional[Dict[str, Any]]:
    link = await telegram_model.get_link_by_chat_id(chat_id)
    if not link:
        return None
    return link


async def _cmd_profile(chat_id: int) -> str:
    link = await _require_link(chat_id)
    if not link:
        return _welcome_unlinked()
    return (
        f"👤 Profile\n"
        f"Name: {link['name']}\n"
        f"Email: {link['email']}\n"
        f"Phone: {link.get('phone') or '—'}\n"
        f"Role: {link.get('role') or 'patient'}"
    )


def _parse_doc_name(apt: Dict[str, Any]) -> str:
    doc = apt.get("doctor_data")
    if isinstance(doc, str):
        try:
            doc = json.loads(doc)
        except json.JSONDecodeError:
            return "Doctor"
    if isinstance(doc, dict):
        return doc.get("name") or "Doctor"
    return "Doctor"


def _apt_status_line(apt: Dict[str, Any]) -> str:
    if apt.get("cancelled"):
        return "Cancelled"
    if apt.get("is_completed"):
        return "Completed"
    return apt.get("status") or "Scheduled"


def _is_upcoming(apt: Dict[str, Any]) -> bool:
    if apt.get("cancelled") or apt.get("is_completed"):
        return False
    slot_date = apt.get("slot_date") or ""
    try:
        d = datetime.strptime(str(slot_date), "%d_%m_%Y").date()
        return d >= datetime.utcnow().date()
    except ValueError:
        return True


async def _cmd_appointments(chat_id: int, *, upcoming_only: bool) -> str:
    link = await _require_link(chat_id)
    if not link:
        return _welcome_unlinked()

    user_id = int(link["user_id"])
    rows = await appointment_model.get_appointments_by_user_id(user_id)
    if upcoming_only:
        rows = [a for a in rows if _is_upcoming(a)]

    if not rows:
        label = "upcoming " if upcoming_only else ""
        return f"No {label}appointments found."

    lines: List[str] = [
        f"📅 {'Upcoming' if upcoming_only else 'My'} appointments ({len(rows[:10])} shown)\n"
    ]
    for apt in rows[:10]:
        doc_name = _parse_doc_name(apt)
        status = _apt_status_line(apt)
        slot_date = (apt.get("slot_date") or "").replace("_", "/")
        slot_time = apt.get("slot_time") or ""
        token = apt.get("token_number")
        token_s = f" | Token #{token}" if token else ""
        lines.append(
            f"\n#{apt['id']} — {doc_name}\n"
            f"📆 {slot_date} {slot_time}{token_s}\n"
            f"Status: {status} | Rs.{apt.get('amount', 0)}"
        )
    if len(rows) > 10:
        lines.append(f"\n…and {len(rows) - 10} more. Open MediChain+ app for full list.")
    return "".join(lines)


async def _cmd_records(chat_id: int) -> str:
    link = await _require_link(chat_id)
    if not link:
        return _welcome_unlinked()

    records = await health_record_model.get_health_records_by_user_id(int(link["user_id"]))
    if not records:
        return "📁 No health records uploaded yet. Add records in the MediChain+ app."

    lines = [f"📁 Health records ({min(len(records), 10)} shown)\n"]
    for rec in records[:10]:
        title = rec.get("title") or rec.get("record_type") or "Record"
        created = rec.get("created_at")
        if hasattr(created, "strftime"):
            created = created.strftime("%Y-%m-%d")
        lines.append(f"\n• {title} ({created})")
    if len(records) > 10:
        lines.append(f"\n…and {len(records) - 10} more.")
    return "".join(lines)
