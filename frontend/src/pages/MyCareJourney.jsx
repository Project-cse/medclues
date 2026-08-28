import React, { useContext, useEffect, useState, useCallback } from 'react'

import { useNavigate } from 'react-router-dom'

import axios from 'axios'

import { toast } from 'react-toastify'

import { AppContext } from '../context/AppContext'
import { fetchDoctorSlots, invalidateDoctorSlots } from '../utils/slotCache'



const STEPS = [

  ['registration', 'Registration'],

  ['problem', 'Problem reported'],

  ['doctor_accepted', 'Doctor accepted'],

  ['consultation', 'Consultation'],

  ['investigation', 'Investigation'],

  ['report', 'Lab report'],

  ['doctor_review', 'Doctor review'],

  ['pharmacy', 'Pharmacy'],

  ['referral', 'Referral'],

  ['specialist_appointment', 'Specialist appointment'],

  ['followup', 'Follow-up'],

]



const statusDot = (tone) => ({ ok: '🟢', warn: '🟡', danger: '🔴', muted: '⚪' }[tone] || '⚪')

const journeyBanner = (status) => {
  const s = String(status || '').toUpperCase()
  if (s === 'ON_TRACK') return { text: '🟢 ON TRACK', cls: 'bg-emerald-50 border-emerald-100 text-emerald-800' }
  if (s === 'UPCOMING') return { text: '🟡 UPCOMING', cls: 'bg-amber-50 border-amber-100 text-amber-800' }
  if (s === 'OVERDUE') return { text: '🔴 OVERDUE', cls: 'bg-rose-50 border-rose-100 text-rose-800' }
  return { text: '🟡 ACTION NEEDED', cls: 'bg-amber-50 border-amber-100 text-amber-800' }
}



const reportUrl = (backendUrl, id, token, download = false) => {

  const q = new URLSearchParams({ token })

  if (download) q.set('download', '1')

  return `${backendUrl}/api/investigations/${id}/report?${q.toString()}`

}



const formatSlotDay = (slotDate) => {

  const parts = String(slotDate || '').split('_')

  if (parts.length !== 3) return slotDate

  const [d, m, y] = parts

  return new Date(`${y}-${m}-${d}`).toLocaleDateString('en-US', { month: 'short', day: 'numeric' })

}



const SpecialistReferralBooking = ({ referral, backendUrl, token, onBooked }) => {

  const [slots, setSlots] = useState([])

  const [loadingSlots, setLoadingSlots] = useState(false)

  const [booking, setBooking] = useState(false)



  useEffect(() => {

    if (!referral?.specialist_id || !referral.bookable) return

    let cancelled = false

    const load = async () => {

      setLoadingSlots(true)

      try {

        const data = await fetchDoctorSlots(backendUrl, referral.specialist_id, 'offline')

        if (cancelled) return

        const flat = []

        for (const day of data?.days || []) {

          for (const block of day.blocks || []) {

            if (block.bookable !== false && (block.available_count ?? 1) > 0) {

              flat.push({

                slotDate: day.slotDate,

                slotTime: block.display,

                slotId: block.slot_id || block.representative_slot_id,

                dayLabel: formatSlotDay(day.slotDate),

              })

            }

          }

        }

        setSlots(flat.slice(0, 12))

      } catch (e) {

        console.warn('Could not load specialist slots', e)

      } finally {

        if (!cancelled) setLoadingSlots(false)

      }

    }

    load()

    return () => { cancelled = true }

  }, [referral?.specialist_id, referral?.bookable, backendUrl])



  const bookSlot = async (slot) => {

    setBooking(true)

    try {

      const { data } = await axios.post(

        `${backendUrl}/api/referrals/${referral.id}/book`,

        {

          slotDate: slot.slotDate,

          slotTime: slot.slotTime,

          slotId: slot.slotId,

          paymentMethod: 'payOnVisit',

        },

        { headers: { token } }

      )

      if (data.success) {

        toast.success('Specialist appointment booked')

        invalidateDoctorSlots(referral.specialist_id)

        onBooked?.()

      } else {

        toast.error(data.message || 'Booking failed')

      }

    } catch (e) {

      toast.error(e.response?.data?.detail || e.message || 'Booking failed')

    } finally {

      setBooking(false)

    }

  }



  if (!referral.bookable) return null



  return (

    <div className="mt-3 pt-3 border-t border-slate-100">

      <p className="text-xs font-bold text-slate-500 uppercase tracking-wide">Available appointments</p>

      {loadingSlots ? (

        <p className="text-xs text-slate-400 mt-2">Loading slots…</p>

      ) : slots.length === 0 ? (

        <p className="text-xs text-slate-400 mt-2">No slots available yet — check back soon.</p>

      ) : (

        <div className="flex flex-wrap gap-2 mt-2">

          {slots.map((s) => (

            <button

              key={`${s.slotDate}-${s.slotTime}`}

              type="button"

              disabled={booking}

              onClick={() => bookSlot(s)}

              className="px-3 py-1.5 rounded-lg border border-indigo-200 bg-indigo-50 text-indigo-800 text-xs font-bold hover:bg-indigo-100 disabled:opacity-50"

            >

              {s.dayLabel} · {s.slotTime}

            </button>

          ))}

        </div>

      )}

    </div>

  )

}



const CACHE_KEY = 'myCareJourneyCache_v3'
const CACHE_MS = 2 * 60 * 1000

const formatDoctorName = (name) => {
  if (!name) return null
  let s = String(name).trim()
  if (/^dr\.?\s/i.test(s)) s = s.replace(/^dr\.?\s+/i, '').trim()
  return s ? `Dr. ${s}` : null
}

const EpisodeDetails = ({ episode, backendUrl, token, onBooked, showReferralBooking = true }) => {
  const care = episode?.care || {}
  const careTones = episode?.care_tones || {}
  const referrals = episode?.referrals || []
  const reports = episode?.reports || []
  const banner = journeyBanner(episode?.journey_status)

  return (
    <>
      <div className={`rounded-2xl border px-4 py-3 font-bold ${banner.cls}`}>
        JOURNEY: {banner.text}
      </div>

      <div className="mt-6 bg-white rounded-2xl border border-slate-200 divide-y">
        {STEPS.map(([key, label]) => (
          <div key={key} className="flex items-center justify-between px-4 py-3">
            <span className="text-sm font-semibold text-slate-700">{label}</span>
            <span className="text-sm font-bold text-slate-800 text-right max-w-[60%]">
              {statusDot(careTones[key])} {care[key] || '— Not yet created'}
            </span>
          </div>
        ))}
      </div>

      {referrals.length > 0 && (
        <div className="mt-6">
          <h2 className="text-sm font-black uppercase tracking-wide text-slate-500">Specialist referrals</h2>
          <ul className="mt-2 space-y-3">
            {referrals.map((ref) => (
              <li key={ref.id} className="rounded-xl border border-sky-100 bg-sky-50/50 px-4 py-3">
                <div className="flex justify-between gap-2">
                  <div>
                    <p className="text-sm font-bold text-slate-800">{ref.to_dept}</p>
                    <p className="text-xs text-slate-600 mt-0.5">
                      {ref.specialist_name ? `Dr. ${ref.specialist_name}` : 'Specialist pending'}
                      {ref.referring_doctor_name ? ` · Referred by ${ref.referring_doctor_name}` : ''}
                    </p>
                    {ref.reason && <p className="text-xs text-slate-500 mt-1">{ref.reason}</p>}
                  </div>
                  <span className="text-xs font-bold text-sky-700 shrink-0">
                    {String(ref.status || '').replaceAll('_', ' ')}
                  </span>
                </div>
                {showReferralBooking && (
                  <SpecialistReferralBooking
                    referral={ref}
                    backendUrl={backendUrl}
                    token={token}
                    onBooked={onBooked}
                  />
                )}
              </li>
            ))}
          </ul>
        </div>
      )}

      {reports.length > 0 && (
        <div className="mt-6">
          <h2 className="text-sm font-black uppercase tracking-wide text-slate-500">Lab reports</h2>
          <ul className="mt-2 space-y-2">
            {reports.map((r) => {
              const published = ['REPORT_AVAILABLE', 'REVIEWED'].includes(String(r.status || '').toUpperCase())
              return (
                <li key={r.id} className="rounded-xl border border-slate-100 bg-white px-3 py-2 flex flex-wrap justify-between gap-2 items-center">
                  <span className="text-sm font-semibold text-slate-800">{r.test_name}</span>
                  {published && r.id ? (
                    <span className="flex gap-2">
                      <a href={reportUrl(backendUrl, r.id, token)} target="_blank" rel="noopener noreferrer" className="text-xs font-bold text-indigo-600">
                        View report
                      </a>
                      <a href={reportUrl(backendUrl, r.id, token, true)} download={`${r.test_name || 'report'}.pdf`} className="text-xs font-bold text-indigo-600">
                        Download PDF
                      </a>
                    </span>
                  ) : (
                    <span className="text-xs text-slate-400">{String(r.status || 'Pending').replaceAll('_', ' ')}</span>
                  )}
                </li>
              )
            })}
          </ul>
        </div>
      )}
    </>
  )
}

const PastJourneyPanel = ({ episodes, onClose, backendUrl, token }) => {
  const [expandedId, setExpandedId] = useState(null)

  return (
    <div className="fixed inset-0 z-50 flex justify-end">
      <button type="button" className="absolute inset-0 bg-slate-900/40" onClick={onClose} aria-label="Close history" />
      <div className="relative w-full max-w-md bg-white h-full shadow-2xl flex flex-col">
        <div className="flex items-center justify-between px-4 py-4 border-b border-slate-200">
          <h2 className="text-lg font-extrabold text-slate-900">Past My Journey</h2>
          <button type="button" onClick={onClose} className="text-slate-500 hover:text-slate-800 text-sm font-bold px-2 py-1">
            Close
          </button>
        </div>
        <div className="flex-1 overflow-y-auto p-4 space-y-3">
          {episodes.length === 0 ? (
            <p className="text-sm text-slate-400">No past visits yet.</p>
          ) : (
            episodes.map((ep) => {
              const epKey = ep.appointment_id || ep.label
              const isOpen = expandedId === epKey
              const epBanner = journeyBanner(ep.journey_status)
              return (
                <div key={epKey} className="rounded-xl border border-slate-200 bg-slate-50/50 overflow-hidden">
                  <button
                    type="button"
                    onClick={() => setExpandedId(isOpen ? null : epKey)}
                    className="w-full text-left px-4 py-3 flex items-start justify-between gap-2 hover:bg-slate-50"
                  >
                    <div>
                      <p className="text-sm font-bold text-slate-800">{ep.label || 'Past visit'}</p>
                      <p className={`text-xs font-semibold mt-1 ${epBanner.cls} inline-block px-2 py-0.5 rounded-lg border`}>
                        {epBanner.text.replace('JOURNEY: ', '')}
                      </p>
                    </div>
                    <span className="text-slate-400 text-xs shrink-0 mt-1">{isOpen ? '▲' : '▼'}</span>
                  </button>
                  {isOpen && (
                    <div className="px-4 pb-4 border-t border-slate-100">
                      <EpisodeDetails
                        episode={ep}
                        backendUrl={backendUrl}
                        token={token}
                        showReferralBooking={false}
                      />
                    </div>
                  )}
                </div>
              )
            })
          )}
        </div>
      </div>
    </div>
  )
}

const MyCareJourney = () => {

  const { token, backendUrl } = useContext(AppContext)

  const navigate = useNavigate()

  const [data, setData] = useState(null)

  const [loading, setLoading] = useState(true)

  const [error, setError] = useState(null)

  const [historyOpen, setHistoryOpen] = useState(false)



  const load = useCallback(async (opts = {}) => {
    if (!token) return
    const force = Boolean(opts.force)
    let usedCache = false

    if (!force) {
      try {
        const raw = sessionStorage.getItem(CACHE_KEY)
        if (raw) {
          const { ts, data: cached } = JSON.parse(raw)
          if (cached?.active_episode) {
            setData(cached)
            setError(null)
            setLoading(false)
            usedCache = true
            if (Date.now() - ts < CACHE_MS) return
          }
        }
      } catch {
        // ignore bad cache
      }
    }

    if (!usedCache) setLoading(true)

    try {
      const { data: res } = await axios.get(`${backendUrl}/api/ai/my-care-journey`, {
        headers: { token },
        timeout: 90000,
      })

      if (res.success === false) {
        setError(res.message || 'Could not load your care journey')
      } else {
        setData(res)
        setError(null)
        try {
          sessionStorage.setItem(CACHE_KEY, JSON.stringify({ ts: Date.now(), data: res }))
        } catch {
          // ignore quota errors
        }
      }
    } catch (e) {
      if (!usedCache) {
        setError(e.response?.data?.detail || e.message || 'Could not load your care journey')
      }
    } finally {
      setLoading(false)
    }
  }, [token, backendUrl])



  useEffect(() => {
    if (!token) {
      navigate('/login?mode=login')
      return
    }
    load()
  }, [token, backendUrl, navigate, load])



  const activeEpisode = data?.active_episode || {}
  const pastEpisodes = data?.past_episodes || []
  const hasActiveAppointment = Boolean(data?.has_active_appointment)



  return (

    <div className="py-8 max-w-3xl mx-auto px-4">

      <div className="flex items-start justify-between gap-3">
        <h1 className="text-2xl font-extrabold text-slate-900">My Care Journey</h1>
        {!loading && !error && pastEpisodes.length > 0 && (
          <button
            type="button"
            onClick={() => setHistoryOpen(true)}
            title="Past My Journey"
            className="shrink-0 w-10 h-10 rounded-xl border border-slate-200 bg-white text-slate-600 hover:bg-slate-50 hover:text-indigo-700 flex items-center justify-center text-lg"
            aria-label="Past My Journey"
          >
            ↩
          </button>
        )}
      </div>



      {loading ? (

        <div className="mt-8 space-y-3 animate-pulse">
          <div className="h-12 rounded-2xl bg-slate-100" />
          <div className="h-24 rounded-2xl bg-slate-100" />
          <div className="h-24 rounded-2xl bg-slate-100" />
        </div>

      ) : error ? (

        <p className="mt-6 text-sm text-rose-600 font-semibold">{error}</p>

      ) : (

        <>
          {(hasActiveAppointment || activeEpisode.doctor_name) && (
            <p className="mt-4 text-sm text-slate-600">
              Current visit: <span className="font-bold text-slate-800">{formatDoctorName(activeEpisode.doctor_name) || activeEpisode.doctor_name || 'Your doctor'}</span>
              {activeEpisode.slot_date ? ` · ${formatSlotDay(activeEpisode.slot_date)}` : ''}
            </p>
          )}

          <div className="mt-6">
            <EpisodeDetails
              episode={activeEpisode}
              backendUrl={backendUrl}
              token={token}
              onBooked={() => load({ force: true })}
            />
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

          {historyOpen && (
            <PastJourneyPanel
              episodes={pastEpisodes}
              onClose={() => setHistoryOpen(false)}
              backendUrl={backendUrl}
              token={token}
            />
          )}

        </>

      )}

    </div>

  )

}



export default MyCareJourney

