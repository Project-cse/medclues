# MediChain+ Telegram Bot (Patient)

Runs inside **FastAPI** when `TELEGRAM_BOT_TOKEN` is set in `fastapi_back/.env`.

## Start

```bash
cd fastapi_back
python main.py
```

Console should show: `[Telegram] Bot started: @your_bot_username`

## Link account (recommended — MediChain+ app)

1. Log in to the **MediChain+** app (Google or email).
2. **Settings → Connect Telegram** → tap **Connect Telegram**.
3. Telegram opens; tap **Start** — account links automatically (no password in chat).

Legacy (not recommended):

```
/login your@email.com your_password
```

## Patient commands

| Command | Description |
|---------|-------------|
| `/start` | Welcome + link status |
| `/help` | Command list |
| `/login <email> <password>` | Link Telegram to patient account |
| `/logout` | Unlink |
| `/my_appointments` | All appointments (alias: `/appointments`) |
| `/upcoming` | Upcoming visits only |
| `/profile` | Name, email, phone |
| `/records` | Health records list |

## Important: one bot process per token

Telegram allows **only one** `getUpdates` connection per bot token.

- If the bot also runs on another server (e.g. `MEDICHAIN_BOT_BASE_URL`), set in `.env`:

  ```
  TELEGRAM_BOT_ENABLED=false
  ```

  on the machine that should **not** poll (e.g. local `.env`).

  On **Render**, set `TELEGRAM_BOT_ENABLED=true` and `TELEGRAM_BOT_USERNAME=YourBotUsername`.

- For local development, stop the remote bot or disable it and run FastAPI locally with `TELEGRAM_BOT_ENABLED=true`.

## Database

Links are stored in `telegram_user_links` (created automatically on startup).
