import React, { useContext, useEffect, useMemo } from 'react'
import { useNavigate } from 'react-router-dom'
import { DoctorContext } from '../../context/DoctorContext'
import { AppContext } from '../../context/AppContext'
import { canJoinVideoCall } from '../../utils/videoConsult'
import { getPatientName, getPatientAge, getPatientImage } from '../../utils/appointmentDisplay'

const DoctorVideoCalls = () => {
  const { dToken, appointments, getAppointments } = useContext(DoctorContext)
  const { slotDateFormat, calculateAge, currency } = useContext(AppContext)
  const navigate = useNavigate()

  useEffect(() => {
    if (dToken) getAppointments()
  }, [dToken])

  const videoAppointments = useMemo(
    () => appointments.filter((a) => canJoinVideoCall(a)),
    [appointments]
  )

  return (
    <div className='w-full bg-white p-4 sm:p-4 animate-fade-in-up mobile-safe-area pb-6'>
      <div className='mb-4'>
        <h1 className='text-lg sm:text-xl font-bold text-gray-800 mb-1'>Video Call</h1>
        <p className='text-xs sm:text-sm text-gray-600'>
          Connect with your active patients via secure Agora video
        </p>
      </div>

      <div className='bg-white rounded-xl sm:rounded-2xl shadow-sm border border-gray-200 overflow-hidden p-4 sm:p-6'>
        {videoAppointments.length === 0 ? (
          <div className='flex flex-col items-center justify-center py-16 text-gray-400'>
            <svg className='w-16 h-16 mb-3 text-indigo-200' fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
            </svg>
            <p className='font-medium text-gray-600'>No active appointments for video call</p>
            <p className='text-xs mt-1 text-center max-w-sm'>
              Completed and cancelled visits are not listed. Bookings appear here when patients have upcoming visits.
            </p>
          </div>
        ) : (
          <div className='space-y-3'>
            {videoAppointments.map((item) => (
              <div
                key={item._id}
                className='flex flex-col sm:flex-row sm:items-center gap-4 p-4 rounded-xl border border-indigo-100 bg-gradient-to-r from-indigo-50/50 to-white hover:shadow-md transition-shadow'
              >
                <img
                  src={getPatientImage(item)}
                  alt=""
                  className='w-14 h-14 rounded-full object-cover ring-2 ring-indigo-200 flex-shrink-0'
                />
                <div className='flex-1 min-w-0'>
                  <p className='font-bold text-gray-900 text-base'>{getPatientName(item)}</p>
                  <p className='text-sm text-gray-600 mt-0.5'>
                    Age {getPatientAge(item, calculateAge)} · {slotDateFormat(item.slotDate)} at {item.slotTime}
                  </p>
                  <p className='text-xs text-gray-500 mt-1'>
                    {item.payment ? 'Paid online' : 'In-clinic'} · {currency}{item.amount}
                  </p>
                </div>
                <button
                  type='button'
                  onClick={() => navigate(`/doctor-video/${item._id}`)}
                  className='flex items-center justify-center gap-2 px-5 py-3 bg-indigo-600 hover:bg-indigo-700 text-white text-sm font-semibold rounded-lg shadow-md flex-shrink-0'
                >
                  <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                  </svg>
                  Join Video Call
                </button>
              </div>
            ))}
          </div>
        )}
      </div>
    </div>
  )
}

export default DoctorVideoCalls
