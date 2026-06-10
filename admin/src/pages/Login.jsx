import axios from 'axios'
import React, { useContext, useState } from 'react'
import { saveAuthTokens } from '../services/authApi'
import { DoctorContext } from '../context/DoctorContext'
import { AdminContext } from '../context/AdminContext'
import { DeanContext } from '../context/DeanContext'
import { toast } from 'react-toastify'
import { useNavigate } from 'react-router-dom'

const PortalCard = ({ title, sub, icon, email, setEmail, password, setPassword, onSubmit, loading, showPwd, setShowPwd, colorClass, btnText, role, isDoctor, navigate }) => (
  <div className='flex-1 flex flex-col items-center justify-center p-4 sm:p-6 transition-all duration-500 snap-start min-h-[85vh] lg:min-h-0'>
    <div className='w-full max-w-[360px] bg-white/95 backdrop-blur-2xl rounded-[2.5rem] p-6 sm:p-10 shadow-[0_30px_70px_rgba(0,0,0,0.06)] border border-white/50 flex flex-col gap-6 animate-portal-in'>
      <div className='text-center'>
        <div className={`mx-auto mb-5 w-14 h-14 rounded-2xl bg-gradient-to-br ${colorClass.icon} flex items-center justify-center shadow-xl shadow-blue-100/50 text-white transform hover:rotate-6 hover:scale-105 transition-all duration-300`}>
          {icon}
        </div>
        <h1 className='text-2xl font-black text-gray-900 tracking-tight font-outfit mb-2'>{title}</h1>
        <div className='inline-block px-4 py-1.5 bg-gray-50 rounded-full'>
          <p className='text-[10px] text-gray-500 font-black uppercase tracking-[0.2em]'>{sub}</p>
        </div>
      </div>

      <form onSubmit={onSubmit} className='space-y-5'>
        <div className='space-y-2'>
          <label className={`block text-[11px] font-black uppercase tracking-widest ${colorClass.textLabel} ml-2`}>Identity</label>
          <div className='relative group'>
            <input
              value={email}
              onChange={e => setEmail(e.target.value)}
              type="email"
              required
              placeholder={role === 'Super Admin' ? 'admin@id.com' : role === 'DEAN' ? 'dean@id.com' : 'doc@id.com'}
              className='w-full px-5 py-3.5 rounded-[1.25rem] border-2 border-slate-100 bg-slate-50/50 focus:bg-white focus:border-indigo-400 outline-none transition-all text-sm font-bold text-gray-800 placeholder:text-slate-300'
            />
          </div>
        </div>

        <div className='space-y-2'>
          <div className='flex justify-between items-center ml-2'>
            <label className={`block text-[11px] font-black uppercase tracking-widest ${colorClass.textLabel}`}>Security</label>
            {isDoctor && (
              <span onClick={() => navigate('/doctor-forgot-password')} className='text-[10px] font-black text-slate-400 hover:text-indigo-600 cursor-pointer transition-colors tracking-wider'>RECOVER?</span>
            )}
          </div>
          <div className='relative group'>
            <input
              value={password}
              onChange={e => setPassword(e.target.value)}
              type={showPwd ? 'text' : 'password'}
              required
              placeholder="••••••••"
              className='w-full px-5 py-3.5 pr-12 rounded-[1.25rem] border-2 border-slate-100 bg-slate-50/50 focus:bg-white focus:border-indigo-400 outline-none transition-all text-sm font-bold text-gray-800 placeholder:text-slate-300'
            />
            <button type="button" onClick={() => setShowPwd(!showPwd)} className='absolute right-4 top-3.5 text-slate-300 hover:text-indigo-500 transition-colors'>
              {showPwd ? (
                <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2.5} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l3.29 3.29m13.42 13.42l-3.29-3.29M3 3l18 18" /></svg>
              ) : (
                <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2.5} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2.5} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
              )}
            </button>
          </div>
        </div>

        <button type="submit" disabled={loading} className={`group w-full py-5 rounded-[1.5rem] font-black text-white ${colorClass.btn} shadow-lg active:scale-[0.98] hover:shadow-xl transition-all text-xs uppercase tracking-[0.2em] flex items-center justify-center gap-3 relative overflow-hidden`}>
          {loading ? <div className='w-4 h-4 border-2 border-white/30 border-t-white rounded-full animate-spin'></div> : null}
          <span>{loading ? 'Validating...' : btnText}</span>
          {!loading && (
            <svg className='w-4 h-4 transform group-hover:translate-x-1 transition-transform' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M14 5l7 7m0 0l-7 7m7-7H3" /></svg>
          )}
        </button>
      </form>
    </div>
  </div>
)

const Login = () => {
  const [adminEmail, setAdminEmail] = useState('')
  const [adminPassword, setAdminPassword] = useState('')
  const [doctorEmail, setDoctorEmail] = useState('')
  const [doctorPassword, setDoctorPassword] = useState('')
  const [deanEmail, setDeanEmail] = useState('')
  const [deanPassword, setDeanPassword] = useState('')

  const [isAdminLoading, setIsAdminLoading] = useState(false)
  const [isDoctorLoading, setIsDoctorLoading] = useState(false)
  const [isDeanLoading, setIsDeanLoading] = useState(false)

  const [showAdminPwd, setShowAdminPwd] = useState(false)
  const [showDoctorPwd, setShowDoctorPwd] = useState(false)
  const [showDeanPwd, setShowDeanPwd] = useState(false)

  const backendUrl = import.meta.env.VITE_BACKEND_URL
  const { setDToken } = useContext(DoctorContext)
  const { setAToken } = useContext(AdminContext)
  const { setDeanToken, setDeanInfo } = useContext(DeanContext)
  const navigate = useNavigate()

  const onAdminSubmit = async (e) => {
    e.preventDefault()
    setIsAdminLoading(true)
    try {
      const { data } = await axios.post(backendUrl + '/api/admin/login', { email: adminEmail, password: adminPassword }, { withCredentials: true })
      if (data.success) {
        setAToken(data.token)
        saveAuthTokens('admin', data.token)
        toast.success('Admin login successful!')
        navigate('/admin-dashboard')
      } else { toast.error(data.message) }
    } catch (err) {
      const msg = err.response?.data?.message
      if (!err.response) {
        toast.error('Cannot reach backend. Start FastAPI on port 5000 and check admin/.env VITE_BACKEND_URL.')
      } else {
        toast.error(msg || 'Admin login failed')
      }
    }
    finally { setIsAdminLoading(false) }
  }

  const onDeanSubmit = async (e) => {
    e.preventDefault()
    setIsDeanLoading(true)
    try {
      const { data } = await axios.post(backendUrl + '/api/dean/login', { email: deanEmail, password: deanPassword }, { withCredentials: true })
      if (data.success) {
        setDeanToken(data.token)
        setDeanInfo(data.dean)
        saveAuthTokens('dean', data.token)
        sessionStorage.setItem('deanInfo', JSON.stringify(data.dean))
        toast.success('DEAN login successful!')
        navigate('/dean-dashboard')
      } else { toast.error(data.message) }
    } catch (err) {
      if (!err.response) toast.error('Cannot reach backend on ' + backendUrl)
      else toast.error(err.response?.data?.message || 'DEAN login failed')
    }
    finally { setIsDeanLoading(false) }
  }

  const onDoctorSubmit = async (e) => {
    e.preventDefault()
    setIsDoctorLoading(true)
    try {
      const { data } = await axios.post(backendUrl + '/api/doctor/login', { email: doctorEmail, password: doctorPassword }, { withCredentials: true })
      if (data.success) {
        setDToken(data.token)
        saveAuthTokens('doctor', data.token)
        toast.success('Doctor login successful!')
        navigate('/doctor-dashboard')
      } else { toast.error(data.message) }
    } catch (err) {
      if (!err.response) toast.error('Cannot reach backend on ' + backendUrl)
      else toast.error(err.response?.data?.message || 'Doctor login failed')
    }
    finally { setIsDoctorLoading(false) }
  }

  return (
    <div className='min-h-screen w-full flex flex-col lg:flex-row overflow-y-auto lg:overflow-hidden font-inter bg-slate-50 snap-y lg:snap-none snap-mandatory'>
      {/* Admin Portal Section */}
      <div className='flex-1 lg:h-screen bg-white flex flex-col items-center justify-center relative overflow-hidden'>
        <div className='absolute top-0 left-0 w-full h-full bg-[radial-gradient(circle_at_top_left,rgba(56,189,248,0.08),transparent_50%)]'></div>
        <PortalCard
          title="Super Admin"
          sub="SYSTEM MASTER"
          role="ADMIN"
          icon={<svg className='w-8 h-8' fill='none' stroke='currentColor' strokeWidth='2' viewBox='0 0 24 24'><path strokeLinecap="round" strokeLinejoin="round" d='M9 12l2 2 4-4m5.618-4.016A11.955 11.955 0 0112 2.944a11.955 11.955 0 01-8.618 3.04A12.02 12.02 0 003 9c0 5.591 3.824 10.29 9 11.622 5.176-1.332 9-6.03 9-11.622 0-1.042-.133-2.052-.382-3.016z' /></svg>}
          email={adminEmail}
          setEmail={setAdminEmail}
          password={adminPassword}
          setPassword={setAdminPassword}
          onSubmit={onAdminSubmit}
          loading={isAdminLoading}
          showPwd={showAdminPwd}
          setShowPwd={setShowAdminPwd}
          colorClass={{ icon: 'from-sky-400 to-sky-600', btn: 'bg-[#0ea5e9] hover:bg-[#0284c7]', textLabel: 'text-sky-600' }}
          btnText="Master Login"
          navigate={navigate}
        />
      </div>

      <div className='hidden lg:block w-[1px] h-2/3 self-center bg-slate-100'></div>

      {/* DEAN Portal Section */}
      <div className='flex-1 lg:h-screen bg-slate-50 flex flex-col items-center justify-center relative overflow-hidden'>
        <div className='absolute top-0 left-0 w-full h-full bg-[radial-gradient(circle_at_top_left,rgba(20,184,166,0.08),transparent_50%)]'></div>
        <PortalCard
          title="DEAN Portal"
          sub="OPERATIONS HEAD"
          role="DEAN"
          icon={<svg className='w-8 h-8' fill='none' stroke='currentColor' strokeWidth='2' viewBox='0 0 24 24'><path strokeLinecap="round" strokeLinejoin="round" d='M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4' /></svg>}
          email={deanEmail}
          setEmail={setDeanEmail}
          password={deanPassword}
          setPassword={setDeanPassword}
          onSubmit={onDeanSubmit}
          loading={isDeanLoading}
          showPwd={showDeanPwd}
          setShowPwd={setShowDeanPwd}
          colorClass={{ icon: 'from-teal-400 to-teal-600', btn: 'bg-[#14b8a6] hover:bg-[#0d9488]', textLabel: 'text-teal-600' }}
          btnText="Controller Login"
          navigate={navigate}
        />
      </div>

      <div className='hidden lg:block w-[1px] h-2/3 self-center bg-slate-100'></div>

      {/* Doctor Portal Section */}
      <div className='flex-1 lg:h-screen bg-white flex flex-col items-center justify-center relative overflow-hidden'>
        <div className='absolute top-0 left-0 w-full h-full bg-[radial-gradient(circle_at_top_left,rgba(99,102,241,0.08),transparent_50%)]'></div>
        <PortalCard
          title="Doctor Portal"
          sub="CLINICAL EXPERT"
          role="DOCTOR"
          icon={<svg className='w-8 h-8' fill='none' stroke='currentColor' strokeWidth='2' viewBox='0 0 24 24'><path strokeLinecap="round" strokeLinejoin="round" d="M9 12h6m-3-3v6m-3-9a11.955 11.955 0 018.618 3.04A12.02 12.02 0 0121 9c0 5.591-3.824 10.29-9 11.622-5.176-1.332-9-6.03-9-11.622 0-1.042-.133-2.052-.382-3.016z" /></svg>}
          email={doctorEmail}
          setEmail={setDoctorEmail}
          password={doctorPassword}
          setPassword={setDoctorPassword}
          onSubmit={onDoctorSubmit}
          loading={isDoctorLoading}
          showPwd={showDoctorPwd}
          setShowPwd={setShowDoctorPwd}
          colorClass={{ icon: 'from-indigo-400 to-indigo-600', btn: 'bg-[#6366f1] hover:bg-[#4f46e5]', textLabel: 'text-indigo-600' }}
          btnText="Professional Login"
          isDoctor={true}
          navigate={navigate}
        />
      </div>

      <style>{`
        .font-outfit { font-family: 'Outfit', sans-serif !important; }
        .font-inter { font-family: 'Inter', sans-serif !important; }
        @keyframes portalIn { from { opacity: 0; transform: translateY(30px) scale(0.98); } to { opacity: 1; transform: translateY(0) scale(1); } }
        .animate-portal-in { animation: portalIn 1s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
      `}</style>
    </div>
  )
}

export default Login