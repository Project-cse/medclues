import React, { useContext, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import axios from 'axios'
import { AppContext } from '../context/AppContext'

const STEPS = [
  ['consultation', 'Consultation'],
  ['investigation', 'Blood Test / Investigation'],
  ['report', 'Report'],
  ['referral', 'Specialist Referral'],
  ['specialist_appointment', 'Specialist Visit'],
  ['followup', 'Follow-up'],
]

const iconFor = (value) => {
  const v = String(value || '').toUpperCase()
  if (['COMPLETED', 'REVIEWED', 'CONFIRMED', 'AVAILABLE'].includes(v)) return '✅'
  if (['PENDING_REVIEW', 'APPOINTMENT_PENDING', 'OVERDUE', 'MISSED', 'ACTION_NEEDED'].includes(v)) return '⚠️'
  if (['UPCOMING', 'SCHEDULED', 'REMINDED'].includes(v)) return '📅'
  if (v === 'NONE') return '—'
  return '•'
}

const MyCareJourney = () => {
  const { token, backendUrl } = useContext(AppContext)
  const navigate = useNavigate()
  const [data, setData] = useState(null)
  const [loading, setLoading] = useState(true)

  useEffect(() => {
    if (!token) {
      navigate('/login?mode=login')
      return
    }
    let cancelled = false
    const load = async () => {
      try {
        const { data: res } = await axios.get(`${backendUrl}/api/ai/my-care-journey`, {
          headers: { token },
        })
        if (!cancelled) setData(res)
      } catch (e) {
        if (!cancelled) setData({ success: false, message: e.message })
      } finally {
        if (!cancelled) setLoading(false)
      }
    }
    load()
    return () => { cancelled = true }
  }, [token, backendUrl, navigate])

  const care = data?.care || data?.journey || {}
  const onTrack = data?.journey_status === 'ON_TRACK'

  return (
    <div className="py-8 max-w-3xl mx-auto">
      <h1 className="text-2xl font-extrabold text-slate-900">My Care Journey</h1>
      <p className="text-sm text-slate-500 mt-1">A simple view of your hospital visit, tests, referrals, and follow-up.</p>

      {loading ? (
        <p className="mt-8 text-sm text-slate-400">Loading your journey…</p>
      ) : (
        <>
          <div className={`mt-6 rounded-2xl border px-4 py-3 font-bold ${onTrack ? 'bg-emerald-50 border-emerald-100 text-emerald-800' : 'bg-amber-50 border-amber-100 text-amber-800'}`}>
            JOURNEY: {onTrack ? '🟢 ON TRACK' : '🟡 ACTION NEEDED'}
          </div>

          <div className="mt-6 bg-white rounded-2xl border border-slate-200 divide-y">
            {STEPS.map(([key, label]) => (
              <div key={key} className="flex items-center justify-between px-4 py-3">
                <span className="text-sm font-semibold text-slate-700">{label}</span>
                <span className="text-sm font-bold text-slate-800">
                  {iconFor(care[key])} {String(care[key] || 'None').replaceAll('_', ' ')}
                </span>
              </div>
            ))}
          </div>

          <div className="mt-6">
            <h2 className="text-sm font-black uppercase tracking-wide text-slate-500">Notifications</h2>
            {(data?.notifications || []).length === 0 ? (
              <p className="text-sm text-slate-400 mt-2">No recent notifications.</p>
            ) : (
              <ul className="mt-2 space-y-2">
                {data.notifications.map((n) => (
                  <li key={n.id} className="rounded-xl border border-slate-100 bg-slate-50 px-3 py-2">
                    <p className="text-sm font-semibold text-slate-800">{n.title}</p>
                    <p className="text-xs text-slate-500">{n.body}</p>
                  </li>
                ))}
              </ul>
            )}
          </div>
        </>
      )}
    </div>
  )
}

export default MyCareJourney
