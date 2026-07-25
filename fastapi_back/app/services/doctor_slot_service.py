import asyncio
from datetime import date, datetime, time, timedelta
from typing import Any, Dict, List, Optional, Tuple
from zoneinfo import ZoneInfo

from app.config.db import db
from app.models import doctor_model, doctor_slot_model, doctor_schedule_model

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


def _parse_time_str(val: Optional[str], default_time: time) -> time:
    if not val:
        return default_time
    try:
        parts = val.split(":")
        h = int(parts[0])
        m = int(parts[1]) if len(parts) > 1 else 0
        return time(h, m)
    except Exception:
        return default_time


def _calculate_slot_count(start: time, end: time, slot_size_mins: int) -> int:
    dt_start = datetime.combine(date.today(), start)
    dt_end = datetime.combine(date.today(), end)
    if dt_end <= dt_start:
        dt_end += timedelta(days=1)
    total_mins = int((dt_end - dt_start).total_seconds() / 60)
    return max(1, total_mins // slot_size_mins)


def _now_ist_time() -> time:
    return datetime.now(IST).time()


# End-of-block times used to auto-close elapsed OPD blocks for the current day.
_BLOCK_END_TIME = {
    "morning_opd": MORNING_END,
    "evening_opd": EVENING_END,
}


def _block_has_passed(slot_type: str, slot_day: date) -> bool:
    """True when slot_day is today (IST) and the block's end time has already passed."""
    if slot_day != _today_ist():
        return False
    end_time = _BLOCK_END_TIME.get(slot_type)
    if end_time is None:
        return False
    return _now_ist_time() >= end_time


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


def _build_day_slot_rows(
    doctor_ref: str,
    doctor_numeric_id: int,
    day: date,
    t_morning_start: time,
    t_morning_end: time,
    t_afternoon_start: time,
    t_afternoon_end: time,
    morning_slots_count: int,
    afternoon_slots_count: int,
) -> List[Dict[str, Any]]:
    date_key = day.strftime("%Y%m%d")
    rows: List[Dict[str, Any]] = []

    cursor = t_morning_start
    for i in range(morning_slots_count):
        end = _add_minutes(cursor, OFFLINE_SLOT_MINUTES)
        if cursor >= t_morning_end:
            break
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

    cursor = t_afternoon_start
    for i in range(afternoon_slots_count):
        end = _add_minutes(cursor, OFFLINE_SLOT_MINUTES)
        if cursor >= t_afternoon_end:
            break
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


async def generate_day_slots(doctor_ref: str, doctor_numeric_id: int, day: date, force_regenerate: bool = False):
    has_slots = await doctor_slot_model.day_has_slots(doctor_ref, day)
    if not force_regenerate and has_slots:
        return

    # Fetch doctor timing parameters from DB
    op_start = "10:00"
    op_end = "13:00"
    op_start_afternoon = "18:00"
    op_end_afternoon = "21:00"
    morning_slots = 20
    afternoon_slots = 20

    try:
        if str(doctor_ref).startswith("emb_"):
            row = await db.fetch_row(
                "SELECT op_start, op_end, op_start_afternoon, op_end_afternoon, max_appointments_morning, max_appointments_afternoon FROM hospital_tieup_doctors WHERE id = $1",
                int(doctor_numeric_id),
            )
        else:
            row = await db.fetch_row(
                "SELECT op_start, op_end, op_start_afternoon, op_end_afternoon, max_appointments_morning, max_appointments_afternoon FROM doctors WHERE id = $1",
                int(doctor_numeric_id),
            )
        if row:
            if row.get("op_start"): op_start = row["op_start"]
            if row.get("op_end"): op_end = row["op_end"]
            if row.get("op_start_afternoon"): op_start_afternoon = row["op_start_afternoon"]
            if row.get("op_end_afternoon"): op_end_afternoon = row["op_end_afternoon"]
            if row.get("max_appointments_morning") is not None:
                morning_slots = int(row["max_appointments_morning"])
            if row.get("max_appointments_afternoon") is not None:
                afternoon_slots = int(row["max_appointments_afternoon"])
            # Cap generated slot count by hospital policy (booking capacity source of truth).
            try:
                from app.models import hospital_policy_model
                policy = await hospital_policy_model.get_policy_for_doctor(int(doctor_numeric_id))
                policy_cap = int(policy.get("opd_slot_capacity") or 0) if policy else 0
                if policy_cap > 0:
                    # Split policy cap roughly across morning/afternoon generation.
                    half = max(1, policy_cap // 2)
                    morning_slots = min(morning_slots, half)
                    afternoon_slots = min(afternoon_slots, policy_cap - half if policy_cap > half else half)
            except Exception:
                pass
    except Exception as e:
        print(f"[WARNING] generate_day_slots db fetch error: {e}")

    t_morning_start = _parse_time_str(op_start, time(10, 0))
    t_morning_end = _parse_time_str(op_end, time(13, 0))
    t_afternoon_start = _parse_time_str(op_start_afternoon, time(18, 0))
    t_afternoon_end = _parse_time_str(op_end_afternoon, time(21, 0))

    # Fetch booked/completed slots for this day to avoid overlaps
    booked_slots = []
    if has_slots:
        booked_slots = await db.query(
            "SELECT start_time, end_time FROM doctor_slots WHERE doctor_ref = $1 AND slot_date = $2 AND status != 'available'",
            doctor_ref,
            day
        )
        # Delete only available slots
        await db.execute(
            "DELETE FROM doctor_slots WHERE doctor_ref = $1 AND slot_date = $2 AND status = 'available'",
            doctor_ref,
            day
        )

    # Build potential new slots
    potential_rows = _build_day_slot_rows(
        doctor_ref,
        doctor_numeric_id,
        day,
        t_morning_start,
        t_morning_end,
        t_afternoon_start,
        t_afternoon_end,
        morning_slots,
        afternoon_slots,
    )

    # Filter out slots that overlap with booked slots
    final_rows = []
    for r in potential_rows:
        overlaps = False
        r_start = r["start_time"]
        r_end = r["end_time"]
        for b in booked_slots:
            b_start = b["start_time"]
            b_end = b["end_time"]
            if max(r_start, b_start) < min(r_end, b_end):
                overlaps = True
                break
        if not overlaps:
            final_rows.append(r)

    if final_rows:
        await doctor_slot_model.insert_slots_bulk(final_rows)


async def ensure_all_doctors_scheduled(days: int = SCHEDULE_DAYS):
    await doctor_slot_model.ensure_doctor_slots_schema()
    start = _today_ist()
    refs = await list_bookable_doctor_refs()
    for doctor_ref, doctor_numeric_id in refs:
        # Respect per-doctor booking_window_days if set
        window = await _get_doctor_booking_window(doctor_ref)
        effective_days = window if window else days
        await asyncio.gather(
            *[
                generate_day_slots(doctor_ref, doctor_numeric_id, start + timedelta(days=offset))
                for offset in range(effective_days)
            ]
        )


async def _get_doctor_booking_window(doctor_ref: str) -> Optional[int]:
    """Fetch booking_window_days from the doctor record. Returns None for embedded doctors."""
    if str(doctor_ref).startswith("emb_"):
        return None
    try:
        row = await db.fetch_row(
            "SELECT booking_window_days FROM doctors WHERE id = $1",
            int(doctor_ref),
        )
        if row and row.get("booking_window_days"):
            return int(row["booking_window_days"])
    except Exception:
        pass
    return None


async def _is_date_blocked_for_doctor(doctor_numeric_id: int, check_date: date) -> bool:
    """Return True if the date is blocked by hospital calendar or a doctor leave."""
    # Check hospital calendar (get hospital_id for doctor)
    try:
        row = await db.fetch_row(
            "SELECT hospital_id FROM doctors WHERE id = $1",
            int(doctor_numeric_id),
        )
        if row and row.get("hospital_id"):
            hospital_id = int(row["hospital_id"])
            if await doctor_schedule_model.is_date_hospital_holiday(hospital_id, check_date):
                return True
    except Exception:
        pass

    # Check doctor leave
    try:
        if await doctor_schedule_model.is_doctor_on_leave(doctor_numeric_id, check_date):
            return True
    except Exception:
        pass

    return False


async def get_public_slots(doctor_ref: str, mode: str) -> Dict[str, Any]:
    mode = (mode or "offline").lower()
    if mode not in ("offline", "online"):
        mode = "offline"

    start = _today_ist()
    end = start + timedelta(days=SCHEDULE_DAYS - 1)
    await ensure_doctor_slots_for_doctor(doctor_ref)

    days_map: Dict[str, Dict[str, Any]] = {}

    if mode == "online":
        rows = await doctor_slot_model.get_slots_for_doctor(doctor_ref, mode, start, end)
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
            start_passed = d == _today_ist() and row["start_time"] <= _now_ist_time()
            days_map[key].setdefault("slots", []).append(
                {
                    "slot_id": row["id"],
                    "slot_type": row["slot_type"],
                    "start_time": row["start_time"].strftime("%H:%M"),
                    "end_time": row["end_time"].strftime("%H:%M"),
                    "display": format_range_12h(row["start_time"], row["end_time"]),
                    "available": not start_passed,
                }
            )
        days_list = [days_map[k] for k in sorted(days_map.keys())]
        return {"success": True, "mode": mode, "days": days_list}

    # Fetch doctor timing parameters from DB
    op_start = "10:00"
    op_end = "13:00"
    op_start_afternoon = "18:00"
    op_end_afternoon = "21:00"
    morning_slots = 20
    afternoon_slots = 20

    try:
        doctor_ref, doctor_numeric_id = normalize_doctor_ref(doctor_ref)
        if str(doctor_ref).startswith("emb_"):
            row = await db.fetch_row(
                "SELECT op_start, op_end, op_start_afternoon, op_end_afternoon, max_appointments_morning, max_appointments_afternoon FROM hospital_tieup_doctors WHERE id = $1",
                int(doctor_numeric_id),
            )
        else:
            row = await db.fetch_row(
                "SELECT op_start, op_end, op_start_afternoon, op_end_afternoon, max_appointments_morning, max_appointments_afternoon FROM doctors WHERE id = $1",
                int(doctor_numeric_id),
            )
        if row:
            if row.get("op_start"): op_start = row["op_start"]
            if row.get("op_end"): op_end = row["op_end"]
            if row.get("op_start_afternoon"): op_start_afternoon = row["op_start_afternoon"]
            if row.get("op_end_afternoon"): op_end_afternoon = row["op_end_afternoon"]
            if row.get("max_appointments_morning") is not None:
                morning_slots = int(row["max_appointments_morning"])
            if row.get("max_appointments_afternoon") is not None:
                afternoon_slots = int(row["max_appointments_afternoon"])
            # Cap generated slot count by hospital policy (booking capacity source of truth).
            try:
                from app.models import hospital_policy_model
                policy = await hospital_policy_model.get_policy_for_doctor(int(doctor_numeric_id))
                policy_cap = int(policy.get("opd_slot_capacity") or 0) if policy else 0
                if policy_cap > 0:
                    # Split policy cap roughly across morning/afternoon generation.
                    half = max(1, policy_cap // 2)
                    morning_slots = min(morning_slots, half)
                    afternoon_slots = min(afternoon_slots, policy_cap - half if policy_cap > half else half)
            except Exception:
                pass
    except Exception as e:
        print(f"[WARNING] get_public_slots db fetch error: {e}")

    def format_timestr_12h(time_str: str) -> str:
        try:
            parts = time_str.split(":")
            h = int(parts[0])
            m = int(parts[1]) if len(parts) > 1 else 0
            t = time(h, m)
            return format_time_12h(t)
        except Exception:
            return time_str

    disp_morning = f"{format_timestr_12h(op_start)} - {format_timestr_12h(op_end)}"
    disp_afternoon = f"{format_timestr_12h(op_start_afternoon)} - {format_timestr_12h(op_end_afternoon)}"

    t_morning_start = _parse_time_str(op_start, time(10, 0))
    t_morning_end = _parse_time_str(op_end, time(13, 0))
    t_afternoon_start = _parse_time_str(op_start_afternoon, time(18, 0))
    t_afternoon_end = _parse_time_str(op_end_afternoon, time(21, 0))

    block_meta = {
        "morning_opd": {
            "label": "Morning OPD",
            "display": disp_morning,
            "total_count": morning_slots,
        },
        "evening_opd": {
            "label": "Evening OPD",
            "display": disp_afternoon,
            "total_count": afternoon_slots,
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
        try:
            day_date = date.fromisoformat(key)
        except ValueError:
            day_date = None
        blocks: List[Dict[str, Any]] = []
        for slot_type in block_order:
            meta = block_meta[slot_type]
            row = day_summaries.get(slot_type)
            avail = int(row["available_count"]) if row else 0
            total = int(row["total_count"]) if row else meta["total_count"]
            rep_id = row.get("representative_slot_id") if row else None
            passed = day_date is not None and _block_has_passed(slot_type, day_date)
            blocks.append(
                {
                    "label": meta["label"],
                    "display": meta["display"],
                    "slot_type": slot_type,
                    "available_count": avail,
                    "total_count": total,
                    "bookable": avail > 0 and rep_id is not None and not passed,
                    "representative_slot_id": rep_id,
                    "slot_id": rep_id,
                }
            )
        day_entry["blocks"] = blocks

    days_list = [days_map[k] for k in sorted(days_map.keys())]
    return {"success": True, "mode": mode, "days": days_list}


async def ensure_doctor_slots_for_doctor(doctor_ref: str):
    doctor_ref, doctor_numeric_id = normalize_doctor_ref(doctor_ref)
    # Use dynamic booking window if configured, else fall back to default SCHEDULE_DAYS
    window = await _get_doctor_booking_window(doctor_ref)
    effective_days = window if window else SCHEDULE_DAYS
    start = _today_ist()
    end = start + timedelta(days=effective_days - 1)
    if await doctor_slot_model.schedule_covers_range(
        doctor_ref, start, end, effective_days
    ):
        return
    tasks = []
    for offset in range(effective_days):
        target_date = start + timedelta(days=offset)
        # Skip blocked dates (hospital holidays / doctor leaves) for dynamic scheduling
        if not str(doctor_ref).startswith("emb_"):
            blocked = await _is_date_blocked_for_doctor(doctor_numeric_id, target_date)
            if blocked:
                # Drop only available slots on this date; preserve booked/completed
                await db.execute(
                    """
                    DELETE FROM doctor_slots
                    WHERE doctor_ref = $1 AND slot_date = $2 AND status = 'available'
                    """,
                    doctor_ref,
                    target_date,
                )
                continue
        tasks.append(generate_day_slots(doctor_ref, doctor_numeric_id, target_date))
    if tasks:
        await asyncio.gather(*tasks)


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
        # Peek first for validation messages; claim holds FOR UPDATE in one TX.
        peek = await doctor_slot_model.get_slot_by_id(int(slot_id))
        if not peek:
            return None, "This slot is no longer available. Please choose another time."
        if peek["doctor_ref"] != doctor_ref:
            return None, "This slot does not belong to the selected doctor."
        if peek["mode"] != mode:
            return None, "This slot does not match the selected consultation type."
        if peek["status"] != "available":
            return None, "This time was just booked by another patient."
        if _slot_time_has_passed(peek):
            return None, "This slot time has already passed. Please choose another time."
        # Soft Redis hold (optional) + PostgreSQL claim (authority)
        from app.services import slot_lock_service
        holder = f"book:{doctor_ref}:{slot_id}"
        if not await slot_lock_service.hold_slot(int(slot_id), holder):
            return None, "This time was just booked by another patient."
        slot = await doctor_slot_model.claim_slot_by_id(int(slot_id))
        if not slot:
            await slot_lock_service.release_hold(int(slot_id), holder)
            return None, "This time was just booked by another patient."
        await slot_lock_service.release_hold(int(slot_id), holder)
        return slot, None

    if mode == "offline" and slot_type and slot_date_str:
        d = _parse_legacy_date(slot_date_str)
        if not d:
            return None, "Invalid appointment date."
        if _block_has_passed(slot_type, d):
            return None, "This slot time has already passed. Please choose another time."
        slot = await doctor_slot_model.claim_first_available_in_block(
            doctor_ref, d, slot_type
        )
        if not slot:
            label = "Morning OPD" if slot_type == "morning_opd" else "Evening OPD"
            return None, f"{label} is full for this date. Try another day."
        return slot, None

    return None, "Please select a time slot."


def _slot_time_has_passed(slot: Dict[str, Any]) -> bool:
    """True when a resolved slot row is on today (IST) and its usable time has elapsed.

    Offline OPD closes at the block end; online video closes once the slot start passes.
    """
    slot_day = slot.get("slot_date")
    if not isinstance(slot_day, date) or slot_day != _today_ist():
        return False
    if slot.get("mode") == "offline":
        return _block_has_passed(slot.get("slot_type"), slot_day)
    start = slot.get("start_time")
    if isinstance(start, time):
        return start <= _now_ist_time()
    return False


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


async def regenerate_future_slots(doctor_ref: str):
    doctor_ref, doctor_numeric_id = normalize_doctor_ref(doctor_ref)
    window = await _get_doctor_booking_window(doctor_ref)
    effective_days = window if window else SCHEDULE_DAYS
    start = _today_ist()
    
    async def process_day(offset: int):
        target_date = start + timedelta(days=offset)
        if not str(doctor_ref).startswith("emb_"):
            blocked = await _is_date_blocked_for_doctor(doctor_numeric_id, target_date)
            if blocked:
                await db.execute(
                    "DELETE FROM doctor_slots WHERE doctor_ref = $1 AND slot_date = $2 AND status = 'available'",
                    doctor_ref,
                    target_date,
                )
                return
        await generate_day_slots(doctor_ref, doctor_numeric_id, target_date, force_regenerate=True)

    tasks = [process_day(offset) for offset in range(effective_days)]
    await asyncio.gather(*tasks)
