import React, { useContext, useRef, useState, useEffect } from 'react'
import { toast } from 'react-toastify'
import { ReceptionContext } from '../../context/ReceptionContext'
import { PageWrap, RcHeader, Avatar, Pill, EmptyState, ReceptionTabs, RECEPTION_TAB_GROUPS } from './components'

const inputCls = 'w-full px-3 py-2 rounded-rd border border-rd-border bg-rd-surface focus:border-rd-primary outline-none text-sm font-medium text-rd-text'

const QRCheckIn = () => {
  const { checkIn, searchPatients } = useContext(ReceptionContext)
  const [bookingId, setBookingId] = useState('')
  const [busy, setBusy] = useState(false)
  const [camOn, setCamOn] = useState(false)
  const [recent, setRecent] = useState([])
  const [query, setQuery] = useState('')
  const [results, setResults] = useState([])
  const videoRef = useRef(null)
  const streamRef = useRef(null)

  const toggleCam = async () => {
    if (camOn) {
      streamRef.current?.getTracks().forEach((t) => t.stop())
      streamRef.current = null
      setCamOn(false)
      return
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ video: { facingMode: 'environment' } })
      streamRef.current = stream
      if (videoRef.current) videoRef.current.srcObject = stream
      setCamOn(true)
    } catch {
      toast.error('Could not access camera. Enter the Booking ID manually.')
    }
  }

  useEffect(() => () => streamRef.current?.getTracks().forEach((t) => t.stop()), [])

  const doCheckIn = async (id) => {
    const code = (id || bookingId).trim()
    if (!code) return toast.error('Enter a Booking ID')
    setBusy(true)
    const res = await checkIn(code)
    setBusy(false)
    if (res?.success) {
      toast.success(res.message || 'Checked in')
      setRecent((r) => [{ bookingId: code, name: res.patientName || res.appointment?.userData?.name || 'Patient', time: new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }), status: 'COMPLETED', image: res.appointment?.userData?.image }, ...r].slice(0, 8))
      setBookingId('')
    } else {
      setRecent((r) => [{ bookingId: code, name: 'Unknown', time: new Date().toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit' }), status: 'NO_SHOW' }, ...r].slice(0, 8))
    }
  }

  useEffect(() => {
    const t = setTimeout(async () => {
      if (query.trim().length < 2) { setResults([]); return }
      const r = await searchPatients(query.trim())
      if (r?.success) setResults(r.patients || [])
    }, 350)
    return () => clearTimeout(t)
  }, [query])

  return (
    <PageWrap>
      <RcHeader title='Check-In' subtitle='Scan patient QR code or enter booking ID' />
      <ReceptionTabs items={RECEPTION_TAB_GROUPS.checkin} />

      <div className='grid lg:grid-cols-2 gap-5'>
        <div className='rd-panel p-5'>
          <p className='text-sm font-bold text-rd-text mb-4'>Scan QR Code</p>
          <div className='aspect-square max-w-xs mx-auto rounded-rd bg-rd-sidebar overflow-hidden flex items-center justify-center relative'>
            {camOn ? (
              <video ref={videoRef} autoPlay playsInline muted className='w-full h-full object-cover' />
            ) : (
              <svg className='w-28 h-28 text-rd-muted' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={1.2} d='M12 4v1m6 11h2m-6 0h-2v4m0-11v3m0 0h.01M12 12h4.01M16 20h4M4 12h4m12 0h.01M5 8h2a1 1 0 001-1V5a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1zm12 0h2a1 1 0 001-1V5a1 1 0 00-1-1h-2a1 1 0 00-1 1v2a1 1 0 001 1zM5 20h2a1 1 0 001-1v-2a1 1 0 00-1-1H5a1 1 0 00-1 1v2a1 1 0 001 1z' /></svg>
            )}
            <div className='absolute inset-6 border-2 border-blue-400/60 rounded-rd pointer-events-none' />
          </div>
          <p className='text-center text-xs text-rd-muted mt-3'>Position the QR code within the frame</p>
          <button onClick={toggleCam} className='mt-4 w-full py-3 rounded-rd bg-rd-primary text-white text-sm font-bold hover:bg-rd-primary-hover'>{camOn ? 'Turn off Camera' : 'Turn on Camera'}</button>
        </div>

        <div className='space-y-5'>
          <div className='rd-panel p-5'>
            <p className='text-sm font-bold text-rd-text mb-3'>Or Enter Booking ID</p>
            <div className='flex gap-2'>
              <input className={inputCls} value={bookingId} onChange={(e) => setBookingId(e.target.value)} onKeyDown={(e) => e.key === 'Enter' && doCheckIn()} placeholder='Enter booking ID' />
              <button disabled={busy} onClick={() => doCheckIn()} className='px-5 py-2.5 rounded-rd bg-rd-primary text-white text-sm font-bold hover:bg-rd-primary-hover disabled:opacity-50 shrink-0'>Check</button>
            </div>
          </div>

          <div className='rd-panel p-5'>
            <p className='text-sm font-bold text-rd-text mb-3'>Search Patient</p>
            <input className={inputCls} value={query} onChange={(e) => setQuery(e.target.value)} placeholder='Search by name or mobile number' />
            <div className='mt-3 space-y-2 max-h-44 overflow-y-auto'>
              {results.map((p) => (
                <div key={p._id} className='flex items-center gap-3 p-2.5 rounded-rd bg-rd-canvas'>
                  <Avatar name={p.name} src={p.image} />
                  <div className='min-w-0'>
                    <p className='text-sm font-bold text-rd-text truncate'>{p.name}</p>
                    <p className='text-xs text-rd-muted'>{p.phone || p.email}</p>
                  </div>
                </div>
              ))}
            </div>
          </div>
        </div>
      </div>

      <div className='rd-panel mt-5 overflow-hidden'>
        <div className='px-5 py-4 border-b border-rd-border'><p className='text-sm font-bold text-rd-text'>Recent Check-Ins</p></div>
        {recent.length === 0 ? <EmptyState title='No check-ins yet' /> : (
          <div className='overflow-x-auto'>
            <table className='w-full text-sm'>
              <thead><tr className='text-left text-[11px] uppercase tracking-wider text-rd-muted border-b border-rd-border bg-rd-canvas/60'>
                <th className='px-5 py-3 font-bold'>Patient</th><th className='px-5 py-3 font-bold'>Booking ID</th><th className='px-5 py-3 font-bold'>Time</th><th className='px-5 py-3 font-bold'>Status</th>
              </tr></thead>
              <tbody>
                {recent.map((r, i) => (
                  <tr key={i} className='border-b border-rd-border'>
                    <td className='px-5 py-3'><div className='flex items-center gap-2'><Avatar name={r.name} src={r.image} /><span className='font-semibold text-rd-text'>{r.name}</span></div></td>
                    <td className='px-5 py-3 font-mono text-xs text-rd-muted'>{r.bookingId}</td>
                    <td className='px-5 py-3 text-rd-muted'>{r.time}</td>
                    <td className='px-5 py-3'><Pill status={r.status} label={r.status === 'COMPLETED' ? 'Success' : 'Failed'} /></td>
                  </tr>
                ))}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </PageWrap>
  )
}

export default QRCheckIn
