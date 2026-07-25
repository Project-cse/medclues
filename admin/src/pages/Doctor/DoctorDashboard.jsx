import React, { useContext, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'
import { toast } from 'react-toastify'
import { DoctorContext } from '../../context/DoctorContext'
import { AppContext } from '../../context/AppContext'
import AnimatedCounter from '../../components/ui/AnimatedCounter'
import { getPatientName, getPatientAge, getPatientImage } from '../../utils/appointmentDisplay'
import { isOnlineVideoAppointment } from '../../utils/videoConsult'
import CompleteConsultationModal from '../../components/CompleteConsultationModal'
import { DeskPage, DeskHeader, DeskKpi, DeskBtn } from '../../components/desk/DeskChrome'
import { McCard } from '../../components/mc'

const WEEK_DAYS = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun']

const STATUS_OPTIONS = [
  { value: 'available', label: 'Available', dot: 'bg-emerald-500', activeCls: 'bg-emerald-50 border-emerald-300 text-emerald-700 ring-emerald-400' },
  { value: 'in-clinic', label: 'In-clinic', dot: 'bg-sky-500', activeCls: 'bg-sky-50 border-sky-300 text-sky-700 ring-sky-400' },
  { value: 'emergency', label: 'Emergency', dot: 'bg-rose-500', activeCls: 'bg-rose-50 border-rose-300 text-rose-700 ring-rose-400' },
  { value: 'offline', label: 'Offline', dot: 'bg-slate-400', activeCls: 'bg-slate-100 border-slate-300 text-slate-700 ring-slate-400' },
]

const DoctorDashboard = () => {
  const { dToken, backendUrl, dashData, getDashData, cancelAppointment, completeAppointment, profileData, getProfileData } = useContext(DoctorContext)
  const { slotDateFormat, calculateAge, currency } = useContext(AppContext)
  const [currentTime, setCurrentTime] = useState(new Date())
  const [completeTarget, setCompleteTarget] = useState(null)
  const [completing, setCompleting] = useState(false)
  const [sched, setSched] = useState({
    opStart: '09:00',
    opEnd: '13:00',
    opStartAfternoon: '16:00',
    opEndAfternoon: '20:00',
    maxAppointmentsMorning: 20,
    maxAppointmentsAfternoon: 20,
    days: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri']
  })
  const [savingStatus, setSavingStatus] = useState(false)
  const [savingSched, setSavingSched] = useState(false)
  const navigate = useNavigate()

  const handleCompleteSubmit = async (consultationData) => {
    if (!completeTarget) return
    setCompleting(true)
    const ok = await completeAppointment(completeTarget._id, consultationData)
    setCompleting(false)
    if (ok) setCompleteTarget(null)
  }

  useEffect(() => {
    if (dToken) {
      getDashData()
      getProfileData()
    }
  }, [dToken])

  // Initialize scheduling editor from the doctor's saved profile.
  useEffect(() => {
    if (!profileData) return
    setSched({
      opStart: profileData.opStart || '09:00',
      opEnd: profileData.opEnd || '13:00',
      opStartAfternoon: profileData.opStartAfternoon || '16:00',
      opEndAfternoon: profileData.opEndAfternoon || '20:00',
      maxAppointmentsMorning: profileData.maxAppointmentsMorning || 20,
      maxAppointmentsAfternoon: profileData.maxAppointmentsAfternoon || 20,
      days: Array.isArray(profileData.availableDays) && profileData.availableDays.length
        ? profileData.availableDays
        : ['Mon', 'Tue', 'Wed', 'Thu', 'Fri'],
    })
  }, [profileData])

  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000)
    return () => clearInterval(timer)
  }, [])

  // Persist a partial profile change via the existing update-profile endpoint.
  // address/fees/about are always sent so they are not wiped server-side.
  const saveProfile = async (overrides = {}, successMsg) => {
    try {
      const fd = new FormData()
      fd.append('address', JSON.stringify(profileData?.address || { line1: '', line2: '' }))
      fd.append('fees', String(profileData?.fees ?? 0))
      fd.append('about', profileData?.about || '')
      if (overrides.status !== undefined) fd.append('status', overrides.status)
      if (overrides.opStart !== undefined) fd.append('opStart', overrides.opStart)
      if (overrides.opEnd !== undefined) fd.append('opEnd', overrides.opEnd)
      if (overrides.opStartAfternoon !== undefined) fd.append('opStartAfternoon', overrides.opStartAfternoon)
      if (overrides.opEndAfternoon !== undefined) fd.append('opEndAfternoon', overrides.opEndAfternoon)
      if (overrides.maxAppointmentsMorning !== undefined) fd.append('maxAppointmentsMorning', String(overrides.maxAppointmentsMorning))
      if (overrides.maxAppointmentsAfternoon !== undefined) fd.append('maxAppointmentsAfternoon', String(overrides.maxAppointmentsAfternoon))
      if (overrides.availableDays !== undefined) fd.append('availableDays', JSON.stringify(overrides.availableDays))
      const { data } = await axios.post(backendUrl + '/api/doctor/update-profile', fd, { headers: { dToken } })
      if (data.success) {
        if (successMsg) toast.success(successMsg)
        getProfileData()
        return true
      }
      toast.error(data.message || 'Could not save')
      return false
    } catch (e) {
      toast.error(e.response?.data?.message || e.message || 'Could not save')
      return false
    }
  }

  const handleStatusChange = async (value, label) => {
    if (savingStatus) return
    setSavingStatus(true)
    await saveProfile({ status: value }, `Status updated to ${label}`)
    setSavingStatus(false)
  }

  const toggleDay = (day) => {
    setSched((prev) => ({
      ...prev,
      days: prev.days.includes(day) ? prev.days.filter((d) => d !== day) : [...prev.days, day],
    }))
  }

  const handleScheduleSave = async () => {
    if (savingSched) return
    if (!sched.opStart || !sched.opEnd || !sched.opStartAfternoon || !sched.opEndAfternoon) {
      toast.error('Please set both morning and afternoon OP timings')
      return
    }
    if (sched.days.length === 0) {
      toast.error('Select at least one available day')
      return
    }
    setSavingSched(true)
    await saveProfile(
      { 
        opStart: sched.opStart, 
        opEnd: sched.opEnd, 
        opStartAfternoon: sched.opStartAfternoon,
        opEndAfternoon: sched.opEndAfternoon,
        maxAppointmentsMorning: sched.maxAppointmentsMorning,
        maxAppointmentsAfternoon: sched.maxAppointmentsAfternoon,
        availableDays: sched.days 
      },
      'Schedule updated'
    )
    setSavingSched(false)
  }

  const currentStatus = profileData?.status || (profileData?.available === false ? 'offline' : 'available')

  const formatTime = (date) =>
    date.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true })

  const formatDate = (date) =>
    date.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })

  if (!dashData) {
    return (
      <DeskPage>
        <div className="flex items-center justify-center min-h-[60vh]">
          <div className="text-center">
            <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-500 mx-auto" />
            <p className="mt-4 text-rd-muted">Loading dashboard...</p>
          </div>
        </div>
      </DeskPage>
    )
  }

  return (
    <DeskPage>
      <DeskHeader
        title={`Good day, ${profileData?.name || 'Doctor'}`}
        subtitle={`${formatDate(currentTime)} · ${formatTime(currentTime)}`}
        right={<DeskBtn onClick={() => getDashData()}>Refresh</DeskBtn>}
      />

      <div className="grid grid-cols-1 sm:grid-cols-3 gap-3 sm:gap-4">
        <DeskKpi
          label="Revenue"
          value={`${currency}${dashData.earnings ? dashData.earnings.toLocaleString() : '0'}`}
          tone="emerald"
          icon={<svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>}
        />
        <DeskKpi
          label="Appointments"
          value={<AnimatedCounter value={dashData.appointments || 0} duration={2000} />}
          tone="violet"
          onClick={() => navigate('/doctor-appointments')}
          icon={<svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" /></svg>}
        />
        <DeskKpi
          label="Total Patients"
          value={<AnimatedCounter value={dashData.patients || 0} duration={2000} />}
          tone="teal"
          onClick={() => navigate('/doctor-appointments')}
          icon={<svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" /></svg>}
        />
      </div>

      <div className="rd-card rd-soft bg-rd-surface rounded-[16px] border border-rd-border px-3.5 py-3">
        <div className="flex items-center gap-3 flex-wrap">
          <h2 className="text-sm font-bold text-rd-text shrink-0">Quick Actions</h2>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-2 flex-1 min-w-0">
            {[
              { label: 'Queue Manager', to: '/doctor-in-queue', bg: 'bg-indigo-500' },
              { label: 'Video Calls', to: '/doctor-video-calls', bg: 'bg-sky-500' },
              { label: 'Patients', to: '/doctor-patients', bg: 'bg-teal-500' },
              { label: 'Profile', to: '/doctor-profile', bg: 'bg-violet-500' },
            ].map((a) => (
              <button
                key={a.to}
                type="button"
                onClick={() => navigate(a.to)}
                className={`${a.bg} text-white text-[11px] font-semibold rounded-xl px-2 py-2.5 text-center hover:opacity-90`}
              >
                {a.label}
              </button>
            ))}
          </div>
        </div>
      </div>

      {/* Availability status + Scheduling */}
      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        {/* Status buttons */}
        <McCard title="My Availability">
          <p className="text-xs text-mc-text-muted mb-3">Set your current consultation status — patients see this instantly.</p>
          <div className="grid grid-cols-2 sm:grid-cols-4 gap-3">
            {STATUS_OPTIONS.map((opt) => {
              const active = currentStatus === opt.value
              return (
                <button
                  key={opt.value}
                  type="button"
                  disabled={savingStatus}
                  onClick={() => handleStatusChange(opt.value, opt.label)}
                  className={`flex flex-col items-center gap-2 p-4 rounded-xl border-2 transition-all disabled:opacity-60 ${
                    active
                      ? `${opt.activeCls} ring-2 ring-offset-2`
                      : 'bg-white border-mc-border hover:border-slate-300 text-mc-text'
                  }`}
                >
                  <span className={`w-3 h-3 rounded-full ${opt.dot} shadow-sm`} />
                  <span className="text-xs font-bold uppercase tracking-wider">{opt.label}</span>
                </button>
              )
            })}
          </div>
        </McCard>

        {/* Scheduling & Consultation */}
        <McCard title="Scheduling & Consultation">
          <div className="space-y-4">
            {/* Morning Session */}
            <div>
              <div className="flex justify-between items-center mb-1">
                <label className="block text-xs font-semibold text-mc-text uppercase tracking-wider text-sky-600">Morning Session Timings *</label>
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Capacity / Slots</span>
              </div>
              <div className="flex items-center gap-3">
                <div className="flex-1 flex items-center gap-2">
                  <input
                    type="time"
                    value={sched.opStart}
                    onChange={(e) => setSched((p) => ({ ...p, opStart: e.target.value }))}
                    className="flex-1 px-3 py-2 border border-mc-border rounded-lg text-sm bg-white outline-none focus:ring-2 focus:ring-sky-500/30 focus:border-sky-400"
                  />
                  <span className="text-xs text-mc-text-muted">to</span>
                  <input
                    type="time"
                    value={sched.opEnd}
                    onChange={(e) => setSched((p) => ({ ...p, opEnd: e.target.value }))}
                    className="flex-1 px-3 py-2 border border-mc-border rounded-lg text-sm bg-white outline-none focus:ring-2 focus:ring-sky-500/30 focus:border-sky-400"
                  />
                </div>
                <div className="w-24 shrink-0">
                  <input
                    type="number"
                    min="1"
                    max="100"
                    value={sched.maxAppointmentsMorning}
                    onChange={(e) => setSched((p) => ({ ...p, maxAppointmentsMorning: parseInt(e.target.value) || '' }))}
                    className="w-full px-3 py-2 border border-mc-border rounded-lg text-sm bg-white outline-none focus:ring-2 focus:ring-sky-500/30 focus:border-sky-400 text-center font-bold text-slate-700"
                  />
                </div>
              </div>
            </div>

            {/* Afternoon Session */}
            <div>
              <div className="flex justify-between items-center mb-1">
                <label className="block text-xs font-semibold text-mc-text uppercase tracking-wider text-teal-600">Afternoon / Evening Session *</label>
                <span className="text-[10px] font-bold text-slate-400 uppercase tracking-wider">Capacity / Slots</span>
              </div>
              <div className="flex items-center gap-3">
                <div className="flex-1 flex items-center gap-2">
                  <input
                    type="time"
                    value={sched.opStartAfternoon}
                    onChange={(e) => setSched((p) => ({ ...p, opStartAfternoon: e.target.value }))}
                    className="flex-1 px-3 py-2 border border-mc-border rounded-lg text-sm bg-white outline-none focus:ring-2 focus:ring-sky-500/30 focus:border-sky-400"
                  />
                  <span className="text-xs text-mc-text-muted">to</span>
                  <input
                    type="time"
                    value={sched.opEndAfternoon}
                    onChange={(e) => setSched((p) => ({ ...p, opEndAfternoon: e.target.value }))}
                    className="flex-1 px-3 py-2 border border-mc-border rounded-lg text-sm bg-white outline-none focus:ring-2 focus:ring-sky-500/30 focus:border-sky-400"
                  />
                </div>
                <div className="w-24 shrink-0">
                  <input
                    type="number"
                    min="1"
                    max="100"
                    value={sched.maxAppointmentsAfternoon}
                    onChange={(e) => setSched((p) => ({ ...p, maxAppointmentsAfternoon: parseInt(e.target.value) || '' }))}
                    className="w-full px-3 py-2 border border-mc-border rounded-lg text-sm bg-white outline-none focus:ring-2 focus:ring-sky-500/30 focus:border-sky-400 text-center font-bold text-slate-700"
                  />
                </div>
              </div>
            </div>

            <div>
              <label className="block text-xs font-semibold text-mc-text mb-1.5">Available Days *</label>
              <div className="flex flex-wrap gap-2">
                {WEEK_DAYS.map((day) => {
                  const active = sched.days.includes(day)
                  return (
                    <button
                      key={day}
                      type="button"
                      onClick={() => toggleDay(day)}
                      className={`px-3.5 py-2 rounded-lg text-xs font-bold transition-all ${
                        active
                          ? 'bg-teal-500 text-white shadow-sm'
                          : 'bg-slate-100 text-slate-500 hover:bg-slate-200'
                      }`}
                    >
                      {day}
                    </button>
                  )
                })}
              </div>
            </div>
            <button
              type="button"
              onClick={handleScheduleSave}
              disabled={savingSched}
              className="mc-btn mc-btn--primary w-full sm:w-auto disabled:opacity-60"
            >
              {savingSched ? 'Saving…' : 'Save Schedule'}
            </button>
          </div>
        </McCard>
      </div>

      {/* Video consultations */}
      <McCard title="Video Consultations" noPadding>
        <div className="px-5 py-2 text-xs text-mc-text-muted border-b border-mc-border">Paid online appointments ready for video call</div>
        <div className="divide-y divide-mc-border max-h-[360px] overflow-y-auto">
          {(!dashData.todayVideoConsults || dashData.todayVideoConsults.length === 0) ? (
            <div className="flex flex-col items-center justify-center py-12 text-mc-text-muted">
              <svg className="w-12 h-12 mb-2 text-sky-200" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>
              <p className="text-sm font-semibold text-mc-text">No active video consultations</p>
              <p className="text-xs">You currently have no ongoing video consultations.</p>
            </div>
          ) : (
            dashData.todayVideoConsults.map((item, index) => (
              <div key={item._id || index} className="flex flex-col sm:flex-row sm:items-center gap-3 px-5 py-3 hover:bg-sky-50/40 transition-colors">
                <div className="flex items-center gap-3 flex-1 min-w-0">
                  <img className="rounded-full w-10 h-10 object-cover ring-2 ring-sky-100 shrink-0" src={getPatientImage(item)} alt="" />
                  <div className="min-w-0 flex-1">
                    <p className="text-mc-text font-bold text-sm truncate">{getPatientName(item)}</p>
                    <p className="text-xs text-mc-text-muted mt-0.5">{item.slotTime || 'Time TBD'} · Age {getPatientAge(item, calculateAge)}</p>
                    <p className="text-[10px] mt-1">
                      <span className={`inline-flex px-2 py-0.5 rounded-full font-semibold ${item.payment ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'}`}>
                        {item.payment ? 'Paid' : 'Payment pending'}
                      </span>
                      <span className="text-mc-text-muted mx-1">·</span>
                      <span className="text-mc-text-muted">{currency}{item.amount}</span>
                    </p>
                  </div>
                </div>
                {isOnlineVideoAppointment(item) && !item.cancelled && !item.isCompleted && (
                  <button type="button" onClick={() => navigate(`/doctor-video/${item._id}`)}
                    className="mc-btn mc-btn--primary shrink-0">
                    <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>
                    Join Video Call
                  </button>
                )}
              </div>
            ))
          )}
        </div>
      </McCard>

      {/* Latest appointments */}
      <McCard title="Latest Appointments" noPadding>
        <div className="px-5 py-2 text-xs text-mc-text-muted border-b border-mc-border">Recent patient appointments</div>
        <div className="divide-y divide-mc-border max-h-[400px] overflow-y-auto">
          {(!dashData.latestAppointments || dashData.latestAppointments.length === 0) ? (
            <div className="flex flex-col items-center justify-center py-12 text-mc-text-muted">
              <svg className="w-14 h-14 mb-3 text-slate-200" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" /></svg>
              <p className="text-base font-semibold text-mc-text">No appointments yet</p>
              <p className="text-xs">Your recent bookings will appear here.</p>
            </div>
          ) : (
            dashData.latestAppointments.slice(0, 10).map((item, index) => (
              <div key={index} onClick={() => navigate('/doctor-appointments?tab=today')}
                className="flex items-center px-5 py-3 gap-3 hover:bg-sky-50/40 transition-colors group cursor-pointer">
                <div className="relative shrink-0">
                  <img className="rounded-full w-10 h-10 object-cover ring-2 ring-slate-100 shadow-sm" src={getPatientImage(item)} alt="" />
                  {!item.cancelled && !item.isCompleted && (
                    <div className="absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-emerald-500 rounded-full border-2 border-white" />
                  )}
                </div>
                <div className="flex-1 min-w-0">
                  <p className="text-mc-text font-bold text-sm truncate">{getPatientName(item)}</p>
                  <div className="flex items-center gap-2 mt-1 flex-wrap text-xs text-mc-text-muted">
                    <span>Age <span className="font-semibold text-mc-text">{getPatientAge(item, calculateAge)}</span></span>
                    <span>•</span>
                    <span className="font-semibold">{slotDateFormat(item.slotDate)}</span>
                    {item.slotTime ? <span>at {item.slotTime}</span> : null}
                  </div>
                </div>
                <div className="flex items-center gap-2 shrink-0" onClick={(e) => e.stopPropagation()}>
                  {item.cancelled ? (
                    <span className="inline-flex items-center px-2 py-0.5 rounded-full bg-rose-100 text-rose-700 text-[10px] font-bold">Cancelled</span>
                  ) : item.isCompleted ? (
                    <span className="inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-emerald-100 text-emerald-700 text-[10px] font-bold">Completed</span>
                  ) : (
                    <div className="flex gap-1">
                      <button onClick={() => cancelAppointment(item._id)} className="p-1.5 rounded-md bg-rose-50 hover:bg-rose-100 text-rose-600" title="Cancel">
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M6 18L18 6M6 6l12 12" /></svg>
                      </button>
                      <button onClick={() => setCompleteTarget(item)} className="p-1.5 rounded-md bg-emerald-50 hover:bg-emerald-100 text-emerald-600" title="Complete">
                        <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" /></svg>
                      </button>
                    </div>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      </McCard>

      {completeTarget && (
        <CompleteConsultationModal
          appointment={completeTarget}
          onClose={() => setCompleteTarget(null)}
          onSubmit={handleCompleteSubmit}
          submitting={completing}
        />
      )}
    </DeskPage>
  )
}

export default DoctorDashboard
