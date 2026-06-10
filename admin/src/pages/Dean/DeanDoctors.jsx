import React, { useContext, useEffect, useState } from 'react'
import { DeanContext } from '../../context/DeanContext'
import { toast } from 'react-toastify'
import GlassCard from '../../components/ui/GlassCard'
import { useNavigate } from 'react-router-dom'

const DeanDoctors = () => {
    const { 
        deanToken, doctors, getDoctors, updateDoctor, 
        deleteDoctor, toggleStatus, resetPassword 
    } = useContext(DeanContext)
    
    const [search, setSearch] = useState('')
    const [selectedDoc, setSelectedDoc] = useState(null)
    const [modalOpen, setModalOpen] = useState(false)
    const [newPass, setNewPass] = useState('')
    const navigate = useNavigate()

    useEffect(() => {
        if (deanToken) getDoctors()
    }, [deanToken])

    const handleDelete = async (id, name) => {
        if (window.confirm(`Are you sure you want to remove Dr. ${name}?`)) {
            await deleteDoctor(id)
        }
    }

    const handleResetPassword = async () => {
        if (!selectedDoc) return
        const res = await resetPassword(selectedDoc._id, newPass || null)
        if (res) {
            setModalOpen(false)
            setNewPass('')
            setSelectedDoc(null)
        }
    }

    const filtered = doctors.filter(d =>
        d.name?.toLowerCase().includes(search.toLowerCase()) ||
        d.speciality?.toLowerCase().includes(search.toLowerCase())
    )

    return (
        <div className='w-full bg-gradient-to-br from-gray-50 to-white p-4 sm:p-6 min-h-screen'>
            <div className='space-y-4'>
                {/* Header */}
                <div className='flex flex-col sm:flex-row sm:items-center justify-between gap-4'>
                    <div>
                        <h1 className='text-2xl font-bold bg-gradient-to-r from-emerald-600 to-teal-600 bg-clip-text text-transparent'>Active Doctors</h1>
                        <p className='text-sm text-gray-500'>Manage {filtered.length} doctor{filtered.length !== 1 ? 's' : ''} in your facility</p>
                    </div>

                    <div className='flex flex-col sm:flex-row items-center gap-3 w-full sm:w-auto'>
                        <div className='relative w-full sm:w-64'>
                            <svg className='absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d='M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z' />
                            </svg>
                            <input value={search} onChange={e => setSearch(e.target.value)}
                                placeholder='Search doctors...'
                                className='w-full pl-9 pr-4 py-2 border border-gray-200 rounded-xl bg-white text-sm focus:ring-2 focus:ring-emerald-500 outline-none' />
                        </div>

                        <button onClick={() => navigate('/dean-add-doctor')} className='w-full sm:w-auto px-6 py-2 bg-emerald-600 text-white rounded-xl font-bold text-sm shadow-lg hover:shadow-emerald-500/20 active:scale-95 transition-all flex items-center justify-center gap-2'>
                            <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 4v16m8-8H4" />
                            </svg>
                            Add Doctor
                        </button>
                    </div>
                </div>

                {/* Doctors Grid */}
                {filtered.length === 0 ? (
                    <GlassCard className='p-12 text-center'>
                        <p className='text-5xl mb-4 text-emerald-500 opacity-20'>👨‍⚕️</p>
                        <p className='text-gray-500 font-medium'>No doctors found in your hospital records.</p>
                    </GlassCard>
                ) : (
                    <div className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4'>
                        {filtered.map((doc, i) => (
                            <GlassCard key={doc._id || i} className='p-4 flex flex-col gap-3 relative group overflow-hidden'>
                                {/* Status Indicator Bar */}
                                <div className={`absolute top-0 left-0 w-full h-1 ${
                                    (doc.status === 'Inactive' || !doc.available) ? 'bg-red-400' : 'bg-emerald-500'
                                }`} />

                                {/* Delete button */}
                                <button onClick={() => handleDelete(doc._id, doc.name)} className='absolute top-2 right-2 p-1.5 text-gray-300 hover:text-red-500 hover:bg-red-50 rounded-lg transition-all opacity-0 group-hover:opacity-100 z-10'>
                                    <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                                    </svg>
                                </button>

                                {/* Avatar & Name */}
                                <div className='flex items-center gap-3'>
                                    <div className='relative'>
                                        <img
                                            src={doc.image || `https://ui-avatars.com/api/?name=${encodeURIComponent(doc.name)}&background=059669&color=fff&size=64`}
                                            alt={doc.name}
                                            className={`w-14 h-14 rounded-full object-cover ring-2 ring-emerald-200 flex-shrink-0 ${doc.status === 'Inactive' ? 'grayscale opacity-50' : ''}`}
                                        />
                                        {doc.status === 'Inactive' && (
                                            <div className='absolute inset-0 bg-red-500/10 rounded-full flex items-center justify-center'>
                                                <svg className="w-6 h-6 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M18.364 18.364A9 9 0 005.636 5.636m12.728 12.728L5.636 5.636" /></svg>
                                            </div>
                                        )}
                                    </div>
                                    <div className='min-w-0 pr-6'>
                                        <p className={`font-bold text-sm truncate ${doc.status === 'Inactive' ? 'text-gray-400 line-through' : 'text-gray-900'}`}>{doc.name}</p>
                                        <p className='text-xs text-emerald-600 font-medium truncate'>{doc.speciality}</p>
                                    </div>
                                </div>

                                {/* Details */}
                                <div className='text-[10px] text-gray-500 space-y-1 border-t border-gray-100 pt-3'>
                                    <p className='flex justify-between'><span>Degree:</span> <span className='text-gray-700 font-medium'>{doc.degree}</span></p>
                                    <p className='flex justify-between'><span>Email:</span> <span className='text-gray-700 font-medium truncate max-w-[120px]'>{doc.email}</span></p>
                                </div>

                                {/* Account Controls */}
                                <div className='mt-auto pt-3 border-t border-gray-50 flex gap-2'>
                                    <button
                                        onClick={() => { setSelectedDoc(doc); setModalOpen(true); }}
                                        className='flex-1 flex items-center justify-center gap-1.5 py-1.5 bg-gray-50 text-gray-600 rounded-lg text-[10px] font-bold border border-gray-200 hover:bg-emerald-50 hover:text-emerald-700 hover:border-emerald-200 transition-all'
                                    >
                                        <svg className='w-3 h-3' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 7a2 2 0 012 2m4 0a6 6 0 01-7.743 5.743L11 17H9v2H7v2H4a1 1 0 01-1-1v-2.586a1 1 0 01.293-.707l5.964-5.964A6 6 0 1121 9z" /></svg>
                                        Access
                                    </button>
                                    <button
                                        onClick={() => toggleStatus(doc._id)}
                                        className={`flex-1 py-1.5 rounded-lg text-[10px] font-bold border transition-all ${
                                            doc.status === 'Inactive'
                                                ? 'bg-green-600 text-white border-green-700'
                                                : 'bg-white text-red-500 border-red-100 hover:bg-red-50 hover:border-red-200'
                                        }`}
                                    >
                                        {doc.status === 'Inactive' ? 'Activate' : 'Deactivate'}
                                    </button>
                                </div>

                                {/* Availability Bar (only if active) */}
                                {doc.status !== 'Inactive' && (
                                    <div className='flex items-center justify-between gap-1 mt-2 bg-gray-50/50 p-1 rounded-lg'>
                                        {[
                                            { id: 'available', color: 'bg-green-500' },
                                            { id: 'busy', color: 'bg-yellow-500' },
                                            { id: 'emergency', color: 'bg-red-500' },
                                            { id: 'unavailable', color: 'bg-gray-400' }
                                        ].map(st => {
                                            const isActive = (doc.status === st.id || (!doc.status && st.id === (doc.available ? 'available' : 'unavailable')));
                                            return (
                                                <button
                                                    key={st.id}
                                                    onClick={() => updateDoctor(doc._id, { status: st.id })}
                                                    className={`flex-1 h-5 rounded-md flex items-center justify-center transition-all ${
                                                        isActive
                                                            ? 'bg-white shadow-sm ring-1 ring-emerald-500/20'
                                                            : 'opacity-40 hover:opacity-100'
                                                    }`}
                                                    title={st.id.charAt(0).toUpperCase() + st.id.slice(1)}
                                                >
                                                    <div className={`w-2 h-2 rounded-full ${st.color}`} />
                                                </button>
                                            )
                                        })}
                                    </div>
                                )}
                            </GlassCard>
                        ))}
                    </div>
                )}
            </div>

            {/* Credential Management Modal */}
            {modalOpen && selectedDoc && (
                <div className='fixed inset-0 z-50 flex items-center justify-center p-4 bg-black/40 backdrop-blur-sm'>
                    <GlassCard className='w-full max-w-md p-6 animate-scale-in'>
                        <div className='flex justify-between items-center mb-6'>
                            <h3 className='text-lg font-bold text-gray-900'>Security & Access</h3>
                            <button onClick={() => { setModalOpen(false); setSelectedDoc(null); }} className='text-gray-400 hover:text-gray-600'>
                                <svg className='w-6 h-6' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" /></svg>
                            </button>
                        </div>

                        <div className='space-y-6'>
                            <div className='bg-emerald-50 rounded-2xl p-4 flex items-center gap-4 border border-emerald-100'>
                                <img src={selectedDoc.image} className='w-12 h-12 rounded-full object-cover ring-2 ring-white shadow-sm' />
                                <div>
                                    <p className='font-bold text-sm text-emerald-900'>{selectedDoc.name}</p>
                                    <p className='text-xs text-emerald-600'>{selectedDoc.email}</p>
                                </div>
                            </div>

                            <div className='space-y-3'>
                                <label className='block text-xs font-black text-gray-400 uppercase tracking-widest'>Credential Reset</label>
                                <div className='space-y-2'>
                                    <input
                                        value={newPass}
                                        onChange={e => setNewPass(e.target.value)}
                                        placeholder='New Secure Password (optional)'
                                        className='w-full px-4 py-3 border border-gray-200 rounded-xl text-sm focus:ring-2 focus:ring-emerald-500 outline-none'
                                    />
                                    <p className='text-[10px] text-gray-400 px-1'>Leave blank to auto-generate a secure password.</p>
                                </div>
                                <button
                                    onClick={handleResetPassword}
                                    className='w-full py-3 bg-emerald-600 text-white rounded-xl font-bold text-sm shadow-lg hover:shadow-emerald-500/20 active:scale-95 transition-all flex items-center justify-center gap-2'
                                >
                                    <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
                                    Reset & Send Credentials
                                </button>
                            </div>

                            <div className='pt-6 border-t border-gray-100'>
                                <div className='bg-blue-50 rounded-xl p-4 flex gap-3 italic'>
                                    <svg className='w-5 h-5 text-blue-500 flex-shrink-0' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" /></svg>
                                    <p className='text-[11px] text-blue-700 leading-relaxed font-medium'>
                                        Resetting credentials will immediately send an automated email to Dr. {selectedDoc.name} with the new login details. The previous password will stop working.
                                    </p>
                                </div>
                            </div>
                        </div>
                    </GlassCard>
                </div>
            )}

            <style>{`
        @keyframes scaleIn {
            0% { opacity: 0; transform: scale(0.95) translateY(10px); }
            100% { opacity: 1; transform: scale(1) translateY(0); }
        }
        .animate-scale-in { animation: scaleIn 0.3s cubic-bezier(0.16, 1, 0.3, 1) forwards; }
      `}</style>
        </div>
    )
}

export default DeanDoctors
