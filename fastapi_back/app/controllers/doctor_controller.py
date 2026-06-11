import bcrypt
import json
import os
import time
from datetime import datetime, timedelta
from jose import jwt
from fastapi import HTTPException, UploadFile, File
from typing import Optional, List, Dict, Any, Union
from app.config.config import settings
from app.config.db import db
from app.services import token_service
from app.models import user_model, doctor_model, appointment_model
from app.utils.formatters import format_user, format_doctor, format_appointment_for_frontend, parse_json_field
from app.services import queue_service, email_service
import cloudinary.uploader

# Helper to verify password (supporting plain text with auto-upgrade fallback)
def verify_password(password: str, hashed: str) -> bool:
    if not hashed:
        return False
    is_bcrypt = hashed.startswith('$2b$') or hashed.startswith('$2a$') or hashed.startswith('$2y$')
    if is_bcrypt:
        try:
            return bcrypt.checkpw(password.encode('utf-8'), hashed.encode('utf-8'))
        except:
            return False
    else:
        # Fallback to plain text comparison for manual database updates
        return password == hashed

# Helper to generate password hash
def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(10)).decode('utf-8')

# Helper to generate JWT token for Doctor (legacy callers)
def create_doctor_token(doc_id: int):
    return token_service.create_access_token("doctor", user_id=doc_id)

# API for doctor Login
async def login_doctor(req_body: dict):
    try:
        email = req_body.get('email')
        password = req_body.get('password')
        
        doctor = await doctor_model.get_doctor_by_email(email)
        if not doctor:
            return {"success": False, "message": "Invalid credentials"}

        if verify_password(password, doctor['password']):
            auth_response = await token_service.issue_token_pair("doctor", user_id=doctor['id'])

            # --- Auto-secure Plain Text password if detected ---
            is_bcrypt = doctor['password'].startswith('$2b$') or doctor['password'].startswith('$2a$') or doctor['password'].startswith('$2y$')
            if not is_bcrypt:
                try:
                    new_hash = get_password_hash(password)
                    await doctor_model.update_doctor_password(doctor['id'], new_hash)
                    print(f"[SECURITY] Successfully upgraded plain-text password to secure bcrypt hash for doctor: {email}", flush=True)
                except Exception as hash_err:
                    print(f"[WARNING] Failed to secure doctor password on login: {hash_err}", flush=True)

            return auth_response
        else:
            return {"success": False, "message": "Invalid credentials"}
    except Exception as e:
        print(f"[ERROR] Doctor Login Error: {e}")
        return {"success": False, "message": str(e)}

async def _enrich_user_data_for_appointment(apt: dict, user_data: dict) -> dict:
    """Fill missing name/dob/age from live user profile when booking snapshot is incomplete."""
    if not apt.get('user_id'):
        return user_data
    if user_data.get('name') and (user_data.get('dob') or user_data.get('age')):
        return user_data
    live = await user_model.get_user_by_id(apt['user_id'])
    if not live:
        return user_data
    fresh = format_user(live) or {}
    merged = dict(user_data)
    for key in ('name', 'email', 'phone', 'image', 'dob', 'age', 'gender'):
        if not merged.get(key) and fresh.get(key):
            merged[key] = fresh[key]
    return merged


async def _format_doctor_appointment(apt: dict) -> dict:
    user_data = parse_json_field(apt.get('user_data'))
    user_data = await _enrich_user_data_for_appointment(apt, user_data)
    return format_appointment_for_frontend(apt, user_data)


def _is_online_appointment(apt: dict) -> bool:
    mode = str(apt.get('mode') or '').lower()
    pm = str(apt.get('payment_method') or '').lower()
    return (
        'online' in mode
        or 'video' in mode
        or pm in ('razorpay', 'onlinepayment', 'online')
        or bool(apt.get('payment'))
    )


def _slot_date_is_today_ist(slot_date_str: str) -> bool:
    from zoneinfo import ZoneInfo
    from app.services.doctor_slot_service import legacy_slot_date, legacy_slot_date_padded

    if not slot_date_str:
        return False
    today = datetime.now(ZoneInfo('Asia/Kolkata')).date()
    return slot_date_str in (
        legacy_slot_date(today),
        legacy_slot_date_padded(today),
    )


# API to get doctor appointments
async def appointments_doctor(doc_id: int):
    try:
        raw_appointments = await appointment_model.get_appointments_by_doctor_id(doc_id)
        appointments = []
        for apt in raw_appointments:
            appointments.append(await _format_doctor_appointment(apt))
        return {"success": True, "appointments": appointments}
    except Exception as e:
        return {"success": False, "message": str(e)}

# API to cancel/reject appointment
async def appointment_cancel(doc_id: int, appointment_id: int, reason: Optional[str] = None):
    try:
        appointment = await appointment_model.get_appointment_by_id(appointment_id)
        if appointment and appointment['doctor_id'] == doc_id:
            await appointment_model.cancel_appointment(appointment_id)
            try:
                from app.services import doctor_slot_service
                await doctor_slot_service.release_slot_for_appointment(appointment)
            except Exception as slot_err:
                print(f"[WARNING] Slot release on cancel: {slot_err}")
            
            # Send Rejection/Cancellation Email
            try:
                user = await user_model.get_user_by_id(appointment['user_id'])
                if user:
                    await email_service.send_appointment_rejection(
                        user['email'],
                        user['name'],
                        {
                            "doctorName": appointment.get('doctor_data', {}).get('name', 'Doctor'),
                            "date": str(appointment.get('slot_date', '')).replace('_', '/'),
                            "time": appointment.get('slot_time', ''),
                            "tokenNumber": appointment.get('token_number', 'N/A'),
                            "bookingId": f"#APT{appointment_id}",
                            "reason": reason or "Administrative conflict",
                        },
                    )
            except Exception as e:
                print(f"[WARNING] Rejection email failed: {e}")

            return {"success": True, "message": 'Appointment Cancelled/Rejected'}
        return {"success": False, "message": 'Unauthorized or not found'}
    except Exception as e:
        return {"success": False, "message": str(e)}

# API to mark appointment completed
async def appointment_complete(doc_id: int, appointment_id: int):
    try:
        appointment = await appointment_model.get_appointment_by_id(appointment_id)
        if not appointment or appointment['doctor_id'] != doc_id:
            return {"success": False, "message": 'Appointment not found'}

        # In Python we can just update status directly or use a queue service if implemented
        await appointment_model.update_appointment(appointment_id, {"status": "completed", "isCompleted": True})
        try:
            from app.services import doctor_slot_service
            await doctor_slot_service.complete_slot_for_appointment(appointment)
        except Exception as slot_err:
            print(f"[WARNING] Slot complete: {slot_err}")
        
        # Update doctor status
        doctor = await doctor_model.get_doctor_by_id(doc_id)
        if doctor.get('current_appointment_id') == appointment_id:
            await db.execute('UPDATE doctors SET status = $1, current_appointment_id = NULL WHERE id = $2', 'in-clinic', doc_id)

        # Send completion email (optional logic)
        return {"success": True, "message": 'Appointment Completed'}
    except Exception as e:
        return {"success": False, "message": str(e)}

# API to get all doctors list for Frontend
async def doctor_list(hospital_id: Optional[int] = None):
    try:
        if hospital_id:
            doctors = await doctor_model.get_doctors_by_hospital_id(hospital_id)
        else:
            doctors = await doctor_model.get_all_doctors()
        
        formatted_doctors = [format_doctor(doc) for doc in doctors]
        return {"success": True, "doctors": formatted_doctors}
    except Exception as e:
        return {"success": False, "message": str(e)}

# API to toggle doctor availability
async def change_availability(doc_id: Union[str, int]):
    try:
        doc_data = await doctor_model.get_doctor_by_id(doc_id)
        if not doc_data:
            return {"success": False, "message": "Doctor not found"}
            
        new_avail = not doc_data['available']
        await doctor_model.update_doctor(doc_id, {
            'available': new_avail,
            'status': 'available' if new_avail else 'unavailable'
        })
        return {"success": True, "message": 'Availability Changed'}
    except Exception as e:
        return {"success": False, "message": str(e)}

# API to get doctor profile
async def doctor_profile(doc_id):
    try:
        doctor = await doctor_model.get_doctor_by_id(doc_id)
        if not doctor:
            return {"success": False, "message": "Doctor not found"}
            
        profile_data = format_doctor(doctor)
        if profile_data:
            profile_data.pop('password', None)
            
        return {"success": True, "profileData": profile_data}
    except Exception as e:
        return {"success": False, "message": str(e)}

# API to update doctor profile
async def update_doctor_profile(doc_id: int, form_data: dict, image=None):
    try:
        update_data = {}

        if form_data.get('fees') is not None:
            try:
                update_data['fees'] = float(form_data['fees'])
            except (ValueError, TypeError):
                pass

        if form_data.get('about') is not None:
            update_data['about'] = form_data['about']

        if form_data.get('available') is not None:
            val = form_data['available']
            if isinstance(val, str):
                update_data['available'] = val.lower() in ('true', '1', 'yes')
            else:
                update_data['available'] = bool(val)

        if form_data.get('address') is not None:
            import json as _json
            try:
                addr = _json.loads(form_data['address'])
            except Exception:
                addr = {'line1': form_data['address'], 'line2': ''}
            update_data['address'] = addr

        if form_data.get('status') is not None:
            st = form_data['status']
            update_data['status'] = st
            # Sync available field if status is provided
            if st in ('available', 'busy'):
                update_data['available'] = True
            elif st in ('unavailable', 'emergency'):
                update_data['available'] = False

        if image and image.filename:
            file_bytes = await image.read()
            import cloudinary.uploader, io
            result = cloudinary.uploader.upload(io.BytesIO(file_bytes), folder="doctors/profiles", resource_type='image')
            update_data['image'] = result.get('secure_url', '')

        if not update_data:
            return {"success": False, "message": "No data to update"}

        updated = await doctor_model.update_doctor(doc_id, update_data)
        if not updated:
            return {"success": False, "message": "Update failed"}
            
        try:
            from app.models.appointment_model import sync_appointments_doctor_data
            await sync_appointments_doctor_data(doc_id)
        except Exception as sync_err:
            print(f"[WARNING] Syncing doctor data to appointments failed: {sync_err}")
            
        return {"success": True, "message": "Profile Updated Successfully"}
    except Exception as e:
        print(f"[ERROR] update_doctor_profile error: {e}")
        return {"success": False, "message": str(e)}

# API to get dashboard data
async def doctor_dashboard(doc_id: int):
    try:
        appointments = await appointment_model.get_appointments_by_doctor_id(doc_id)
        
        earnings = 0
        patients_set = set()
        
        for apt in appointments:
            if apt['is_completed'] or apt['payment']:
                earnings += float(apt['amount'])
            if apt['user_id']:
                patients_set.add(apt['user_id'])
                
        latest = []
        for apt in list(reversed(appointments))[:5]:
            latest.append(await _format_doctor_appointment(apt))

        video_vc = []
        for apt in appointments:
            if (
                _is_online_appointment(apt)
                and not apt.get('cancelled')
                and not apt.get('is_completed')
            ):
                video_vc.append(await _format_doctor_appointment(apt))

        dash_data = {
            "earnings": earnings,
            "appointments": len(appointments),
            "patients": len(patients_set),
            "latestAppointments": latest,
            "todayVideoConsults": video_vc,
            "upcomingVideoConsults": video_vc,
        }
        return {"success": True, "dashData": dash_data}
    except Exception as e:
        return {"success": False, "message": str(e)}

# API to get queue status
async def get_queue_status(doc_id: int, slot_date: str):
    try:
        queue_status = await queue_service.get_doctor_queue_status(doc_id, slot_date)
        if not queue_status:
            return {"success": True, "queueStatus": {"status": 'in-clinic', "currentAppointmentId": None, "queueLength": 0, "appointments": [], "docId": doc_id}}

        return {"success": True, "queueStatus": {**queue_status, "docId": doc_id}, "suggestions": [], "delayedAppointments": []}
    except Exception as e:
        return {"success": False, "message": str(e)}

# API to start consultation
async def start_consultation(doc_id: int, appointment_id: int):
    try:
        appointment = await appointment_model.get_appointment_by_id(appointment_id)
        if not appointment or appointment['doctor_id'] != doc_id:
            return {"success": False, "message": 'Invalid appointment'}
            
        await db.execute("UPDATE appointments SET status = $1, alerted = true, updated_at = CURRENT_TIMESTAMP WHERE id = $2", 'in-consult', appointment_id)
        await db.execute("UPDATE doctors SET status = $1, current_appointment_id = $2, updated_at = CURRENT_TIMESTAMP WHERE id = $3", 'in-consult', appointment_id, doc_id)
        
        return {"success": True, "message": 'Consultation started'}
    except Exception as e:
        return {"success": False, "message": str(e)}

from app.controllers import consultation_controller

async def end_consultation(doc_id: int, req_body: dict):
    try:
        consultation_id = req_body.get('consultationId')
        
        # We can reuse the consultation_controller logic or implement directly
        # The JS version uses endConsultation from consultationController.
        return await consultation_controller.end_consultation(consultation_id, req_body)
    except Exception as e:
        return {"success": False, "message": str(e)}

async def doctor_consultations(doc_id: int):
    try:
        return await consultation_controller.get_doctor_consultations(doc_id)
    except Exception as e:
        return {"success": False, "message": str(e)}

async def get_consultation_details(doc_id: int, consultation_id: int):
    try:
        # Verify doctor is allowed to see this
        consultation = await consultation_model.get_consultation_by_id(consultation_id)
        if not consultation or consultation['doctor_id'] != doc_id:
            return {"success": False, "message": "Unauthorized or not found"}
            
        return await consultation_controller.get_consultation(consultation_id)
    except Exception as e:
        return {"success": False, "message": str(e)}
