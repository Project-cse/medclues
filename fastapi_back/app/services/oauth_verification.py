"""Verify Google / Firebase ID tokens server-side."""
from typing import Any, Optional

from google.auth.transport import requests as google_requests
from google.oauth2 import id_token

from app.config.config import settings
from app.utils.app_logger import get_logger

log = get_logger(__name__)


class OAuthVerificationError(Exception):
    pass


def _audiences() -> list[str]:
    raw = settings.GOOGLE_CLIENT_IDS or settings.GOOGLE_CLIENT_ID or ""
    return [a.strip() for a in raw.split(",") if a.strip()]


def verify_google_id_token(raw_token: str) -> dict[str, Any]:
    """
    Verify signature, issuer, audience, and expiration.
    Tries each configured GOOGLE_CLIENT_ID / GOOGLE_CLIENT_IDS audience.
    """
    token = (raw_token or "").strip()
    if not token:
        raise OAuthVerificationError("Missing ID token")

    audiences = _audiences()
    if not audiences:
        raise OAuthVerificationError("Google OAuth client ID not configured on server")

    last_error: Optional[Exception] = None
    for audience in audiences:
        try:
            info = id_token.verify_oauth2_token(
                token,
                google_requests.Request(),
                audience=audience,
            )
            issuer = info.get("iss", "")
            if issuer not in (
                "accounts.google.com",
                "https://accounts.google.com",
                "securetoken.google.com",
            ) and not issuer.startswith("https://securetoken.google.com/"):
                raise OAuthVerificationError("Invalid token issuer")
            if not info.get("email"):
                raise OAuthVerificationError("Token missing email claim")
            if info.get("email_verified") is False:
                raise OAuthVerificationError("Email not verified by provider")
            return info
        except OAuthVerificationError:
            raise
        except Exception as e:
            last_error = e
            continue

    raise OAuthVerificationError("Invalid or expired ID token") from last_error


def extract_id_token_from_body(body: dict) -> Optional[str]:
    for key in ("idToken", "id_token", "token", "credential"):
        val = body.get(key)
        if isinstance(val, str) and val.strip():
            return val.strip()
    return None
