import bcrypt
import json
import os
import random
import time
from datetime import datetime, timedelta
from jose import jwt
from fastapi import HTTPException, UploadFile, File
from typing import Optional, List, Dict, Any, Union
from app.config.config import settings
from app.config.db import db
from app.services import token_service
from app.models import user_model, doctor_model, appointment_model, admin_model
from app.utils.formatters import format_user, format_doctor
from app.services import email_service
import cloudinary.uploader

# Helper to generate password hash
def get_password_hash(password: str) -> str:
    return bcrypt.hashpw(password.encode('utf-8'), bcrypt.gensalt(10)).decode('utf-8')

# Helper to generate JWT token for Admin (legacy callers)
def create_admin_token(email: str):
    return token_service.create_access_token("admin", email=email)

def to_datetime(val):
    from dateutil import parser
    if not val:
        return None
    if isinstance(val, (int, float)):
        # Handle both sec and ms timestamps
        if val > 1e11: val /= 1000
        return datetime.fromtimestamp(val)
    if isinstance(val, str):
        try:
            # Try parsing as ISO or common formats
            if '_' in val: # Handle our custom date format if needed
                 val = val.replace('_', '-')
            dt = parser.parse(val)
            return dt.replace(tzinfo=None) if dt.tzinfo else dt
        except:
            return None
    if isinstance(val, datetime):
        return val.replace(tzinfo=None) if val.tzinfo else val
    return None

# API for admin login
async def login_admin(req_body: dict):
    try:
        email = str(req_body.get('email', '')).strip().lower()
        password = str(req_body.get('password', '')).strip()
        
        expected_email = str(settings.ADMIN_EMAIL or "").strip().lower()
        expected_pass = str(settings.ADMIN_PASSWORD or "").strip()

        if not expected_email or not expected_pass:
            return {
                "success": False,
                "message": "Admin credentials not configured in fastapi_back/.env",
            }

        from app.controllers.user_controller import verify_password

        admin_row = await admin_model.get_admin_by_email(email)
        if admin_row and admin_row.get("password"):
            if verify_password(password, admin_row["password"]):
                return await token_service.issue_token_pair("admin", email=email)

        if email == expected_email and password == expected_pass:
            return await token_service.issue_token_pair("admin", email=email)
        return {"success": False, "message": "Invalid credentials"}
    except Exception as e:
        print(f"[admin login] error: {e}", flush=True)
        return {"success": False, "message": "Login failed"}

# API to get all appointments list
async def appointments_admin():
    try:
        appointments = await appointment_model.get_all_appointments()
        
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
                "paymentMethod": apt['payment_method']
            })
        return {"success": True, "appointments": formatted}
    except Exception as e:
        return {"success": False, "message": str(e)}

# API for appointment cancellation/rejection
async def appointment_cancel(appointment_id: int, reason: Optional[str] = None):
    try:
        appointment = await appointment_model.get_appointment_by_id(appointment_id)
        if not appointment:
            return {"success": False, "message": 'Appointment not found'}

        await appointment_model.cancel_appointment(appointment_id)
        
        # --- SEND REJECTION EMAIL ---
        try:
            # Need user details for the email
            user = await user_model.get_user_by_id(appointment['user_id'])
            if user:
                await email_service.send_appointment_rejection(
                    user['email'],
                    user['name'],
                    {
                        "doctorName": appointment.get('doctor_data', {}).get('name', 'Hospital Section'),
                        "date": str(appointment.get('slot_date', '')).replace('_', '/'),
                        "time": appointment.get('slot_time', ''),
                        "tokenNumber": appointment.get('token_number', 'N/A'),
                        "bookingId": f"#APT{appointment_id}",
                        "reason": reason or "Administrative change",
                    },
                )
        except Exception as e:
            print(f"[WARNING] Admin rejection email error: {e}")

        # --- REAL-TIME UPDATE ---
        from app.services.socket_service import sio
        await sio.emit('appointments-deleted', {'id': appointment_id})

        return {"success": True, "message": 'Appointment Cancelled/Rejected'}
    except Exception as e:
        return {"success": False, "message": str(e)}

# API for adding Doctor
async def add_doctor(form_data: dict, image_file: Optional[UploadFile] = None):
    try:
        name = form_data.get('name')
        email = form_data.get('email')
        password = form_data.get('password')
        speciality = form_data.get('speciality')
        degree = form_data.get('degree')
        experience = form_data.get('experience')
        about = form_data.get('about')
        fees = form_data.get('fees')
        address = form_data.get('address')

        if not all([name, email, password, speciality, degree, experience, about, fees, address]):
            return {"success": False, "message": "Missing Details"}

        # email check and hashed password logic...
        existing_doctor = await doctor_model.get_doctor_by_email(email)
        if existing_doctor:
            return {"success": False, "message": "Doctor already exists"}

        hashed_password = get_password_hash(password)
        
        image_url = f"https://ui-avatars.com/api/?name={name.replace(' ', '+')}&background=0ea5e9&color=ffffff"
        if image_file:
            upload_result = cloudinary.uploader.upload(image_file.file, folder="doctors/profiles")
            image_url = upload_result.get('secure_url')

        doctor_data = {
            "name": name,
            "email": email,
            "image": image_url,
            "password": hashed_password,
            "speciality": speciality,
            "degree": degree,
            "experience": experience,
            "about": about,
            "fees": float(fees),
            "address": json.loads(address) if isinstance(address, str) else address,
            "date": int(time.time() * 1000)
        }

        await doctor_model.create_doctor(doctor_data)
        return {"success": True, "message": 'Doctor Added'}

    except Exception as e:
        return {"success": False, "message": str(e)}

# API to update doctor details
async def update_doctor(form_data: dict, image_file: Optional[UploadFile] = None):
    try:
        doc_id = form_data.get('docId')
        if not doc_id:
            return {"success": False, "message": "Doctor ID is required"}

        update_data = {}
        if 'name' in form_data: update_data['name'] = form_data['name']
        if 'email' in form_data: update_data['email'] = form_data['email']
        if 'speciality' in form_data: update_data['speciality'] = form_data['speciality']
        if 'degree' in form_data: update_data['degree'] = form_data['degree']
        if 'experience' in form_data: update_data['experience'] = form_data['experience']
        if 'about' in form_data: update_data['about'] = form_data['about']
        if 'fees' in form_data: update_data['fees'] = float(form_data['fees'])
        
        if 'address' in form_data:
            addr = form_data['address']
            update_data['address'] = json.loads(addr) if isinstance(addr, str) else addr

        if 'status' in form_data:
            st = form_data['status']
            update_data['status'] = st
            # Sync available field
            if st in ('available', 'busy'):
                update_data['available'] = True
            elif st in ('unavailable', 'emergency'):
                update_data['available'] = False

        if image_file:
            upload_result = cloudinary.uploader.upload(image_file.file, folder="doctors/profiles")
            update_data['image'] = upload_result.get('secure_url')

        await doctor_model.update_doctor(doc_id, update_data)
        try:
            from app.models.appointment_model import sync_appointments_doctor_data
            await sync_appointments_doctor_data(doc_id)
        except Exception as sync_err:
            print(f"[WARNING] Syncing doctor data to appointments failed: {sync_err}")
            
        return {"success": True, "message": 'Doctor Updated Successfully'}
    except Exception as e:
        return {"success": False, "message": str(e)}

# API to get all doctors list for admin
async def all_doctors():
    try:
        import asyncio
        # Run queries in parallel
        doctors_task = doctor_model.get_all_doctors()
        embedded_sql = """
            SELECT d.*, h.name as hospital_name 
            FROM hospital_tieup_doctors d
            JOIN hospital_tieups h ON d.hospital_tieup_id = h.id
        """
        embedded_task = db.query(embedded_sql)
        
        doctors, embedded_docs = await asyncio.gather(doctors_task, embedded_task)
        
        formatted_doctors = [format_doctor(doc) for doc in doctors]
        seen_names = {d['name'].lower().strip() for d in formatted_doctors if d and d.get('name')}
        
        for doc in embedded_docs:
            name_key = doc['name'].lower().strip()
            if name_key not in seen_names:
                formatted_doctors.append({
                    "_id": f"emb_{doc['id']}",
                    "id": f"emb_{doc['id']}",
                    "name": doc['name'],
                    "speciality": doc.get('specialization') or doc.get('speciality'),
                    "degree": doc.get('qualification') or doc.get('degree'),
                    "experience": doc['experience'],
                    "about": doc.get('about', "Medical Specialist"),
                    "fees": doc.get('fees', 500),
                    "image": doc['image'],
                    "available": doc.get('available', True),
                    "hospitalId": doc['hospital_tieup_id'],
                    "hospital_name": doc['hospital_name']
                })
        
        return {"success": True, "doctors": formatted_doctors}
    except Exception as e:
        print(f"[ERROR] all_doctors error: {e}")
        return {"success": False, "message": str(e)}

# API to toggle doctor availability
async def change_availability(doc_id: Union[str, int]):
    try:
        from app.controllers import doctor_controller
        return await doctor_controller.change_availability(doc_id)
    except Exception as e:
        return {"success": False, "message": str(e)}

def _prepare_dashboard_charts(appointments: list, users: list, all_appointments: list, total_before_window: int = 0, days: int = 14):
    """Generate multi-day chart data for growth/revenue and all-time peak hours"""
    from datetime import datetime, timedelta
    from dateutil import parser
    from collections import defaultdict
    
    now = datetime.now()
    today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
    window_start = (today_start - timedelta(days=days-1))
    
    # 1. Growth & Revenue (Daily for last X days)
    users_by_day = defaultdict(int)
    for u in users:
        dt = to_datetime(u.get('created_at') or u.get('date'))
        if dt and dt >= window_start:
            day_key = dt.date()
            users_by_day[day_key] += 1

    rev_by_day = defaultdict(float)
    for a in appointments:
        if a.get('cancelled'):
            continue
        dt = to_datetime(a.get('created_at') or a.get('date'))
        if dt and dt >= window_start:
            day_key = dt.date()
            rev_by_day[day_key] += float(a.get('amount', 0))

    growth_labels = []
    patient_growth = []
    revenue_streak = []
    
    for i in range(days-1, -1, -1):
        day = (today_start - timedelta(days=i)).date()
        growth_labels.append(day.strftime("%d %b"))
        
        patient_growth.append(users_by_day[day])
        revenue_streak.append(rev_by_day[day])

    # 2. Peak Hours (All-time hourly distribution)
    # Based on slot_time (e.g. "10:00 AM")
    peak_hours_map = defaultdict(int)
    for a in all_appointments:
        if a.get('cancelled'): continue
        time_str = a.get('slot_time', '')
        if not time_str: continue
        try:
            # Parse "10:00 AM" to hour
            hour = parser.parse(time_str).hour
            peak_hours_map[hour] += 1
        except:
            continue

    peak_labels = []
    peak_values = []
    for h in range(24):
        peak_labels.append(f"{h:02d}:00")
        peak_values.append(peak_hours_map.get(h, 0))
        
    return {
        "patientGrowth": {"labels": growth_labels, "values": patient_growth},
        "revenue": {"labels": growth_labels, "values": revenue_streak},
        "appointments": {"labels": peak_labels, "values": peak_values}
    }

# API to get dashboard data
async def admin_dashboard():
    try:
        import asyncio
        from datetime import datetime, timedelta
        
        now = datetime.now()
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        
        # 60 day window for charts to ensure we have data if system is sparsely used
        chart_window_start = (today_start - timedelta(days=60))
        
        d, m, y = now.day, now.month, now.year
        today_str_standard = f"{d:02d}_{m:02d}_{y}"
        today_str_legacy = f"{d}_{m}_{y}"
        
        # Parallelize independent database aggregation tasks
        tasks = [
            db.fetch_one("SELECT COUNT(*) as count FROM doctors"),
            db.fetch_one("SELECT COUNT(*) as count FROM doctors WHERE available = true"),
            db.fetch_one("""
                SELECT COUNT(d.id) as count 
                FROM hospital_tieup_doctors d
                JOIN hospital_tieups h ON d.hospital_tieup_id = h.id
            """),
            db.fetch_one("""
                SELECT COUNT(d.id) as count 
                FROM hospital_tieup_doctors d
                JOIN hospital_tieups h ON d.hospital_tieup_id = h.id
                WHERE d.available = true
            """),
            db.fetch_one("SELECT COUNT(*) FROM users"),
            db.fetch_one("SELECT COUNT(*) FROM appointments"),
            db.fetch_one("SELECT COUNT(*) FROM appointments WHERE slot_date = $1 OR slot_date = $2", today_str_standard, today_str_legacy),
            db.fetch_one("SELECT SUM(amount) FROM appointments WHERE (slot_date = $1 OR slot_date = $2) AND cancelled = false", today_str_standard, today_str_legacy),
            db.fetch_one("SELECT SUM(amount) FROM appointments WHERE cancelled = false"),
            # Fetch data for charts
            db.fetch_all("SELECT created_at, date, amount, cancelled FROM appointments WHERE created_at >= $1 OR (date::bigint / 1000) >= $2", chart_window_start, chart_window_start.timestamp()),
            db.fetch_all("SELECT created_at FROM users WHERE created_at >= $1", chart_window_start),
            db.fetch_one("SELECT COUNT(*) FROM users WHERE created_at < $1", chart_window_start),
            # All-time for peak hours
            db.fetch_all("SELECT slot_time, cancelled FROM appointments"),
            # Patients today
            db.fetch_one("SELECT COUNT(*) FROM users WHERE created_at >= $1", today_start),
            # Hospital tie-ups count
            db.fetch_one("SELECT COUNT(*) FROM hospital_tieups")
        ]
        
        results = await asyncio.gather(*tasks)
        
        total_docs = results[0]['count'] + results[2]['count']
        active_docs = results[1]['count'] + results[3]['count']
        total_users = results[4]['count']
        total_appts = results[5]['count']
        appts_today = results[6]['count']
        rev_today = float(results[7]['sum'] or 0)
        rev_total = float(results[8]['sum'] or 0)
        
        recent_appointments = results[9]
        recent_users = results[10]
        users_before_window = results[11]['count']
        all_appts_for_peak = results[12]
        patients_today = results[13]['count']
        total_hospitals = results[14]['count']
        
        # Fetch latest 10 for the UI
        latest_appointments = await appointment_model.get_all_appointments()
        latest_appointments = latest_appointments[:10]

        dash_data = {
            "doctors": total_docs,
            "activeDoctors": active_docs,
            "appointments": total_appts,
            "appointmentsToday": appts_today,
            "patients": total_users,
            "patientsToday": patients_today,
            "revenueToday": rev_today,
            "revenueTotal": rev_total,
            "hospitals": total_hospitals,
            "chartData": _prepare_dashboard_charts(recent_appointments, recent_users, all_appts_for_peak, users_before_window, days=30),
            "latestAppointments": [
                {
                    "_id": apt['id'],
                    "docData": apt['doctor_data'] if isinstance(apt['doctor_data'], dict) else json.loads(apt['doctor_data'] or "{}"),
                    "userData": apt['user_data'] if isinstance(apt['user_data'], dict) else json.loads(apt['user_data'] or "{}"),
                    "amount": apt['amount'],
                    "date": apt['date'],
                    "cancelled": apt['cancelled'],
                    "status": apt['status'],
                    "slotDate": apt['slot_date'],
                    "slotTime": apt['slot_time']
                } for apt in latest_appointments
            ]
        }
        return {"success": True, "dashData": dash_data}
    except Exception as e:
        import traceback
        traceback.print_exc()
        print(f"[ERROR] admin_dashboard error: {e}")
        return {"success": False, "message": str(e)}
    except Exception as e:
        print(f"[ERROR] admin_dashboard error: {e}")
        return {"success": False, "message": str(e)}

# API to get detailed revenue analytics
async def get_revenue_analytics():
    try:
        from datetime import datetime, timedelta
        now = datetime.now()
        
        # Helper to get start of today
        today_start = now.replace(hour=0, minute=0, second=0, microsecond=0)
        
        # 1. Today's Revenue (Hourly)
        # Fetch hourly aggregates for today
        sql_today = """
            SELECT EXTRACT(HOUR FROM created_at) as hour, SUM(amount) as total
            FROM appointments
            WHERE cancelled = false AND created_at >= $1
            GROUP BY hour
            ORDER BY hour
        """
        hourly_rows = await db.fetch_all(sql_today, today_start)
        hourly_map = {int(r['hour']): float(r['total']) for r in hourly_rows}
        
        today_labels = []
        today_values = []
        for i in range(24):
            today_labels.append(f"{i:02d}:00")
            today_values.append(hourly_map.get(i, 0.0))

        # 2. Last 15 Days Revenue (Day-by-day)
        days_15_start = today_start - timedelta(days=14)
        sql_15days = """
            SELECT date_trunc('day', created_at) as day, SUM(amount) as total
            FROM appointments
            WHERE cancelled = false AND created_at >= $1
            GROUP BY day
            ORDER BY day
        """
        day_rows = await db.fetch_all(sql_15days, days_15_start)
        day_map = {r['day'].date(): float(r['total']) for r in day_rows}
        
        days_15_labels = []
        days_15_values = []
        for i in range(14, -1, -1):
            day = (now - timedelta(days=i)).date()
            days_15_labels.append(day.strftime("%d %b"))
            days_15_values.append(day_map.get(day, 0.0))

        # 3. Monthly Revenue (Current Month, day-by-day)
        month_start = now.replace(day=1, hour=0, minute=0, second=0, microsecond=0)
        sql_month = """
            SELECT date_trunc('day', created_at) as day, SUM(amount) as total
            FROM appointments
            WHERE cancelled = false AND created_at >= $1
            GROUP BY day
            ORDER BY day
        """
        month_rows = await db.fetch_all(sql_month, month_start)
        month_map = {r['day'].date(): float(r['total']) for r in month_rows}
        
        month_labels = []
        month_values = []
        # Calculate days in current month
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
        sql_year = """
            SELECT EXTRACT(MONTH FROM created_at) as month, SUM(amount) as total
            FROM appointments
            WHERE cancelled = false AND created_at >= $1 AND created_at <= $2
            GROUP BY month
            ORDER BY month
        """
        month_agg_rows = await db.fetch_all(sql_year, year_start, now)
        month_agg_map = {int(r['month']): float(r['total']) for r in month_agg_rows}
        
        year_labels = ["Jan", "Feb", "Mar", "Apr", "May", "Jun", "Jul", "Aug", "Sep", "Oct", "Nov", "Dec"]
        year_values = [month_agg_map.get(m, 0.0) for m in range(1, 13)]

        # 5. Yearly Comparison (Last 5 Years)
        five_years_ago = now.year - 4
        sql_five_years = """
            SELECT EXTRACT(YEAR FROM created_at) as year, SUM(amount) as total
            FROM appointments
            WHERE cancelled = false AND EXTRACT(YEAR FROM created_at) >= $1
            GROUP BY year
            ORDER BY year
        """
        year_rows = await db.fetch_all(sql_five_years, five_years_ago)
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
        print(f"[ERROR] get_revenue_analytics: {e}")
        return {"success": False, "message": str(e)}
    except Exception as e:
        print(f"[ERROR] get_revenue_analytics: {e}")
        return {"success": False, "message": str(e)}

# API to delete all appointments
async def delete_all_appointments():
    try:
        await db.execute('DELETE FROM appointments')
        await db.execute('UPDATE doctors SET slots_booked = $1', json.dumps({}))
        
        # Notify all clients
        from app.services.socket_service import sio
        await sio.emit('appointments-deleted', {'all': True})
        
        return {"success": True, "message": "Successfully deleted appointments"}
    except Exception as e:
        return {"success": False, "message": str(e)}

# --- Bulk Doctor Management ---

import pandas as pd
import io

async def bulk_add_doctors_preview(file: UploadFile):
    try:
        content = await file.read()
        df = None
        if file.filename.endswith('.csv'):
            df = pd.read_csv(io.BytesIO(content))
        elif file.filename.endswith(('.xlsx', '.xls')):
            df = pd.read_excel(io.BytesIO(content))
        else:
            return {"success": False, "message": "Unsupported format"}
            
        data = df.to_dict('records')
        preview = []
        errors = []
        
        for i, row in enumerate(data):
            name = row.get('name') or row.get('Name')
            email = row.get('email') or row.get('Email')
            
            if not name or not email:
                errors.append({"row": i+2, "reason": "Missing details"})
                continue
                
            preview.append({
                "row": i+2,
                "name": name,
                "email": email,
                "speciality": row.get('speciality', 'General physician'),
                "degree": row.get('degree', 'MBBS'),
                "experience": row.get('experience', '1 Year'),
                "fees": float(row.get('fees', 500)),
                "address": {"line1": row.get('addressLine1', ''), "line2": row.get('addressLine2', '')},
                "password": f"pms{random_string(5)}"
            })
            
        return {"success": True, "preview": preview, "errors": errors}
    except Exception as e:
        return {"success": False, "message": str(e)}

def random_string(n):
    import random, string
    return ''.join(random.choices(string.ascii_lowercase + string.digits, k=n))

async def bulk_add_doctors(preview_data: list):
    try:
        success_count = 0
        for doc in preview_data:
            hashed_password = get_password_hash(doc['password'])
            def get_gender(name):
                female_names = ["priya", "sneha", "anjali", "meera", "kavita", "swati", "amrita", "lekha", "riya", "sunita", "deepa", "pooja", "nandini", "kaveri", "shanti", "anita", "divya", "sonia", "kajal", "rekha", "maya", "swapna", "ananya", "lakshmi", "saraswati", "padma", "haritha", "bhavani", "anitha", "sridevi", "kavitha", "vyshnavi", "meena"]
                name_lower = name.lower()
                return "female" if any(f in name_lower for f in female_names) else "male"

            image_url = f"https://ui-avatars.com/api/?name={doc['name'].replace(' ', '+')}&background=0ea5e9&color=ffffff"
            
            doctor_data = {
                **doc,
                "password": hashed_password,
                "image": image_url,
                "date": int(time.time() * 1000)
            }
            await doctor_model.create_doctor(doctor_data)
            success_count += 1
            
        return {"success": True, "message": f"Successfully added {success_count} doctors"}
    except Exception as e:
        return {"success": False, "message": str(e)}

# --- Data Export ---

from app.utils import data_exporter
from fastapi.responses import Response

async def export_data(table_name: str):
    valid_tables = ['users', 'doctors', 'appointments', 'hospitals', 'hospital_tieups', 'job_applications']
    if table_name not in valid_tables:
        return {"success": False, "message": "Invalid table"}
        
    excel_data = await data_exporter.export_table_to_excel(table_name)
    if not excel_data:
        return {"success": False, "message": "No data found"}
        
    return Response(
        content=excel_data,
        media_type="application/vnd.openxmlformats-officedocument.spreadsheetml.sheet",
        headers={"Content-Disposition": f"attachment; filename={table_name}_export.xlsx"}
    )


async def get_all_users():
    try:
        users = await user_model.get_all_users_minimal()
        return {"success": True, "users": [format_user(u) for u in users]}
    except Exception as e:
        return {"success": False, "message": str(e)}

async def _get_hospital_doctors_merged(hospital_id: int):
    """Internal helper to get both regular and tie-up doctors for a hospital"""
    from app.models import hospital_model
    # 1. Get regular doctors assigned to this hospital
    assigned_docs = await doctor_model.get_doctors_by_hospital_id(hospital_id)
    real_doctors = [format_doctor(doc) for doc in assigned_docs]
    
    seen_names = {d['name'].lower().strip() for d in real_doctors if d and d.get('name')}
    
    # 2. Get embedded doctors (from hospital-specific roster)
    embedded_docs = await hospital_model.get_hospital_tieup_doctors(hospital_id)
    for doc in embedded_docs:
        name_key = doc['name'].lower().strip()
        if name_key not in seen_names:
            real_doctors.append({
                "_id": f"emb_{doc['id']}",
                "name": doc['name'],
                "speciality": doc['specialization'],
                "degree": doc['qualification'],
                "experience": doc['experience'],
                "about": doc.get('about', f"Specialist"),
                "fees": doc.get('fees', 500),
                "image": doc['image'],
                "available": doc.get('available', True)
            })
            seen_names.add(name_key)
    return real_doctors
