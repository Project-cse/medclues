import React, { useEffect, useState, useContext } from 'react'
import axios from 'axios'
import { toast } from 'react-toastify'
import { AdminContext } from '../../context/AdminContext'
import { AppContext } from '../../context/AppContext'

const SuperAppointments = () => {
    const { aToken } = useContext(AdminContext)
    const { backendUrl } = useContext(AppContext)

    const [appointments, setAppointments] = useState([])
    const [loading, setLoading] = useState(false)

    const fetchAppointments = async () => {
        try {
            setLoading(true)
            const { data } = await axios.get(
                `${backendUrl}/api/appointments`,
                { headers: { aToken } }
            )
            if (data.success) {
                setAppointments(data.appointments || [])
            }
        } catch (error) {
            console.error('Error fetching appointments:', error)
            toast.error('Failed to fetch appointments.')
        } finally {
            setLoading(false)
        }
    }

    useEffect(() => {
        if (aToken) {
            fetchAppointments()
        }
    }, [aToken])

    const handleStatusUpdate = async (id, status) => {
        try {
            const { data } = await axios.post(`${backendUrl}/api/appointments/${id}/update-status`, null, {
                headers: { aToken },
                params: { status }
            })
            if (data.success) {
                toast.success(`Appointment ${status} successfully.`)
                setAppointments(prev =>
                    prev.map(apt => apt.id === id ? { ...apt, status } : apt)
                )
            }
        } catch (error) {
            toast.error('Failed to update status.')
        }
    }

    return (
        <div className='w-full bg-slate-50 p-4 sm:p-6 min-h-screen'>
            <div className='max-w-6xl mx-auto'>
                <div className='mb-6'>
                    <h2 className='text-3xl font-bold bg-gradient-to-r from-blue-600 to-indigo-600 bg-clip-text text-transparent'>
                        General Appointments
                    </h2>
                    <p className='text-gray-500 mt-1'>Manage all service-based appointments submitted by users.</p>
                </div>

                <div className='bg-white rounded-2xl shadow-xl overflow-hidden border border-gray-100'>
                    {loading ? (
                        <div className='p-20 text-center text-gray-500'>
                            <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-indigo-600 mx-auto mb-4"></div>
                            Loading appointments...
                        </div>
                    ) : appointments.length === 0 ? (
                        <div className='p-20 text-center text-gray-500 italic'>
                            No appointments found.
                        </div>
                    ) : (
                        <div className='overflow-x-auto'>
                            <table className='w-full text-left border-collapse'>
                                <thead className='bg-slate-50 border-b border-gray-100'>
                                    <tr>
                                        <th className='px-6 py-4 text-xs font-bold text-gray-600 uppercase tracking-wider'>User</th>
                                        <th className='px-6 py-4 text-xs font-bold text-gray-600 uppercase tracking-wider'>Contact</th>
                                        <th className='px-6 py-4 text-xs font-bold text-gray-600 uppercase tracking-wider'>Service Type</th>
                                        <th className='px-6 py-4 text-xs font-bold text-gray-600 uppercase tracking-wider'>Date & Time</th>
                                        <th className='px-6 py-4 text-xs font-bold text-gray-600 uppercase tracking-wider'>Status</th>
                                        <th className='px-6 py-4 text-xs font-bold text-gray-600 uppercase tracking-wider text-center'>Actions</th>
                                    </tr>
                                </thead>
                                <tbody className='divide-y divide-gray-100'>
                                    {appointments.map((apt) => (
                                        <tr key={apt.id} className='hover:bg-slate-50/50 transition-colors'>
                                            <td className='px-6 py-4'>
                                                <div className='font-semibold text-gray-900'>{apt.user_name}</div>
                                            </td>
                                            <td className='px-6 py-4'>
                                                <div className='text-sm text-gray-600'>{apt.email}</div>
                                            </td>
                                            <td className='px-6 py-4'>
                                                <span className='inline-flex px-3 py-1 rounded-full text-xs font-semibold bg-indigo-50 text-indigo-700'>
                                                    {apt.service_type}
                                                </span>
                                            </td>
                                            <td className='px-6 py-4'>
                                                <div className='text-sm text-gray-900 font-medium'>{apt.appointment_date}</div>
                                                <div className='text-xs text-gray-500'>{apt.appointment_time}</div>
                                            </td>
                                            <td className='px-6 py-4'>
                                                <span className={`inline-flex px-3 py-1 rounded-full text-xs font-bold ${
                                                    apt.status === 'Confirmed' ? 'bg-green-100 text-green-700' :
                                                    apt.status === 'Cancelled' ? 'bg-red-100 text-red-700' :
                                                    'bg-amber-100 text-amber-700'
                                                }`}>
                                                    {apt.status}
                                                </span>
                                            </td>
                                            <td className='px-6 py-4 text-center'>
                                                <div className='flex items-center justify-center gap-2'>
                                                    <button 
                                                        onClick={() => handleStatusUpdate(apt.id, 'Confirmed')}
                                                        className='p-1.5 text-green-600 hover:bg-green-50 rounded-lg transition-colors'
                                                        title="Confirm"
                                                    >
                                                        <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" /></svg>
                                                    </button>
                                                    <button 
                                                        onClick={() => handleStatusUpdate(apt.id, 'Cancelled')}
                                                        className='p-1.5 text-red-600 hover:bg-red-50 rounded-lg transition-colors'
                                                        title="Cancel"
                                                    >
                                                        <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                                                    </button>
                                                </div>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>
            </div>
        </div>
    )
}

export default SuperAppointments
