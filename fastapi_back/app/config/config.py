import os
import sys
from dotenv import load_dotenv
from pathlib import Path

# Load .env from the current backend directory (fastapi_back)
env_path = Path(__file__).resolve().parent.parent.parent / '.env'
load_dotenv(dotenv_path=env_path)


def _env_bool(key: str, default: bool = False) -> bool:
    raw = os.getenv(key)
    if raw is None:
        return default
    return raw.strip().lower() in ("1", "true", "yes", "on")


def _env_int(key: str, default: int) -> int:
    raw = os.getenv(key)
    if raw is None or raw.strip() == "":
        return default
    return int(raw)


def _env_float(key: str, default: float) -> float:
    raw = os.getenv(key)
    if raw is None or raw.strip() == "":
        return default
    return float(raw)


class Config:
    # Core
    DEBUG = _env_bool("DEBUG", True)
    PORT = _env_int("PORT", 5000)
    CURRENCY = os.getenv("CURRENCY", "INR").replace('"', '').replace("'", "").strip()

    # JWT — no insecure defaults in production (validated on startup)
    JWT_SECRET = os.getenv("JWT_SECRET") or os.getenv("ACCESS_TOKEN_SECRET")
    REFRESH_TOKEN_SECRET = os.getenv("REFRESH_TOKEN_SECRET") or JWT_SECRET
    ACCESS_TOKEN_EXPIRE_MINUTES = _env_int("ACCESS_TOKEN_EXPIRE_MINUTES", 15)
    REFRESH_TOKEN_EXPIRE_DAYS = _env_int("REFRESH_TOKEN_EXPIRE_DAYS", 7)

    # Admin Credentials
    ADMIN_EMAIL = os.getenv("ADMIN_EMAIL")
    ADMIN_PASSWORD = os.getenv("ADMIN_PASSWORD")

    # PostgreSQL — prefer DATABASE_URL; legacy PG_* only if URL unset
    DATABASE_URL = os.getenv("DATABASE_URL")
    PG_USER = os.getenv("PG_USER", "postgres")
    PG_HOST = os.getenv("PG_HOST", "localhost")
    PG_DATABASE = os.getenv("PG_DATABASE", "healthsystem_pg")
    PG_PASSWORD = os.getenv("PG_PASSWORD")
    PG_PORT = _env_int("PG_PORT", 5432)
    PG_SSL = _env_bool("PG_SSL", False)

    # MongoDB
    MONGODB_URI = os.getenv("MONGODB_URI")

    # Cloudinary
    CLOUDINARY_NAME = os.getenv("CLOUDINARY_NAME")
    CLOUDINARY_API_KEY = os.getenv("CLOUDINARY_API_KEY")
    CLOUDINARY_API_SECRET = os.getenv("CLOUDINARY_API_SECRET") or os.getenv("CLOUDINARY_SECRET_KEY")

    # Payments
    RAZORPAY_KEY_ID = os.getenv("RAZORPAY_KEY_ID")
    RAZORPAY_KEY_SECRET = os.getenv("RAZORPAY_KEY_SECRET")
    RAZORPAY_WEBHOOK_SECRET = os.getenv("RAZORPAY_WEBHOOK_SECRET")
    STRIPE_SECRET_KEY = os.getenv("STRIPE_SECRET_KEY")
    PAYU_MERCHANT_KEY = os.getenv("PAYU_MERCHANT_KEY")
    PAYU_MERCHANT_SALT = os.getenv("PAYU_MERCHANT_SALT")
    PAYU_BASE_URL = os.getenv("PAYU_BASE_URL")

    # AI
    GEMINI_API_KEY = os.getenv("GEMINI_API_KEY")
    MISTRAL_API_KEY = os.getenv("MISTRAL_API_KEY")
    OPENAI_API_KEY = os.getenv("OPENAI_API_KEY")

    # MediChain Bot Integration
    MEDICHAIN_BOT_BASE_URL = os.getenv("MEDICHAIN_BOT_BASE_URL")
    MEDICHAIN_BOT_API_KEY = os.getenv("MEDICHAIN_BOT_API_KEY")
    MEDICHAIN_BOT_PASSWORD = os.getenv("MEDICHAIN_BOT_PASSWORD")

    TELEGRAM_BOT_TOKEN = os.getenv("TELEGRAM_BOT_TOKEN")
    TELEGRAM_BOT_ENABLED = _env_bool("TELEGRAM_BOT_ENABLED", True)

    # Agora
    AGORA_APP_ID = os.getenv("AGORA_APP_ID")
    AGORA_APP_CERTIFICATE = os.getenv("AGORA_APP_CERTIFICATE")

    # Email (Brevo/SMTP)
    BREVO_API_KEY = os.getenv("BREVO_API_KEY") or os.getenv("BERVO_API_KEY")
    BREVO_SENDER_EMAIL = os.getenv("BREVO_SENDER_EMAIL") or os.getenv("BERVO_SENDER_EMAIL")
    BREVO_APP_NAME = os.getenv("BREVO_APP_NAME") or os.getenv("BERVO_APP_NAME")
    EMAIL_LOGO_URL = os.getenv("EMAIL_LOGO_URL") or (
        "https://res.cloudinary.com/dinbiaq7q/image/upload/v1781150365/medclues/branding/medclues_logo_email.png"
    )
    MEDCLUES_APP_DEEP_LINK_SCHEME = os.getenv("MEDCLUES_APP_DEEP_LINK_SCHEME", "mediclues")
    EMAIL_USER = os.getenv("EMAIL_USER")
    EMAIL_APP_PASSWORD = os.getenv("EMAIL_APP_PASSWORD")

    # URLs
    FRONTEND_URL = os.getenv("FRONTEND_URL", "http://localhost:5173")
    BACKEND_URL = os.getenv("BACKEND_URL", "http://localhost:5000")

    # CORS — comma-separated allowlist for production
    CORS_ALLOWED_ORIGINS = os.getenv("CORS_ALLOWED_ORIGINS", "")

    # OAuth / social login
    GOOGLE_CLIENT_ID = os.getenv("GOOGLE_CLIENT_ID")
    GOOGLE_CLIENT_IDS = os.getenv("GOOGLE_CLIENT_IDS")
    # Legacy email-only social login — default True until all clients send idToken
    SOCIAL_LOGIN_ALLOW_LEGACY = _env_bool("SOCIAL_LOGIN_ALLOW_LEGACY", default=True)

    # Fees
    PLATFORM_FEE_PERCENTAGE = _env_float("PLATFORM_FEE_PERCENTAGE", 5)
    GST_PERCENTAGE = _env_float("GST_PERCENTAGE", 18)

    # Firebase Cloud Messaging (push notifications)
    FIREBASE_CREDENTIALS_PATH = os.getenv("FIREBASE_CREDENTIALS_PATH", "")
    FIREBASE_SENDER_ID = os.getenv("FIREBASE_SENDER_ID", "")


settings = Config()

_INSECURE_JWT_VALUES = frozenset({"greatstack", "secret", "changeme", "jwt_secret"})


def validate_settings() -> None:
    """Fail fast when required production secrets are missing or weak."""
    errors: list[str] = []
    warnings: list[str] = []

    if not settings.DEBUG:
        if not settings.DATABASE_URL:
            errors.append("DATABASE_URL is required when DEBUG=false")

        secret = (settings.JWT_SECRET or "").strip()
        if not secret:
            errors.append("JWT_SECRET (or ACCESS_TOKEN_SECRET) is required when DEBUG=false")
        elif len(secret) < 32:
            errors.append("JWT_SECRET must be at least 32 characters in production")
        elif secret.lower() in _INSECURE_JWT_VALUES:
            errors.append("JWT_SECRET is a known insecure default — set a strong random value")

        if not settings.CORS_ALLOWED_ORIGINS.strip():
            warnings.append(
                "CORS_ALLOWED_ORIGINS is empty — only built-in localhost origins will be allowed"
            )

        if settings.SOCIAL_LOGIN_ALLOW_LEGACY:
            warnings.append(
                "SOCIAL_LOGIN_ALLOW_LEGACY=true — social login accepts unverified email. "
                "Send idToken from clients and set SOCIAL_LOGIN_ALLOW_LEGACY=false when ready."
            )
    else:
        if not settings.JWT_SECRET:
            warnings.append("JWT_SECRET not set — using insecure dev-only fallback")
            Config.JWT_SECRET = "dev-only-insecure-jwt-secret-change-me"
            if not os.getenv("REFRESH_TOKEN_SECRET"):
                Config.REFRESH_TOKEN_SECRET = Config.JWT_SECRET

    for w in warnings:
        print(f"[CONFIG WARNING] {w}", file=sys.stderr)

    if errors:
        for e in errors:
            print(f"[CONFIG ERROR] {e}", file=sys.stderr)
        raise SystemExit(1)


def cors_allowed_origins() -> list[str]:
    """Production CORS allowlist: env + sensible localhost defaults."""
    defaults = [
        "http://localhost:5173",
        "http://127.0.0.1:5173",
        "http://localhost:5174",
        "http://127.0.0.1:5174",
        "http://localhost:5175",
        "http://127.0.0.1:5175",
        "http://localhost:5176",
        "http://127.0.0.1:5176",
        "http://localhost:5177",
        "http://127.0.0.1:5177",
        "http://localhost:5178",
        "http://127.0.0.1:5178",
        "http://localhost:5179",
        "http://127.0.0.1:5179",
        "http://localhost:5180",
        "http://127.0.0.1:5180",
    ]
    extra = [
        o.strip()
        for o in (settings.CORS_ALLOWED_ORIGINS or "").split(",")
        if o.strip()
    ]
    if settings.FRONTEND_URL and settings.FRONTEND_URL not in extra:
        extra.append(settings.FRONTEND_URL.rstrip("/"))
    if settings.BACKEND_URL and settings.BACKEND_URL not in extra:
        extra.append(settings.BACKEND_URL.rstrip("/"))
    merged = list(dict.fromkeys(extra + defaults))
    return merged
