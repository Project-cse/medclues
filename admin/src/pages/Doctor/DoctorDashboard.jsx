import React from 'react'
import { useContext } from 'react'
import { useEffect } from 'react'
import { useState } from 'react'
import { useNavigate } from 'react-router-dom'
import { DoctorContext } from '../../context/DoctorContext'
import { assets } from '../../assets/assets'
import { AppContext } from '../../context/AppContext'
import AnimatedCounter from '../../components/ui/AnimatedCounter'
import { getPatientName, getPatientAge, getPatientImage } from '../../utils/appointmentDisplay'
import { isOnlineVideoAppointment } from '../../utils/videoConsult'

const DoctorDashboard = () => {

  const { dToken, dashData, getDashData, cancelAppointment, completeAppointment } = useContext(DoctorContext)
  const { slotDateFormat, calculateAge, currency } = useContext(AppContext)
  const [currentTime, setCurrentTime] = useState(new Date())
  const navigate = useNavigate()

  useEffect(() => {

    if (dToken) {
      getDashData()
    }

  }, [dToken])

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date())
    }, 1000)
    return () => clearInterval(timer)
  }, [])

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

  if (!dashData) {
    return (
      <div className="flex items-center justify-center min-h-[calc(100vh-64px)] bg-gradient-to-br from-gray-50 via-white to-indigo-50/30">
        <div className="text-center">
          <div className="animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto"></div>
          <p className="mt-4 text-gray-600">Loading dashboard...</p>
        </div>
      </div>
    )
  }

  return (
    <div className='w-full bg-gradient-to-br from-gray-50 via-white to-indigo-50/30 p-4 sm:p-5 lg:p-6 animate-fade-in-up mobile-safe-area pb-6 min-h-screen'>
      <div className='max-w-7xl mx-auto space-y-4'>
        
      {/* Enhanced Clock and Date Widget */}
      <div className='flex flex-col sm:flex-row gap-3 sm:gap-4'>
        {/* Live Clock Card */}
        <div className='flex-1 bg-white rounded-xl shadow-lg border border-white/50 p-4 hover:shadow-xl transition-all duration-300'>
          <div className='flex items-center gap-3'>
            <div className='bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 rounded-lg p-2 shadow-md shadow-indigo-500/30 flex-shrink-0'>
              <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div className='min-w-0 flex-1'>
              <h2 className='text-xl sm:text-2xl font-bold tracking-wider text-gray-900'>{formatTime(currentTime)}</h2>
              <div className='flex items-center gap-1.5 mt-1'>
                <span className='w-1.5 h-1.5 rounded-full bg-green-500 animate-pulse'></span>
                <p className='text-indigo-600 text-xs font-semibold'>Live</p>
                <span className='text-gray-400'>•</span>
                <p className='text-gray-500 text-[10px]'>{formatDate(currentTime)}</p>
              </div>
            </div>
          </div>
        </div>
        
        {/* Current Date Card */}
        <div className='flex-1 bg-white rounded-xl shadow-lg border border-white/50 p-4 hover:shadow-xl transition-all duration-300'>
          <div className='flex items-center gap-3'>
            <div className='bg-gradient-to-br from-blue-500 via-cyan-500 to-teal-500 rounded-lg p-2 shadow-md shadow-blue-500/30 flex-shrink-0'>
              <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <div className='min-w-0 flex-1'>
              <p className='text-sm sm:text-base font-bold text-gray-900 break-words leading-tight'>{formatDate(currentTime)}</p>
              <p className='text-blue-600 text-xs font-semibold mt-1'>Current Date</p>
            </div>
          </div>
        </div>
      </div>

      {/* Modern Analytics Cards */}
      <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-3 sm:gap-4'>
        {/* Earnings Card */}
        <div className='bg-white rounded-xl p-4 shadow-lg border border-white/50 hover:shadow-xl transition-all duration-300 relative overflow-hidden group cursor-pointer'>
          <div className='absolute top-0 right-0 w-24 h-24 bg-gradient-to-br from-blue-500/5 to-cyan-500/5 rounded-full -mr-12 -mt-12'></div>
          <div className='relative z-10 flex items-center gap-3'>
            <div className='bg-gradient-to-br from-blue-500 via-cyan-500 to-teal-500 rounded-lg p-2.5 shadow-md shadow-blue-500/30 group-hover:scale-105 transition-transform duration-300 flex-shrink-0'>
              <svg className='w-5 h-5 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 8c-1.657 0-3 .895-3 2s1.343 2 3 2 3 .895 3 2-1.343 2-3 2m0-8c1.11 0 2.08.402 2.599 1M12 8V7m0 1v8m0 0v1m0-1c-1.11 0-2.08-.402-2.599-1M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
              </svg>
            </div>
            <div className='flex-1 min-w-0'>
              <p className='text-gray-600 text-xs font-semibold mb-0.5'>Revenue</p>
              <p className='text-xl sm:text-2xl font-bold bg-gradient-to-r from-blue-600 to-cyan-600 bg-clip-text text-transparent'>
                {currency}{dashData.earnings ? dashData.earnings.toLocaleString() : '0'}
              </p>
            </div>
          </div>
        </div>

        {/* Appointments Card */}
        <div 
          onClick={() => navigate('/doctor-appointments')}
          className='bg-white rounded-xl p-4 shadow-lg border border-white/50 hover:shadow-xl transition-all duration-300 relative overflow-hidden group cursor-pointer'
        >
          <div className='absolute top-0 right-0 w-24 h-24 bg-gradient-to-br from-purple-500/5 to-pink-500/5 rounded-full -mr-12 -mt-12'></div>
          <div className='relative z-10 flex items-center gap-3'>
            <div className='bg-gradient-to-br from-purple-500 via-pink-500 to-rose-500 rounded-lg p-2.5 shadow-md shadow-purple-500/30 group-hover:scale-105 transition-transform duration-300 flex-shrink-0'>
              <svg className='w-5 h-5 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
            </div>
            <div className='flex-1 min-w-0'>
              <p className='text-gray-600 text-xs font-semibold mb-0.5'>Appointments</p>
              <p className='text-xl sm:text-2xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent'>
                <AnimatedCounter value={dashData.appointments || 0} duration={2000} />
              </p>
            </div>
          </div>
        </div>

        {/* Patients Card */}
        <div 
          onClick={() => navigate('/doctor-appointments')}
          className='bg-white rounded-xl p-4 shadow-lg border border-white/50 hover:shadow-xl transition-all duration-300 relative overflow-hidden group cursor-pointer'
        >
          <div className='absolute top-0 right-0 w-24 h-24 bg-gradient-to-br from-green-500/5 to-emerald-500/5 rounded-full -mr-12 -mt-12'></div>
          <div className='relative z-10 flex items-center gap-3'>
            <div className='bg-gradient-to-br from-green-500 via-emerald-500 to-teal-500 rounded-lg p-2.5 shadow-md shadow-green-500/30 group-hover:scale-105 transition-transform duration-300 flex-shrink-0'>
              <svg className='w-5 h-5 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
              </svg>
            </div>
            <div className='flex-1 min-w-0'>
              <p className='text-gray-600 text-xs font-semibold mb-0.5'>Total Patients</p>
              <p className='text-xl sm:text-2xl font-bold bg-gradient-to-r from-green-600 to-emerald-600 bg-clip-text text-transparent'>
                <AnimatedCounter value={dashData.patients || 0} duration={2000} />
              </p>
            </div>
          </div>
        </div>
      </div>

      {/* Today's Video Consultations */}
      <div className='bg-white rounded-xl shadow-lg border border-white/50 overflow-hidden'>
        <div className='flex items-center justify-between px-4 py-3 bg-gradient-to-r from-indigo-50 via-blue-50 to-cyan-50 border-b border-gray-200'>
          <div className='flex items-center gap-2.5'>
            <div className='bg-gradient-to-br from-indigo-600 to-blue-600 rounded-lg p-2 shadow-md'>
              <svg className='w-5 h-5 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
              </svg>
            </div>
            <div>
              <h3 className='font-bold text-gray-900 text-base'>Video Consultations</h3>
              <p className='text-[10px] text-gray-500 mt-0.5'>Paid online appointments ready for video call</p>
            </div>
          </div>
        </div>

        <div className='divide-y divide-gray-100 max-h-[360px] overflow-y-auto'>
          {(!dashData.todayVideoConsults || dashData.todayVideoConsults.length === 0) ? (
            <div className='flex flex-col items-center justify-center py-10 text-gray-400'>
              <svg className='w-12 h-12 mb-2 text-indigo-200' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
              </svg>
              <p className='text-sm font-medium text-gray-600'>No active video consultations</p>
            </div>
          ) : (
            dashData.todayVideoConsults.map((item, index) => (
              <div
                key={item._id || index}
                className='flex flex-col sm:flex-row sm:items-center gap-3 px-4 py-3 hover:bg-indigo-50/40 transition-colors'
              >
                <div className='flex items-center gap-3 flex-1 min-w-0'>
                  <img
                    className='rounded-full w-10 h-10 object-cover ring-2 ring-indigo-100 flex-shrink-0'
                    src={getPatientImage(item)}
                    alt=""
                  />
                  <div className='min-w-0 flex-1'>
                    <p className='text-gray-900 font-bold text-sm truncate'>{getPatientName(item)}</p>
                    <p className='text-xs text-gray-600 mt-0.5'>
                      {item.slotTime || 'Time TBD'} · Age {getPatientAge(item, calculateAge)}
                    </p>
                    {item.selectedSymptoms?.length > 0 && (
                      <p className='text-[10px] text-gray-500 mt-1 truncate'>
                        Symptoms: {item.selectedSymptoms.slice(0, 3).join(', ')}
                      </p>
                    )}
                    <p className='text-[10px] mt-1'>
                      <span className={`inline-flex px-2 py-0.5 rounded-full font-semibold ${item.payment ? 'bg-green-100 text-green-700' : 'bg-amber-100 text-amber-700'}`}>
                        {item.payment ? 'Paid' : 'Payment pending'}
                      </span>
                      <span className='text-gray-400 mx-1'>·</span>
                      <span className='text-gray-600'>{currency}{item.amount}</span>
                    </p>
                  </div>
                </div>
                {isOnlineVideoAppointment(item) && !item.cancelled && !item.isCompleted && (
                  <button
                    type='button'
                    onClick={() => navigate(`/doctor-video/${item._id}`)}
                    className='flex items-center justify-center gap-2 px-4 py-2.5 bg-indigo-600 hover:bg-indigo-700 text-white text-xs font-semibold rounded-lg shadow-md flex-shrink-0'
                  >
                    <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                      <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                    </svg>
                    Join Video Call
                  </button>
                )}
              </div>
            ))
          )}
        </div>
      </div>

      {/* Latest Bookings Section */}
      <div className='bg-white rounded-xl shadow-lg border border-white/50 overflow-hidden'>
        <div className='flex items-center justify-between px-4 py-3 bg-gradient-to-r from-indigo-50 via-purple-50 to-pink-50 border-b border-gray-200'>
          <div className='flex items-center gap-2.5'>
            <div className='bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 rounded-lg p-2 shadow-md'>
              <svg className='w-5 h-5 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
            </div>
            <div>
              <h3 className='font-bold text-gray-900 text-base'>Latest Appointments</h3>
              <p className='text-[10px] text-gray-500 mt-0.5'>Recent patient appointments</p>
            </div>
          </div>
        </div>

        <div className='divide-y divide-gray-100 max-h-[400px] overflow-y-auto'>
          {(!dashData.latestAppointments || dashData.latestAppointments.length === 0) ? (
            <div className='flex flex-col items-center justify-center py-12 text-gray-400'>
              <svg className='w-16 h-16 mb-3' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M9 5H7a2 2 0 00-2 2v12a2 2 0 002 2h10a2 2 0 002-2V7a2 2 0 00-2-2h-2M9 5a2 2 0 002 2h2a2 2 0 002-2M9 5a2 2 0 012-2h2a2 2 0 012 2" />
              </svg>
              <p className='text-base font-medium'>No appointments yet</p>
              <p className='text-xs'>Your recent bookings will appear here</p>
            </div>
          ) : (
            dashData.latestAppointments.slice(0, 10).map((item, index) => (
              <div 
                onClick={() => navigate('/doctor-appointments?tab=today')}
                className='flex items-center px-4 py-3 gap-3 hover:bg-gradient-to-r hover:from-indigo-50/50 hover:to-purple-50/50 transition-all duration-300 group cursor-pointer' 
                key={index}
              >
                <div className='relative flex-shrink-0'>
                  <img 
                    className='rounded-full w-10 h-10 object-cover ring-2 ring-indigo-100 group-hover:ring-indigo-300 transition-all duration-300 shadow-md' 
                    src={getPatientImage(item)} 
                    alt="" 
                  />
                  {!item.cancelled && !item.isCompleted && (
                    <div className='absolute -bottom-0.5 -right-0.5 w-3 h-3 bg-green-500 rounded-full border-2 border-white shadow-sm'></div>
                  )}
                </div>
                <div className='flex-1 min-w-0'>
                  <p className='text-gray-900 font-bold text-sm truncate'>
                    {getPatientName(item)}
                  </p>
                  {item.actualPatient && !item.actualPatient.isSelf && (
                    <div className='flex items-center gap-1.5 mt-1 flex-wrap'>
                      <span className='inline-flex items-center px-2 py-0.5 rounded-full bg-cyan-100 text-cyan-700 border border-cyan-300 text-[10px] font-semibold'>
                        {item.actualPatient.relationship}
                      </span>
                      <span className='text-[10px] text-gray-500'>
                        Booked by: <span className='font-semibold text-gray-700'>{item.userData?.name || 'User'}</span>
                      </span>
                    </div>
                  )}
                  <div className='flex items-center gap-2 mt-1 flex-wrap text-xs text-gray-600'>
                    <span>Age <span className='font-semibold text-gray-800'>{getPatientAge(item, calculateAge)}</span></span>
                    <span className='text-gray-300'>•</span>
                    <span className='flex items-center gap-1'>
                      <svg className='w-3 h-3 text-gray-400' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
                      </svg>
                      <span className='font-semibold'>{slotDateFormat(item.slotDate)}</span>
                      {item.slotTime ? <span>at <span className='font-semibold'>{item.slotTime}</span></span> : null}
                    </span>
                  </div>
                </div>
                <div className='flex items-center gap-2 flex-shrink-0' onClick={(e) => e.stopPropagation()}>
                  {item.cancelled ? (
                    <span className='inline-flex items-center px-2 py-0.5 rounded-full bg-red-100 text-red-700 border border-red-300 text-[10px] font-bold'>Cancelled</span>
                  ) : item.isCompleted ? (
                    <span className='inline-flex items-center gap-1 px-2 py-0.5 rounded-full bg-green-100 text-green-700 border border-green-300 text-[10px] font-bold'>
                      <svg className='w-3 h-3' fill="currentColor" viewBox="0 0 20 20">
                        <path fillRule="evenodd" d="M10 18a8 8 0 100-16 8 8 0 000 16zm3.707-9.293a1 1 0 00-1.414-1.414L9 10.586 7.707 9.293a1 1 0 00-1.414 1.414l2 2a1 1 0 001.414 0l4-4z" clipRule="evenodd" />
                      </svg>
                      Completed
                    </span>
                  ) : (
                    <div className='flex gap-1'>
                      <button 
                        onClick={() => cancelAppointment(item._id)} 
                        className='p-1 rounded-md bg-red-50 hover:bg-red-100 text-red-600 transition-all duration-300 hover:scale-110 shadow-sm'
                        title="Cancel Appointment"
                      >
                        <svg className='w-3.5 h-3.5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      </button>
                      <button 
                        onClick={() => completeAppointment(item._id)} 
                        className='p-1 rounded-md bg-green-50 hover:bg-green-100 text-green-600 transition-all duration-300 hover:scale-110 shadow-sm'
                        title="Complete Appointment"
                      >
                        <svg className='w-3.5 h-3.5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                        </svg>
                      </button>
                    </div>
                  )}
                </div>
              </div>
            ))
          )}
        </div>
      </div>

      </div>
    </div>
  )
}

export default DoctorDashboard