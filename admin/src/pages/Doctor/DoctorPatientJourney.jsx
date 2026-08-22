import React, { useContext, useEffect, useMemo, useState } from 'react'
import axios from 'axios'
import { toast } from 'react-toastify'
import { DoctorContext } from '../../context/DoctorContext'
import { ReceptionContext } from '../../context/ReceptionContext'
import { DeanContext } from '../../context/DeanContext'
import { AdminPageLayout, McCard } from '../../components/mc'

const PIPELINE = [
  ['consultation', 'Consultation'],
  ['investigation', 'Investigation'],
  ['report', 'Report'],
  ['referral', 'Referral'],
  ['specialist_appointment', 'Specialist Appointment'],
  ['followup', 'Follow-up'],
]

const toneFor = (value) => {
  const v = String(value || '').toUpperCase()
  if (['COMPLETED', 'REVIEWED', 'CONFIRMED', 'ON_TRACK', 'AVAILABLE'].includes(v)) return 'ok'
  if (['PENDING_REVIEW', 'APPOINTMENT_PENDING', 'ATTENTION_REQUIRED', 'OVERDUE', 'MISSED', 'ACTION_NEEDED'].includes(v)) return 'warn'
  if (['UPCOMING', 'SCHEDULED', 'REMINDED'].includes(v)) return 'soon'
  return 'muted'
}

const Pill = ({ value }) => {
  const tone = toneFor(value)
  const cls = {
    ok: 'bg-emerald-50 text-emerald-700 border-emerald-100',
    warn: 'bg-amber-50 text-amber-800 border-amber-100',
    soon: 'bg-sky-50 text-sky-700 border-sky-100',
    muted: 'bg-slate-50 text-slate-600 border-slate-200',
  }[tone]
  const icon = tone === 'ok' ? '✅' : tone === 'warn' ? '⚠️' : tone === 'soon' ? '📅' : '•'
  return (
    <span className={`inline-flex items-center gap-1 px-2 py-0.5 rounded-full text-[11px] font-bold border ${cls}`}>
      <span>{icon}</span> {String(value || '—').replaceAll('_', ' ')}
    </span>
  )
}

const DoctorPatientJourney = () => {
  const { dToken, backendUrl } = useContext(DoctorContext)
  const { recToken } = useContext(ReceptionContext)
  const { deanToken } = useContext(DeanContext)
  const token = dToken || recToken || deanToken
  const headers = dToken
    ? { dtoken: dToken }
    : recToken
      ? { Token: recToken }
      : { deantoken: deanToken }

  const [journeys, setJourneys] = useState([])
  const [selectedId, setSelectedId] = useState(null)
  const [detail, setDetail] = useState(null)
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(false)
  const [evidenceFinding, setEvidenceFinding] = useState(null)
  const [modifyFor, setModifyFor] = useState(null)
  const [modifyDate, setModifyDate] = useState('')
  const [note, setNote] = useState('')

  const staffHeaders = useMemo(() => ({ headers }), [dToken, recToken, deanToken])

  const loadList = async () => {
    try {
      const { data } = await axios.get(`${backendUrl}/api/ai/patient-journeys`, staffHeaders)
      if (data.success) {
        setJourneys(data.journeys || [])
        if (!selectedId && data.journeys?.[0]?.patient_id) {
          setSelectedId(data.journeys[0].patient_id)
        }
      }
    } catch (e) {
      toast.error(e.response?.data?.detail || e.message)
    } finally {
      setLoading(false)
    }
  }

  const loadDetail = async (patientId) => {
    if (!patientId) return
    try {
      const { data } = await axios.post(
        `${backendUrl}/api/ai/patient-journey/${patientId}/refresh`,
        {},
        staffHeaders
      )
      setDetail(data)
    } catch (e) {
      toast.error(e.response?.data?.detail || e.message)
    }
  }

  useEffect(() => {
    if (token) loadList()
  }, [token])

  useEffect(() => {
    if (selectedId && token) loadDetail(selectedId)
  }, [selectedId, token])

  const review = async (findingId, decision, extra = {}) => {
    setBusy(true)
    try {
      const { data } = await axios.post(
        `${backendUrl}/api/ai/findings/${findingId}/review`,
        { decision, note, modifications: extra },
        staffHeaders
      )
      if (data.success) {
        toast.success(data.resolved ? 'Finding verified as resolved' : 'Review recorded')
        setNote('')
        setModifyFor(null)
        setDetail(data.journey)
        await loadList()
      } else {
        toast.error(data.message || 'Review failed')
      }
    } catch (e) {
      toast.error(e.response?.data?.detail || e.message)
    } finally {
      setBusy(false)
    }
  }

  const journey = detail?.journey || {}
  const findings = detail?.findings || []

  return (
    <AdminPageLayout>
      <div className="flex items-start justify-between gap-3 flex-wrap">
        <div>
          <h1 className="text-xl font-black text-slate-900">AI Patient Journey</h1>
          <p className="text-xs text-slate-500 mt-1">Coordination monitoring only — AI does not diagnose or replace the doctor.</p>
        </div>
        <button
          type="button"
          onClick={() => selectedId && loadDetail(selectedId)}
          className="px-3 py-2 rounded-xl bg-indigo-600 text-white text-xs font-bold"
        >
          Re-check agents
        </button>
      </div>

      <div className="grid grid-cols-1 lg:grid-cols-12 gap-4">
        <McCard title="Patients needing attention" className="lg:col-span-4">
          {loading ? (
            <p className="text-xs text-slate-400 py-6 text-center">Loading journeys…</p>
          ) : journeys.length === 0 ? (
            <p className="text-xs text-emerald-700 py-6 text-center">🟢 No open coordination findings</p>
          ) : (
            <div className="space-y-2 max-h-[640px] overflow-y-auto">
              {journeys.map((j) => (
                <button
                  key={j.patient_id}
                  type="button"
                  onClick={() => setSelectedId(j.patient_id)}
                  className={`w-full text-left p-3 rounded-xl border ${selectedId === j.patient_id ? 'border-indigo-300 bg-indigo-50' : 'border-slate-200 bg-white'}`}
                >
                  <div className="flex items-center justify-between gap-2">
                    <span className="text-sm font-bold text-slate-800">{j.patient_name || `Patient #${j.patient_id}`}</span>
                    <Pill value={j.priority} />
                  </div>
                  <p className="text-[11px] text-slate-500 mt-1">{String(j.journey_status || '').replaceAll('_', ' ')}</p>
                </button>
              ))}
            </div>
          )}
        </McCard>

        <div className="lg:col-span-8 space-y-4">
          {!detail ? (
            <McCard title="Journey"><p className="text-xs text-slate-400">Select a patient.</p></McCard>
          ) : (
            <>
              <McCard title={`PATIENT: ${detail.patient_name || detail.patient_id}`}>
                <div className="mb-3">
                  <span className="text-sm font-black">
                    {detail.journey_status === 'ON_TRACK' ? '🟢 ON TRACK' : '🔴 ATTENTION REQUIRED'}
                  </span>
                  {detail.priority && detail.priority !== 'NONE' && (
                    <span className="ml-2 text-[11px] font-bold text-slate-500">Priority {detail.priority}</span>
                  )}
                </div>
                <div className="grid grid-cols-1 sm:grid-cols-2 gap-2">
                  {PIPELINE.map(([key, label]) => (
                    <div key={key} className="flex items-center justify-between gap-2 p-2 rounded-lg bg-slate-50 border border-slate-100">
                      <span className="text-xs font-semibold text-slate-600">{label}</span>
                      <Pill value={journey[key]} />
                    </div>
                  ))}
                </div>
              </McCard>

              <McCard title="AI Findings">
                {findings.length === 0 ? (
                  <p className="text-xs text-emerald-700">No open findings. Journey is on track.</p>
                ) : (
                  <div className="space-y-3">
                    {findings.map((f) => (
                      <div key={f.id} className="p-3 rounded-xl border border-slate-200 bg-white">
                        <div className="flex items-center gap-2 mb-1">
                          <span className={`text-[10px] font-black uppercase ${f.priority === 'HIGH' ? 'text-rose-600' : f.priority === 'MEDIUM' ? 'text-amber-600' : 'text-sky-600'}`}>
                            {f.priority === 'HIGH' ? '🔴 HIGH' : f.priority === 'MEDIUM' ? '🟠 MEDIUM' : '🔵 LOW'}
                          </span>
                          <span className="text-[10px] text-slate-400 font-mono">{f.finding_type}</span>
                        </div>
                        <p className="text-sm font-semibold text-slate-800">{f.message}</p>
                        {f.recommended_action && (
                          <p className="text-xs text-slate-500 mt-1">Recommended: {f.recommended_action}</p>
                        )}
                        <div className="flex flex-wrap gap-2 mt-3">
                          <button type="button" className="px-2.5 py-1 rounded-lg bg-slate-100 text-[11px] font-bold" onClick={() => setEvidenceFinding(f)}>VIEW EVIDENCE</button>
                          <button disabled={busy} type="button" className="px-2.5 py-1 rounded-lg bg-emerald-600 text-white text-[11px] font-bold" onClick={() => review(f.id, 'APPROVE')}>APPROVE</button>
                          <button disabled={busy} type="button" className="px-2.5 py-1 rounded-lg bg-rose-500 text-white text-[11px] font-bold" onClick={() => review(f.id, 'REJECT')}>REJECT</button>
                          <button disabled={busy} type="button" className="px-2.5 py-1 rounded-lg bg-indigo-500 text-white text-[11px] font-bold" onClick={() => setModifyFor(f)}>MODIFY</button>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </McCard>

              <McCard title="AI Summary">
                <p className="text-sm text-slate-700 leading-relaxed">{detail.summary || '—'}</p>
                {(detail.recommendations || []).length > 0 && (
                  <ol className="mt-3 list-decimal pl-5 text-xs text-slate-600 space-y-1">
                    {detail.recommendations.map((r) => <li key={r}>{r}</li>)}
                  </ol>
                )}
              </McCard>
            </>
          )}
        </div>
      </div>

      {evidenceFinding && (
        <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-4" onClick={() => setEvidenceFinding(null)}>
          <div className="bg-white rounded-2xl p-5 max-w-lg w-full shadow-xl" onClick={(e) => e.stopPropagation()}>
            <h3 className="font-black text-slate-900 mb-3">Evidence (live MEDCLUES data)</h3>
            <pre className="text-xs bg-slate-50 border border-slate-100 rounded-xl p-3 overflow-auto max-h-80">
              {JSON.stringify(evidenceFinding.evidence || detail?.evidence || {}, null, 2)}
            </pre>
            <button type="button" className="mt-3 px-3 py-2 rounded-xl bg-slate-800 text-white text-xs font-bold" onClick={() => setEvidenceFinding(null)}>Close</button>
          </div>
        </div>
      )}

      {modifyFor && (
        <div className="fixed inset-0 z-50 bg-black/40 flex items-center justify-center p-4" onClick={() => setModifyFor(null)}>
          <div className="bg-white rounded-2xl p-5 max-w-lg w-full shadow-xl" onClick={(e) => e.stopPropagation()}>
            <h3 className="font-black text-slate-900 mb-2">Modify coordination</h3>
            <p className="text-xs text-slate-500 mb-3">{modifyFor.message}</p>
            <label className="text-[11px] font-bold text-slate-500">Note</label>
            <textarea value={note} onChange={(e) => setNote(e.target.value)} className="w-full mt-1 mb-3 border rounded-xl p-2 text-sm" rows={3} />
            {String(modifyFor.finding_type || '').includes('REFERRAL') && (
              <>
                <label className="text-[11px] font-bold text-slate-500">Specialist appointment</label>
                <input type="datetime-local" value={modifyDate} onChange={(e) => setModifyDate(e.target.value)} className="w-full mt-1 mb-3 border rounded-xl p-2 text-sm" />
              </>
            )}
            <div className="flex gap-2">
              <button
                type="button"
                disabled={busy}
                className="px-3 py-2 rounded-xl bg-indigo-600 text-white text-xs font-bold"
                onClick={() => review(modifyFor.id, 'MODIFY', modifyDate ? { appointment_date: new Date(modifyDate).toISOString() } : {})}
              >
                Save & re-check
              </button>
              <button type="button" className="px-3 py-2 rounded-xl bg-slate-100 text-xs font-bold" onClick={() => setModifyFor(null)}>Cancel</button>
            </div>
          </div>
        </div>
      )}
    </AdminPageLayout>
  )
}

export default DoctorPatientJourney
