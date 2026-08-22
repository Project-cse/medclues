import React, { useContext, useEffect, useState } from 'react'
import axios from 'axios'
import { ReceptionContext } from '../../context/ReceptionContext'
import { AppContext } from '../../context/AppContext'
import { PageWrap, RcHeader, Pill, Spinner, Avatar, EmptyState } from './components'
import { toast } from 'react-toastify'

const LabQueue = () => {
  const { recToken, backendUrl } = useContext(ReceptionContext)
  const { slotDateFormat } = useContext(AppContext)
  
  const [queue, setQueue] = useState([])
  const [loading, setLoading] = useState(true)
  const [busy, setBusy] = useState(null)
  
  // State for report uploading
  const [activeReportUploadId, setActiveReportUploadId] = useState(null)
  const [reportUrlInput, setReportUrlInput] = useState('')

  const loadQueue = async () => {
    try {
      const { data } = await axios.get(`${backendUrl}/api/lab/queue`, {
        headers: { Token: recToken }
      })
      if (data.success) {
        setQueue(data.queue)
      } else {
        toast.error(data.message || 'Failed to load lab queue')
      }
    } catch (e) {
      toast.error(e.message)
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    if (recToken) loadQueue()
  }, [recToken])

  const transitionStatus = async (id, newStatus, extra = {}) => {
    setBusy(id)
    try {
      const { data } = await axios.patch(
        `${backendUrl}/api/investigations/${id}`,
        { status: newStatus, ...extra },
        { headers: { Token: recToken } }
      )
      if (data.success) {
        toast.success(`Order transitioned to ${newStatus}`)
        await loadQueue()
      } else {
        toast.error(data.message || 'Failed to update order status')
      }
    } catch (e) {
      toast.error(e.message)
    } finally {
      setBusy(null)
      setActiveReportUploadId(null)
      setReportUrlInput('')
    }
  }

  const handleUploadReport = (id) => {
    if (!reportUrlInput.trim()) {
      toast.warn('Please enter a valid report URL')
      return
    }
    transitionStatus(id, 'REPORT_AVAILABLE', { reportUrl: reportUrlInput.trim() })
  }

  return (
    <PageWrap>
      <RcHeader 
        title='Lab Staff Worklist' 
        subtitle='Manage patient investigation orders, sample collection, and pathology test publishing.'
        right={
          <button 
            onClick={() => { setLoading(true); loadQueue(); }} 
            className='px-4 py-2 rounded-xl bg-rd-primary text-white text-sm font-semibold hover:bg-rd-primary-hover shadow-sm transition-colors'
          >
            Refresh Queue
          </button>
        }
      />

      <div className='rd-panel overflow-hidden border border-rd-border rounded-2xl bg-rd-surface'>
        {loading ? (
          <Spinner />
        ) : queue.length === 0 ? (
          <EmptyState title='No active laboratory investigations' sub='Doctor orders will appear here automatically.' />
        ) : (
          <div className='overflow-x-auto'>
            <table className='w-full text-sm text-left border-collapse'>
              <thead>
                <tr className='text-left text-[11px] uppercase tracking-wider text-rd-muted border-b border-rd-border bg-rd-canvas/60'>
                  <th className='px-5 py-3 font-bold'>Patient</th>
                  <th className='px-5 py-3 font-bold'>Order Details</th>
                  <th className='px-5 py-3 font-bold'>Doctor / Priority</th>
                  <th className='px-5 py-3 font-bold'>Status</th>
                  <th className='px-5 py-3 font-bold text-right'>Workflow Action</th>
                </tr>
              </thead>
              <tbody className='divide-y divide-rd-border'>
                {queue.map((item) => {
                  const patientName = item.patient_name || 'Patient'
                  const doctorName = item.doctor_name || 'Doctor'
                  const isUrgent = item.priority === 'URGENT' || item.priority === 'STAT'
                  
                  return (
                    <tr key={item.id} className='hover:bg-rd-canvas/30 transition-colors'>
                      <td className='px-5 py-4'>
                        <div className='flex items-center gap-3'>
                          <Avatar name={patientName} src={item.patient_image} />
                          <div>
                            <span className='font-semibold text-rd-text block'>{patientName}</span>
                            <span className='text-xs text-rd-muted'>{item.patient_phone || '—'}</span>
                          </div>
                        </div>
                      </td>
                      <td className='px-5 py-4'>
                        <span className='font-medium text-rd-text block'>{item.test_name}</span>
                        {item.notes && <span className='text-xs text-rd-muted italic'>&ldquo;{item.notes}&rdquo;</span>}
                      </td>
                      <td className='px-5 py-4'>
                        <span className='font-medium text-rd-text block'>{doctorName}</span>
                        <span className={`text-xs font-bold uppercase ${isUrgent ? 'text-rose-500' : 'text-slate-400'}`}>
                          {item.priority}
                        </span>
                      </td>
                      <td className='px-5 py-4'>
                        <Pill status={item.status} />
                      </td>
                      <td className='px-5 py-4 text-right'>
                        {busy === item.id ? (
                          <span className='text-xs text-rd-muted animate-pulse'>Processing…</span>
                        ) : activeReportUploadId === item.id ? (
                          <div className='flex flex-col gap-2 items-end max-w-xs ml-auto'>
                            <input 
                              type='text' 
                              value={reportUrlInput}
                              onChange={(e) => setReportUrlInput(e.target.value)}
                              placeholder='https://report-link.pdf'
                              className='px-3 py-1.5 rounded-lg border border-rd-border bg-rd-canvas text-xs w-full focus:outline-none focus:border-rd-primary'
                            />
                            <div className='flex gap-1.5'>
                              <button 
                                onClick={() => setActiveReportUploadId(null)}
                                className='px-2.5 py-1 rounded-lg border border-rd-border text-rd-muted text-[11px] font-semibold hover:bg-rd-canvas'
                              >
                                Cancel
                              </button>
                              <button 
                                onClick={() => handleUploadReport(item.id)}
                                className='px-2.5 py-1 rounded-lg bg-emerald-500 hover:bg-emerald-600 text-white text-[11px] font-semibold'
                              >
                                Publish
                              </button>
                            </div>
                          </div>
                        ) : (
                          <div className='flex justify-end gap-2'>
                            {item.status === 'ORDERED' && (
                              <button 
                                onClick={() => transitionStatus(item.id, 'ACCEPTED')}
                                className='px-3 py-1.5 rounded-xl bg-rd-primary text-white text-xs font-bold hover:bg-rd-primary-hover shadow-sm'
                              >
                                ✓ Accept Order
                              </button>
                            )}
                            {item.status === 'ACCEPTED' && (
                              <button 
                                onClick={() => transitionStatus(item.id, 'SAMPLE_COLLECTED')}
                                className='px-3 py-1.5 rounded-xl bg-amber-500 text-white text-xs font-bold hover:bg-amber-600 shadow-sm'
                              >
                                🧪 Collect Sample
                              </button>
                            )}
                            {item.status === 'SAMPLE_COLLECTED' && (
                              <button 
                                onClick={() => transitionStatus(item.id, 'TEST_PERFORMED')}
                                className='px-3 py-1.5 rounded-xl bg-indigo-500 text-white text-xs font-bold hover:bg-indigo-600 shadow-sm'
                              >
                                ⚙️ Run Pathology Test
                              </button>
                            )}
                            {(item.status === 'TEST_PERFORMED' || item.status === 'REPORT_AVAILABLE') && (
                              <button 
                                onClick={() => {
                                  setActiveReportUploadId(item.id)
                                  setReportUrlInput(item.report_url || '')
                                }}
                                className='px-3 py-1.5 rounded-xl bg-emerald-500 text-white text-xs font-bold hover:bg-emerald-600 shadow-sm'
                              >
                                📁 {item.report_url ? 'Update Report' : 'Upload PDF Report'}
                              </button>
                            )}
                          </div>
                        )}
                      </td>
                    </tr>
                  )
                })}
              </tbody>
            </table>
          </div>
        )}
      </div>
    </PageWrap>
  )
}

export default LabQueue
