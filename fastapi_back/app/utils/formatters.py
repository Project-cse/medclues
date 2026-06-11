from typing import Any, Dict, Optional, List
import json
import re
from datetime import date, datetime

def format_user(user: Any) -> Optional[Dict[str, Any]]:
    if not user:
        return None
    
    # Handle both dict-like and record-like objects from asyncpg
    u = dict(user)
    
    # Handle address fields
    address = {}
    if u.get('address_line1'):
        address = {
            "line1": u.get('address_line1'),
            "line2": u.get('address_line2', '')
        }
    
    # Handle JSON fields that might be stored as strings in some DB drivers
    saved_profiles = u.get('saved_profiles') or []
    if saved_profiles is None:
        saved_profiles = []
    if isinstance(saved_profiles, str):
        try:
            saved_profiles = json.loads(saved_profiles)
        except Exception:
            saved_profiles = []
    if not isinstance(saved_profiles, list):
        saved_profiles = []

    emergency_contacts = u.get('emergency_contacts') or {}
    if emergency_contacts is None:
        emergency_contacts = {}
    if isinstance(emergency_contacts, str):
        try:
            emergency_contacts = json.loads(emergency_contacts)
        except Exception:
            emergency_contacts = {"friends": [], "family": []}
    if not isinstance(emergency_contacts, dict):
        emergency_contacts = {"friends": [], "family": []}
            
    return {
        "_id": u.get('id'),
        "id": u.get('id'),
        "name": u.get('name'),
        "email": u.get('email'),
        "phone": u.get('phone'),
        "image": u.get('image'),
        "address": address,
        "gender": u.get('gender'),
        "dob": u.get('dob'),
        "age": u.get('age'),
        "bloodGroup": u.get('blood_group'),
        "role": u.get('role', 'patient'),
        "savedProfiles": saved_profiles,
        "emergencyContacts": emergency_contacts,
        "onboardingCompleted": bool(u.get('onboarding_completed')),
        "tutorialCompleted": bool(u.get('tutorial_completed')),
        "emergencyContactCompleted": bool(u.get('emergency_contact_completed')),
        "profileCompleted": bool(u.get('profile_completed')),
        "onboardingStep": int(u.get('onboarding_step') or 0),
    }

def _rating_from_experience(experience) -> float:
    if experience is None:
        return 4.2
    text = str(experience)
    m = re.search(r"(\d+)", text)
    years = int(m.group(1)) if m else 5
    return round(min(4.9, max(3.8, 3.7 + years * 0.08)), 1)


def _parse_doctor_rating(d: Dict[str, Any]) -> float:
    rating_raw = d.get('rating')
    if rating_raw is not None:
        try:
            rating = float(rating_raw)
            if rating > 0:
                return rating
        except (TypeError, ValueError):
            pass
    return _rating_from_experience(d.get('experience'))


def format_doctor(doc: Any) -> Optional[Dict[str, Any]]:
    if not doc:
        return None
    
    d = dict(doc)
    
    slots_booked = d.get('slots_booked', {})
    if isinstance(slots_booked, str):
        try:
            slots_booked = json.loads(slots_booked)
        except:
            slots_booked = {}
            
    rating = round(_parse_doctor_rating(d), 1)
    reviews = d.get('reviews') or d.get('review_count') or 0
    try:
        reviews = int(reviews)
    except (TypeError, ValueError):
        reviews = 0
    if reviews <= 0 and d.get('id') is not None:
        try:
            reviews = 15 + (int(d['id']) % 100)
        except (TypeError, ValueError):
            reviews = 0

    return {
        "_id": d.get('id'),
        "id": d.get('id'),
        "name": d.get('name'),
        "image": d.get('image'),
        "rating": rating,
        "reviews": reviews,
        "speciality": d.get('speciality'),
        "degree": d.get('degree'),
        "experience": d.get('experience'),
        "about": d.get('about'),
        "fees": float(d.get('fees', 0)),
        "videoConsultationFee": float(d.get('video_consultation_fee') or 450),
        "followupVideoFee": float(d.get('followup_video_fee') or 250),
        "address": {
            "line1": d.get('address_line1', ''),
            "line2": d.get('address_line2', '')
        } if d.get('address_line1') else {},
        "available": d.get('available', True),
        "status": d.get('status', 'available'),
        "phone": d.get('phone') or d.get('hospital_contact') or d.get('contact'),
        "slots_booked": slots_booked,
        "hospitalId": d.get('hospital_id'),
        "hospitalName": d.get('hospital_name')
    }

def parse_json_field(val: Any) -> Dict[str, Any]:
    if isinstance(val, dict):
        return val
    if isinstance(val, str):
        try:
            return json.loads(val) if val else {}
        except Exception:
            return {}
    return {}


def build_actual_patient(apt: Dict[str, Any]) -> Dict[str, Any]:
    is_self = apt.get('actual_patient_is_self')
    if is_self is None:
        is_self = True
    age_raw = apt.get('actual_patient_age')
    age = None
    if age_raw not in (None, '', 0):
        try:
            age = int(age_raw)
        except (TypeError, ValueError):
            age = age_raw
    return {
        'name': apt.get('actual_patient_name') or '',
        'age': age,
        'gender': apt.get('actual_patient_gender'),
        'relationship': apt.get('actual_patient_relationship'),
        'isSelf': bool(is_self),
    }


def compute_age_from_dob(dob: Any) -> Optional[int]:
    if not dob:
        return None
    try:
        if isinstance(dob, datetime):
            birth = dob.date()
        elif isinstance(dob, date):
            birth = dob
        else:
            text = str(dob).strip()[:10]
            birth = datetime.strptime(text, '%Y-%m-%d').date()
        today = date.today()
        age = today.year - birth.year
        if (today.month, today.day) < (birth.month, birth.day):
            age -= 1
        return age if age >= 0 else None
    except Exception:
        return None


def resolve_patient_age(apt: Dict[str, Any], user_data: Dict[str, Any], actual_patient: Dict[str, Any]) -> Optional[int]:
    if actual_patient.get('age') not in (None, '', 0):
        try:
            return int(actual_patient['age'])
        except (TypeError, ValueError):
            pass
    if not actual_patient.get('isSelf', True):
        return None
    if user_data.get('age') not in (None, '', 0):
        try:
            return int(user_data['age'])
        except (TypeError, ValueError):
            pass
    return compute_age_from_dob(user_data.get('dob'))


def format_appointment_for_frontend(apt: Dict[str, Any], user_data: Optional[Dict[str, Any]] = None) -> Dict[str, Any]:
    """Map a DB appointment row to the shape expected by doctor/patient web apps."""
    user_data = user_data if user_data is not None else parse_json_field(apt.get('user_data'))
    doc_data = parse_json_field(apt.get('doctor_data'))
    actual_patient = build_actual_patient(apt)
    patient_age = resolve_patient_age(apt, user_data, actual_patient)

    created = apt.get('created_at') or apt.get('date')
    date_val = created.isoformat() if hasattr(created, 'isoformat') else created

    symptoms = apt.get('selected_symptoms') or []
    if isinstance(symptoms, str):
        try:
            symptoms = json.loads(symptoms) if symptoms else []
        except Exception:
            symptoms = []

    mode_val = apt.get('mode')
    visit_type = 'Online' if str(mode_val or '').lower() in ('online', 'video') else 'In-clinic'

    return {
        '_id': apt['id'],
        'id': apt['id'],
        'docId': apt.get('doctor_id'),
        'userId': apt.get('user_id'),
        'slotDate': apt.get('slot_date'),
        'slotTime': apt.get('slot_time'),
        'userData': user_data,
        'docData': doc_data,
        'actualPatient': actual_patient,
        'patientAge': patient_age,
        'amount': float(apt.get('amount') or 0),
        'date': date_val,
        'cancelled': bool(apt.get('cancelled')),
        'payment': bool(apt.get('payment')),
        'isCompleted': bool(apt.get('is_completed')),
        'status': apt.get('status'),
        'paymentMethod': apt.get('payment_method'),
        'mode': mode_val,
        'visitType': visit_type,
        'selectedSymptoms': symptoms,
        'tokenNumber': apt.get('token_number'),
        'bookingId': apt.get('booking_id'),
    }


def format_health_record(record: Any) -> Optional[Dict[str, Any]]:
    if not record:
        return None
    
    r = dict(record)
    
    files = r.get('attachments', [])
    if isinstance(files, str):
        try:
            files = json.loads(files)
        except:
            files = []
            
    tags = r.get('tags', [])
    if isinstance(tags, str):
        try:
            tags = json.loads(tags)
        except:
            tags = []
            
    from app.services.cloudinary_delivery import enrich_attachment_files
    files = enrich_attachment_files(files)

    return {
        "_id": r.get('id'),
        "id": r.get('id'),
        "userId": r.get('user_id'),
        "docId": r.get('doctor_id'),
        "appointmentId": r.get('appointment_id'),
        "recordType": r.get('record_type'),
        "title": r.get('title'),
        "description": r.get('description'),
        "doctorName": r.get('doctor_name'),
        "date": r.get('record_date').isoformat() if hasattr(r.get('record_date', None), 'isoformat') else r.get('record_date'),
        "files": files,
        "tags": tags,
        "isImportant": r.get('is_important', False),
        "viewedByDoctor": r.get('viewed_by_doctor', False),
        "viewedAt": r.get('viewed_at').isoformat() if hasattr(r.get('viewed_at', None), 'isoformat') else r.get('viewed_at')
    }
