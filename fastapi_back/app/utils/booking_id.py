"""Unique short booking IDs for appointment receipts (BK + 6 alphanumeric)."""
import random
import re
import string

BOOKING_ID_PATTERN = re.compile(r"^BK[A-Z0-9]{6}$", re.IGNORECASE)
_CHARS = string.ascii_uppercase + string.digits


def is_valid_booking_id(value: str) -> bool:
    return bool(BOOKING_ID_PATTERN.match((value or "").strip()))


def normalize_booking_id(value: str) -> str:
    return (value or "").strip().upper()
