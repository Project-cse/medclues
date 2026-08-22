"""Specialized coordination agents on top of existing order tables.

Investigation / Referral / Follow-up agents detect workflow gaps.
They never interpret lab results or replace the doctor.
"""
import asyncio
from datetime import datetime, timedelta, date
from typing import Optional
from zoneinfo import ZoneInfo

from app.config.db import db
from app.utils.app_logger import get_logger
from app.models import (
    investigation_model,
    referral_model,
    followup_model,
    order_finding_model,
    order_event_model,
)
from app.services import patient_journey_service

log = get_logger("medclues.order_monitoring")
IST = ZoneInfo("Asia/Kolkata")


def _now_ist() -> datetime:
    return datetime.now(IST)


def _today_ist() -> date:
    return _now_ist().date()


def _parse_db_datetime(dt_val) -> Optional[datetime]:
    if not dt_val:
        return None
    if isinstance(dt_val, str):
        try:
            return datetime.fromisoformat(dt_val.replace("Z", "+00:00"))
        except ValueError:
            return None
    return dt_val


def _iso(val) -> Optional[str]:
    if val is None:
        return None
    if hasattr(val, "isoformat"):
        return val.isoformat()
    return str(val)


async def investigation_agent(review_threshold_mins: int = 0, turnaround_threshold_hours: int = 2):
    """Monitor investigation lifecycle. Does not read or interpret report contents."""
    active_invs = await investigation_model.get_active_investigations()
    for inv in active_invs:
        status = inv.get("status")
        inv_id = inv["id"]
        patient_id = inv["patient_id"]
        created_at = _parse_db_datetime(inv.get("created_at"))
        updated_at = _parse_db_datetime(inv.get("updated_at"))

        if status == "REPORT_AVAILABLE" and not inv.get("reviewed_at"):
            stale_ok = True
            if review_threshold_mins > 0 and updated_at:
                now = datetime.now(updated_at.tzinfo)
                stale_ok = now - updated_at >= timedelta(minutes=review_threshold_mins)
            if stale_ok:
                await order_finding_model.create_finding(
                    entity_type="investigation",
                    entity_id=inv_id,
                    patient_id=patient_id,
                    finding_type="REPORT_REVIEW_PENDING",
                    message="Investigation report is available but has not yet been reviewed.",
                    priority="HIGH",
                    assigned_role="doctor",
                    recommended_action="Review the available investigation report.",
                    evidence={
                        "ordered": _iso(created_at),
                        "completed": _iso(updated_at),
                        "report": "Available",
                        "reviewed": "Pending",
                        "test_name": inv.get("test_name"),
                    },
                )

        elif status in ("ORDERED", "ACCEPTED", "SAMPLE_COLLECTED", "TEST_PERFORMED") and created_at:
            now = datetime.now(created_at.tzinfo)
            if now - created_at > timedelta(hours=turnaround_threshold_hours):
                ftype = (
                    "INVESTIGATION_DELAYED"
                    if status in ("ACCEPTED", "SAMPLE_COLLECTED", "TEST_PERFORMED")
                    else "INVESTIGATION_PENDING"
                )
                await order_finding_model.create_finding(
                    entity_type="investigation",
                    entity_id=inv_id,
                    patient_id=patient_id,
                    finding_type=ftype,
                    message="Investigation pending",
                    priority="MEDIUM",
                    assigned_role="lab_staff",
                    recommended_action="Advance the investigation to the next lab step.",
                    evidence={"ordered": _iso(created_at), "status": status},
                )


async def referral_agent(booking_threshold_hours: int = 0):
    """Monitor referral coordination. Does not choose a specialist clinically."""
    active_refs = await referral_model.get_active_referrals()
    for ref in active_refs:
        status = str(ref.get("status") or "").upper()
        ref_id = ref["id"]
        patient_id = ref["patient_id"]
        booked = bool(ref.get("appointment_date")) or status in {
            "APPOINTMENT_BOOKED",
            "SPECIALIST_CONSULTATION",
            "COMPLETED",
        }
        if booked:
            continue

        updated_at = _parse_db_datetime(ref.get("updated_at"))
        delayed = False
        if booking_threshold_hours > 0 and updated_at:
            now = datetime.now(updated_at.tzinfo)
            delayed = now - updated_at > timedelta(hours=booking_threshold_hours)

        ftype = "REFERRAL_DELAYED" if delayed else "REFERRAL_APPOINTMENT_PENDING"
        await order_finding_model.create_finding(
            entity_type="referral",
            entity_id=ref_id,
            patient_id=patient_id,
            finding_type=ftype,
            message="Specialist appointment has not yet been scheduled.",
            priority="HIGH" if delayed else "MEDIUM",
            assigned_role="referral_coordinator",
            recommended_action="Coordinate the specialist appointment.",
            evidence={
                "created": _iso(ref.get("created_at")),
                "accepted": _iso(updated_at) if status != "PENDING" else None,
                "specialist": "Not assigned" if not ref.get("assigned_to") else str(ref.get("assigned_to")),
                "appointment": "Not booked",
                "to_dept": ref.get("to_dept"),
            },
        )


async def followup_agent():
    """Monitor follow-up schedule. Does not change treatment."""
    active_followups = await followup_model.get_active_followups()
    today = _today_ist()
    for f in active_followups:
        f_id = f["id"]
        patient_id = f["patient_id"]
        due_date = f.get("due_date")
        status = str(f.get("status") or "")

        if not due_date:
            continue
        if isinstance(due_date, str):
            try:
                due_date = date.fromisoformat(due_date[:10])
            except ValueError:
                continue

        if due_date < today and status != "COMPLETED":
            if status != "OVERDUE":
                await followup_model.update_followup(f_id, {"status": "OVERDUE"})
                await order_event_model.create_order_event(
                    entity_type="followup",
                    entity_id=f_id,
                    event_type="STATUS_CHANGED",
                    payload={"old_status": status, "new_status": "OVERDUE", "actor_role": "agent"},
                )
            ftype = "FOLLOWUP_MISSED" if status == "OVERDUE" else "FOLLOWUP_OVERDUE"
            await order_finding_model.create_finding(
                entity_type="followup",
                entity_id=f_id,
                patient_id=patient_id,
                finding_type=ftype,
                message="Follow-up appointment overdue",
                priority="HIGH",
                assigned_role="appointment_coordinator",
                recommended_action="Reschedule or complete the overdue follow-up.",
                evidence={"followup": due_date.isoformat(), "status": "Overdue"},
            )

        elif status in ("SCHEDULED", "REMINDED"):
            diff = (due_date - today).days
            if 0 <= diff <= 2:
                await order_finding_model.create_finding(
                    entity_type="followup",
                    entity_id=f_id,
                    patient_id=patient_id,
                    finding_type="FOLLOWUP_UPCOMING",
                    message="Follow-up appointment due soon",
                    priority="LOW",
                    assigned_role="appointment_coordinator",
                    recommended_action="Confirm the patient will attend the upcoming follow-up.",
                    evidence={"followup": due_date.isoformat(), "status": "Upcoming"},
                )


monitor_investigations = investigation_agent
monitor_referrals = referral_agent
monitor_followups = followup_agent


async def run_order_monitoring_cycle():
    """Runs a single pass of all order monitoring agents plus stale-finding verification."""
    try:
        log.info("Running AI Order Monitoring Agent cycle...")
        await patient_journey_service.verify_and_close_stale_findings()
        await investigation_agent(review_threshold_mins=0, turnaround_threshold_hours=2)
        await referral_agent(booking_threshold_hours=0)
        await followup_agent()
        log.info("AI Order Monitoring Agent cycle completed successfully.")
    except Exception as e:
        log.error("Error in AI Order Monitoring Agent cycle: %s", e, exc_info=True)


async def start_order_monitoring_worker(interval_seconds: int = 60) -> None:
    log.info("AI Order Monitoring Agent worker started (interval=%ss)", interval_seconds)
    while True:
        try:
            if db.pool:
                await run_order_monitoring_cycle()
        except Exception as e:
            log.warning("AI Order Monitoring worker iteration error: %s", e)
        await asyncio.sleep(interval_seconds)
