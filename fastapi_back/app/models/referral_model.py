from typing import Optional, List, Dict, Any
from app.config.db import db
from datetime import datetime

async def create_referral(
    patient_id: int,
    ordered_by: int,
    hospital_id: Optional[int],
    from_dept: Optional[str],
    to_dept: str,
    reason: str,
    notes: Optional[str] = None
) -> Dict[str, Any]:
    sql = """
        INSERT INTO referrals (patient_id, ordered_by, hospital_id, from_dept, to_dept, reason, notes, status)
        VALUES ($1, $2, $3, $4, $5, $6, $7, 'PENDING')
        RETURNING *
    """
    return await db.fetch_row(sql, patient_id, ordered_by, hospital_id, from_dept, to_dept, reason, notes)

async def get_referral_by_id(referral_id: int) -> Optional[Dict[str, Any]]:
    sql = "SELECT * FROM referrals WHERE id = $1"
    return await db.fetch_row(sql, referral_id)

async def update_referral(referral_id: int, update_data: Dict[str, Any]) -> Optional[Dict[str, Any]]:
    fields = []
    values = []
    param_count = 1

    for key, value in update_data.items():
        fields.append(f"{key} = ${param_count}")
        values.append(value)
        param_count += 1

    if not fields:
        return None

    fields.append("updated_at = CURRENT_TIMESTAMP")
    sql = f"UPDATE referrals SET {', '.join(fields)} WHERE id = ${param_count} RETURNING *"
    values.append(referral_id)

    return await db.fetch_row(sql, *values)

async def get_referrals_by_patient(patient_id: int) -> List[Dict[str, Any]]:
    sql = "SELECT * FROM referrals WHERE patient_id = $1 ORDER BY created_at DESC"
    return await db.query(sql, patient_id)

async def get_referrals_queue(hospital_id: Optional[int] = None, status: Optional[str] = None) -> List[Dict[str, Any]]:
    sql = """
        SELECT r.*, u.name as patient_name, u.phone as patient_phone, d.name as doctor_name
        FROM referrals r
        JOIN users u ON r.patient_id = u.id
        JOIN doctors d ON r.ordered_by = d.id
        WHERE 1=1
    """
    params = []
    param_idx = 1
    if hospital_id is not None:
        sql += f" AND r.hospital_id = ${param_idx}"
        params.append(hospital_id)
        param_idx += 1
    if status is not None:
        sql += f" AND r.status = ${param_idx}"
        params.append(status)
        param_idx += 1
    else:
        # Default queue excludes completed referrals
        sql += " AND r.status != 'COMPLETED'"
    
    sql += " ORDER BY r.created_at ASC"
    return await db.query(sql, *params)

async def get_active_referrals() -> List[Dict[str, Any]]:
    """Returns all referrals that are not completed."""
    sql = "SELECT * FROM referrals WHERE status != 'COMPLETED'"
    return await db.query(sql)
