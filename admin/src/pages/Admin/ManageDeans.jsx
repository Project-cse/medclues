import React, { useContext, useEffect, useState } from 'react'
import axios from 'axios'
import { AdminContext } from '../../context/AdminContext'
import { toast } from 'react-toastify'
import GlassCard from '../../components/ui/GlassCard'

const ManageDeans = () => {
  const { aToken, hospitals, getAllHospitals } = useContext(AdminContext)
  const backendUrl = import.meta.env.VITE_BACKEND_URL
  const authHeader = { aToken }

  const [deans, setDeans] = useState([])
  const [isLoading, setIsLoading] = useState(false)
  const [showForm, setShowForm] = useState(false)
  const [form, setForm] = useState({ name: '', email: '', password: '', hospital_id: '' })
  const [creating, setCreating] = useState(false)

  const fetchDeans = async () => {
    setIsLoading(true)
    try {
      const { data } = await axios.get(`${backendUrl}/api/admin/deans`, { headers: authHeader })
      if (data.success) setDeans(data.deans)
      else toast.error(data.message)
    } catch (err) { toast.error(err.message) }
    finally { setIsLoading(false) }
  }

  useEffect(() => {
    if (aToken) { fetchDeans(); getAllHospitals() }
  }, [aToken])

  const handleCreate = async (e) => {
    e.preventDefault()
    if (!form.name || !form.email || !form.password || !form.hospital_id) {
      toast.error('All fields are required'); return
    }
    setCreating(true)
    try {
      const { data } = await axios.post(`${backendUrl}/api/admin/deans/create`, form, { headers: authHeader })
      if (data.success) {
        toast.success(data.message)
        setForm({ name: '', email: '', password: '', hospital_id: '' })
        setShowForm(false)
        fetchDeans()
      } else { toast.error(data.message) }
    } catch (err) { toast.error(err.response?.data?.message || err.message) }
    finally { setCreating(false) }
  }

  const handleDelete = async (deanId, deanName) => {
    if (!window.confirm(`Remove DEAN "${deanName}"? This cannot be undone.`)) return
    try {
      const { data } = await axios.delete(`${backendUrl}/api/admin/deans/${deanId}`, { headers: authHeader })
      if (data.success) { toast.success(data.message); fetchDeans() }
      else toast.error(data.message)
    } catch (err) { toast.error(err.message) }
  }

  const [showPasswords, setShowPasswords] = useState({})

  const copyToClipboard = async (text, label) => {
    try {
      if (navigator.clipboard && window.isSecureContext) {
        await navigator.clipboard.writeText(text)
      } else {
        const textArea = document.createElement("textarea")
        textArea.value = text
        document.body.appendChild(textArea)
        textArea.select()
        try { document.execCommand('copy') } catch (err) { }
        document.body.removeChild(textArea)
      }
      toast.success(`${label} copied to clipboard!`)
    } catch (err) {
      toast.error('Failed to copy')
    }
  }

  const togglePassword = (id) => {
    setShowPasswords(prev => ({ ...prev, [id]: !prev[id] }))
  }

  const [showEmails, setShowEmails] = useState({})
  const toggleEmail = (id) => {
    setShowEmails(prev => ({ ...prev, [id]: !prev[id] }))
  }

  return (
    <div className='w-full bg-gradient-to-br from-gray-50 via-white to-emerald-50/20 p-4 sm:p-6 min-h-screen'>
      <div className='max-w-6xl mx-auto space-y-5'>

        {/* Page Header */}
        <div className='flex flex-col sm:flex-row sm:items-center justify-between gap-3'>
          <div>
            <h1 className='text-2xl font-bold text-gray-900'>Manage DEANs</h1>
            <p className='text-sm text-gray-500 mt-0.5'>Assign Hospital Controllers to manage specific hospitals</p>
          </div>
          <button onClick={() => setShowForm(v => !v)}
            className='px-5 py-2.5 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white font-semibold rounded-xl shadow-lg shadow-emerald-500/20 hover:-translate-y-0.5 active:scale-95 transition-all text-sm'>
            {showForm ? '✕ Cancel' : '+ Create New DEAN'}
          </button>
        </div>

        {/* Info Banner */}
        <div className='bg-gradient-to-r from-emerald-600 to-teal-600 rounded-2xl p-4 text-white flex items-start gap-3'>
          <span className='text-2xl mt-0.5'>🏥</span>
          <div>
            <p className='font-bold'>What is a DEAN?</p>
            <p className='text-sm text-emerald-100 mt-0.5'>A DEAN (Hospital Controller) manages day-to-day operations of a specific hospital — doctors, appointments, and settings — independently from global admin control.</p>
          </div>
        </div>

        {/* Create DEAN Form */}
        {showForm && (
          <GlassCard className='p-6'>
            <h2 className='text-lg font-bold text-gray-800 mb-5 flex items-center gap-2'>
              <span className='w-8 h-8 bg-emerald-100 rounded-lg flex items-center justify-center text-emerald-700'>+</span>
              Create DEAN Account
            </h2>
            <form onSubmit={handleCreate} className='grid grid-cols-1 sm:grid-cols-2 gap-4'>

              {/* Name */}
              <div>
                <label className='block text-[10px] font-bold uppercase tracking-widest text-emerald-700 mb-1.5'>Full Name</label>
                <input value={form.name} onChange={e => setForm(f => ({ ...f, name: e.target.value }))} required
                  placeholder="Dr. Ravi Kumar" className='w-full px-4 py-2.5 border-2 border-gray-100 focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 outline-none rounded-xl text-sm transition-all' />
              </div>

              {/* Email */}
              <div>
                <label className='block text-[10px] font-bold uppercase tracking-widest text-emerald-700 mb-1.5'>Email Address</label>
                <input value={form.email} onChange={e => setForm(f => ({ ...f, email: e.target.value }))} type='email' required
                  placeholder="dean@hospital.com" className='w-full px-4 py-2.5 border-2 border-gray-100 focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 outline-none rounded-xl text-sm transition-all' />
              </div>

              {/* Password */}
              <div>
                <label className='block text-[10px] font-bold uppercase tracking-widest text-emerald-700 mb-1.5'>Password</label>
                <input value={form.password} onChange={e => setForm(f => ({ ...f, password: e.target.value }))} type='password' required
                  placeholder="Minimum 8 characters" className='w-full px-4 py-2.5 border-2 border-gray-100 focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 outline-none rounded-xl text-sm transition-all' />
              </div>

              {/* Hospital select */}
              <div>
                <label className='block text-[10px] font-bold uppercase tracking-widest text-emerald-700 mb-1.5'>Assign Hospital</label>
                <select value={form.hospital_id} onChange={e => setForm(f => ({ ...f, hospital_id: e.target.value }))} required
                  className='w-full px-4 py-2.5 border-2 border-gray-100 focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 outline-none rounded-xl text-sm transition-all bg-white appearance-none cursor-pointer'>
                  <option value=''>Select a hospital…</option>
                  {hospitals.map(h => (
                    <option key={h.id} value={h.id}>{h.name}</option>
                  ))}
                </select>
              </div>

              {/* Submit */}
              <div className='sm:col-span-2 flex justify-end'>
                <button type='submit' disabled={creating}
                  className='px-8 py-3 bg-gradient-to-r from-emerald-600 to-teal-600 hover:from-emerald-700 hover:to-teal-700 text-white font-bold rounded-xl shadow-lg hover:-translate-y-0.5 active:scale-95 transition-all text-sm disabled:opacity-50'>
                  {creating
                    ? <span className='flex items-center gap-2'><span className='w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin' />Creating…</span>
                    : '🎓 Create DEAN Account'}
                </button>
              </div>
            </form>
          </GlassCard>
        )}

        {/* DEANs Data Section */}
        <div className='bg-gray-50/50 rounded-2xl p-1'>
          {isLoading ? (
            <div className='flex items-center justify-center py-20 bg-white rounded-2xl border border-gray-100'>
              <div className='flex flex-col items-center gap-3'>
                <div className='animate-spin rounded-full h-10 w-10 border-4 border-emerald-100 border-t-emerald-600' />
                <p className='text-sm text-gray-500 font-medium'>Fetching controllers...</p>
              </div>
            </div>
          ) : deans.length === 0 ? (
            <div className='py-20 text-center bg-white rounded-2xl border border-dashed border-gray-200'>
              <p className='text-5xl mb-4'>🎓</p>
              <p className='text-gray-500 font-bold text-lg'>No DEAN accounts yet.</p>
              <p className='text-sm text-gray-400 mt-2 max-w-xs mx-auto'>Create your first controller account to manage an individual hospital's operations.</p>
            </div>
          ) : (
            <>
              {/* Desktop View (Table) */}
              <div className='hidden lg:block'>
                <GlassCard className='overflow-hidden border-none shadow-sm'>
                   <div className='px-6 py-4 border-b border-gray-100 flex items-center justify-between bg-white/60'>
                    <h2 className='font-bold text-gray-800 flex items-center gap-2'>
                        <svg className='w-5 h-5 text-emerald-600' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" /></svg>
                        All Controller Accounts
                    </h2>
                    <span className='text-xs font-bold text-emerald-700 bg-emerald-50 px-3 py-1 rounded-full border border-emerald-100'>{deans.length} Controllers</span>
                  </div>
                  <div className='overflow-x-auto'>
                    <table className='w-full text-sm'>
                      <thead className='bg-gray-50/80'>
                        <tr>
                          {['Controller Name', 'Email Access', 'Assigned Hospital', 'Established', 'Actions'].map(h => (
                            <th key={h} className='px-6 py-4 text-left text-[11px] font-bold text-gray-400 uppercase tracking-widest'>{h}</th>
                          ))}
                        </tr>
                      </thead>
                      <tbody className='divide-y divide-gray-50 bg-white/40'>
                        {deans.map((dean, i) => (
                          <tr key={dean.id || i} className='hover:bg-emerald-50/40 transition-colors group'>
                            <td className='px-6 py-4'>
                              <div className='flex items-center gap-3'>
                                <div className='w-10 h-10 bg-gradient-to-br from-emerald-500 to-teal-600 rounded-xl flex items-center justify-center text-white text-sm font-bold flex-shrink-0 shadow-sm group-hover:scale-105 transition-transform'>
                                  {(dean.name || 'D')[0].toUpperCase()}
                                </div>
                                <span className='font-bold text-gray-900'>{dean.name}</span>
                              </div>
                            </td>
                            <td className='px-6 py-4'>
                              <div className='flex items-center justify-between bg-slate-50/60 border border-slate-100 px-4 py-2 rounded-2xl max-w-[280px] min-w-[240px] group/email shadow-sm hover:shadow transition-all duration-300'>
                                <div className='flex flex-col gap-0.5'>
                                  <span className='text-[9px] text-slate-400 font-black uppercase tracking-wider'>DEAN Identity</span>
                                  <span className='text-xs font-bold text-slate-700 font-mono tracking-tight transition-all duration-300'>
                                    {showEmails[dean.id] ? dean.email : dean.email.split('@')[0].slice(0, 4) + '••••••••@' + dean.email.split('@')[1]}
                                  </span>
                                </div>
                                <div className='flex items-center gap-1 opacity-60 group-hover/email:opacity-100 transition-opacity duration-300 ml-2'>
                                  <button onClick={() => toggleEmail(dean.id)}
                                    className={`p-1.5 rounded-lg transition-all shadow-sm ${showEmails[dean.id] ? 'bg-orange-100/80 text-orange-600 hover:bg-orange-600 hover:text-white' : 'bg-indigo-50 text-indigo-600 hover:bg-indigo-600 hover:text-white'}`}
                                    title={showEmails[dean.id] ? "Hide Email" : "Reveal Email"}>
                                    {showEmails[dean.id] ? (
                                      <svg className='w-3.5 h-3.5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2.5} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l18 18" /></svg>
                                    ) : (
                                      <svg className='w-3.5 h-3.5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2.5} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2.5} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
                                    )}
                                  </button>
                                  {showEmails[dean.id] && (
                                    <button onClick={() => copyToClipboard(dean.email, 'Email')}
                                      className='p-1.5 bg-emerald-50 text-emerald-600 rounded-lg hover:bg-emerald-600 hover:text-white transition-all shadow-sm'
                                      title="Copy Email">
                                      <svg className="w-3.5 h-3.5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>
                                    </button>
                                  )}
                                </div>
                              </div>
                            </td>

                            <td className='px-6 py-4'>
                              <div className='flex flex-col'>
                                <span className='inline-flex items-center gap-1.5 px-3 py-1 bg-white border border-emerald-100 text-emerald-700 rounded-lg text-xs font-bold shadow-sm'>
                                    🏥 {dean.hospital_name || `ID: ${dean.hospital_id}`}
                                </span>
                              </div>
                            </td>
                            <td className='px-6 py-4 text-gray-400 text-xs font-medium'>
                              {dean.created_at ? new Date(dean.created_at).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : '—'}
                            </td>
                            <td className='px-6 py-4'>
                              <button onClick={() => handleDelete(dean.id, dean.name)}
                                className='px-4 py-1.5 bg-red-50 hover:bg-red-100 text-red-600 text-xs font-bold rounded-lg transition-all opacity-0 group-hover:opacity-100'>
                                Remove Account
                              </button>
                            </td>
                          </tr>
                        ))}
                      </tbody>
                    </table>
                  </div>
                </GlassCard>
              </div>

              {/* Mobile View (Cards) */}
              <div className='lg:hidden space-y-4'>
                 {deans.map((dean, i) => (
                    <GlassCard key={dean.id || i} className='p-4 border-none shadow-sm relative overflow-hidden group'>
                         {/* Header Stripe */}
                        <div className="absolute top-0 left-0 w-1 h-full bg-emerald-500" />
                        
                        <div className='flex items-start justify-between mb-4'>
                            <div className='flex items-center gap-3'>
                                <div className='w-12 h-12 bg-gradient-to-br from-emerald-500 to-teal-600 rounded-2xl flex items-center justify-center text-white text-lg font-bold shadow-lg'>
                                    {(dean.name || 'D')[0].toUpperCase()}
                                </div>
                                <div>
                                    <h3 className='font-bold text-gray-900'>{dean.name}</h3>
                                    <p className='text-[10px] font-black uppercase tracking-wider text-emerald-600 bg-emerald-50 px-2.5 py-0.5 rounded-full inline-block mt-1 border border-emerald-100'>Hospital Dean</p>
                                </div>
                            </div>
                            <button onClick={() => handleDelete(dean.id, dean.name)} className='p-2 text-red-500 bg-red-50 hover:bg-red-100 rounded-xl active:scale-90 transition-all'>
                                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                            </button>
                        </div>

                        <div className='grid grid-cols-1 gap-3'>
                            <div className='p-3 bg-emerald-50/50 rounded-xl border border-emerald-100'>
                                <p className='text-[10px] uppercase tracking-widest font-bold text-emerald-700 mb-1'>Assigned Hospital</p>
                                <p className='text-sm font-bold text-gray-800 flex items-center gap-2'>
                                    <span className='text-lg'>🏥</span> {dean.hospital_name || `Hospital ID: ${dean.hospital_id}`}
                                </p>
                            </div>
                            
                            <div className='p-3 bg-slate-50/60 rounded-xl border border-slate-100 flex items-center justify-between'>
                                <div className='flex flex-col gap-0.5'>
                                    <p className='text-[9px] uppercase tracking-widest font-black text-slate-400 mb-0.5'>DEAN Identity (Email)</p>
                                    <p className='text-xs font-bold text-slate-700 font-mono'>
                                        {showEmails[dean.id] ? dean.email : dean.email.split('@')[0].slice(0, 4) + '••••••••@' + dean.email.split('@')[1]}
                                    </p>
                                </div>
                                <div className='flex items-center gap-1.5'>
                                    <button onClick={() => toggleEmail(dean.id)}
                                        className={`p-2 rounded-xl transition-all shadow-sm ${showEmails[dean.id] ? 'bg-orange-100 text-orange-600' : 'bg-indigo-50 text-indigo-600'}`}>
                                        {showEmails[dean.id] ? (
                                            <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l18 18" /></svg>
                                        ) : (
                                            <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
                                        )}
                                    </button>
                                    {showEmails[dean.id] && (
                                        <button onClick={() => copyToClipboard(dean.email, 'Email')}
                                            className='p-2 bg-emerald-50 text-emerald-600 rounded-xl transition-all shadow-sm'>
                                            <svg className="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>
                                        </button>
                                    )}
                                </div>
                            </div>

                            <div className='flex items-center justify-between text-[11px] text-gray-500 px-1'>
                                <span className='font-medium'>Established On</span>
                                <span className='font-bold'>{dean.created_at ? new Date(dean.created_at).toLocaleDateString('en-IN', { day: '2-digit', month: 'short', year: 'numeric' }) : '—'}</span>
                            </div>
                        </div>
                    </GlassCard>
                 ))}
              </div>
            </>
          )}
        </div>
      </div>
    </div>
  )
}

export default ManageDeans
