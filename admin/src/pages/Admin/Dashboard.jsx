import React, { useContext, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { assets } from '../../assets/assets'
import { AdminContext } from '../../context/AdminContext'
import { AppContext } from '../../context/AppContext'
import { useSocket } from '../../context/SocketContext'
import { toast } from 'react-toastify'
import GlassCard from '../../components/ui/GlassCard'
import AnimatedCounter from '../../components/ui/AnimatedCounter'
import StatusIndicator from '../../components/ui/StatusIndicator'
import LineChart from '../../components/charts/LineChart'
import BarChart from '../../components/charts/BarChart'
import AreaChart from '../../components/charts/AreaChart'

const Dashboard = () => {
  const { aToken, getDashData, cancelAppointment, dashData, getAllDoctors, doctors, getAllAppointments, hospitals, getAllHospitals } = useContext(AdminContext)
  const { slotDateFormat } = useContext(AppContext)
  const { socket, isConnected, liveData } = useSocket()
  const navigate = useNavigate()
  const [currentTime, setCurrentTime] = useState(new Date())
  const [chartData, setChartData] = useState({
    patientGrowth: { labels: [], values: [] },
    revenue: { labels: [], values: [] },
    appointments: { labels: [], values: [] }
  })
  const [docSearch, setDocSearch] = useState('')

  useEffect(() => {
    if (aToken) {
      getDashData()
      getAllDoctors()
      getAllHospitals()

      // Auto-refresh dashboard every 30 seconds to get latest counts
      const refreshInterval = setInterval(() => {
        getDashData()
      }, 30000) // Refresh every 30 seconds

      return () => clearInterval(refreshInterval)
    }
  }, [aToken])

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date())
    }, 1000)
    return () => clearInterval(timer)
  }, [])

  // Initialize chart data from actual dashboard data (no random values)
  useEffect(() => {
    if (dashData && dashData.chartData) {
      // Use actual chart data from backend (starts at 0, updates live)
      setChartData({
        patientGrowth: dashData.chartData.patientGrowth || { labels: [], values: [] },
        revenue: dashData.chartData.revenue || { labels: [], values: [] },
        appointments: dashData.chartData.appointments || { labels: [], values: [] }
      })
    } else {
      // Initialize with zeros if no data yet
      const days = Array.from({ length: 30 }, (_, i) => {
        const d = new Date()
        d.setDate(d.getDate() - (29 - i))
        return d.toLocaleDateString('en-US', { day: 'numeric', month: 'short' })
      })

      const hours = Array.from({ length: 24 }, (_, i) => {
        return `${i.toString().padStart(2, '0')}:00`
      })

      setChartData({
        patientGrowth: { labels: days, values: new Array(30).fill(0) },
        revenue: { labels: days, values: new Array(30).fill(0) },
        appointments: { labels: hours, values: new Array(24).fill(0) }
      })
    }
  }, [dashData])

  // Listen for real-time updates
  useEffect(() => {
    if (socket && isConnected) {
      socket.on('new-appointment', (data) => {
        toast.success(`🟢 New Appointment: ${data.patientName} at ${data.slotTime}`, {
          position: 'top-right',
          autoClose: 3000
        })
        // Refresh dashboard to update counts, revenue, and charts
        getDashData()
        if (getAllAppointments) getAllAppointments()
      })

      socket.on('appointments-deleted', (data) => {
        console.log('📋 Appointments deleted:', data)
        getDashData()
        if (getAllAppointments) getAllAppointments()
      })

      socket.on('patient-count-updated', (count) => {
        console.log('👥 Patient count updated:', count)
      })

      socket.on('revenue-updated', (data) => {
        console.log('💰 Revenue updated:', data)
      })

      return () => {
        socket.off('new-appointment')
        socket.off('appointments-deleted')
        socket.off('patient-count-updated')
        socket.off('revenue-updated')
      }
    }
  }, [socket, isConnected])


  const formatTime = (date) => {
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: true
    })
  }

  const formatDate = (date) => {
    return date.toLocaleDateString('en-US', {
      weekday: 'long',
      year: 'numeric',
      month: 'long',
      day: 'numeric'
    })
  }

  // Calculate stats from actual dashboard data - only show if appointments exist
  // Default to 0 if no appointments have been made
  const totalPatientsToday = (dashData?.patientsToday && dashData?.patientsToday > 0) ? dashData.patientsToday : 0
  const totalAppointmentsToday = (dashData?.appointmentsToday && dashData?.appointmentsToday > 0) ? dashData.appointmentsToday : 0
  const totalDoctors = dashData?.doctors || doctors?.length || 0
  const activeDoctorsOnline = dashData?.activeDoctors || doctors?.filter(doc => doc.available).length || 0
  const totalHospitals = dashData?.hospitals || hospitals?.length || 0
  const todayRevenue = (dashData?.revenueToday && dashData?.revenueToday > 0) ? dashData.revenueToday : 0 // Revenue from today's appointments

  if (!dashData) {
    return (
      <div className="flex items-center justify-center min-h-[calc(100vh-64px)]">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    )
  }

  return (
    <div className='w-full bg-gradient-to-br from-gray-50 via-white to-indigo-50/30 p-4 sm:p-4 mobile-safe-area pb-6 min-h-screen'>
      <div className='space-y-3 sm:space-y-4 animate-fade-in-up'>
        {/* Live Clock Widget & Quick Access */}
        <GlassCard className="p-3 sm:p-4 overflow-visible">
          <div className='flex flex-col sm:flex-row items-center justify-between gap-4 sm:gap-3'>
            <div className='flex items-center gap-2 sm:gap-3'>
              <div className='bg-gradient-to-br from-indigo-500 to-purple-600 rounded-lg p-2 shadow-lg'>
                <svg className='w-5 h-5 sm:w-6 sm:h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                </svg>
              </div>
              <div>
                <h2 className='text-lg sm:text-xl lg:text-2xl font-bold text-gray-800 tracking-wider'>{formatTime(currentTime)}</h2>
                <p className='text-gray-500 text-[10px] sm:text-xs mt-0.5 flex items-center gap-1.5 flex-wrap'>
                  <span className='w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse' />
                  <span className='whitespace-nowrap'>Live Dashboard</span>
                  <span className='hidden sm:inline'>•</span>
                  <span className='text-[9px] sm:text-[10px]'>{formatDate(currentTime)}</span>
                </p>
              </div>
            </div>
          </div>
        </GlassCard>

        {/* Top Widgets - Animated Counters */}
        <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3 sm:gap-4'>
          {/* 1. Revenue */}
          <GlassCard
            hover={true}
            className="p-4 bg-white rounded-3xl shadow-sm border border-gray-100 flex items-center gap-4 cursor-pointer hover-lift transition-all"
            onClick={() => navigate('/revenue-analytics')}
          >
            <div className='bg-pink-500 rounded-2xl p-3 shadow-lg flex-shrink-0'>
              <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div className='flex flex-col min-w-0'>
              <p className='text-xl sm:text-2xl font-bold text-gray-900 leading-tight truncate'>
                <AnimatedCounter value={dashData?.revenueTotal || 0} prefix="₹" />
              </p>
              <p className='text-gray-500 text-[10px] sm:text-xs font-medium'>Revenue</p>
              <p className='text-[9px] text-pink-600 font-semibold mt-0.5'>Today: ₹{todayRevenue}</p>
            </div>
          </GlassCard>

          {/* 2. Total Appointments */}
          <GlassCard
            hover={true}
            className="p-4 bg-white rounded-3xl shadow-sm border border-gray-100 flex items-center gap-4 cursor-pointer hover-lift transition-all"
            onClick={() => navigate('/all-appointments')}
          >
            <div className='bg-blue-500 rounded-2xl p-3 shadow-lg flex-shrink-0'>
              <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <div className='flex flex-col min-w-0'>
              <p className='text-xl sm:text-2xl font-bold text-gray-900 leading-tight'>
                <AnimatedCounter value={dashData?.appointments || 0} />
              </p>
              <p className='text-gray-500 text-[10px] sm:text-xs font-medium'>Total Appointments</p>
            </div>
          </GlassCard>

          {/* 3. Active Doctors */}
          <GlassCard
            hover={true}
            className="p-4 bg-white rounded-3xl shadow-sm border border-gray-100 flex items-center gap-4 cursor-pointer hover-lift transition-all"
            onClick={() => navigate('/doctor-list?filter=available')}
          >
            <div className='bg-green-500 rounded-2xl p-3 shadow-lg flex-shrink-0'>
              <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div className='flex flex-col min-w-0'>
              <p className='text-xl sm:text-2xl font-bold text-gray-900 leading-tight'>
                <AnimatedCounter value={activeDoctorsOnline} /> / {totalDoctors}
              </p>
              <p className='text-gray-500 text-[10px] sm:text-xs font-medium'>Active Doctors</p>
            </div>
          </GlassCard>

          {/* 4. Tie-Up Hospitals */}
          <GlassCard
            hover={true}
            className="p-4 bg-white rounded-3xl shadow-sm border border-gray-100 flex items-center gap-4 cursor-pointer hover-lift transition-all"
            onClick={() => navigate('/hospital-tieups')}
          >
            <div className='bg-indigo-600 rounded-2xl p-3 shadow-lg flex-shrink-0'>
              <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" />
              </svg>
            </div>
            <div className='flex flex-col min-w-0'>
              <p className='text-xl sm:text-2xl font-bold text-gray-900 leading-tight'>
                <AnimatedCounter value={totalHospitals} />
              </p>
              <p className='text-gray-500 text-[10px] sm:text-xs font-medium'>Tie-Up Hospitals</p>
            </div>
          </GlassCard>

          {/* 5. Appointments Today */}
          <GlassCard
            hover={true}
            className="p-4 bg-white rounded-3xl shadow-sm border border-gray-100 flex items-center gap-4 cursor-pointer hover-lift transition-all"
            onClick={() => navigate('/all-appointments')}
          >
            <div className='bg-purple-600 rounded-2xl p-3 shadow-lg flex-shrink-0'>
              <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <div className='flex flex-col min-w-0'>
              <p className='text-xl sm:text-2xl font-bold text-gray-900 leading-tight'>
                <AnimatedCounter value={totalAppointmentsToday} />
              </p>
              <p className='text-gray-500 text-[10px] sm:text-xs font-medium'>Appointments Today</p>
            </div>
          </GlassCard>
        </div>

        {/* Live Graphs Section - Equal Cards (Same Design Desktop & Mobile) */}
        <div className='grid grid-cols-1 lg:grid-cols-2 gap-3 sm:gap-4'>
          <GlassCard className="p-3 sm:p-4 flex flex-col lg:h-full w-full min-h-[260px]">
            <h3 className='text-base sm:text-lg font-bold text-gray-800 mb-2 sm:mb-3 flex items-center gap-1.5'>
              <svg className='w-5 h-5 sm:w-6 sm:h-6 text-indigo-600 flex-shrink-0' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
              </svg>
              <span className='text-sm sm:text-base lg:text-xl'>Patient Registration Trend</span>
            </h3>
            <div className="chart-container overflow-x-auto flex-1 min-h-0 w-full">
              <LineChart data={chartData.patientGrowth} title="Patients" color="#667eea" />
            </div>
          </GlassCard>

          <GlassCard className="p-3 sm:p-4 flex flex-col lg:h-full w-full min-h-[260px]">
            <h3 className='text-base sm:text-lg font-bold text-gray-800 mb-2 sm:mb-3 flex items-center gap-1.5'>
              <svg className='w-5 h-5 sm:w-6 sm:h-6 text-purple-600 flex-shrink-0' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
              Revenue Trend (30 Days)
            </h3>
            <div className="chart-container flex-1 min-h-0 w-full">
              <BarChart data={chartData.revenue} title="Revenue" color="#764ba2" />
            </div>
          </GlassCard>
        </div>

        {/* Appointments Peak Hours - Full Width */}
        <GlassCard className="p-3 sm:p-4 mt-3 sm:mt-4 min-h-[260px]">
          <h3 className='text-base sm:text-lg font-bold text-gray-800 mb-2 sm:mb-3 flex items-center gap-1.5'>
            <svg className='w-5 h-5 sm:w-6 sm:h-6 text-pink-600 flex-shrink-0' fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
            </svg>
            Appointments Peak Hours
          </h3>
          <div className="chart-container overflow-x-auto">
            <AreaChart data={chartData.appointments} title="Distribution" color="#f093fb" />
          </div>
        </GlassCard>

        {/* Quick Doctor Explorer - NEW Section */}
        <div className='mt-6'>
          <div className='flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-4'>
            <div>
              <h3 className='text-xl font-black text-gray-800 flex items-center gap-2'>
                <div className='w-8 h-8 bg-indigo-100 rounded-lg flex items-center justify-center'>
                  <svg className='w-5 h-5 text-indigo-600' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0z" />
                  </svg>
                </div>
                Quick Doctor Explorer
              </h3>
              <p className='text-xs text-gray-500 font-medium ml-10'>Find and monitor any professional on the platform</p>
            </div>
            
            <div className='relative w-full sm:w-72'>
              <input 
                type="text"
                value={docSearch}
                onChange={(e) => setDocSearch(e.target.value)}
                placeholder='Search by name or speciality...'
                className='w-full pl-10 pr-4 py-2.5 bg-white border-2 border-gray-100 rounded-2xl text-sm font-bold focus:border-indigo-500 outline-none transition-all shadow-sm'
              />
              <svg className='absolute left-3.5 top-1/2 -translate-y-1/2 w-4 h-4 text-indigo-400' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" />
              </svg>
            </div>
          </div>

          <div className='flex gap-4 overflow-x-auto pb-4 custom-scrollbar snap-x'>
            {(doctors || [])
              .filter(doc => !docSearch || doc.name.toLowerCase().includes(docSearch.toLowerCase()) || doc.speciality.toLowerCase().includes(docSearch.toLowerCase()))
              .slice(0, 20) // Show top 20 or filtered results
              .map((doc, idx) => (
                <div 
                  key={doc._id || idx}
                  className='min-w-[200px] sm:min-w-[240px] bg-white rounded-3xl p-4 border border-gray-100 shadow-sm hover:shadow-xl hover:-translate-y-1 transition-all group snap-start cursor-pointer'
                  onClick={() => navigate('/doctor-list')}
                >
                  <div className='relative mb-3'>
                    <img src={doc.image} className='w-full h-32 object-cover rounded-2xl bg-indigo-50' alt='' />
                    <div className={`absolute top-2 right-2 px-2 py-1 rounded-lg text-[9px] font-black uppercase tracking-widest shadow-sm ${doc.available ? 'bg-green-500 text-white' : 'bg-red-500 text-white'}`}>
                      {doc.available ? 'Online' : 'Offline'}
                    </div>
                  </div>
                  <h4 className='font-bold text-gray-800 text-sm truncate group-hover:text-indigo-600 transition-colors'>{doc.name}</h4>
                  <p className='text-[10px] text-gray-500 font-bold uppercase tracking-wider mb-2'>{doc.speciality}</p>
                  {doc.hospital_name && (
                    <div className='flex items-center gap-1.5 py-1.5 px-2 bg-indigo-50/50 rounded-lg'>
                      <svg className='w-3 h-3 text-indigo-500 shrink-0' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4" /></svg>
                      <span className='text-[9px] font-bold text-indigo-600 truncate'>{doc.hospital_name}</span>
                    </div>
                  )}
                </div>
              ))}
              
              {(!doctors || doctors.length === 0) && (
                <div className='w-full py-12 flex flex-col items-center justify-center bg-gray-50/50 rounded-3xl border-2 border-dashed border-gray-200'>
                  <div className='w-12 h-12 bg-gray-100 rounded-full flex items-center justify-center mb-3 text-gray-400'>
                    <svg className='w-6 h-6' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" /></svg>
                  </div>
                  <p className='text-sm font-bold text-gray-400'>No doctors registered yet</p>
                </div>
              )}
          </div>
        </div>

      </div>
    </div>
  )
}

export default Dashboard
