from datetime import date, timedelta

from app.services.patient_journey_service import (
    _consultation_label,
    _followup_label,
    _investigation_labels,
    _referral_labels,
    finding_still_valid,
    _journey_status,
    _dedupe_findings,
)


def test_consultation_completed_from_flag():
    assert _consultation_label({"is_completed": True}) == "COMPLETED"


def test_investigation_report_pending_review():
    inv, report = _investigation_labels({"status": "REPORT_AVAILABLE"})
    assert inv == "COMPLETED"
    assert report == "PENDING_REVIEW"


def test_referral_appointment_pending_without_date():
    ref, spec = _referral_labels({"status": "ACCEPTED"})
    assert spec == "APPOINTMENT_PENDING"
    ref2, spec2 = _referral_labels({"status": "ACCEPTED", "appointment_date": "2026-08-23T10:00:00"})
    assert spec2 == "CONFIRMED"


def test_followup_upcoming_tomorrow():
    tomorrow = date.today() + timedelta(days=1)
    assert _followup_label({"status": "SCHEDULED", "due_date": tomorrow}, today=date.today()) == "UPCOMING"


def test_report_review_pending_requires_live_db_state():
    finding = {"finding_type": "REPORT_REVIEW_PENDING"}
    assert finding_still_valid(finding, {"status": "REPORT_AVAILABLE"}) is True
    assert finding_still_valid(finding, {"status": "REVIEWED", "reviewed_at": "now"}) is False


def test_referral_finding_resolves_when_booked():
    finding = {"finding_type": "REFERRAL_APPOINTMENT_PENDING"}
    assert finding_still_valid(finding, {"status": "ACCEPTED"}) is True
    assert finding_still_valid(finding, {"status": "APPOINTMENT_BOOKED", "appointment_date": "x"}) is False


def test_journey_attention_when_report_pending():
    journey = {
        "consultation": "COMPLETED",
        "investigation": "COMPLETED",
        "report": "PENDING_REVIEW",
        "referral": "ACCEPTED",
        "specialist_appointment": "APPOINTMENT_PENDING",
        "followup": "UPCOMING",
    }
    findings = [{"priority": "HIGH", "message": "report"}]
    assert _journey_status(journey, findings) == "ATTENTION_REQUIRED"
    assert _journey_status(journey, []) == "ATTENTION_REQUIRED"
    assert _journey_status({**journey, "report": "REVIEWED", "specialist_appointment": "CONFIRMED", "followup": "COMPLETED"}, []) == "ON_TRACK"


def test_dedupe_findings_by_type_and_entity():
    rows = [
        {"finding_type": "REPORT_REVIEW_PENDING", "entity_type": "investigation", "entity_id": 1, "message": "a"},
        {"finding_type": "REPORT_REVIEW_PENDING", "entity_type": "investigation", "entity_id": 1, "message": "b"},
        {"finding_type": "FOLLOWUP_UPCOMING", "entity_type": "followup", "entity_id": 2, "message": "c"},
    ]
    out = _dedupe_findings(rows)
    assert len(out) == 2
