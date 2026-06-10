import asyncio
from datetime import date, datetime, time, timedelta
from typing import Any, Dict, List, Optional, Tuple
from zoneinfo import ZoneInfo

from app.config.db import db
from app.models import doctor_model, doctor_slot_model

IST = ZoneInfo("Asia/Kolkata")

MORNING_START = time(10, 0)
MORNING_END = time(13, 0)
EVENING_START = time(18, 0)
EVENING_END = time(21, 0)
VC_START = time(14, 0)
OFFLINE_SLOT_MINUTES = 9
VC_SLOT_MINUTES = 15
OFFLINE_SLOTS_PER_BLOCK = 20
VC_SLOTS_PER_DAY = 4
SCHEDULE_DAYS = 5


def _today_ist() -> date:
    return datetime.now(IST).date()


def normalize_doctor_ref(doc_id: Any) -> Tuple[str, int]:
    text = str(doc_id).strip()
    if text.startswith("emb_"):
        num = int(text.replace("emb_", ""))
        return text, num
    num = int(text)
    return text, num


def normalize_booking_mode(mode_or_visit: Optional[str]) -> str:
    """Map visitType/mode strings to doctor_slots mode (offline | online)."""
    m = (mode_or_visit or "").lower().strip()
    if m in ("online", "video"):
        return "online"
    if m in (
        "offline",
        "in-clinic",
        "in_clinic",
        "in-person",
        "in_person",
        "inperson",
        "in clinic",
        "in person",
    ):
        return "offline"
    return m or "offline"


def infer_slot_type_from_label(
    slot_time: Optional[str], slot_type: Optional[str] = None
) -> Optional[str]:
    if slot_type in ("morning_opd", "evening_opd", "video"):
        return slot_type
    t = (slot_time or "").lower()
    if not t:
        return None
    if "evening" in t or "6:00" in t or "18:" in t or "9:00 pm" in t:
        return "evening_opd"
    if "10:00" in t or "morning" in t or "1:00 pm" in t:
        return "morning_opd"
    return None


def legacy_slot_date(d: date) -> str:
    return f"{d.day}_{d.month}_{d.year}"


def legacy_slot_date_padded(d: date) -> str:
    return f"{d.day:02d}_{d.month:02d}_{d.year}"


def format_time_12h(t: time) -> str:
    dt = datetime.combine(date.today(), t)
    return dt.strftime("%I:%M %p").lstrip("0")


def format_range_12h(start: time, end: time) -> str:
    return f"{format_time_12h(start)} - {format_time_12h(end)}"


def _add_minutes(t: time, minutes: int) -> time:
    base = datetime.combine(date.today(), t) + timedelta(minutes=minutes)
    return base.time()


async def list_bookable_doctor_refs() -> List[Tuple[str, int]]:
    refs: List[Tuple[str, int]] = []
    rows = await db.query(
        "SELECT id FROM doctors WHERE COALESCE(available, true) = true ORDER BY id"
    )
    for row in rows:
        refs.append((str(row["id"]), int(row["id"])))
    try:
        emb_rows = await db.query(
            """
            SELECT id FROM hospital_tieup_doctors
            WHERE COALESCE(available, true) = true
            ORDER BY id
            """
        )
        for row in emb_rows:
            refs.append((f"emb_{row['id']}", int(row["id"])))
    except Exception as e:
        print(f"[WARNING] hospital_tieup_doctors slots skip: {e}")
    return refs


def _build_day_slot_rows(doctor_ref: str, doctor_numeric_id: int, day: date) -> List[Dict[str, Any]]:
    date_key = day.strftime("%Y%m%d")
    rows: List[Dict[str, Any]] = []

    cursor = MORNING_START
    for i in range(OFFLINE_SLOTS_PER_BLOCK):
        end = _add_minutes(cursor, OFFLINE_SLOT_MINUTES)
        rows.append(
            {
                "slot_code": f"DS-{date_key}-M{i+1:02d}-{doctor_ref}",
                "doctor_ref": doctor_ref,
                "doctor_numeric_id": doctor_numeric_id,
                "slot_date": day,
                "start_time": cursor,
                "end_time": end,
                "mode": "offline",
                "slot_type": "morning_opd",
            }
        )
        cursor = end

    cursor = VC_START
    for i in range(VC_SLOTS_PER_DAY):
        end = _add_minutes(cursor, VC_SLOT_MINUTES)
        rows.append(
            {
                "slot_code": f"DS-{date_key}-V{i+1:02d}-{doctor_ref}",
                "doctor_ref": doctor_ref,
                "doctor_numeric_id": doctor_numeric_id,
                "slot_date": day,
                "start_time": cursor,
                "end_time": end,
                "mode": "online",
                "slot_type": "video",
            }
        )
        cursor = end

    cursor = EVENING_START
    for i in range(OFFLINE_SLOTS_PER_BLOCK):
        end = _add_minutes(cursor, OFFLINE_SLOT_MINUTES)
        rows.append(
            {
                "slot_code": f"DS-{date_key}-E{i+1:02d}-{doctor_ref}",
                "doctor_ref": doctor_ref,
                "doctor_numeric_id": doctor_numeric_id,
                "slot_date": day,
                "start_time": cursor,
                "end_time": end,
                "mode": "offline",
                "slot_type": "evening_opd",
            }
        )
        cursor = end

    return rows


async def generate_day_slots(doctor_ref: str, doctor_numeric_id: int, day: date):
    if await doctor_slot_model.day_has_slots(doctor_ref, day):
        return
    await doctor_slot_model.insert_slots_bulk(
        _build_day_slot_rows(doctor_ref, doctor_numeric_id, day)
    )


async def ensure_all_doctors_scheduled(days: int = SCHEDULE_DAYS):
    await doctor_slot_model.ensure_doctor_slots_schema()
    start = _today_ist()
    refs = await list_bookable_doctor_refs()
    for doctor_ref, doctor_numeric_id in refs:
        await asyncio.gather(
            *[
                generate_day_slots(doctor_ref, doctor_numeric_id, start + timedelta(days=offset))
                for offset in range(days)
            ]
        )


async def get_public_slots(doctor_ref: str, mode: str) -> Dict[str, Any]:
    mode = (mode or "offline").lower()
    if mode not in ("offline", "online"):
        mode = "offline"

    start = _today_ist()
    end = start + timedelta(days=SCHEDULE_DAYS - 1)
    await ensure_doctor_slots_for_doctor(doctor_ref)

    if mode == "online":
        rows = await doctor_slot_model.get_slots_for_doctor(doctor_ref, mode, start, end)
        days_map: Dict[str, Dict[str, Any]] = {}
        for row in rows:
            d: date = row["slot_date"]
            key = d.isoformat()
            if key not in days_map:
                days_map[key] = {
                    "date": key,
                    "slotDate": legacy_slot_date(d),
                    "slotDatePadded": legacy_slot_date_padded(d),
                    "displayDate": d.strftime("%d %b %Y"),
                }
        for row in rows:
            d: date = row["slot_date"]
            key = d.isoformat()
            days_map[key].setdefault("slots", []).append(
                {
                    "slot_id": row["id"],
                    "slot_type": row["slot_type"],
                    "start_time": row["start_time"].strftime("%H:%M"),
                    "end_time": row["end_time"].strftime("%H:%M"),
                    "display": format_range_12h(row["start_time"], row["end_time"]),
                    "available": True,
                }
            )
        days_list = [days_map[k] for k in sorted(days_map.keys())]
        return {"success": True, "mode": mode, "days": days_list}

    # offline — grouped blocks (single aggregated query, no per-day round trips)
    days_map: Dict[str, Dict[str, Any]] = {}
    block_meta = {
        "morning_opd": {
            "label": "Morning OPD",
            "display": "10:00 AM - 1:00 PM",
            "total_count": OFFLINE_SLOTS_PER_BLOCK,
        },
        "evening_opd": {
            "label": "Evening OPD",
            "display": "6:00 PM - 9:00 PM",
            "total_count": OFFLINE_SLOTS_PER_BLOCK,
        },
    }
    for offset in range(SCHEDULE_DAYS):
        d = start + timedelta(days=offset)
        key = d.isoformat()
        days_map.setdefault(
            key,
            {
                "date": key,
                "slotDate": legacy_slot_date(d),
                "slotDatePadded": legacy_slot_date_padded(d),
                "displayDate": d.strftime("%d %b %Y"),
                "blocks": [],
            },
        )

    block_order = ("morning_opd", "evening_opd")
    summaries = await doctor_slot_model.get_offline_block_summary(doctor_ref, start, end)
    summary_by_day: Dict[str, Dict[str, Dict[str, Any]]] = {}
    for row in summaries:
        d: date = row["slot_date"]
        key = d.isoformat()
        slot_type = row["slot_type"]
        summary_by_day.setdefault(key, {})[slot_type] = row

    for key, day_entry in days_map.items():
        day_summaries = summary_by_day.get(key, {})
        blocks: List[Dict[str, Any]] = []
        for slot_type in block_order:
            meta = block_meta[slot_type]
            row = day_summaries.get(slot_type)
            avail = int(row["available_count"]) if row else 0
            total = int(row["total_count"]) if row else meta["total_count"]
            rep_id = row.get("representative_slot_id") if row else None
            blocks.append(
                {
                    "label": meta["label"],
                    "display": meta["display"],
                    "slot_type": slot_type,
                    "available_count": avail,
                    "total_count": total,
                    "bookable": avail > 0 and rep_id is not None,
                    "representative_slot_id": rep_id,
                    "slot_id": rep_id,
                }
            )
        day_entry["blocks"] = blocks

    days_list = [days_map[k] for k in sorted(days_map.keys())]
    return {"success": True, "mode": mode, "days": days_list}


async def ensure_doctor_slots_for_doctor(doctor_ref: str):
    doctor_ref, doctor_numeric_id = normalize_doctor_ref(doctor_ref)
    start = _today_ist()
    end = start + timedelta(days=SCHEDULE_DAYS - 1)
    if await doctor_slot_model.schedule_covers_range(
        doctor_ref, start, end, SCHEDULE_DAYS
    ):
        return
    await asyncio.gather(
        *[
            generate_day_slots(doctor_ref, doctor_numeric_id, start + timedelta(days=offset))
            for offset in range(SCHEDULE_DAYS)
        ]
    )


async def resolve_slot_for_booking(
    doctor_ref: str,
    slot_id: Optional[int],
    mode: str,
    slot_type: Optional[str] = None,
    slot_date_str: Optional[str] = None,
) -> Tuple[Optional[Dict[str, Any]], Optional[str]]:
    doctor_ref, _ = normalize_doctor_ref(doctor_ref)
    mode = normalize_booking_mode(mode)

    if slot_id:
        slot = await doctor_slot_model.get_slot_by_id_for_update(int(slot_id))
        if not slot:
            return None, "This slot is no longer available. Please choose another time."
        if slot["doctor_ref"] != doctor_ref:
            return None, "This slot does not belong to the selected doctor."
        if slot["mode"] != mode:
            return None, "This slot does not match the selected consultation type."
        if slot["status"] != "available":
            return None, "This time was just booked by another patient."
        return slot, None

    if mode == "offline" and slot_type and slot_date_str:
        d = _parse_legacy_date(slot_date_str)
        if not d:
            return None, "Invalid appointment date."
        slot = await doctor_slot_model.find_first_available_in_block(
            doctor_ref, d, slot_type
        )
        if not slot:
            label = "Morning OPD" if slot_type == "morning_opd" else "Evening OPD"
            return None, f"{label} is full for this date. Try another day."
        return slot, None

    return None, "Please select a time slot."


def _parse_legacy_date(slot_date_str: str) -> Optional[date]:
    try:
        parts = slot_date_str.replace("-", "_").split("_")
        if len(parts) != 3:
            return None
        day, month, year = int(parts[0]), int(parts[1]), int(parts[2])
        return date(year, month, day)
    except Exception:
        return None


def slot_time_label(slot: Dict[str, Any]) -> str:
    if slot["mode"] == "online":
        return format_range_12h(slot["start_time"], slot["end_time"])
    if slot["slot_type"] == "morning_opd":
        return "10:00 AM - 1:00 PM"
    if slot["slot_type"] == "evening_opd":
        return "6:00 PM - 9:00 PM"
    return format_range_12h(slot["start_time"], slot["end_time"])


def consultation_fee_for_mode(doc_data: dict, mode: str) -> float:
    mode_l = (mode or "").lower()
    if mode_l == "online":
        return float(doc_data.get("video_consultation_fee") or 450)
    return float(doc_data.get("fees") or 600)


async def release_slot_for_appointment(appointment: dict):
    slot_id = appointment.get("slot_id")
    if not slot_id:
        return
    await doctor_slot_model.release_slot(int(slot_id))


async def complete_slot_for_appointment(appointment: dict):
    slot_id = appointment.get("slot_id")
    if not slot_id:
        return
    await doctor_slot_model.complete_slot(int(slot_id))


def normalize_appointment_mode_for_db(mode: str) -> str:
    """Map API/slot modes to DB values (appointments_mode_check: In-person | Video)."""
    if str(mode or "").strip().lower() in ("online", "video"):
        return "Video"
    return "In-person"


def appointment_mode_from_slot(slot: Dict[str, Any]) -> str:
    return normalize_appointment_mode_for_db(slot.get("mode"))
