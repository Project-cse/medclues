import bcrypt
from datetime import datetime, timedelta
from typing import Union
from jose import jwt
from app.config.config import settings
from app.services import token_service
from app.models import dean_model, hospital_model, doctor_model, appointment_model
from app.utils.formatters import format_doctor


def _hash(password: str) -> str:
    return bcrypt.hashpw(password.encode(), bcrypt.gensalt(10)).decode()


def _verify(password: str, hashed: str) -> bool:
    if not hashed:
        return False
    is_bcrypt = hashed.startswith('$2b$') or hashed.startswith('$2a$') or hashed.startswith('$2y$')
    if is_bcrypt:
        try:
            return bcrypt.checkpw(password.encode(), hashed.encode())
        except Exception:
            return False
    else:
        # Fallback to plain text comparison for manual database updates
        return password == hashed


def _make_token(dean_id: int, hospital_id: int) -> str:
    return token_service.create_access_token(
        "dean", user_id=dean_id, hospital_id=hospital_id
    )


# ── Auth ──────────────────────────────────────────────────────────────────────

async def login_dean(body: dict):
    try:
        email = body.get("email", "").strip().lower()
        password = body.get("password", "")

        dean = await dean_model.get_dean_by_email(email)
        if not dean:
            return {"success": False, "message": "Invalid credentials"}

        if not _verify(password, dean["password"]):
            return {"success": False, "message": "Invalid credentials"}
            
        # --- Auto-secure Plain Text password if detected ---
        is_bcrypt = dean["password"].startswith('$2b$') or dean["password"].startswith('$2a$') or dean["password"].startswith('$2y$')
        if not is_bcrypt:
            try:
                new_hash = _hash(password)
                await dean_model.update_dean(dean["id"], {"password": new_hash})
                print(f"[SECURITY] Successfully upgraded plain-text password to secure bcrypt hash for dean: {email}", flush=True)
            except Exception as hash_err:
                print(f"[WARNING] Failed to secure dean password on login: {hash_err}", flush=True)

        auth_response = await token_service.issue_token_pair(
            "dean",
            user_id=dean["id"],
            hospital_id=dean["hospital_id"],
        )
        return {
            **auth_response,
            "dean": {
                "id": dean["id"],
                "name": dean["name"],
                "email": dean["email"],
                "hospitalId": dean["hospital_id"],
                "hospitalName": dean.get("hospital_name"),
            },
        }
    except Exception as e:
        print(f"[ERROR] login_dean error: {e}")
        return {"success": False, "message": str(e)}


# ── Dashboard ─────────────────────────────────────────────────────────────────

async def dean_dashboard(hospital_id: int):
    try:
        import asyncio
        host_task = hospital_model.get_hospital_tieup_by_id(hospital_id)
        from app.controllers.admin_controller import _get_hospital_doctors_merged
        docs_task = _get_hospital_doctors_merged(hospital_id)
        from app.models import user_model as um
        patients_task = um.get_patients_by_hospital_id(hospital_id)
        appts_task = appointment_model.get_appointments_by_hospital_id(hospital_id)

        hospital, doctors, appointments, users = await asyncio.gather(host_task, docs_task, appts_task, patients_task)
        
        if not hospital:
            return {"success": False, "message": "Hospital not found"}

        from datetime import datetime
        today = datetime.now()
        d_val, m_val, y_val = today.day, today.month, today.year
        today_str_standard = f"{d_val:02d}_{m_val:02d}_{y_val}"
        today_str_legacy = f"{d_val}_{m_val}_{y_val}"

        appointments_today = [a for a in appointments if (a.get("slot_date") == today_str_standard or a.get("slot_date") == today_str_legacy)]
        revenue_today = sum(float(a.get("amount", 0)) for a in appointments_today if a.get("payment"))
        active_doctors = sum(1 for d in doctors if d.get("available"))
        
        # Calculate patients registered today for this hospital
        from app.controllers.admin_controller import to_datetime
        patients_today = sum(1 for u in users if (to_datetime(u.get('created_at')) or datetime.min).date() == today.date())

        latest = sorted(appointments, key=lambda x: x.get("date", 0), reverse=True)[:10]

        from app.controllers.admin_controller import _prepare_dashboard_charts
        # Prepare chart data with 30-day window
        window_days = 30
        window_start = datetime.now().replace(hour=0, minute=0, second=0, microsecond=0) - timedelta(days=window_days)
        
        # Calculate users before window for the cumulative growth starting point
        from app.controllers.admin_controller import to_datetime
        u_before = sum(1 for u in users if (to_datetime(u.get('created_at')) or datetime.min) < window_start)

        dash = {
            "totalDoctors": len(doctors),
            "activeDoctors": active_doctors,
            "totalAppointments": len(appointments),
            "appointmentsToday": len(appointments_today),
            "patientsToday": patients_today,
            "revenueToday": revenue_today,
            "totalPatients": len(users),
            "hospitalName": hospital["name"],
            "chartData": _prepare_dashboard_charts(appointments, users, appointments, u_before, days=window_days),
            "latestAppointments": [
                {
                    "_id": a["id"],
                    "slotDate": a["slot_date"],
                    "slotTime": a["slot_time"],
                    "cancelled": a["cancelled"],
                    "isCompleted": a["is_completed"],
                    "payment": a["payment"],
                    "amount": float(a["amount"]),
                    "docData": a["doctor_data"] if isinstance(a["doctor_data"], dict) else {},
                    "userData": a["user_data"] if isinstance(a["user_data"], dict) else {},
                }
                for a in latest
            ],
        }
        return {"success": True, "dashData": dash}
    except Exception as e:
        print(f"[ERROR] dean_dashboard error: {e}")
        return {"success": False, "message": str(e)}


# ── Hospital info ─────────────────────────────────────────────────────────────

async def get_hospital(hospital_id: int):
    try:
        hospital = await hospital_model.get_hospital_tieup_by_id(hospital_id)
        if not hospital:
            return {"success": False, "message": "Hospital not found"}
        return {"success": True, "hospital": dict(hospital)}
    except Exception as e:
        return {"success": False, "message": str(e)}


async def update_hospital(hospital_id: int, data: dict):
    try:
        # Auto-geocode if address is present
        if 'address' in data:
            from app.controllers.location_controller import geocode_address
            geo_res = await geocode_address(data['address'])
            if geo_res.get('success'):
                data['latitude'] = geo_res['coordinates']['lat']
                data['longitude'] = geo_res['coordinates']['lon']

        await hospital_model.update_hospital_tieup(hospital_id, data)
        return {"success": True, "message": "Hospital updated"}
    except Exception as e:
        return {"success": False, "message": str(e)}


# ── Doctor management ─────────────────────────────────────────────────────────

async def get_hospital_doctors(hospital_id: int):
    try:
        from app.controllers.admin_controller import _get_hospital_doctors_merged
        doctors = await _get_hospital_doctors_merged(hospital_id)
        return {"success": True, "doctors": doctors}
    except Exception as e:
        # Fallback: get raw list
        try:
            raw = await doctor_model.get_doctors_by_hospital_id(hospital_id)
            return {"success": True, "doctors": [format_doctor(d) for d in raw]}
        except Exception as e2:
            return {"success": False, "message": str(e2)}


async def add_hospital_doctor(hospital_id: int, data: dict):
    try:
        email = data.get("email", "").strip().lower()
        name = data.get("name", "")
        password = data.get("password")
        
        # Validation
        if not email or not name:
            return {"success": False, "message": "Name and Email are required"}
        
        # Check if doctor exists
        existing = await doctor_model.get_doctor_by_email(email)
        if existing:
            return {"success": False, "message": "A doctor with this email already exists"}

        # Auto-generate password if not provided
        if not password:
            import secrets
            import string
            alphabet = string.ascii_letters + string.digits
            password = ''.join(secrets.choice(alphabet) for i in range(10))

        # Cloudinary Image handling if needed, or default
        clean_name = name.replace('Dr. ', '').replace('Dr.', '').strip()
        image_url = f"https://ui-avatars.com/api/?name={clean_name.replace(' ', '+')}&background=4f46e5&color=fff"

        # Prepare doctor data
        doctor_data = {
            "name": name,
            "email": email,
            "password": _hash(password),
            "image": image_url,
            "speciality": data.get("speciality") or data.get("specialization") or "General Medicine",
            "degree": data.get("degree") or data.get("qualification") or "MBBS",
            "experience": data.get("experience", "1 Year"),
            "about": data.get("about", "Specialist Doctor"),
            "fees": float(data.get("fees", 500)),
            "hospitalId": hospital_id,
            "available": True,
            "address": data.get("address") or {"line1": "Hospital Premise", "line2": "Main Ward"}
        }

        # Create doctor
        new_doctor = await doctor_model.create_doctor(doctor_data)
        
        # Get hospital name for email
        hospital = await hospital_model.get_hospital_tieup_by_id(hospital_id)
        hospital_name = hospital["name"] if hospital else "MediChain Hospital"

        # Send Credentials Email
        from app.services.email_service import send_doctor_credentials
        email_res = await send_doctor_credentials(email, name, password, hospital_name)
        
        return {
            "success": True, 
            "message": "Doctor added & credentials sent" if email_res.get("success") else "Doctor added (Email failed)",
            "doctor": {"id": new_doctor["id"], "name": new_doctor["name"]}
        }
    except Exception as e:
        print(f"[ERROR] add_hospital_doctor: {e}")
        return {"success": False, "message": str(e)}


async def reset_doctor_credentials(hospital_id: int, doc_id: Union[int, str], new_password: str = None):
    try:
        # Resolve numeric ID if embedded
        actual_id = doc_id
        if isinstance(doc_id, str) and doc_id.startswith('emb_'):
             return {"success": False, "message": "Cannot manage credentials for shared/tie-up doctors"}
        
        # Verify doctor belongs to hospital
        doc = await doctor_model.get_doctor_by_id(int(actual_id))
        if not doc or doc.get("hospital_id") != hospital_id:
            return {"success": False, "message": "Doctor access denied"}

        # Generate or use provided password
        if not new_password:
            import secrets
            import string
            new_password = ''.join(secrets.choice(string.ascii_letters + string.digits) for i in range(10))

        hashed = _hash(new_password)
        await doctor_model.update_doctor_password(int(actual_id), hashed)

        # Notify doctor
        hospital = await hospital_model.get_hospital_tieup_by_id(hospital_id)
        from app.services.email_service import send_doctor_credentials
        await send_doctor_credentials(doc["email"], doc["name"], new_password, hospital["name"])

        return {"success": True, "message": "Password reset & email sent"}
    except Exception as e:
        return {"success": False, "message": str(e)}


async def toggle_doctor_account_status(hospital_id: int, doc_id: Union[int, str]):
    try:
        if isinstance(doc_id, str) and doc_id.startswith('emb_'):
             return {"success": False, "message": "System restricted"}

        doc = await doctor_model.get_doctor_by_id(int(doc_id))
        if not doc or doc.get("hospital_id") != hospital_id:
            return {"success": False, "message": "Access denied"}

        # Use status field if exists, or available as proxy
        current_status = doc.get("status") != "Inactive"
        new_status = "Inactive" if current_status else "Available"
        
        await doctor_model.update_doctor(int(doc_id), {"status": new_status, "available": not current_status})
        
        return {"success": True, "message": f"Account {'deactivated' if current_status else 'activated'}"}
    except Exception as e:
        return {"success": False, "message": str(e)}


async def update_hospital_doctor(hospital_id: int, doctor_id, data: dict):
    try:
        from app.controllers.admin_controller import update_doctor
        data["docId"] = doctor_id
        return await update_doctor(data, None)
    except Exception as e:
        return {"success": False, "message": str(e)}


async def delete_hospital_doctor(hospital_id: int, doctor_id):
    try:
        from app.models import doctor_model as dm
        doc = await dm.get_doctor_by_id(int(doctor_id))
        if not doc or doc.get("hospital_id") != hospital_id:
            return {"success": False, "message": "Doctor not found in your hospital"}
        await dm.delete_doctor(int(doctor_id))
        return {"success": True, "message": "Doctor removed"}
    except Exception as e:
        return {"success": False, "message": str(e)}


async def change_doctor_availability(hospital_id: int, doctor_id):
    try:
        from app.models import doctor_model as dm
        doc = await dm.get_doctor_by_id(int(doctor_id))
        if not doc or doc.get("hospital_id") != hospital_id:
            return {"success": False, "message": "Doctor not found in your hospital"}
        await dm.change_doctor_availability(int(doctor_id), not doc["available"])
        return {"success": True, "message": "Availability updated"}
    except Exception as e:
        return {"success": False, "message": str(e)}


# ── Appointments ──────────────────────────────────────────────────────────────

async def get_hospital_appointments(hospital_id: int):
    try:
        appts = await appointment_model.get_appointments_by_hospital_id(hospital_id)
        formatted = []
        for a in appts:
            import json
            formatted.append({
                "_id": a["id"],
                "id": a["id"],
                "slotDate": a["slot_date"],
                "slotTime": a["slot_time"],
                "amount": float(a["amount"]),
                "cancelled": a["cancelled"],
                "payment": a["payment"],
                "isCompleted": a["is_completed"],
                "status": a.get("status"),
                "docData": a["doctor_data"] if isinstance(a["doctor_data"], dict) else json.loads(a["doctor_data"] or "{}"),
                "userData": a["user_data"] if isinstance(a["user_data"], dict) else json.loads(a["user_data"] or "{}"),
            })
        formatted.reverse()
        return {"success": True, "appointments": formatted}
    except Exception as e:
        return {"success": False, "message": str(e)}


async def cancel_appointment(hospital_id: int, appointment_id):
    try:
        appt = await appointment_model.get_appointment_by_id(int(appointment_id))
        if not appt:
            return {"success": False, "message": "Appointment not found"}
        await appointment_model.cancel_appointment(int(appointment_id))
        return {"success": True, "message": "Appointment cancelled"}
    except Exception as e:
        return {"success": False, "message": str(e)}


async def get_hospital_patients(hospital_id: int):
    try:
        from app.models import user_model as um
        patients = await um.get_patients_by_hospital_id(hospital_id)
        from app.utils.formatters import format_user
        return {"success": True, "patients": [format_user(p) for p in patients]}
    except Exception as e:
        return {"success": False, "message": str(e)}


# ── Admin helpers to create / manage DEANs ────────────────────────────────────

async def admin_create_dean(data: dict):
    try:
        existing = await dean_model.get_dean_by_email(data["email"].strip().lower())
        if existing:
            return {"success": False, "message": "A DEAN with this email already exists"}
        # Simplified creation logic
        hospital_id = data.get("hospital_id")
        hospital_name = data.get("hospital_name")
        
        if hospital_name and not hospital_id:
            # Check if hospital exists or create it
            from app.models import hospital_model
            tieups = await hospital_model.get_all_hospital_tieups()
            existing = next((h for h in tieups if h['name'].lower() == hospital_name.lower()), None)
            
            if existing:
                hospital_id = existing['id']
            else:
                new_h = await hospital_model.create_hospital_tieup({
                    "name": hospital_name,
                    "address": "Not Provided",
                    "contact": "Not Provided",
                    "specialization": [],
                    "type": "General"
                })
                hospital_id = new_h['id']

        hashed = _hash(data["password"])
        dean = await dean_model.create_dean({
            "name": data.get("name") or hospital_name or "Hospital Admin",
            "email": data["email"].strip().lower(),
            "password": hashed,
            "hospital_id": int(hospital_id),
        })
        return {"success": True, "message": "DEAN account created", "dean": {"id": dean["id"], "name": dean["name"]}}
    except Exception as e:
        return {"success": False, "message": str(e)}


async def admin_list_deans():
    try:
        deans = await dean_model.get_all_deans()
        return {"success": True, "deans": [dict(d) for d in deans]}
    except Exception as e:
        return {"success": False, "message": str(e)}


async def admin_delete_dean(dean_id: int):
    try:
        await dean_model.delete_dean(dean_id)
        return {"success": True, "message": "DEAN account deleted"}
    except Exception as e:
        return {"success": False, "message": str(e)}

async def admin_update_dean(dean_id: int, data: dict):
    try:
        update_data = {}
        if "name" in data: update_data["name"] = data["name"]
        if "email" in data: update_data["email"] = data["email"]
        if "password" in data:
            update_data["password"] = _hash(data["password"])
        
        await dean_model.update_dean(dean_id, update_data)
        return {"success": True, "message": "DEAN account updated"}
    except Exception as e:
        return {"success": False, "message": str(e)}

async def get_hospital_revenue_analytics(hospital_id: int):
    try:
        from datetime import datetime, timedelta
        from app.config.db import db
        now = datetime.now()
        
        # Helper to get start of today
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        
        # Common JOIN and WHERE clause for hospital filtering
        # Since appointments table doesn't have hospital_id, we join with doctors and tieup doctors
        hosp_filter = """
            EXISTS (
                SELECT 1 FROM doctors d WHERE d.id = a.doctor_id AND d.hospital_id = $1
            ) OR EXISTS (
                SELECT 1 FROM hospital_tieup_doctors htd WHERE htd.id = a.doctor_id AND htd.hospital_tieup_id = $1
            )
        """

        # 1. Today's Revenue (Hourly)
        sql_today = f"""
            SELECT EXTRACT(HOUR FROM a.created_at) as hour, SUM(a.amount) as total
            FROM appointments a
            WHERE a.cancelled = false AND a.created_at >= $2 AND ({hosp_filter})
            GROUP BY hour
            ORDER BY hour
        """
        hourly_rows = await db.fetch_all(sql_today, hospital_id, today_start)
        hourly_map = {int(r['hour']): float(r['total']) for r in hourly_rows}
        
        today_labels = []
        today_values = []
        for i in range(24):
            today_labels.append(f"{i:02d}:00")
            today_values.append(hourly_map.get(i, 0.0))

        # 2. Last 15 Days Revenue (Day-by-day)
        days_15_start = today_start - timedelta(days=14)
        sql_15days = f"""
            SELECT date_trunc('day', a.created_at) as day, SUM(a.amount) as total
            FROM appointments a
            WHERE a.cancelled = false AND a.created_at >= $2 AND ({hosp_filter})
            GROUP BY day
            ORDER BY day
        """
        day_rows = await db.fetch_all(sql_15days, hospital_id, days_15_start)
        day_map = {r['day'].date(): float(r['total']) for r in day_rows}
        
        days_15_labels = []
        days_15_values = []
        for i in range(14, -1, -1):
            day = (now - timedelta(days=i)).date()
            days_15_labels.append(day.strftime("%d %b"))
            days_15_values.append(day_map.get(day, 0.0))

        # 3. Monthly Revenue (Current Month, day-by-day)
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        sql_month = f"""
            SELECT date_trunc('day', a.created_at) as day, SUM(a.amount) as total
            FROM appointments a
            WHERE a.cancelled = false AND a.created_at >= $2 AND ({hosp_filter})
            GROUP BY day
            ORDER BY day
        """
        month_rows = await db.fetch_all(sql_month, hospital_id, month_start)
        month_map = {r['day'].date(): float(r['total']) for r in month_rows}
        
        month_labels = []
        month_values = []
        if now.month == 12:
            next_month = now.replace(year=now.year + 1, month=1, day=1)
        else:
            next_month = now.replace(month=now.month + 1, day=1)
        last_day = (next_month - timedelta(days=1)).day
        
        for i in range(1, last_day + 1):
            day = now.replace(day=i).date()
            month_labels.append(str(i))
            month_values.append(month_map.get(day, 0.0))

        # 4. Month-wise Revenue (Jan-Dec of current year)
        year_start = now.replace(month=1, day=1, hour=0, minute=0, second=0, microsecond=0)
        sql_year = f"""
            SELECT EXTRACT(MONTH FROM a.created_at) as month, SUM(a.amount) as total
            FROM appointments a
            WHERE a.cancelled = false AND a.created_at >= $2 AND a.created_at <= $3 AND ({hosp_filter})
            GROUP BY month
            ORDER BY month
        """
        month_agg_rows = await db.fetch_all(sql_year, hospital_id, year_start, now)
        month_agg_map = {int(r['month']): float(r['total']) for r in month_agg_rows}
        
        year_labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        year_values = [month_agg_map.get(m, 0.0) for m in range(1, 13)]

        # 5. Yearly Comparison (Last 5 Years)
        five_years_ago = now.year - 4
        sql_five_years = f"""
            SELECT EXTRACT(YEAR FROM a.created_at) as year, SUM(a.amount) as total
            FROM appointments a
            WHERE a.cancelled = false AND EXTRACT(YEAR FROM a.created_at) >= $2 AND ({hosp_filter})
            GROUP BY year
            ORDER BY year
        """
        year_rows = await db.fetch_all(sql_five_years, hospital_id, five_years_ago)
        year_map = {int(r['year']): float(r['total']) for r in year_rows}
        
        year_wise_labels = []
        year_wise_values = []
        for i in range(4, -1, -1):
            y = now.year - i
            year_wise_labels.append(str(y))
            year_wise_values.append(year_map.get(y, 0.0))

        return {
            "success": True,
            "analytics": {
                "today": {"labels": today_labels, "values": today_values, "total": sum(today_values)},
                "days15": {"labels": days_15_labels, "values": days_15_values, "total": sum(days_15_values)},
                "monthly": {"labels": month_labels, "values": month_values, "total": sum(month_values)},
                "monthWise": {"labels": year_labels, "values": year_values, "total": sum(year_values)},
                "yearWise": {"labels": year_wise_labels, "values": year_wise_values, "total": sum(year_wise_values)}
            }
        }
    except Exception as e:
        print(f"[ERROR] get_hospital_revenue_analytics: {e}")
        return {"success": False, "message": str(e)}

