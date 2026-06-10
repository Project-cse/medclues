from typing import Optional
import asyncio
import bcrypt
import json
import os
import time
from datetime import datetime, timedelta
from jose import jwt
from fastapi import HTTPException, UploadFile, File
from app.config.config import settings
from app.services import token_service
from app.models import user_model, doctor_model, appointment_model, health_record_model
from app.utils.formatters import format_user, format_doctor
import cloudinary.uploader
from app.services import email_service, socket_service
from app.config.db import db
from app.services.oauth_verification import (
    OAuthVerificationError,
    extract_id_token_from_body,
    verify_google_id_token,
)
from app.utils.app_logger import get_logger

log = get_logger(__name__)

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

# Helper to generate JWT token (legacy callers)
def create_access_token(user_id: int):
    return token_service.create_access_token("patient", user_id=user_id)

# API to register user
async def register_user(req_body: dict):
    try:
        name = req_body.get('name')
        email = req_body.get('email')
        password = req_body.get('password')
        phone = req_body.get('phone')

        if not name or not password or not email:
            return {"success": False, "message": "Missing Details"}

        # Basic validation (Node.js used 'validator')
        if "@" not in email or "." not in email:
            return {"success": False, "message": "Enter a valid email"}

        if len(password) < 8:
            return {"success": False, "message": "Enter a strong password"}

        existing_user = await user_model.get_user_by_email(email)
        if existing_user:
            return {"success": False, "message": "User already exists"}

        hashed_password = get_password_hash(password)

        user_data = {
            "name": name,
            "email": email,
            "password": hashed_password,
            "phone": phone,
            "role": 'patient'
        }

        new_user = await user_model.create_user(user_data)
        auth_response = await token_service.issue_token_pair("patient", user_id=new_user['id'])
        auth_response["isNewUser"] = True

        # --- Welcome Email ---
        try:
            await email_service.send_welcome_email(email, name)
        except Exception as e:
            print(f"[WARNING] Welcome Email failed: {e}")

        return auth_response

    except Exception as e:
        print(f"[ERROR] Register Error: {e}")
        return {"success": False, "message": str(e)}

# API to login user
async def login_user(req_body: dict):
    try:
        email = req_body.get('email')
        password = req_body.get('password')
        
        user = await user_model.get_user_by_email(email)
        if not user:
            return {"success": False, "message": "User does not exist"}

        if verify_password(password, user['password']):
            auth_response = await token_service.issue_token_pair("patient", user_id=user['id'])

            # --- Auto-secure Plain Text password if detected ---
            is_bcrypt = user['password'].startswith('$2b$') or user['password'].startswith('$2a$') or user['password'].startswith('$2y$')
            if not is_bcrypt:
                try:
                    new_hash = get_password_hash(password)
                    await user_model.update_user_password(user['id'], new_hash)
                    print(f"[SECURITY] Successfully upgraded plain-text password to secure bcrypt hash for user: {email}", flush=True)
                except Exception as hash_err:
                    print(f"[WARNING] Failed to secure user password on login: {hash_err}", flush=True)

            # --- Login Alert ---
            try:
                await email_service.send_login_alert(user['email'], user['name'])
            except Exception as e:
                print(f"[WARNING] Login alert email failed: {e}")

            return auth_response
        else:
            return {"success": False, "message": "Invalid credentials"}

    except Exception as e:
        print(f"[ERROR] Login Error: {e}")
        return {"success": False, "message": str(e)}

# API for social login (Google/Apple/Facebook)
async def social_login(req_body: dict):
    try:
        import secrets
        email = req_body.get('email')
        name = req_body.get('name')
        photo_url = req_body.get('photoURL')
        provider = (req_body.get('provider') or 'google').strip().lower()
        uid = req_body.get('uid')

        id_token_raw = extract_id_token_from_body(req_body)
        if id_token_raw and provider in ('google', 'firebase'):
            try:
                claims = verify_google_id_token(id_token_raw)
                email = claims.get('email') or email
                name = claims.get('name') or name or (email.split('@')[0] if email else '')
                photo_url = claims.get('picture') or photo_url
                uid = claims.get('sub') or uid
            except OAuthVerificationError as oauth_err:
                return {"success": False, "message": str(oauth_err)}
        elif not settings.SOCIAL_LOGIN_ALLOW_LEGACY:
            return {
                "success": False,
                "message": "ID token required for social login. Update the client app or contact support.",
            }
        else:
            log.warning(
                "Social login legacy path used for provider=%s (no idToken verified)",
                provider,
            )

        if not email:
            return {"success": False, "message": "Missing Email"}

        user = await user_model.get_user_by_email(email)
        is_new_user = False

        if not user:
            # Create a new user with a secure random password
            is_new_user = True
            random_pw = secrets.token_hex(16)
            hashed_password = get_password_hash(random_pw)
            
            user_data = {
                "name": name or email.split('@')[0],
                "email": email,
                "password": hashed_password,
                "image": photo_url,
                "role": 'patient'
            }
            user = await user_model.create_user(user_data)
            
            # --- Welcome Email ---
            try:
                await email_service.send_welcome_email(email, user['name'])
            except Exception as e:
                print(f"[WARNING] Welcome Email failed: {e}")
        else:
            # If user already exists but does not have an avatar/image, update it
            if not user.get('image') and photo_url:
                try:
                    await user_model.update_user(user['id'], {"image": photo_url})
                except Exception as img_err:
                    print(f"[WARNING] Failed to update user image: {img_err}")

        auth_response = await token_service.issue_token_pair("patient", user_id=user['id'])
        auth_response["isNewUser"] = is_new_user

        # --- Login Alert ---
        try:
            await email_service.send_login_alert(user['email'], user['name'])
        except Exception as e:
            print(f"[WARNING] Login alert email failed: {e}")

        return auth_response

    except Exception as e:
        print(f"[ERROR] Social Login Error: {e}")
        return {"success": False, "message": str(e)}

# API to get user profile
async def get_profile(user_id: int):
    try:
        if not user_id or user_id < 0:
            return {"success": False, "message": "Invalid Session. Please login again."}

        user = await user_model.get_user_by_id(user_id)
        if not user:
            return {"success": False, "message": "User not found"}
            
        return {"success": True, "userData": format_user(user)}
    except Exception as e:
        print(f"[ERROR] Get Profile Error: {e}")
        return {"success": False, "message": str(e)}

# API to update user profile
async def update_profile(user_id: int, form_data: dict, image_file: Optional[UploadFile] = None):
    try:
        if not user_id or user_id < 0:
            return {"success": False, "message": "Invalid Session. Please login again."}

        update_data = {}

        def _present(value) -> bool:
            if value is None:
                return False
            if isinstance(value, str) and not value.strip():
                return False
            return True

        # Only apply fields the client actually sent (photo-only upload must not null out name).
        if _present(form_data.get('name')):
            update_data['name'] = form_data['name'].strip() if isinstance(form_data['name'], str) else form_data['name']
        if _present(form_data.get('phone')):
            update_data['phone'] = form_data['phone'].strip() if isinstance(form_data['phone'], str) else form_data['phone']
        if _present(form_data.get('gender')):
            update_data['gender'] = form_data['gender']
        if _present(form_data.get('bloodGroup')):
            update_data['bloodGroup'] = form_data['bloodGroup']

        if _present(form_data.get('address')):
            addr = form_data['address']
            if isinstance(addr, str) and addr.strip():
                try:
                    update_data['address'] = json.loads(addr)
                except json.JSONDecodeError:
                    update_data['address_line1'] = addr
            elif isinstance(addr, dict):
                update_data['address'] = addr

        # Calculate age if dob updated
        dob = form_data.get('dob')
        if dob and dob not in ['Not Selected', 'dd-mm-yyyy']:
            update_data['dob'] = dob
            try:
                birth_date = datetime.strptime(dob, "%Y-%m-%d")
                today = datetime.today()
                age = today.year - birth_date.year - ((today.month, today.day) < (birth_date.month, birth_date.day))
                update_data['age'] = age
            except:
                pass

        if image_file:
            file_content = await image_file.read()
            if not file_content:
                return {"success": False, "message": "Empty image file"}
            upload_result = cloudinary.uploader.upload(
                file_content, folder="user-profiles"
            )
            update_data["image"] = upload_result.get("secure_url")

        if not update_data:
            user = await user_model.get_user_by_id(user_id)
            return {
                "success": True,
                "message": "No changes",
                "userData": format_user(user),
                "profile_pic_url": (user or {}).get("image"),
            }

        await user_model.update_user(user_id, update_data)
        user = await user_model.get_user_by_id(user_id)
        formatted = format_user(user)
        return {
            "success": True,
            "message": "Profile Updated",
            "userData": formatted,
            "profile_pic_url": formatted.get("image") if formatted else None,
        }

    except Exception as e:
        print(f"[ERROR] Update Profile Error: {e}")
        return {"success": False, "message": str(e)}


async def patch_profile(user_id: int, body: dict):
    """JSON profile update — optional fields only."""
    try:
        if not user_id or user_id < 0:
            return {"success": False, "message": "Invalid Session. Please login again."}

        update_data = {}
        field_map = {
            "name": "name",
            "phone": "phone",
            "gender": "gender",
            "dob": "dob",
            "blood_group": "bloodGroup",
            "bloodGroup": "bloodGroup",
            "medical_history": "medical_history",
            "allergies": "allergies",
        }
        for key, model_key in field_map.items():
            if key in body and body[key] is not None and body[key] != "":
                update_data[model_key] = body[key]

        if "address" in body and body["address"] is not None:
            addr = body["address"]
            if isinstance(addr, str) and addr.strip():
                update_data["address"] = {"line1": addr.strip(), "line2": ""}
            elif isinstance(addr, dict):
                update_data["address"] = {
                    "line1": addr.get("line1") or "",
                    "line2": addr.get("line2") or "",
                }

        if not update_data:
            user = await user_model.get_user_by_id(user_id)
            return {"success": True, "userData": format_user(user)}

        await user_model.update_user(user_id, update_data)
        user = await user_model.get_user_by_id(user_id)
        return {"success": True, "userData": format_user(user)}
    except Exception as e:
        print(f"[ERROR] Patch Profile Error: {e}")
        return {"success": False, "message": str(e)}


async def patch_onboarding(user_id: int, body: dict):
    """Persist onboarding progress flags for MEDCLUES first-time flow."""
    try:
        if not user_id or user_id < 0:
            return {"success": False, "message": "Invalid Session. Please login again."}

        update_data = {}
        bool_map = {
            "onboardingCompleted": "onboardingCompleted",
            "tutorialCompleted": "tutorialCompleted",
            "emergencyContactCompleted": "emergencyContactCompleted",
            "profileCompleted": "profileCompleted",
        }
        for key, model_key in bool_map.items():
            if key in body:
                update_data[model_key] = bool(body[key])

        if "onboardingStep" in body and body["onboardingStep"] is not None:
            try:
                update_data["onboardingStep"] = int(body["onboardingStep"])
            except (TypeError, ValueError):
                pass

        if not update_data:
            user = await user_model.get_user_by_id(user_id)
            return {"success": True, "userData": format_user(user)}

        await user_model.update_user(user_id, update_data)
        user = await user_model.get_user_by_id(user_id)
        return {"success": True, "userData": format_user(user)}
    except Exception as e:
        print(f"[ERROR] Patch Onboarding Error: {e}")
        return {"success": False, "message": str(e)}

# --- Appointment Logic ---

from app.services import queue_service, email_service
import razorpay
import hmac
import hashlib

razorpay_client = razorpay.Client(auth=(settings.RAZORPAY_KEY_ID, settings.RAZORPAY_KEY_SECRET))


async def _send_booking_confirmation_email(
    *,
    user_email: str,
    actual_patient: dict,
    user_name: str,
    doc_data: dict,
    slot_date: str,
    slot_time: str,
    amount,
    token_number,
    frontend_hospital_name: Optional[str],
    frontend_location: Optional[str],
):
    try:
        email_details = {
            "patientName": actual_patient.get('name') if not actual_patient.get('isSelf') else user_name,
            "doctorName": doc_data['name'],
            "speciality": doc_data['speciality'],
            "date": slot_date.replace('_', '/'),
            "time": slot_time,
            "fee": amount,
            "tokenNumber": token_number,
        }

        address_line1 = doc_data.get('address_line1', '')
        address_line2 = doc_data.get('address_line2', '')
        hospital_location = " ".join(filter(None, [address_line1, address_line2])).strip()

        if not hospital_location:
            hosp_id = doc_data.get('hospital_id')
            if hosp_id:
                tieup = await db.fetch_row("SELECT name, address FROM hospital_tieups WHERE id = $1", hosp_id)
                if tieup:
                    hospital_location = f"{tieup['name']} - {tieup['address']}" if tieup['address'] else tieup['name']
                else:
                    hosp = await db.fetch_row("SELECT name, address_line1 FROM hospitals WHERE id = $1", hosp_id)
                    if hosp:
                        hospital_location = f"{hosp['name']} - {hosp['address_line1']}" if hosp['address_line1'] else hosp['name']

        if frontend_hospital_name and frontend_location:
            hospital_location_str = f"{frontend_hospital_name} - {frontend_location}"
            email_details["hospitalName"] = frontend_hospital_name
        else:
            hospital_location_str = hospital_location or "MediChain Hospital, Main Branch"
            email_details["hospitalName"] = "MediChain Hospital"

        import urllib.parse
        maps_query = urllib.parse.quote(hospital_location_str)
        maps_link = f"https://www.google.com/maps/search/?api=1&query={maps_query}"

        email_details["hospitalLocation"] = hospital_location_str
        email_details["mapsLink"] = maps_link

        email_res = await email_service.send_appointment_confirmation(user_email, email_details)
        if not email_res.get('success'):
            print(f"[WARNING] Email delivery failed: {email_res.get('message')}")
    except Exception as email_err:
        print(f"[WARNING] Email trigger error: {email_err}")


async def book_appointment(user_id: int, req_body: dict, prescription_file: Optional[UploadFile] = None):
    try:
        doc_id = req_body.get('docId')
        db_doc_id = doc_id
        if isinstance(doc_id, str):
            if doc_id.startswith('emb_'):
                try:
                    db_doc_id = int(doc_id.replace('emb_', ''))
                except ValueError:
                    return {"success": False, "message": "Invalid doctor id format"}
            else:
                try:
                    db_doc_id = int(doc_id)
                except ValueError:
                    pass
        slot_date = req_body.get('slotDate')
        slot_time = req_body.get('slotTime')
        actual_patient = req_body.get('actualPatient') or {"isSelf": True}
        symptoms = req_body.get('symptoms') or []
        payment_method = req_body.get('paymentMethod') or 'payOnVisit'
        frontend_hospital_name = req_body.get('hospitalName')
        frontend_location = req_body.get('location')

        # Handle prescription upload
        prescription_url = None
        prescription_data = None
        if prescription_file:
            try:
                # Read file content to get size and upload properly
                file_content = await prescription_file.read()
                upload_result = cloudinary.uploader.upload(file_content, folder="appointments/prescriptions")
                prescription_url = upload_result.get('secure_url')
                
                # Store data for health record creation
                prescription_data = {
                    "url": prescription_url,
                    "fileName": prescription_file.filename,
                    "fileSize": len(file_content),
                    "fileType": prescription_file.content_type.split('/')[-1] if prescription_file.content_type else 'unknown',
                    "cloudinaryPublicId": upload_result.get('public_id')
                }
            except Exception as e:
                print(f"[WARNING] Prescription Upload Error: {e}")

        doc_data = await doctor_model.get_doctor_by_id(doc_id)
        if not doc_data:
            return {"success": False, "message": "Doctor not found"}

        if not doc_data.get('available'):
            return {"success": False, "message": "Doctor not available"}

        from app.services import doctor_slot_service
        from app.models import doctor_slot_model

        doctor_ref, _ = doctor_slot_service.normalize_doctor_ref(doc_id)
        await doctor_slot_service.ensure_doctor_slots_for_doctor(doctor_ref)

        slot_id_raw = req_body.get('slotId') or req_body.get('slot_id')
        booking_mode_req = doctor_slot_service.normalize_booking_mode(
            req_body.get('mode') or req_body.get('visitType')
        )
        slot_type_req = doctor_slot_service.infer_slot_type_from_label(
            slot_time,
            req_body.get('slotType') or req_body.get('slot_type'),
        )
        resolved_slot = None
        booked_slot_id = None

        wants_slot = bool(
            slot_id_raw
            or booking_mode_req in ("offline", "online")
            or slot_type_req in ("morning_opd", "evening_opd", "video")
        )
        if wants_slot:
            resolved_slot, slot_err = await doctor_slot_service.resolve_slot_for_booking(
                doctor_ref,
                int(slot_id_raw) if slot_id_raw else None,
                booking_mode_req,
                slot_type_req,
                slot_date,
            )
            if slot_err:
                return {"success": False, "message": slot_err}
            booked = await doctor_slot_model.mark_slot_booked(int(resolved_slot['id']))
            if not booked:
                return {"success": False, "message": "This time was just booked by another patient."}
            booked_slot_id = int(resolved_slot['id'])
            slot_date = doctor_slot_service.legacy_slot_date(resolved_slot['slot_date'])
            slot_time = doctor_slot_service.slot_time_label(resolved_slot)

        # Legacy slots_booked sync (queue compatibility)
        slots_booked = doc_data.get('slots_booked', {})
        if isinstance(slots_booked, str):
            slots_booked = json.loads(slots_booked)
        if booked_slot_id:
            # doctor_slots is source of truth — allow multiple bookings per OPD block label
            if slot_date not in slots_booked:
                slots_booked[slot_date] = []
            marker = f"slot:{booked_slot_id}"
            if marker not in slots_booked[slot_date]:
                slots_booked[slot_date].append(marker)
        elif slot_date in slots_booked:
            if slot_time in slots_booked[slot_date]:
                return {"success": False, "message": "Slot not available"}
            slots_booked[slot_date].append(slot_time)
        else:
            slots_booked[slot_date] = [slot_time]

        if isinstance(doc_id, (int, float)) or (isinstance(doc_id, str) and not doc_id.startswith('emb_')):
            try:
                await doctor_model.update_doctor(int(doc_id), {"slots_booked": slots_booked})
            except Exception:
                pass
        else:
            try:
                actual_id = int(str(doc_id).replace('emb_', ''))
                await db.execute(
                    'UPDATE hospital_tieup_doctors SET slots_booked = $1 WHERE id = $2',
                    json.dumps(slots_booked),
                    actual_id,
                )
            except Exception:
                pass

        user_data = await user_model.get_user_by_id(user_id)
        
        # Queue Logic
        queue_data = await queue_service.calculate_queue_position(doc_id, slot_date)
        token_number = await queue_service.assign_token_number(doc_id, slot_date)

        # Merge prescription URL into actual patient info if provided
        if prescription_url:
            actual_patient['prescription'] = prescription_url

        visit_type = (req_body.get('visitType') or req_body.get('visit_type') or '').strip()
        mode = req_body.get('mode')
        if resolved_slot:
            mode = doctor_slot_service.appointment_mode_from_slot(resolved_slot)
        elif not mode:
            mode = doctor_slot_service.normalize_appointment_mode_for_db(
                'online' if visit_type.lower() in ('online', 'video') else 'offline'
            )
        if payment_method.lower() in ('razorpay', 'onlinepayment', 'online'):
            mode = 'Video'
        mode = doctor_slot_service.normalize_appointment_mode_for_db(mode)

        mode_lower = str(mode).lower()
        if mode_lower in ('online', 'video') and payment_method.lower() in ('payonvisit', 'cash', ''):
            if booked_slot_id:
                await doctor_slot_model.release_slot(booked_slot_id)
            return {"success": False, "message": "Video consultation requires online payment."}

        fee_amount = (
            doctor_slot_service.consultation_fee_for_mode(doc_data, 'online')
            if mode_lower in ('online', 'video')
            else doctor_slot_service.consultation_fee_for_mode(doc_data, 'offline')
        )

        from app.models.appointment_model import generate_unique_booking_id
        booking_id = await generate_unique_booking_id()

        appointment_data = {
            "userId": user_id,
            "docId": db_doc_id,
            "userData": format_user(user_data),
            "docData": format_doctor(doc_data),
            "amount": fee_amount,
            "consultationFee": fee_amount,
            "slotDate": slot_date,
            "slotTime": slot_time,
            "actualPatient": actual_patient,
            "selectedSymptoms": symptoms,
            "paymentMethod": payment_method,
            "mode": mode,
            "tokenNumber": token_number,
            "queuePosition": queue_data.get('queuePosition'),
            "estimatedWaitTime": queue_data.get('estimated_wait_time'),
            "status": 'pending',
            "bookingId": booking_id,
            "slotId": booked_slot_id,
        }

        try:
            new_appointment = await appointment_model.create_appointment(appointment_data)
        except Exception as create_err:
            if booked_slot_id:
                await doctor_slot_model.release_slot(booked_slot_id)
            raise create_err

        if mode.lower() in ('online', 'video'):
            try:
                from app.controllers import consultation_controller
                await consultation_controller.ensure_consultation_for_appointment(
                    user_id, int(new_appointment['id'])
                )
            except Exception as consult_err:
                print(f"[WARNING] Video consultation setup: {consult_err}")
        
        # --- Automatic Health Record Creation ---
        # If a prescription was uploaded during booking, create a health record for it 
        # so the doctor can see it in the Patient Reports section.
        if prescription_url and prescription_data:
            try:
                record_title = f"Prescription for {doc_data['name']} Appointment"
                record_payload = {
                    "userId": user_id,
                    "docId": db_doc_id,
                    "appointmentId": new_appointment['id'],
                    "recordType": 'Prescription',
                    "title": record_title,
                    "description": f"Uploaded during appointment booking on {slot_date}",
                    "doctorName": doc_data['name'],
                    "date": datetime.now(),
                    "files": [prescription_data],
                    "tags": ['Autogenerated', 'Appointment'],
                    "isImportant": True,
                    "uploadedBeforeAppointment": True
                }
                await health_record_model.create_health_record(record_payload)
            except Exception as record_err:
                print(f"[WARNING] Failed to autogenerate health record from prescription: {record_err}")

        # Email runs in background so booking response is not blocked (~3–8s on Brevo).
        asyncio.create_task(_send_booking_confirmation_email(
            user_email=user_data['email'],
            actual_patient=actual_patient,
            user_name=user_data['name'],
            doc_data=doc_data,
            slot_date=slot_date,
            slot_time=slot_time,
            amount=appointment_data['amount'],
            token_number=token_number,
            frontend_hospital_name=frontend_hospital_name,
            frontend_location=frontend_location,
        ))

        # Trigger Real-time update for Admin Dashboard
        await socket_service.emit_new_appointment({
            "_id": new_appointment['id'],
            "docData": format_doctor(doc_data),
            "userData": format_user(user_data),
            "amount": appointment_data['amount'],
            "slotDate": slot_date,
            "slotTime": slot_time,
            "actualPatient": actual_patient
        })

        saved_booking_id = new_appointment.get('booking_id') or booking_id

        try:
            from app.services import fcm_service
            asyncio.create_task(
                fcm_service.notify_appointment_booked(
                    user_id,
                    doc_data.get('name', 'Doctor'),
                    slot_date,
                    slot_time,
                    int(new_appointment['id']),
                )
            )
        except Exception as push_err:
            print(f"[WARNING] FCM booking push: {push_err}")

        return {
            "success": True,
            "message": "Appointment Booked",
            "appointmentId": new_appointment['id'],
            "bookingId": saved_booking_id,
            "tokenNumber": token_number,
            "queuePosition": queue_data.get('queuePosition'),
            "estimatedWaitTime": queue_data.get('estimated_wait_time'),
        }

    except Exception as e:
        print(f"[ERROR] Book Appointment Error: {e}")
        return {"success": False, "message": str(e)}

async def list_appointments(
    user_id: int,
    *,
    limit: int | None = None,
    offset: int = 0,
):
    try:
        from app.utils.pagination import pagination_meta, with_pagination

        total = await appointment_model.count_appointments_by_user_id(user_id)
        appointments = await appointment_model.get_appointments_by_user_id(
            user_id, limit=limit, offset=offset
        )
        
        # JS expects specifically formatted objects
        formatted = []
        for apt in appointments:
            formatted.append({
                "_id": apt['id'],
                "id": apt['id'],
                "docId": apt['doctor_id'],
                "userId": apt['user_id'],
                "slotDate": apt['slot_date'],
                "slotTime": apt['slot_time'],
                "userData": apt['user_data'] if isinstance(apt['user_data'], dict) else json.loads(apt['user_data']),
                "docData": apt['doctor_data'] if isinstance(apt['doctor_data'], dict) else json.loads(apt['doctor_data']),
                "amount": float(apt['amount']),
                "date": apt['date'],
                "cancelled": apt['cancelled'],
                "payment": apt['payment'],
                "isCompleted": apt['is_completed'],
                "status": apt['status'],
                "paymentMethod": apt['payment_method'],
                "mode": apt.get('mode'),
                "visitType": (
                    'Online' if str(apt.get('mode') or '').lower() in ('online', 'video')
                    else 'In-clinic'
                ),
                "tokenNumber": apt['token_number'],
                "bookingId": apt.get('booking_id'),
                "queuePosition": apt['queue_position'],
                "estimatedWaitTime": apt['estimated_wait_time']
            })
        payload = {"success": True, "appointments": formatted}
        return with_pagination(
            payload,
            pagination_meta(
                total=total,
                limit=limit,
                offset=offset,
                returned=len(formatted),
            ),
        )
    except Exception as e:
        log.error("List appointments error: %s", e)
        return {"success": False, "message": str(e)}

async def cancel_appointment(user_id: int, appointment_id: int):
    try:
        appointment = await appointment_model.get_appointment_by_id(int(appointment_id))
        if not appointment or appointment['user_id'] != user_id:
            return {"success": False, "message": "Unauthorized or not found"}

        await appointment_model.cancel_appointment(appointment_id)

        try:
            from app.services import doctor_slot_service
            await doctor_slot_service.release_slot_for_appointment(appointment)
        except Exception as slot_err:
            print(f"[WARNING] Slot release on user cancel: {slot_err}")

        # Release slot
        doc_id = appointment['doctor_id']
        doc_data = await doctor_model.get_doctor_by_id(doc_id)
        if doc_data:
            slots_booked = doc_data.get('slots_booked', {})
            if isinstance(slots_booked, str): slots_booked = json.loads(slots_booked)
            
            date = appointment['slot_date']
            time_str = appointment['slot_time']
            slot_id = appointment.get('slot_id')

            if date in slots_booked:
                if slot_id:
                    marker = f"slot:{slot_id}"
                    if marker in slots_booked[date]:
                        slots_booked[date].remove(marker)
                if time_str in slots_booked[date]:
                    slots_booked[date].remove(time_str)
                await doctor_model.update_doctor(doc_id, {"slots_booked": slots_booked})

        # Trigger Real-time update
        from app.services.socket_service import sio
        await sio.emit('appointments-deleted', {'id': appointment_id})

        try:
            from app.services import fcm_service
            doc_name = "your doctor"
            if doc_data and doc_data.get("name"):
                doc_name = doc_data["name"]
            asyncio.create_task(
                fcm_service.notify_appointment_cancelled(
                    user_id, doc_name, int(appointment_id)
                )
            )
        except Exception as push_err:
            print(f"[WARNING] FCM cancel push: {push_err}")

        return {"success": True, "message": "Appointment Cancelled"}
    except Exception as e:
        return {"success": False, "message": str(e)}

# --- Razorpay Payment ---

async def payment_razorpay(appointment_id: int):
    try:
        appointment = await appointment_model.get_appointment_by_id(int(appointment_id))
        if not appointment or appointment['cancelled']:
            return {"success": False, "message": "Invalid appointment"}

        amount_paise = int(float(appointment['amount']) * 100)
        
        order_data = {
            "amount": amount_paise,
            "currency": settings.CURRENCY or "INR",
            "receipt": str(appointment['id']),
            "notes": {"appointmentId": str(appointment['id'])}
        }
        
        order = razorpay_client.order.create(data=order_data)
        
        # Include key_id for frontend
        order['key_id'] = settings.RAZORPAY_KEY_ID
        
        return {"success": True, "order": order}
    except Exception as e:
        return {"success": False, "message": str(e)}

async def verify_razorpay(req_body: dict):
    try:
        razorpay_order_id = req_body.get('razorpay_order_id')
        razorpay_payment_id = req_body.get('razorpay_payment_id')
        razorpay_signature = req_body.get('razorpay_signature')

        # Verify signature
        try:
            params_dict = {
                'razorpay_order_id': razorpay_order_id,
                'razorpay_payment_id': razorpay_payment_id,
                'razorpay_signature': razorpay_signature
            }
            razorpay_client.utility.verify_payment_signature(params_dict)
        except:
            return {"success": False, "message": "Payment verification failed: Invalid signature"}

        # Get appointment ID from order
        order = razorpay_client.order.fetch(razorpay_order_id)
        appointment_id = int(order.get('receipt'))
        
        # Update appointment
        await appointment_model.update_appointment(appointment_id, {
            "payment": True,
            "paymentMethod": 'Online (Razorpay)',
            "transactionId": razorpay_payment_id,
            "status": 'confirmed'
        })

        # Trigger Real-time WebSocket update
        from app.services.websocket_service import manager
        await manager.notify_payment_success(str(appointment_id))

        return {"success": True, "message": "Payment Successful"}
    except Exception as e:
        return {"success": False, "message": str(e)}

# --- Forgot Password ---

import random

async def forgot_password(email: str):
    try:
        user = await user_model.get_user_by_email(email)
        if not user:
            return {"success": False, "message": "User not found"}

        otp = str(random.randint(100000, 999999))
        hashed_otp = get_password_hash(otp)
        expiry = datetime.now() + timedelta(minutes=10)

        await user_model.set_reset_password_otp(email, hashed_otp, expiry)
        await email_service.send_password_reset_otp(email, otp, user['name'])

        return {"success": True, "message": "OTP sent"}
    except Exception as e:
        return {"success": False, "message": str(e)}

async def reset_password(req_body: dict):
    try:
        email = req_body.get('email')
        otp = req_body.get('otp')
        new_password = req_body.get('newPassword')

        user = await user_model.get_user_by_email(email)
        if not user or not user.get('reset_password_otp'):
            return {"success": False, "message": "Invalid request"}

        # Verify OTP
        if not verify_password(otp, user['reset_password_otp']):
            return {"success": False, "message": "Invalid OTP"}

        if datetime.now() > user['reset_password_otp_expiry']:
            return {"success": False, "message": "OTP Expired"}

        hashed_password = get_password_hash(new_password)
        await user_model.update_user_password(user['id'], hashed_password)
        
        # Clear OTP (Simplified: using update_user logic or raw query)
        await db.execute('UPDATE users SET reset_password_otp = NULL, reset_password_otp_expiry = NULL WHERE id = $1', user['id'])

        return {"success": True, "message": "Password reset successful"}
    except Exception as e:
        return {"success": False, "message": str(e)}
async def mark_alerted(appointment_id: int):
    try:
        await appointment_model.update_appointment(appointment_id, {"alerted": True})
        return {"success": True, "message": "Marked as alerted"}
    except Exception as e:
        return {"success": False, "message": str(e)}

# --- Emergency Contacts ---

async def get_emergency_contacts(user_id: int):
    try:
        contacts = await user_model.get_emergency_contacts(user_id)
        return {
            "success": True, 
            "contacts": {
                "friends": [c for c in contacts if c.get('contact_type') == 'friend'],
                "family": [c for c in contacts if c.get('contact_type') == 'family']
            }
        }
    except Exception as e:
        return {"success": False, "message": str(e)}

async def add_emergency_contact(user_id: int, req_body: dict):
    try:
        await user_model.add_emergency_contact(user_id, req_body)
        await user_model.update_user(user_id, {"emergencyContactCompleted": True})
        user = await user_model.get_user_by_id(user_id)
        return {"success": True, "message": "Added", "userData": format_user(user)}
    except Exception as e:
        return {"success": False, "message": str(e)}

async def update_emergency_contact(user_id: int, contact_id: int, req_body: dict):
    try:
        existing = await user_model.get_emergency_contact_by_id(contact_id)
        if not existing or existing.get("user_id") != user_id:
            return {"success": False, "message": "Contact not found"}
        await user_model.update_emergency_contact(contact_id, req_body)
        return {"success": True, "message": "Contact updated"}
    except Exception as e:
        return {"success": False, "message": str(e)}

async def delete_emergency_contact(user_id: int, contact_id: int):
    try:
        existing = await user_model.get_emergency_contact_by_id(contact_id)
        if not existing or existing.get("user_id") != user_id:
            return {"success": False, "message": "Contact not found"}
        await user_model.delete_emergency_contact(contact_id)
        return {"success": True, "message": "Deleted"}
    except Exception as e:
        return {"success": False, "message": str(e)}

# --- Saved Profiles ---

async def get_saved_profiles(user_id: int):
    try:
        profiles = await user_model.get_saved_profiles(user_id)
        return {"success": True, "profiles": profiles}
    except Exception as e:
        return {"success": False, "message": str(e)}

async def save_profile(user_id: int, req_body: dict):
    try:
        await user_model.add_saved_profile(user_id, req_body)
        return {"success": True, "message": "Profile saved"}
    except Exception as e:
        return {"success": False, "message": str(e)}

async def delete_saved_profile(profile_id: int):
    try:
        await user_model.delete_saved_profile(profile_id)
        return {"success": True, "message": "Profile deleted"}
    except Exception as e:
        return {"success": False, "message": str(e)}

# --- Other Functionalities ---

async def send_contact_message(req_body: dict):
    try:
        # Simple logging as in Node.js
        print(f"Contact Message: {req_body}")
        return {"success": True, "message": "Message sent successfully."}
    except Exception as e:
        return {"success": False, "message": str(e)}

async def get_queue_status(doc_id, slot_date: str):
    try:
        queue = await queue_service.get_doctor_queue_status(doc_id, slot_date)
        return {"success": True, **queue}
    except Exception as e:
        return {"success": False, "message": str(e)}

async def get_doctor_status(doc_id):
    try:
        doctor = await doctor_model.get_doctor_by_id(doc_id)
        if not doctor:
            return {"success": False, "message": "Doctor not found"}
        return {
            "success": True,
            "status": doctor.get('status', 'offline'),
            "available": doctor.get('available'),
            "currentAppointmentId": doctor.get('current_appointment_id')
        }
    except Exception as e:
        return {"success": False, "message": str(e)}

def _format_staff_appointment_view(appointment: dict, queue_status: dict | None = None) -> dict:
    user_data = appointment.get('user_data')
    if isinstance(user_data, str):
        user_data = json.loads(user_data) if user_data else {}
    doc_data = appointment.get('doctor_data')
    if isinstance(doc_data, str):
        doc_data = json.loads(doc_data) if doc_data else {}

    token_number = int(appointment.get('token_number') or 0)
    appt_id = int(appointment['id'])

    patient_name = appointment.get('actual_patient_name') or (user_data or {}).get('name') or 'Patient'
    if appointment.get('actual_patient_is_self') and (user_data or {}).get('name'):
        patient_name = user_data['name']

    status = appointment.get('status') or 'pending'
    if appointment.get('cancelled'):
        status = 'cancelled'
    elif appointment.get('is_completed'):
        status = 'completed'

    return {
        "appointmentId": appt_id,
        "bookingId": appointment.get('booking_id'),
        "tokenNumber": token_number,
        "queuePosition": appointment.get('queue_position'),
        "estimatedWaitTime": appointment.get('estimated_wait_time'),
        "patientName": patient_name,
        "patientPhone": (user_data or {}).get('phone'),
        "doctorName": (doc_data or {}).get('name'),
        "specialization": (doc_data or {}).get('speciality') or (doc_data or {}).get('specialization'),
        "hospitalName": (doc_data or {}).get('hospital_name') or (doc_data or {}).get('hospitalName'),
        "slotDate": appointment.get('slot_date'),
        "slotTime": appointment.get('slot_time'),
        "amount": float(appointment.get('amount') or 0),
        "paymentMethod": appointment.get('payment_method'),
        "visitType": appointment.get('mode'),
        "status": status,
        "cancelled": appointment.get('cancelled'),
        "isCompleted": appointment.get('is_completed'),
        "queueLength": (queue_status or {}).get('queueLength'),
        "isNextUp": (queue_status or {}).get('currentAppointmentId') == appt_id,
    }


async def verify_appointment(appointment_id: int, user_id: int = None):
    try:
        appointment = await appointment_model.get_appointment_by_id(appointment_id)
        if not appointment or (user_id and appointment['user_id'] != user_id):
            return {"success": False, "message": "Not found"}

        doc_id = appointment['doctor_id']
        queue_status = await queue_service.get_doctor_queue_status(doc_id, appointment['slot_date'])

        return {
            "success": True,
            "appointment": {
                **appointment,
                "_id": appointment['id'],
                "queuePosition": queue_status.get('queueLength', 0),
                "estimatedWaitTime": appointment['estimated_wait_time'],
                "isNextUp": queue_status.get('currentAppointmentId') == appointment['id'],
                "bookingId": appointment.get('booking_id'),
                "tokenNumber": appointment.get('token_number'),
            }
        }
    except Exception as e:
        return {"success": False, "message": str(e)}


async def get_appointment_by_booking_id(booking_id: str):
    """Public staff lookup: QR contains Booking ID only → fetch full details."""
    try:
        from app.utils.booking_id import is_valid_booking_id, normalize_booking_id

        code = normalize_booking_id(booking_id)
        if not is_valid_booking_id(code):
            return {"success": False, "message": "Invalid booking ID format"}

        appointment = await appointment_model.get_appointment_by_booking_id(code)
        if not appointment:
            return {"success": False, "message": "Appointment not found"}

        doc_id = appointment['doctor_id']
        queue_status = await queue_service.get_doctor_queue_status(doc_id, appointment['slot_date'])

        return {
            "success": True,
            "appointment": _format_staff_appointment_view(appointment, queue_status),
        }
    except Exception as e:
        print(f"[ERROR] Booking ID lookup: {e}")
        return {"success": False, "message": str(e)}

# --- Placeholder Payments ---

async def init_payu_payment(user_id: int, req_body: dict):
    # Replicating hashing logic from JS
    try:
        appointment_id = req_body.get('appointmentId')
        amount = req_body.get('amount')
        firstname = req_body.get('firstname')
        email = req_body.get('email')
        phone = req_body.get('phone')
        productinfo = req_body.get('productinfo')

        merchant_key = settings.PAYU_MERCHANT_KEY or 'gtKFFx'
        merchant_salt = settings.PAYU_MERCHANT_SALT or 'eCwWELxi'
        payu_base_url = settings.PAYU_BASE_URL or 'https://test.payu.in/_payment'

        txnid = f"TXN_{appointment_id}_{int(time.time() * 1000)}"
        udf1 = str(appointment_id)
        udf2 = str(user_id)

        # Hash Formula: key|txnid|amount|productinfo|firstname|email|udf1|udf2|udf3|udf4|udf5||||||salt
        hash_string = f"{merchant_key}|{txnid}|{amount}|{productinfo}|{firstname}|{email}|{udf1}|{udf2}|||||||||{merchant_salt}"
        import hashlib
        hash_val = hashlib.sha512(hash_string.encode('utf-8')).hexdigest()

        return {
            "success": True,
            "paymentData": {
                "key": merchant_key,
                "txnid": txnid,
                "amount": amount,
                "productinfo": productinfo,
                "firstname": firstname,
                "email": email,
                "phone": phone,
                "udf1": udf1,
                "udf2": udf2,
                "hash": hash_val,
                "payuUrl": payu_base_url
            }
        }
    except Exception as e:
        return {"success": False, "message": str(e)}

async def get_merchant_upi():
    return {"success": True, "merchantUPI": settings.MERCHANT_UPI_ID or "demo@upi"}


async def register_fcm_token(user_id: int, body: dict):
    token = (body.get("token") or body.get("fcm_token") or "").strip()
    if not token:
        return {"success": False, "message": "FCM token is required"}
    platform = (body.get("platform") or "android").strip().lower()
    from app.models import fcm_token_model

    await fcm_token_model.upsert_token(user_id, token, platform)
    return {"success": True, "message": "FCM token saved"}


async def remove_fcm_token(user_id: int, body: dict):
    token = (body.get("token") or body.get("fcm_token") or "").strip()
    if not token:
        return {"success": False, "message": "FCM token is required"}
    from app.models import fcm_token_model

    await fcm_token_model.delete_token(user_id, token)
    return {"success": True, "message": "FCM token removed"}
