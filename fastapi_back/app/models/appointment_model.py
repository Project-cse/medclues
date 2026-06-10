import json
import random
import string
import time
from datetime import datetime
from typing import Optional, List, Dict, Any, Union
from app.config.db import db

_BOOKING_CHARS = string.ascii_uppercase + string.digits


async def ensure_booking_id_column():
    """Add booking_id column for receipt QR / staff lookup."""
    try:
        await db.execute(
            """
            ALTER TABLE appointments
            ADD COLUMN IF NOT EXISTS booking_id VARCHAR(12)
            """
        )
        await db.execute(
            """
            CREATE UNIQUE INDEX IF NOT EXISTS idx_appointments_booking_id
            ON appointments (booking_id)
            WHERE booking_id IS NOT NULL
            """
        )
    except Exception as e:
        print(f"[WARNING] ensure_booking_id_column: {e}")


async def booking_id_exists(booking_id: str) -> bool:
    row = await db.fetch_row(
        "SELECT id FROM appointments WHERE UPPER(booking_id) = UPPER($1) LIMIT 1",
        booking_id,
    )
    return row is not None


async def generate_unique_booking_id() -> str:
    for _ in range(30):
        suffix = "".join(random.choices(_BOOKING_CHARS, k=6))
        candidate = f"BK{suffix}"
        if not await booking_id_exists(candidate):
            return candidate
    raise RuntimeError("Could not generate unique booking ID")


async def get_appointment_by_booking_id(booking_id: str):
    return await db.fetch_row(
        "SELECT * FROM appointments WHERE UPPER(booking_id) = UPPER($1) LIMIT 1",
        booking_id,
    )


async def get_all_appointments():
    sql = 'SELECT * FROM appointments ORDER BY created_at DESC'
    return await db.query(sql)

async def get_appointment_by_id(app_id: int):
    sql = 'SELECT * FROM appointments WHERE id = $1'
    return await db.fetch_row(sql, app_id)

async def count_appointments_by_user_id(user_id: int) -> int:
    row = await db.fetch_row(
        "SELECT COUNT(*)::int AS c FROM appointments WHERE user_id = $1",
        user_id,
    )
    return int(row["c"]) if row else 0


async def get_appointments_by_user_id(
    user_id: int,
    *,
    limit: int | None = None,
    offset: int = 0,
):
    if limit is None:
        sql = "SELECT * FROM appointments WHERE user_id = $1 ORDER BY created_at DESC"
        return await db.query(sql, user_id)
    sql = """
        SELECT * FROM appointments
        WHERE user_id = $1
        ORDER BY created_at DESC
        LIMIT $2 OFFSET $3
    """
    return await db.query(sql, user_id, limit, offset)

async def get_appointments_by_doctor_id(doc_id: int):
    sql = 'SELECT * FROM appointments WHERE doctor_id = $1 ORDER BY created_at DESC'
    return await db.query(sql, doc_id)

async def get_appointments_by_filters(filters: Dict[str, Any]):
    doc_id = filters.get('docId')
    if isinstance(doc_id, str) and not doc_id.startswith('emb_'):
        try:
            doc_id = int(doc_id)
        except ValueError:
            pass
    
    slot_date = filters.get('slotDate')
    cancelled = filters.get('cancelled')
    is_completed = filters.get('isCompleted')
    status = filters.get('status')
    
    sql = 'SELECT * FROM appointments WHERE 1=1'
    values = []
    param_count = 1

    if doc_id:
        sql += f" AND doctor_id = ${param_count}"
        values.append(doc_id)
        param_count += 1
    if slot_date:
        sql += f" AND slot_date = ${param_count}"
        values.append(slot_date)
        param_count += 1
    if cancelled is not None:
        sql += f" AND cancelled = ${param_count}"
        values.append(cancelled)
        param_count += 1
    if is_completed is not None:
        sql += f" AND is_completed = ${param_count}"
        values.append(is_completed)
        param_count += 1
    if status:
        if isinstance(status, list):
            sql += f" AND status = ANY(${param_count})"
        else:
            sql += f" AND status = ${param_count}"
        values.append(status)
        param_count += 1

    sql += ' ORDER BY created_at DESC'
    return await db.query(sql, *values)

async def create_appointment(app_data: Dict[str, Any]):
    actual_patient = app_data.get('actualPatient', {})
    booking_id = app_data.get('bookingId') or app_data.get('booking_id')
    if not booking_id:
        booking_id = await generate_unique_booking_id()
    
    sql = """
        INSERT INTO appointments (
            user_id, doctor_id, slot_date, slot_time, user_data, doctor_data,
            amount, consultation_fee, platform_fee, gst, cost_breakdown, date,
            payment_method, mode, actual_patient_name, actual_patient_age,
            actual_patient_gender, actual_patient_relationship, actual_patient_is_self,
            token_number, status, queue_position, estimated_wait_time, selected_symptoms,
            booking_id, slot_id
        ) VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16, $17, $18, $19, $20, $21, $22, $23, $24, $25, $26)
        RETURNING *
    """
    
    values = (
        app_data.get('userId'),
        app_data.get('docId'),
        app_data.get('slotDate'),
        app_data.get('slotTime'),
        json.dumps(app_data.get('userData', {})),
        json.dumps(app_data.get('docData', {})),
        app_data.get('amount'),
        app_data.get('consultationFee', 0),
        app_data.get('platformFee', 0),
        app_data.get('gst', 0),
        json.dumps(app_data.get('costBreakdown', {})),
        int(time.time() * 1000), # JavaScript Date.now() is milliseconds
        app_data.get('paymentMethod', 'payOnVisit'),
        app_data.get('mode', 'In-person'),
        actual_patient.get('name', ''),
        actual_patient.get('age', ''),
        actual_patient.get('gender', ''),
        actual_patient.get('relationship', ''),
        actual_patient.get('isSelf', True),
        app_data.get('tokenNumber', 0),
        app_data.get('status', 'pending'),
        app_data.get('queuePosition', 0),
        app_data.get('estimatedWaitTime', 0),
        list(app_data.get('selectedSymptoms', [])),
        booking_id,
        app_data.get('slotId'),
    )
    
    return await db.fetch_row(sql, *values)

async def update_appointment(app_id: Union[int, str], app_data: Dict[str, Any]):
    app_id = int(app_id)
    fields = []
    values = []
    param_count = 1

    updatable_fields = [
        'status', 'paymentStatus', 'payment', 'paymentMethod', 'cancelled', 'isCompleted',
        'transactionId', 'upiTransactionId', 'payerVpa', 'paymentTimestamp', 'alerted',
        'queuePosition', 'estimatedWaitTime', 'isDelayed', 'delayReason'
    ]

    for f in updatable_fields:
        if f in app_data:
            # Convert camelCase to snake_case for DB columns
            import re
            column = re.sub(r'(?<!^)(?=[A-Z])', '_', f).lower()
            fields.append(f"{column} = ${param_count}")
            values.append(app_data[f])
            param_count += 1

    if not fields:
        return None

    fields.append(f"updated_at = CURRENT_TIMESTAMP")
    sql = f"UPDATE appointments SET {', '.join(fields)} WHERE id = ${param_count} RETURNING *"
    values.append(app_id)

    return await db.fetch_row(sql, *values)

async def cancel_appointment(app_id: int):
    sql = """
        UPDATE appointments 
        SET cancelled = true, status = 'cancelled', updated_at = CURRENT_TIMESTAMP 
        WHERE id = $1 
        RETURNING *
    """
    return await db.fetch_row(sql, app_id)

async def delete_appointment(app_id: int):
    sql = 'DELETE FROM appointments WHERE id = $1 RETURNING *'
    return await db.fetch_row(sql, app_id)

async def get_appointments_by_hospital_id(hospital_id: int):
    """
    Return all appointments for a given hospital.
    Optimized to use indexes by avoiding casting on the main table columns.
    """
    sql = """
        SELECT a.*
        FROM appointments a
        WHERE a.doctor_id IN (
            SELECT id FROM doctors WHERE hospital_id = $1
        )
        OR a.doctor_id IN (
            -- This handles cases where tie-up doctor IDs might have been saved as integers
            SELECT id FROM hospital_tieup_doctors WHERE hospital_tieup_id = $1
        )
        ORDER BY a.created_at DESC
    """
    return await db.query(sql, hospital_id)

async def sync_appointments_doctor_data(doc_id: Union[int, str]):
    """
    Syncs the doctor_data JSONB snapshot inside existing appointments
    whenever a doctor's profile/image is updated.
    """
    try:
        from app.models.doctor_model import get_doctor_by_id
        from app.utils.formatters import format_doctor
        
        doc_data = await get_doctor_by_id(doc_id)
        if not doc_data:
            return False
            
        formatted = format_doctor(doc_data)
        if not formatted:
            return False
            
        # Strip out unwanted fields from the snapshot if needed
        # Resolve doctor_id in database
        if isinstance(doc_id, str) and doc_id.startswith('emb_'):
            actual_id = int(doc_id.replace('emb_', ''))
        else:
            actual_id = int(doc_id)
            
        sql = "UPDATE appointments SET doctor_data = $1::jsonb WHERE doctor_id = $2"
        await db.execute(sql, json.dumps(formatted), actual_id)
        return True
    except Exception as e:
        print(f"[ERROR] sync_appointments_doctor_data error: {e}")
        return False

