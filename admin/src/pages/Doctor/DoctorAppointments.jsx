import React, { useState } from 'react'
import { useContext, useEffect } from 'react'
import { useSearchParams } from 'react-router-dom'
import { getPatientName, getPatientAge, getPatientImage } from '../../utils/appointmentDisplay'
import { DoctorContext } from '../../context/DoctorContext'
import { AppContext } from '../../context/AppContext'
import { assets } from '../../assets/assets'
import AppointmentDetailModal from '../../components/AppointmentDetailModal'

const DoctorAppointments = () => {

  const { dToken, appointments, getAppointments, cancelAppointment, completeAppointment } = useContext(DoctorContext)
  const { slotDateFormat, calculateAge, currency } = useContext(AppContext)
  const [selectedAppointment, setSelectedAppointment] = useState(null)
  const [searchParams, setSearchParams] = useSearchParams()
  const [filteredAppointments, setFilteredAppointments] = useState([])
  const [viewMode, setViewMode] = useState('list') // 'list' or 'calendar'

  // Initialize activeTab from URL parameter or default to 'all'
  const validTabs = ['today', 'all', 'cancelled']
  const [activeTab, setActiveTab] = useState(() => {
    const tabParam = searchParams.get('tab')
    return validTabs.includes(tabParam) ? tabParam : 'all'
  })

  useEffect(() => {
    if (dToken) {
      getAppointments()
    }
  }, [dToken])

  // Update URL when tab changes
  useEffect(() => {
    if (activeTab === 'all') {
      setSearchParams({}, { replace: true })
    } else {
      setSearchParams({ tab: activeTab }, { replace: true })
    }
  }, [activeTab, setSearchParams])

  // Initialize tab from URL on mount
  useEffect(() => {
    const tabParam = searchParams.get('tab')
    setActiveTab(validTabs.includes(tabParam) ? tabParam : 'all')
  }, [searchParams])

  // Apply tab filter
  useEffect(() => {
    const today = new Date()
    const d = today.getDate()
    const m = today.getMonth() + 1
    const y = today.getFullYear()
    const todayStrStd = `${d.toString().padStart(2, '0')}_${m.toString().padStart(2, '0')}_${y}`
    const todayStrLeg = `${d}_${m}_${y}`

    const result = appointments.filter(a => {
      if (activeTab === 'today') {
        const isToday = a.slotDate === todayStrStd || a.slotDate === todayStrLeg
        return isToday
      } else if (activeTab === 'cancelled') {
        return a.cancelled
      }
      return true
    })

    setFilteredAppointments(result)
  }, [appointments, activeTab])

  return (
    <div className='w-full bg-white p-4 sm:p-4 animate-fade-in-up mobile-safe-area pb-6'>

      <div className='mb-3 sm:mb-4 flex items-center justify-between'>
        <div>
          <h1 className='text-lg sm:text-xl font-bold text-gray-800 mb-1'>Appointments</h1>
          <p className='text-xs sm:text-sm text-gray-600'>Manage and track all your patient appointments</p>
        </div>
        <button
          onClick={() => setViewMode(viewMode === 'list' ? 'calendar' : 'list')}
          className='flex items-center gap-2 px-4 py-2 rounded-lg bg-blue-600 hover:bg-blue-700 text-white text-sm font-semibold transition-all duration-200 shadow-md hover:shadow-lg'
          title={viewMode === 'list' ? 'View Calendar' : 'View List'}
        >
          <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={viewMode === 'list' ? "M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" : "M4 6h16M4 10h16M4 14h16M4 18h16"} />
          </svg>
          {viewMode === 'list' ? 'Calendar' : 'List'}
        </button>
      </div>

      {/* Tab Navigation */}
      <div className='flex items-center gap-2 text-sm mb-4'>
        <button
          onClick={() => setActiveTab('today')}
          className={`px-4 py-2 rounded-full font-medium transition-all relative ${
            activeTab === 'today' 
              ? 'bg-white text-indigo-600 shadow-md' 
              : 'text-gray-600 hover:bg-gray-50'
          }`}
        >
          Today
          {activeTab === 'today' && (
            <span className='absolute bottom-0 left-0 w-full h-0.5 bg-indigo-600 rounded-full animate-pulse'></span>
          )}
        </button>
        <button
          onClick={() => setActiveTab('all')}
          className={`px-4 py-2 rounded-full font-medium transition-all relative ${
            activeTab === 'all' 
              ? 'bg-white text-indigo-600 shadow-md' 
              : 'text-gray-600 hover:bg-gray-50'
          }`}
        >
          All
          {activeTab === 'all' && (
            <span className='absolute bottom-0 left-0 w-full h-0.5 bg-indigo-600 rounded-full animate-pulse'></span>
          )}
        </button>
        <button
          onClick={() => setActiveTab('cancelled')}
          className={`px-4 py-2 rounded-full font-medium transition-all relative ${
            activeTab === 'cancelled' 
              ? 'bg-white text-indigo-600 shadow-md' 
              : 'text-gray-600 hover:bg-gray-50'
          }`}
        >
          Cancelled
          {activeTab === 'cancelled' && (
            <span className='absolute bottom-0 left-0 w-full h-0.5 bg-indigo-600 rounded-full animate-pulse'></span>
          )}
        </button>
      </div>

      {viewMode === 'calendar' ? (
        <div className='bg-white rounded-xl sm:rounded-2xl shadow-sm border border-gray-200 overflow-hidden p-4 sm:p-6'>
          <h2 className='text-lg font-bold text-gray-800 mb-4'>Weekly Schedule</h2>
          <div className='overflow-x-auto'>
            <div className='min-w-[800px]'>
              {/* Calendar Header */}
              <div className='grid grid-cols-7 gap-2 mb-2'>
                {['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map((day) => (
                  <div key={day} className='text-center text-xs sm:text-sm font-semibold text-gray-700 py-2 bg-gray-50 rounded-lg'>
                    {day.slice(0, 3)}
                  </div>
                ))}
              </div>
              
              {/* Calendar Grid */}
              <div className='grid grid-cols-7 gap-2'>
                {['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'].map((day) => {
                  // Get appointments for this day of the week
                  const dayAppointments = filteredAppointments.filter(apt => {
                    const aptDate = new Date(apt.slotDate)
                    const dayIndex = aptDate.getDay()
                    const dayMap = { 1: 'Monday', 2: 'Tuesday', 3: 'Wednesday', 4: 'Thursday', 5: 'Friday', 6: 'Saturday', 0: 'Sunday' }
                    return dayMap[dayIndex] === day
                  })

                  return (
                    <div key={day} className='min-h-[400px] bg-gray-50 rounded-lg p-2 border border-gray-200'>
                      {dayAppointments.length === 0 ? (
                        <p className='text-xs text-gray-400 text-center mt-2'>No appointments</p>
                      ) : (
                        <div className='space-y-2'>
                          {dayAppointments.map((apt, idx) => {
                            const patientName = apt.actualPatient && !apt.actualPatient.isSelf ? apt.actualPatient.name : apt.userData?.name || 'Patient'
                            const startTime = apt.slotTime.split('-')[0] || apt.slotTime
                            const endTime = apt.slotTime.includes('-') ? apt.slotTime.split('-')[1] : null

                            return (
                              <div
                                key={idx}
                                onClick={() => setSelectedAppointment(apt)}
                                className='bg-gradient-to-br from-blue-500 to-cyan-500 text-white p-2 rounded-lg cursor-pointer hover:shadow-lg transition-all duration-200 text-xs'
                                style={{
                                  backgroundColor: apt.cancelled ? '#ef4444' : apt.isCompleted ? '#10b981' : '#3b82f6'
                                }}
                              >
                                <div className='font-semibold mb-1 truncate'>{patientName}</div>
                                <div className='text-[10px] opacity-90'>
                                  {startTime}{endTime ? ` - ${endTime}` : ''}
                                </div>
                                {apt.tokenNumber && (
                                  <div className='text-[10px] opacity-75 mt-1'>Token #{apt.tokenNumber}</div>
                                )}
                              </div>
                            )
                          })}
                        </div>
                      )}
                    </div>
                  )
                })}
              </div>
            </div>
          </div>
        </div>
      ) : (
        <div className='bg-white rounded-xl sm:rounded-2xl shadow-sm border border-gray-200 overflow-hidden'>
          {/* Table Body */}
          <div className='overflow-x-auto lg:overflow-y-auto lg:max-h-[calc(100vh-300px)]'
            style={{
              scrollBehavior: 'smooth'
            }}
          >
            <div className='min-w-[1000px]'>
              {/* Table Header - Sticky */}
              <div 
                className='hidden sm:grid grid-cols-[0.5fr_2fr_1fr_1fr_1fr_2.5fr_1fr_1.5fr] gap-2.5 sm:gap-3 py-2.5 px-3 sm:px-4 bg-gradient-to-r from-blue-500 to-cyan-500 text-white font-semibold text-xs sm:text-sm border-b border-blue-600'
                style={{
                  position: 'sticky',
                  top: 0,
                  zIndex: 5
                }}
              >
                <p className='text-center'>#</p>
                <p className='text-left'>Patient</p>
                <p className='text-center'>Token</p>
                <p className='text-center'>Payment</p>
                <p className='text-center'>Age</p>
                <p className='text-left'>Date & Time</p>
                <p className='text-right'>Fees</p>
                <p className='text-center'>Action</p>
              </div>
            {filteredAppointments.length === 0 ? (
            <div className='flex flex-col items-center justify-center py-12 sm:py-16 px-4 sm:px-6'>
              <svg className='w-16 h-16 sm:w-24 sm:h-24 text-gray-300 mb-3 sm:mb-4' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M8 7V3m8 4V3m-9 8h10M5 21h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v12a2 2 0 002 2z" />
              </svg>
              <p className='text-gray-500 text-base sm:text-lg font-medium'>No appointments found</p>
              <p className='text-gray-400 text-xs sm:text-sm mt-1'>Your appointments will appear here</p>
            </div>
          ) : (
            <>
            {/* Mobile Cards */}
            <div className='sm:hidden space-y-4 sm:space-y-5 p-0'>
              {filteredAppointments.map((item, index) => (
                <div key={index} className='bg-white rounded-xl p-5 sm:p-6 border border-gray-200 shadow-sm w-full'>
                    <div className='flex items-start gap-4 sm:gap-5'>
                      <img src={getPatientImage(item)} className='w-14 h-14 sm:w-16 sm:h-16 rounded-full object-cover ring-2 ring-blue-200 flex-shrink-0' alt="" />
                      <div className='flex-1 min-w-0'>
                        <p className='font-semibold text-base sm:text-lg text-gray-800 mb-1'>
                          {getPatientName(item)}
                        </p>
                        <p className='text-xs text-gray-500 mb-1'>Age {getPatientAge(item, calculateAge)}</p>
                        {item.actualPatient && !item.actualPatient.isSelf && (
                          <p className='text-xs sm:text-sm text-cyan-600 mt-1 mb-1.5 font-medium'>{item.actualPatient.relationship}</p>
                        )}
                        <p className='text-xs sm:text-sm text-gray-500 mt-1.5 mb-3'>{slotDateFormat(item.slotDate)} • {item.slotTime}</p>
                        <div className='flex items-center justify-between mt-4 pt-3 border-t border-gray-200'>
                          <span className='text-lg sm:text-xl font-bold text-blue-600'>{currency}{item.amount}</span>
                          {item.cancelled ? (
                            <span className='px-3 sm:px-4 py-1.5 bg-red-100 text-red-700 text-xs sm:text-sm font-semibold rounded-full badge-cancelled'>Cancelled</span>
                          ) : item.isCompleted ? (
                            <span className='px-3 sm:px-4 py-1.5 bg-green-100 text-green-700 text-xs sm:text-sm font-semibold rounded-full badge-completed'>Completed</span>
                          ) : (
                            <div className='flex gap-2.5 flex-wrap'>
                              <button onClick={() => cancelAppointment(item._id)} className='p-2.5 bg-red-50 hover:bg-red-100 rounded-lg transition-colors'>
                                <svg className='w-5 h-5 sm:w-6 sm:h-6 text-red-600' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                                </svg>
                              </button>
                              <button onClick={() => completeAppointment(item._id)} className='p-2.5 bg-green-50 hover:bg-green-100 rounded-lg transition-colors'>
                                <svg className='w-5 h-5 sm:w-6 sm:h-6 text-green-600' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                                </svg>
                              </button>
                            </div>
                          )}
                        </div>
                      </div>
                    </div>
                  </div>
                ))}
              </div>
              
            {/* Desktop Table Rows */}
            {filteredAppointments.map((item, index) => (
              <div 
                className='hidden sm:grid grid-cols-[0.5fr_2fr_1fr_1fr_1fr_2.5fr_1fr_1.5fr] gap-2.5 sm:gap-3 items-center text-gray-700 py-2.5 px-3 sm:px-4 border-b border-gray-100 bg-white hover:bg-gray-50 transition-colors duration-150 group' 
                key={index}
              >
                <p className='text-center text-gray-500 font-medium'>{index + 1}</p>
                
                <div className='flex items-center gap-3 min-w-0'>
                  <div className='relative flex-shrink-0'>
                    <img 
                      src={getPatientImage(item)} 
                      className='w-10 h-10 rounded-full object-cover ring-2 ring-blue-200 group-hover:ring-blue-400 transition-all duration-300 shadow-md' 
                      alt="" 
                    />
                    <div className='absolute -bottom-1 -right-1 w-3 h-3 bg-green-500 rounded-full border-2 border-white'></div>
                  </div>
                  <div className='min-w-0 flex-1'>
                    <p className='font-semibold text-gray-800 truncate text-sm'>
                      {getPatientName(item)}
                    </p>
                    {item.actualPatient && !item.actualPatient.isSelf && (
                      <div className='flex items-center gap-2 mt-1 flex-wrap'>
                        <span className='pill-badge bg-cyan-100 text-cyan-700 border border-cyan-300 text-xs'>
                          {item.actualPatient.relationship}
                        </span>
                        <span className='text-xs text-gray-500'>
                          by {item.userData.name}
                        </span>
                      </div>
                    )}
                  </div>
                </div>

                <div className='flex justify-center'>
                  {item.tokenNumber ? (
                    <span className='pill-badge bg-gradient-to-r from-cyan-100 to-blue-100 text-cyan-700 border border-cyan-300 font-semibold text-xs inline-block'>
                      #{item.tokenNumber}
                    </span>
                  ) : (
                    <span className='text-xs text-gray-400'>-</span>
                  )}
                </div>

                <div className='flex justify-center'>
                  <span className={`pill-badge text-xs font-semibold inline-block ${
                    item.payment 
                      ? 'bg-gradient-to-r from-green-100 to-emerald-100 text-green-700 border border-green-300' 
                      : 'bg-gradient-to-r from-orange-100 to-amber-100 text-orange-700 border border-orange-300'
                  }`}>
                    {item.payment ? 'Online' : 'CASH'}
                  </span>
                </div>

                <p className='text-center text-gray-600 font-medium text-sm'>
                  {getPatientAge(item, calculateAge)}
                </p>

                <p className='text-left text-gray-700 font-medium text-sm'>
                  {slotDateFormat(item.slotDate)}, {item.slotTime}
                </p>

                <p className='text-right font-bold text-gray-800 text-sm'>{currency}{item.amount}</p>

                <div className='flex items-center justify-center gap-2 flex-wrap'>
                  <button
                    onClick={() => setSelectedAppointment(item)}
                    className='px-4 py-2 bg-gradient-to-r from-blue-500 to-cyan-500 hover:from-blue-600 hover:to-cyan-600 text-white text-xs font-semibold rounded-lg transition-all duration-300 shadow-md hover:shadow-lg ripple'
                    title="View Details & Reports"
                  >
                    View
                  </button>
                  {item.cancelled ? (
                    <span className='pill-badge bg-red-100 text-red-700 border border-red-300 text-xs'>Cancelled</span>
                  ) : item.isCompleted ? (
                    <span className='pill-badge bg-green-100 text-green-700 border border-green-300 text-xs'>Completed</span>
                  ) : (
                    <div className='flex gap-2'>
                      <button 
                        onClick={() => cancelAppointment(item._id)} 
                        className='p-2 rounded-lg bg-red-50 hover:bg-red-100 text-red-600 transition-all duration-300'
                        title="Cancel"
                      >
                        <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                        </svg>
                      </button>
                      <button 
                        onClick={() => completeAppointment(item._id)} 
                        className='p-2 rounded-lg bg-green-50 hover:bg-green-100 text-green-600 transition-all duration-300'
                        title="Complete"
                      >
                        <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                        </svg>
                      </button>
                    </div>
                  )}
                </div>
              </div>
            ))}
            </>
          )}
          </div>
        </div>
      </div>
      )}

      {/* Appointment Detail Modal */}
      {selectedAppointment && (
        <AppointmentDetailModal
          appointment={selectedAppointment}
          onClose={() => setSelectedAppointment(null)}
        />
      )}

    </div>
  )
}

export default DoctorAppointments