"""Long-polling loop for Telegram bot (runs with FastAPI lifespan)."""

import asyncio
from typing import Optional

from app.config.config import settings
from app.controllers.telegram_bot_controller import handle_update
from app.models import telegram_model
from app.services.telegram_api import get_telegram_api, register_bot_commands

_polling_task: Optional[asyncio.Task] = None
_stop_event: Optional[asyncio.Event] = None


async def start_telegram_bot() -> None:
    global _polling_task, _stop_event

    if not settings.TELEGRAM_BOT_ENABLED:
        print("[Telegram] Bot disabled (TELEGRAM_BOT_ENABLED=false)")
        return

    api = get_telegram_api()
    if not api:
        print("[Telegram] TELEGRAM_BOT_TOKEN not set — bot not started")
        return

    await telegram_model.ensure_telegram_schema()

    try:
        me = await api.get_me()
        username = me.get("result", {}).get("username", "?")
        print(f"[Telegram] Bot started: @{username}")
        await register_bot_commands()
    except Exception as e:
        print(f"[Telegram] Failed to verify bot token: {e}")
        return

    _stop_event = asyncio.Event()

    async def _poll() -> None:
        offset: Optional[int] = None
        while _stop_event and not _stop_event.is_set():
            try:
                updates = await api.get_updates(offset=offset, timeout=25)
                for upd in updates:
                    upd_id = upd.get("update_id")
                    if upd_id is not None:
                        offset = int(upd_id) + 1
                    try:
                        await handle_update(api, upd)
                    except Exception as handler_err:
                        print(f"[Telegram] Handler error: {handler_err}")
            except asyncio.CancelledError:
                break
            except Exception as poll_err:
                print(f"[Telegram] Poll error: {poll_err}")
                await asyncio.sleep(3)

    _polling_task = asyncio.create_task(_poll(), name="telegram-polling")


async def stop_telegram_bot() -> None:
    global _polling_task, _stop_event
    if _stop_event:
        _stop_event.set()
    if _polling_task:
        _polling_task.cancel()
        try:
            await _polling_task
        except asyncio.CancelledError:
            pass
        _polling_task = None
    _stop_event = None
    print("[Telegram] Bot stopped")
