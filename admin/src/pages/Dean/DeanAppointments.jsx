import React, { useContext, useEffect, useState } from 'react'
import { DeanContext } from '../../context/DeanContext'
import { AppContext } from '../../context/AppContext'
import GlassCard from '../../components/ui/GlassCard'
import { toast } from 'react-toastify'

const statusBadge = (item) => {
  if (item.cancelled) return <span className='px-2.5 py-1 rounded-full bg-red-50 text-red-600 text-[11px] font-bold border border-red-100'>Cancelled</span>
  if (item.isCompleted) return <span className='px-2.5 py-1 rounded-full bg-green-50 text-green-600 text-[11px] font-bold border border-green-100'>Completed</span>
  return <span className='px-2.5 py-1 rounded-full bg-blue-50 text-blue-600 text-[11px] font-bold border border-blue-100'>Active</span>
}

const DeanAppointments = () => {
  const { deanToken, appointments, getAllAppointments, cancelAppointment } = useContext(DeanContext)
  const { slotDateFormat, currency } = useContext(AppContext)
  
  const [search, setSearch] = useState('')
  const [activeTab, setActiveTab] = useState('all') // all | today | cancelled
  const [filters, setFilters] = useState({
    date: '',
    doctor: '',
    status: ''
  })
  const [doctors, setDoctors] = useState([])

  useEffect(() => {
    if (deanToken) getAllAppointments()
  }, [deanToken])

    // Extract unique doctors for filter dropdown
    useEffect(() => {
        if (appointments.length > 0) {
            const doctorMap = new Map()
            appointments.forEach(apt => {
                const doc = apt.docData
                if (doc) {
                    const id = doc._id || doc.id
                    if (id && !doctorMap.has(id)) {
                        doctorMap.set(id, {...doc, _id: id})
                    }
                }
            })
            setDoctors(Array.from(doctorMap.values()))
        }
    }, [appointments])

    const filteredAppointments = appointments.filter(a => {
        // 1. Text Search
        const patientName = a.actualPatient && !a.actualPatient.isSelf ? a.actualPatient.name : a.userData?.name
        const matchSearch =
            a.docData?.name?.toLowerCase().includes(search.toLowerCase()) ||
            patientName?.toLowerCase().includes(search.toLowerCase())
        
        if (!matchSearch) return false

        // 2. Tab Logical Presets (prioritize manual overrides)
        if (!filters.date && !filters.status) {
            const today = new Date()
            const d = today.getDate()
            const m = today.getMonth() + 1
            const y = today.getFullYear()
            const todayStrStd = `${d.toString().padStart(2, '0')}_${m.toString().padStart(2, '0')}_${y}`
            const todayStrLeg = `${d}_${m}_${y}`

            if (activeTab === 'today') {
                const isToday = a.slotDate === todayStrStd || a.slotDate === todayStrLeg
                if (!isToday) return false
            } else if (activeTab === 'cancelled') {
                if (!a.cancelled) return false
            }
        }

        // 3. Manual Filters (Global Narrowing)
        
        // Date Narrowing
        if (filters.date) {
            const [y, m, d] = filters.date.split('-')
            const fStd = `${d.padStart(2, '0')}_${m.padStart(2, '0')}_${y}`
            const fLeg = `${parseInt(d)}_${parseInt(m)}_${y}`
            if (a.slotDate !== fStd && a.slotDate !== fLeg) return false
        }

        // Doctor Narrowing (Handles both _id and id formats)
        if (filters.doctor) {
            const docId = a.docData?._id || a.docData?.id
            if (String(docId) !== String(filters.doctor)) return false
        }

        // Status Narrowing
        if (filters.status) {
            if (filters.status === 'cancelled' && !a.cancelled) return false
            if (filters.status === 'completed' && !a.isCompleted) return false
            if (filters.status === 'active' && (a.cancelled || a.isCompleted)) return false
        }

        return true
    })

  return (
    <div className='w-full bg-white p-4 sm:p-6 mobile-safe-area pb-6'>
      <div className='space-y-4 animate-fade-in-up'>
        {/* Header */}
        <GlassCard className="p-4 sm:p-6">
          <div className='flex flex-col sm:flex-row items-start sm:items-center justify-between gap-4'>
            <div>
              <h1 className='text-2xl font-bold text-gray-900'>Appointments</h1>
              <p className='text-sm text-gray-500 mt-1'>Manage and view all patient appointments for your facility</p>
            </div>
            <div className='flex items-center gap-3 w-full sm:w-auto overflow-x-auto pb-1 sm:pb-0'>
              {[
                { id: 'all', label: 'All Time' },
                { id: 'today', label: 'Today' },
                { id: 'cancelled', label: 'Cancelled' }
              ].map(tab => (
                <button
                  key={tab.id}
                  onClick={() => setActiveTab(tab.id)}
                  className={`px-4 py-2 rounded-full text-xs font-bold whitespace-nowrap transition-all ${
                    activeTab === tab.id 
                    ? 'bg-emerald-600 text-white shadow-lg' 
                    : 'bg-gray-100 text-gray-600 hover:bg-gray-200'
                  }`}
                >
                  {tab.label}
                </button>
              ))}
            </div>
          </div>
        </GlassCard>

        {/* Search & Filters */}
        <GlassCard className="p-4 sm:p-5">
            <div className='flex flex-col gap-4'>
                <div className='relative w-full overflow-hidden'>
                    <svg className='absolute left-4 top-1/2 -translate-y-1/2 w-5 h-5 text-gray-400' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
                        <path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z' />
                    </svg>
                    <input 
                        value={search} 
                        onChange={e => setSearch(e.target.value)}
                        placeholder='Search and filter appointments instantly…'
                        className='w-full pl-12 pr-4 py-3 border-2 border-slate-50 bg-slate-50/50 rounded-2xl text-sm font-medium focus:bg-white focus:border-emerald-400 outline-none transition-all' 
                    />
                </div>

                <div className='grid grid-cols-1 sm:grid-cols-3 gap-3'>
                    <div className='space-y-1'>
                        <label className='text-[10px] font-black uppercase tracking-wider text-gray-400 ml-1'>Filter Date</label>
                        <input 
                            type="date" 
                            value={filters.date} 
                            onChange={e => setFilters({...filters, date: e.target.value})}
                            className='w-full px-4 py-2.5 border-2 border-slate-50 bg-slate-50/50 rounded-xl text-sm font-bold focus:bg-white focus:border-emerald-400' 
                        />
                    </div>
                    <div className='space-y-1'>
                        <label className='text-[10px] font-black uppercase tracking-wider text-gray-400 ml-1'>Select Doctor</label>
                        <select 
                            value={filters.doctor} 
                            onChange={e => setFilters({...filters, doctor: e.target.value})}
                            className='w-full px-4 py-3 border-2 border-slate-50 bg-slate-50/50 rounded-xl text-sm font-bold focus:bg-white focus:border-emerald-400 appearance-none'
                        >
                            <option value="">All Hospital Doctors</option>
                            {doctors.map(d => (
                                <option key={d._id} value={d._id}>{d.name}</option>
                            ))}
                        </select>
                    </div>
                    <div className='space-y-1'>
                        <label className='text-[10px] font-black uppercase tracking-wider text-gray-400 ml-1'>Status</label>
                        <select 
                            value={filters.status} 
                            onChange={e => setFilters({...filters, status: e.target.value})}
                            className='w-full px-4 py-3 border-2 border-slate-50 bg-slate-50/50 rounded-xl text-sm font-bold focus:bg-white focus:border-emerald-400 appearance-none'
                        >
                            <option value="">Any Status</option>
                            <option value="active">Active</option>
                            <option value="completed">Completed</option>
                            <option value="cancelled">Cancelled</option>
                        </select>
                    </div>
                </div>
            </div>
        </GlassCard>

        {/* List */}
        <div className='overflow-x-auto rounded-3xl border border-gray-100 shadow-sm'>
            <table className='w-full text-sm text-left'>
                <thead className='bg-gray-50/50 text-gray-500 uppercase text-[10px] font-black tracking-widest'>
                    <tr>
                        <th className='px-6 py-4'>#</th>
                        <th className='px-6 py-4'>Doctor Info</th>
                        <th className='px-6 py-4'>Patient</th>
                        <th className='px-6 py-4'>Schedule</th>
                        <th className='px-6 py-4'>Payment</th>
                        <th className='px-6 py-4 text-center'>State</th>
                        <th className='px-6 py-4 text-right'>Actions</th>
                    </tr>
                </thead>
                <tbody className='divide-y divide-gray-50'>
                    {filteredAppointments.length === 0 ? (
                        <tr><td colSpan={7} className='text-center py-20 text-gray-400 font-medium'>No appointments match your criteria.</td></tr>
                    ) : filteredAppointments.map((item, idx) => {
                        const patientName = item.actualPatient && !item.actualPatient.isSelf ? item.actualPatient.name : item.userData?.name
                        return (
                            <tr key={idx} className='bg-white hover:bg-emerald-50/30 transition-colors'>
                                <td className='px-6 py-4 font-mono text-gray-300 text-xs'>{idx + 1}</td>
                                <td className='px-6 py-4'>
                                    <div className='flex items-center gap-3'>
                                        <img src={item.docData?.image} className='w-9 h-9 rounded-full border border-gray-100 object-cover' alt="" />
                                        <div>
                                            <p className='font-bold text-gray-900 leading-tight'>{item.docData?.name}</p>
                                            <p className='text-[10px] text-gray-500 font-medium'>{item.docData?.speciality}</p>
                                        </div>
                                    </div>
                                </td>
                                <td className='px-6 py-4 font-bold text-gray-800'>{patientName}</td>
                                <td className='px-6 py-4'>
                                    <p className='font-bold text-gray-900'>{slotDateFormat(item.slotDate)}</p>
                                    <p className='text-xs text-emerald-600 font-black'>{item.slotTime}</p>
                                </td>
                                <td className='px-6 py-4'>
                                    <p className='font-black text-gray-900'>{currency}{item.amount}</p>
                                    <span className={`text-[9px] uppercase font-black ${item.payment ? 'text-green-600' : 'text-orange-600'}`}>
                                        {item.payment ? 'Online Paid' : 'Cash/Pending'}
                                    </span>
                                </td>
                                <td className='px-6 py-4 text-center'>{statusBadge(item)}</td>
                                <td className='px-6 py-4 text-right'>
                                    {!item.cancelled && !item.isCompleted && (
                                        <button 
                                            onClick={() => cancelAppointment(item._id)}
                                            className='px-3 py-1.5 bg-red-50 text-red-600 text-xs font-black rounded-lg hover:bg-red-100 transition-colors'
                                        >
                                            REJECT
                                        </button>
                                    )}
                                </td>
                            </tr>
                        )
                    })}
                </tbody>
            </table>
        </div>
      </div>
    </div>
  )
}

export default DeanAppointments
