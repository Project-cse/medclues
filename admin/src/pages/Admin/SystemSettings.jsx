import React, { useContext, useState } from 'react'
import { AdminContext } from '../../context/AdminContext'
import GlassCard from '../../components/ui/GlassCard'
import { toast } from 'react-toastify'

const SystemSettings = () => {
    const { aToken } = useContext(AdminContext)
    const [maintenanceMode, setMaintenanceMode] = useState(false)
    const [emailNotifications, setEmailNotifications] = useState(true)
    const [auditLogRetention, setAuditLogRetention] = useState(30)
    const [systemName, setSystemName] = useState('MedChain+')

    const handleSave = () => {
        toast.promise(
            new Promise(res => setTimeout(res, 800)),
            {
                pending: 'Saving system configuration...',
                success: 'Core system variables updated.',
                error: 'Encountered error while syncing settings.'
            }
        )
    }

    return (
        <div className='w-full bg-gradient-to-br from-indigo-50 via-white to-purple-50/30 p-4 sm:p-6 min-h-screen'>
            <div className='max-w-4xl mx-auto space-y-6'>
                <div className='mb-8'>
                    <h2 className='text-3xl font-bold bg-gradient-to-r from-gray-900 to-gray-500 bg-clip-text text-transparent'>System Configuration</h2>
                    <p className='text-sm text-gray-500'>Super Admin: Global properties and platform controls.</p>
                </div>

                <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
                    <GlassCard className='p-6'>
                        <h3 className='text-lg font-bold text-gray-800 mb-6 flex items-center gap-2'>
                            <svg className='w-5 h-5 text-indigo-500' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 6V4m0 2a2 2 0 100 4m0-4a2 2 0 110 4m-6 8a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4m6 6v10m6-2a2 2 0 100-4m0 4a2 2 0 110-4m0 4v2m0-6V4" />
                            </svg>
                            General Settings
                        </h3>
                        <div className='space-y-4'>
                            <div>
                                <label className='text-xs font-bold uppercase tracking-widest text-indigo-600 mb-2 block'>Platform Display Name</label>
                                <input value={systemName} onChange={e => setSystemName(e.target.value)}
                                    className='w-full px-4 py-2 border-2 border-gray-100 rounded-xl focus:border-indigo-500 outline-none transition-all text-sm' />
                            </div>
                            <div className='flex items-center justify-between p-3 bg-gray-50 rounded-xl'>
                                <div>
                                    <p className='text-sm font-bold text-gray-800'>Email Notifications</p>
                                    <p className='text-[10px] text-gray-500'>Enable global system alerts</p>
                                </div>
                                <button onClick={() => setEmailNotifications(!emailNotifications)} className={`w-12 h-6 rounded-full transition-all relative ${emailNotifications? 'bg-green-500':'bg-gray-300'}`}>
                                    <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${emailNotifications?'right-1':'left-1'}`} />
                                </button>
                            </div>
                        </div>
                    </GlassCard>

                    <GlassCard className='p-6 border-red-50'>
                        <h3 className='text-lg font-bold text-red-700 mb-6 flex items-center gap-2'>
                            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 9v2m0 4h.01m-6.938 4h13.856c1.54 0 2.502-1.667 1.732-3L13.732 4c-.77-1.333-2.694-1.333-3.464 0L3.34 16c-.77 1.333.192 3 1.732 3z" />
                            </svg>
                            Danger Zone Settings
                        </h3>
                        <div className='space-y-4'>
                            <div className='flex items-center justify-between p-3 bg-red-50 rounded-xl border border-red-100'>
                                <div>
                                    <p className='text-sm font-bold text-red-800'>Maintenance Mode</p>
                                    <p className='text-[10px] text-red-500'>Temporarily block user access</p>
                                </div>
                                <button onClick={() => setMaintenanceMode(!maintenanceMode)} className={`w-12 h-6 rounded-full transition-all relative ${maintenanceMode? 'bg-red-600':'bg-gray-300'}`}>
                                    <div className={`absolute top-1 w-4 h-4 rounded-full bg-white transition-all ${maintenanceMode?'right-1':'left-1'}`} />
                                </button>
                            </div>
                            <div>
                                <label className='text-xs font-bold uppercase tracking-widest text-red-600 mb-2 block'>Audit Log Retention (Days)</label>
                                <input type='number' value={auditLogRetention} onChange={e => setAuditLogRetention(e.target.value)}
                                    className='w-full px-4 py-2 border-2 border-red-100 rounded-xl focus:border-red-500 outline-none transition-all text-sm' />
                            </div>
                        </div>
                    </GlassCard>
                </div>

                <div className='flex justify-end'>
                    <button onClick={handleSave} className='px-10 py-3 bg-gray-900 text-white font-bold rounded-xl shadow-xl active:scale-95 transition-all text-sm'>
                        Update Platform Config
                    </button>
                </div>
            </div>
        </div>
    )
}

export default SystemSettings
