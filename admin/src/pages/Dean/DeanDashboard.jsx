import React, { useContext, useEffect, useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { DeanContext } from '../../context/DeanContext'
import GlassCard from '../../components/ui/GlassCard'
import AnimatedCounter from '../../components/ui/AnimatedCounter'
import LineChart from '../../components/charts/LineChart'
import BarChart from '../../components/charts/BarChart'
import AreaChart from '../../components/charts/AreaChart'

const DeanDashboard = () => {
  const { deanToken, deanInfo, dashData, getDashData, getHospital, hospital } = useContext(DeanContext)
  const navigate = useNavigate()
  const [currentTime, setCurrentTime] = useState(new Date())
  const [chartData, setChartData] = useState({
    patientGrowth: { labels: [], values: [] },
    revenue: { labels: [], values: [] },
    appointments: { labels: [], values: [] }
  })

  useEffect(() => {
    if (deanToken) {
      getDashData()
      getHospital()
    }
  }, [deanToken])

  useEffect(() => {
    if (dashData && dashData.chartData) {
      setChartData({
        patientGrowth: dashData.chartData.patientGrowth || { labels: [], values: [] },
        revenue: dashData.chartData.revenue || { labels: [], values: [] },
        appointments: dashData.chartData.appointments || { labels: [], values: [] }
      })
    }
  }, [dashData])

  useEffect(() => {
    const timer = setInterval(() => setCurrentTime(new Date()), 1000)
    return () => clearInterval(timer)
  }, [])

  const formatTime = (d) => d.toLocaleTimeString('en-US', { hour: '2-digit', minute: '2-digit', second: '2-digit', hour12: true })
  const formatDate = (d) => d.toLocaleDateString('en-US', { weekday: 'long', year: 'numeric', month: 'long', day: 'numeric' })

  if (!dashData) {
    return (
      <div className="flex items-center justify-center min-h-[calc(100vh-64px)]">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-emerald-600 mx-auto" />
          <p className="mt-4 text-gray-600">Loading hospital dashboard…</p>
        </div>
      </div>
    )
  }

  return (
    <div className='w-full bg-gradient-to-br from-gray-50 via-white to-emerald-50/30 p-4 sm:p-6 min-h-screen'>
      <div className='space-y-4 animate-fade-in-up'>

        {/* Hospital Banner */}
        <div className='bg-gradient-to-r from-emerald-600 via-teal-600 to-cyan-600 rounded-2xl p-4 sm:p-6 text-white shadow-xl'>
          <div className='flex flex-col sm:flex-row items-start sm:items-center justify-between gap-3'>
            <div>
              <p className='text-xs font-semibold uppercase tracking-widest text-emerald-100 mb-1'>Dashboard</p>
              <h1 className='text-2xl sm:text-3xl font-bold'>{hospital?.name || deanInfo?.hospitalName || 'Your Hospital'}</h1>
              <p className='text-sm text-emerald-100 mt-1'>{hospital?.address}</p>
            </div>
            <div className='text-right bg-white/20 backdrop-blur rounded-xl p-3'>
              <p className='text-lg font-bold tracking-wider'>{formatTime(currentTime)}</p>
              <p className='text-[10px] text-emerald-100 mt-0.5'>{formatDate(currentTime)}</p>
            </div>
          </div>
        </div>

        {/* Top Widgets - Premium Style matched with Super Admin */}
        <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-3 sm:gap-4'>
          {/* 1. Revenue */}
          <GlassCard
            className="p-4 bg-white rounded-3xl shadow-sm border border-gray-100 flex items-center gap-4 cursor-pointer hover-lift transition-all"
            onClick={() => navigate('/dean-appointments')}
          >
            <div className='bg-pink-500 rounded-2xl p-3 shadow-lg flex-shrink-0'>
              <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div className='flex flex-col min-w-0'>
              <p className='text-xl sm:text-2xl font-bold text-gray-900 leading-tight'>
                <AnimatedCounter value={dashData.revenueTotal || 0} prefix="₹" />
              </p>
              <p className='text-gray-500 text-[10px] sm:text-xs font-medium'>Revenue</p>
              <p className='text-[9px] text-pink-600 font-semibold mt-0.5'>Today: ₹{dashData.revenueToday || 0}</p>
            </div>
          </GlassCard>

          {/* 2. Total Appointments */}
          <GlassCard
            className="p-4 bg-white rounded-3xl shadow-sm border border-gray-100 flex items-center gap-4 cursor-pointer hover-lift transition-all"
            onClick={() => navigate('/dean-appointments')}
          >
            <div className='bg-blue-500 rounded-2xl p-3 shadow-lg flex-shrink-0'>
              <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <div className='flex flex-col min-w-0'>
              <p className='text-xl sm:text-2xl font-bold text-gray-900 leading-tight'>
                <AnimatedCounter value={dashData.totalAppointments || 0} />
              </p>
              <p className='text-gray-500 text-[10px] sm:text-xs font-medium'>Total Appts</p>
            </div>
          </GlassCard>

          {/* 3. Active Doctors */}
          <GlassCard
            className="p-4 bg-white rounded-3xl shadow-sm border border-gray-100 flex items-center gap-4 cursor-pointer hover-lift transition-all"
            onClick={() => navigate('/dean-doctors')}
          >
            <div className='bg-green-500 rounded-2xl p-3 shadow-lg flex-shrink-0'>
              <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div className='flex flex-col min-w-0'>
              <p className='text-xl sm:text-2xl font-bold text-gray-900 leading-tight'>
                {dashData.activeDoctors || 0} / {dashData.totalDoctors || 0}
              </p>
              <p className='text-gray-500 text-[10px] sm:text-xs font-medium'>Active Doctors</p>
            </div>
          </GlassCard>

          {/* 4. Total Patients */}
          <GlassCard
            className="p-4 bg-white rounded-3xl shadow-sm border border-gray-100 flex items-center gap-4 cursor-pointer hover-lift transition-all"
            onClick={() => navigate('/dean-patients')}
          >
            <div className='bg-indigo-600 rounded-2xl p-3 shadow-lg flex-shrink-0'>
              <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4.354a4 4 0 110 5.292M15 21H3v-1a6 6 0 0112 0v1zm0 0h6v-1a6 6 0 00-9-5.197M13 7a4 4 0 11-8 0 4 4 0 018 0z" />
              </svg>
            </div>
            <div className='flex flex-col min-w-0'>
              <p className='text-xl sm:text-2xl font-bold text-gray-900 leading-tight'>
                <AnimatedCounter value={dashData.totalPatients || 0} />
              </p>
              <p className='text-gray-500 text-[10px] sm:text-xs font-medium'>Total Patients</p>
              <p className='text-[9px] text-indigo-600 font-semibold mt-0.5'>Today: {dashData.patientsToday || 0}</p>
            </div>
          </GlassCard>

          {/* 5. Appointments Today */}
          <GlassCard
            className="p-4 bg-white rounded-3xl shadow-sm border border-gray-100 flex items-center gap-4 cursor-pointer hover-lift transition-all"
            onClick={() => navigate('/dean-appointments')}
          >
            <div className='bg-purple-600 rounded-2xl p-3 shadow-lg flex-shrink-0'>
              <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <div className='flex flex-col min-w-0'>
              <p className='text-xl sm:text-2xl font-bold text-gray-900 leading-tight'>
                <AnimatedCounter value={dashData.appointmentsToday || 0} />
              </p>
              <p className='text-gray-500 text-[10px] sm:text-xs font-medium'>Appts Today</p>
            </div>
          </GlassCard>
        </div>

        {/* Charts Section */}
        <div className='grid grid-cols-1 lg:grid-cols-2 gap-4'>
          <GlassCard className="p-4 flex flex-col min-h-[300px]">
            <h3 className='text-lg font-bold text-gray-800 mb-4 flex items-center gap-2'>
              <svg className='w-6 h-6 text-emerald-600' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
              </svg>
              Patient Registration Trend
            </h3>
            <div className="flex-1">
              <LineChart data={chartData.patientGrowth} title="Patients" color="#10b981" />
            </div>
          </GlassCard>

          <GlassCard className="p-4 flex flex-col min-h-[300px]">
            <h3 className='text-lg font-bold text-gray-800 mb-4 flex items-center gap-2'>
              <svg className='w-6 h-6 text-teal-600' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 19v-6a2 2 0 00-2-2H5a2 2 0 00-2 2v6a2 2 0 002 2h2a2 2 0 002-2zm0 0V9a2 2 0 012-2h2a2 2 0 012 2v10m-6 0a2 2 0 002 2h2a2 2 0 002-2m0 0V5a2 2 0 012-2h2a2 2 0 012 2v14a2 2 0 01-2 2h-2a2 2 0 01-2-2z" />
              </svg>
              Revenue Trend (30 Days)
            </h3>
            <div className="flex-1">
              <BarChart data={chartData.revenue} title="Revenue" color="#0d9488" />
            </div>
          </GlassCard>
        </div>

        {/* Appointments Peak Hours */}
        <GlassCard className="p-4 min-h-[300px]">
          <h3 className='text-lg font-bold text-gray-800 mb-4 flex items-center gap-2'>
            <svg className='w-6 h-6 text-cyan-600' fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
            </svg>
            Appointments Peak Hours
          </h3>
          <div className="flex-1">
            <AreaChart data={chartData.appointments} title="Appointments" color="#0891b2" />
          </div>
        </GlassCard>



      </div>
    </div>
  )
}

export default DeanDashboard
