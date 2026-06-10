import React from 'react'
import QueueManager from '../../components/QueueManager'

const QueueManagement = () => {
  return (
    <div className='w-full bg-white p-4 sm:p-4 lg:p-6 animate-fade-in-up mobile-safe-area pb-6'>
      <div className="mb-4 sm:mb-5">
        <h1 className="text-xl sm:text-2xl font-bold text-gray-900 mb-1">Queue Management</h1>
        <p className="text-sm text-gray-600">Manage your patient queue and schedule</p>
      </div>
      <QueueManager />
    </div>
  )
}

export default QueueManagement

