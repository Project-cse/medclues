import React, { useContext, useEffect, useState } from 'react'
import { AdminContext } from '../../context/AdminContext'
import { toast } from 'react-toastify'
import GlassCard from '../../components/ui/GlassCard'

const ManageLabs = () => {
    const { labs, getAllLabs, addLab, updateLab, deleteLab } = useContext(AdminContext)

    const [loading, setLoading] = useState(true)
    const [showModal, setShowModal] = useState(false)
    const [editingLab, setEditingLab] = useState(null)

    const [formData, setFormData] = useState({
        name: '',
        location: '',
        city: '',
        latitude: '',
        longitude: '',
        rating: 4.5,
        verified: true,
        services: '',
        openNow: true,
        partnerType: 'normal',
        image: ''
    })

    useEffect(() => {
        fetchData()
    }, [])

    const fetchData = async () => {
        setLoading(true)
        await getAllLabs()
        setLoading(false)
    }

    const handleSubmit = async (e) => {
        e.preventDefault()
        
        if (!formData.latitude || !formData.longitude) {
            toast.warning('Please provide latitude and longitude for mapping')
        }

        const labData = {
            ...formData,
            latitude: parseFloat(formData.latitude) || 0,
            longitude: parseFloat(formData.longitude) || 0,
            services: formData.services.split(',').map(s => s.trim()).filter(s => s !== '')
        }

        let success
        if (editingLab) {
            success = await updateLab(editingLab.id, labData)
        } else {
            success = await addLab(labData)
        }

        if (success) {
            setShowModal(false)
            resetForm()
        }
    }

    const resetForm = () => {
        setFormData({
            name: '',
            location: '',
            city: '',
            latitude: '',
            longitude: '',
            rating: 4.5,
            verified: true,
            services: '',
            openNow: true,
            partnerType: 'normal',
            image: ''
        })
        setEditingLab(null)
    }

    const handleEdit = (lab) => {
        setEditingLab(lab)
        setFormData({
            name: lab.name,
            location: lab.location,
            city: lab.city,
            latitude: lab.latitude,
            longitude: lab.longitude,
            rating: lab.rating,
            verified: lab.verified,
            services: Array.isArray(lab.services) ? lab.services.join(', ') : lab.services,
            openNow: lab.open_now,
            partnerType: lab.partner_type || 'normal',
            image: lab.image || ''
        })
        setShowModal(true)
    }

    return (
        <div className='w-full p-4 sm:p-6 lg:p-10 min-h-screen bg-white'>
            <div className='max-w-7xl mx-auto'>
                {/* Header Section */}
                <div className='flex flex-col md:flex-row justify-between items-start md:items-center gap-6 mb-10'>
                    <div className='animate-fade-in'>
                        <h1 className='text-3xl sm:text-4xl font-extrabold text-gray-900 tracking-tight'>
                            Diagnostic Lab <span className='text-indigo-600'>Management</span>
                        </h1>
                        <p className='text-gray-500 mt-2 text-lg'>Register and verify partner labs for diagnostic services.</p>
                    </div>
                    <button
                        onClick={() => { resetForm(); setShowModal(true) }}
                        className='group relative px-8 py-4 bg-indigo-600 text-white rounded-2xl shadow-xl shadow-indigo-200 hover:shadow-indigo-300 hover:-translate-y-1 transition-all duration-300 font-bold flex items-center gap-3 overflow-hidden active:scale-95'
                    >
                        <div className='absolute inset-0 bg-white/10 group-hover:translate-x-full transition-transform duration-500'></div>
                        <svg className='w-6 h-6' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 4v16m8-8H4" />
                        </svg>
                        Register New Lab
                    </button>
                </div>

                {loading ? (
                    <div className='flex flex-col items-center justify-center py-32 space-y-4'>
                        <div className='w-12 h-12 border-4 border-indigo-100 border-t-indigo-600 rounded-full animate-spin'></div>
                        <p className='text-gray-400 font-medium animate-pulse'>Fetching lab directory...</p>
                    </div>
                ) : labs.length === 0 ? (
                    <div className='text-center py-32 bg-gray-50 rounded-3xl border-2 border-dashed border-gray-200'>
                        <div className='bg-indigo-50 w-20 h-20 rounded-full flex items-center justify-center mx-auto mb-4'>
                            <svg className='w-10 h-10 text-indigo-500' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M19.428 15.428a2 2 0 00-1.022-.547l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517L6.05 15.21a2 2 0 00-1.183.394l-1.154.908a2 2 0 01-2.003.882l-2.387-.477a6 6 0 00-3.86.517l-.318.158a6 6 0 01-3.86.517" />
                            </svg>
                        </div>
                        <h3 className='text-xl font-bold text-gray-800'>No Labs Registered</h3>
                        <p className='text-gray-500 mt-2'>Connect with diagnostic centres to expand your healthcare network.</p>
                    </div>
                ) : (
                    <div className='grid grid-cols-1 md:grid-cols-2 xl:grid-cols-3 gap-8'>
                        {labs.map(lab => (
                            <div key={lab.id} className='group bg-white border border-gray-100 rounded-3xl shadow-sm hover:shadow-2xl transition-all duration-500 overflow-hidden flex flex-col'>
                                {/* Image Section */}
                                <div className='h-48 bg-gradient-to-br from-indigo-500 to-purple-700 relative overflow-hidden'>
                                    {lab.image ? (
                                        <img src={lab.image} className='w-full h-full object-cover group-hover:scale-110 transition-transform duration-700 opacity-90' alt={lab.name} />
                                    ) : (
                                        <div className='w-full h-full flex items-center justify-center opacity-10'>
                                            <svg className='w-24 h-24 text-white' fill="currentColor" viewBox="0 0 24 24"><path d="M19 3H5c-1.1 0-2 .9-2 2v14c0 1.1.9 2 2 2h14c1.1 0 2-.9 2-2V5c0-1.1-.9-2-2-2zm-5 14H7v-2h7v2zm3-4H7v-2h10v2zm0-4H7V7h10v2z"/></svg>
                                        </div>
                                    )}
                                    <div className='absolute top-4 right-4'>
                                        <span className={`px-4 py-1.5 rounded-full text-[10px] font-black uppercase tracking-[0.2em] shadow-lg backdrop-blur-md ${lab.partner_type === 'partner' ? 'bg-white/90 text-indigo-600' : 'bg-black/20 text-white'}`}>
                                            {lab.partner_type || 'NORMAL'}
                                        </span>
                                    </div>
                                    {lab.verified && (
                                        <div className='absolute top-4 left-4 bg-green-500 text-white p-1.5 rounded-full shadow-lg'>
                                            <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={3} d="M5 13l4 4L19 7" /></svg>
                                        </div>
                                    )}
                                </div>

                                <div className='p-8 flex flex-col flex-1'>
                                    <div className='mb-6'>
                                        <div className='flex items-center gap-2 mb-2'>
                                            <div className='flex gap-0.5'>
                                                {[...Array(5)].map((_, i) => (
                                                    <svg key={i} className={`w-3.5 h-3.5 ${i < Math.floor(lab.rating || 5) ? 'text-amber-400' : 'text-gray-200'}`} fill="currentColor" viewBox="0 0 24 24"><path d="M12 17.27L18.18 21l-1.64-7.03L22 9.24l-7.19-.61L12 2 9.19 8.63 2 9.24l5.46 4.73L5.82 21z"/></svg>
                                                ))}
                                            </div>
                                            <span className='text-xs font-bold text-gray-400'>{lab.rating || 4.5} Rating</span>
                                        </div>
                                        <h3 className='text-2xl font-bold text-gray-900 group-hover:text-indigo-700 transition-colors truncate'>{lab.name}</h3>
                                        <div className='flex items-center gap-2 mt-2 text-gray-500'>
                                            <svg className='w-4 h-4 text-indigo-400' fill='none' stroke='currentColor' viewBox='0 0 24 24'><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M17.657 16.657L13.414 20.9a1.998 1.998 0 01-2.827 0l-4.244-4.243a8 8 0 1111.314 0z'/><path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M15 11a3 3 0 11-6 0 3 3 0 016 0z'/></svg>
                                            <span className='text-sm font-medium'>{lab.location}, {lab.city}</span>
                                        </div>
                                    </div>

                                    <div className='flex flex-wrap gap-2 mb-8'>
                                        {Array.isArray(lab.services) && lab.services.slice(0, 4).map(service => (
                                            <span key={service} className='text-[10px] bg-indigo-50 text-indigo-600 px-3 py-1.5 rounded-xl font-bold uppercase tracking-wider'>{service}</span>
                                        ))}
                                        {Array.isArray(lab.services) && lab.services.length > 4 && (
                                            <span className='text-[10px] bg-gray-50 text-gray-400 px-3 py-1.5 rounded-xl font-bold'>+{lab.services.length - 4} MORE</span>
                                        )}
                                    </div>

                                    <div className='flex items-center gap-3 mt-auto'>
                                        <button 
                                            onClick={() => handleEdit(lab)} 
                                            className='flex-[2] py-4 px-4 bg-indigo-50 text-indigo-700 text-sm font-bold rounded-2xl hover:bg-indigo-100 transition-colors flex items-center justify-center gap-2'
                                        >
                                            <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.232 5.232l3.536 3.536m-2.036-5.036a2.5 2.5 0 113.536 3.536L6.5 21.036H3v-3.572L16.732 3.732z" /></svg>
                                            Modify Lab
                                        </button>
                                        <button 
                                            onClick={() => {
                                                if(window.confirm('Remove this lab permanently?')) deleteLab(lab.id)
                                            }} 
                                            className='flex-1 py-4 flex items-center justify-center bg-rose-50 text-rose-600 rounded-2xl hover:bg-rose-100 transition-colors'
                                        >
                                            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" /></svg>
                                        </button>
                                    </div>
                                </div>
                            </div>
                        ))}
                    </div>
                )}

                {/* Lab Modal */}
                {showModal && (
                    <div className='fixed inset-0 bg-black/60 backdrop-blur-md z-[100] flex items-center justify-center p-4 sm:p-6 overflow-y-auto'>
                        <div className='bg-white rounded-[2rem] shadow-2xl w-full max-w-3xl overflow-hidden my-auto animate-modal-in'>
                            <div className='bg-gradient-to-r from-indigo-600 to-purple-700 px-8 py-6 flex items-center justify-between'>
                                <div>
                                    <h2 className='text-2xl font-black text-white tracking-tight'>{editingLab ? 'Update Lab Registry' : 'Establish New Lab'}</h2>
                                    <p className='text-indigo-100 text-xs font-medium mt-1'>Configure diagnostic services and verify credentials.</p>
                                </div>
                                <button onClick={() => setShowModal(false)} className='bg-white/20 hover:bg-white/30 text-white p-2 rounded-xl transition-colors'>
                                    <svg className='w-6 h-6' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M6 18L18 6M6 6l12 12" /></svg>
                                </button>
                            </div>

                            <form onSubmit={handleSubmit} className='p-8 space-y-8 h-[75vh] overflow-y-auto scrollbar-hide'>
                                <div className='space-y-6'>
                                    <h3 className='text-sm font-black text-gray-400 uppercase tracking-widest flex items-center gap-2'>
                                        <span className='w-8 h-px bg-gray-200'></span> Directory Information
                                    </h3>
                                    
                                    <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
                                        <div className='md:col-span-2'>
                                            <label className='block text-[11px] font-black text-gray-500 uppercase tracking-wider mb-2 ml-1'>Full Name of Lab</label>
                                            <input type='text' required placeholder='e.g. Apollo Diagnostics & Research Lab' className='w-full px-5 py-4 bg-gray-50 border-2 border-gray-100 rounded-2xl focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-medium' value={formData.name} onChange={e => setFormData({ ...formData, name: e.target.value })} />
                                        </div>

                                        <div className='md:col-span-2'>
                                            <label className='block text-[11px] font-black text-gray-500 uppercase tracking-wider mb-2 ml-1'>Image URL</label>
                                            <input type='text' placeholder='https://...' className='w-full px-5 py-4 bg-gray-50 border-2 border-gray-100 rounded-2xl focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-medium' value={formData.image} onChange={e => setFormData({ ...formData, image: e.target.value })} />
                                        </div>

                                        <div>
                                            <label className='block text-[11px] font-black text-gray-500 uppercase tracking-wider mb-2 ml-1'>Street Address</label>
                                            <input type='text' required placeholder='Locality, Building...' className='w-full px-5 py-4 bg-gray-50 border-2 border-gray-100 rounded-2xl focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-medium' value={formData.location} onChange={e => setFormData({ ...formData, location: e.target.value })} />
                                        </div>
                                        <div>
                                            <label className='block text-[11px] font-black text-gray-500 uppercase tracking-wider mb-2 ml-1'>City</label>
                                            <input type='text' required placeholder='City' className='w-full px-5 py-4 bg-gray-50 border-2 border-gray-100 rounded-2xl focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-medium' value={formData.city} onChange={e => setFormData({ ...formData, city: e.target.value })} />
                                        </div>
                                    </div>
                                </div>

                                <div className='space-y-6'>
                                    <h3 className='text-sm font-black text-gray-400 uppercase tracking-widest flex items-center gap-2'>
                                        <span className='w-8 h-px bg-gray-200'></span> Mapping & Tier
                                    </h3>
                                    <div className='grid grid-cols-1 md:grid-cols-3 gap-6'>
                                        <div>
                                            <label className='block text-[11px] font-black text-gray-500 uppercase tracking-wider mb-2 ml-1'>Latitude</label>
                                            <input type='number' step="any" required placeholder='Latitude' className='w-full px-5 py-4 bg-gray-50 border-2 border-gray-100 rounded-2xl focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-medium' value={formData.latitude} onChange={e => setFormData({ ...formData, latitude: e.target.value })} />
                                        </div>
                                        <div>
                                            <label className='block text-[11px] font-black text-gray-500 uppercase tracking-wider mb-2 ml-1'>Longitude</label>
                                            <input type='number' step="any" required placeholder='Longitude' className='w-full px-5 py-4 bg-gray-50 border-2 border-gray-100 rounded-2xl focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-medium' value={formData.longitude} onChange={e => setFormData({ ...formData, longitude: e.target.value })} />
                                        </div>
                                        <div>
                                            <label className='block text-[11px] font-black text-gray-500 uppercase tracking-wider mb-2 ml-1'>Lab Rating (0-5)</label>
                                            <input type='number' step="0.1" min="0" max="5" required placeholder='4.5' className='w-full px-5 py-4 bg-gray-50 border-2 border-gray-100 rounded-2xl focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-medium' value={formData.rating} onChange={e => setFormData({ ...formData, rating: e.target.value })} />
                                        </div>
                                        <div>
                                            <label className='block text-[11px] font-black text-gray-500 uppercase tracking-wider mb-2 ml-1'>Partnership Tier</label>
                                            <select className='w-full px-5 py-[1.12rem] bg-gray-50 border-2 border-gray-100 rounded-2xl focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-bold appearance-none cursor-pointer' value={formData.partnerType} onChange={e => setFormData({ ...formData, partnerType: e.target.value })}>
                                                <option value="normal">Standard Vendor</option>
                                                <option value="partner">Elite Partner</option>
                                            </select>
                                        </div>
                                    </div>
                                </div>

                                <div className='space-y-6'>
                                    <h3 className='text-sm font-black text-gray-400 uppercase tracking-widest flex items-center gap-2'>
                                        <span className='w-8 h-px bg-gray-200'></span> Service Metrics
                                    </h3>
                                    <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
                                        <div className='md:col-span-2'>
                                            <label className='block text-[11px] font-black text-gray-500 uppercase tracking-wider mb-2 ml-1'>Offered Services (Comma Separated)</label>
                                            <input type='text' placeholder='Blood Test, MRI, CT Scan, X-Ray, Pathology' className='w-full px-5 py-4 bg-gray-50 border-2 border-gray-100 rounded-2xl focus:ring-4 focus:ring-indigo-500/10 focus:border-indigo-500 outline-none transition-all font-medium' value={formData.services} onChange={e => setFormData({ ...formData, services: e.target.value })} />
                                        </div>
                                        <div className='flex gap-6 pt-4'>
                                            <div className='flex items-center gap-3 group cursor-pointer'>
                                                <input type='checkbox' id='verified' className='w-6 h-6 rounded-lg text-green-500 focus:ring-green-500 transition-all cursor-pointer' checked={formData.verified} onChange={e => setFormData({ ...formData, verified: e.target.checked })} />
                                                <label htmlFor='verified' className='text-sm font-black text-gray-700 cursor-pointer group-hover:text-green-600 transition-colors'>Certified & Verified</label>
                                            </div>
                                            <div className='flex items-center gap-3 group cursor-pointer'>
                                                <input type='checkbox' id='openNow' className='w-6 h-6 rounded-lg text-indigo-500 focus:ring-indigo-500 transition-all cursor-pointer' checked={formData.openNow} onChange={e => setFormData({ ...formData, openNow: e.target.checked })} />
                                                <label htmlFor='openNow' className='text-sm font-black text-gray-700 cursor-pointer group-hover:text-indigo-600 transition-colors'>Currently Operational</label>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div className='flex gap-4 pt-6 pb-2'>
                                    <button type='button' onClick={() => setShowModal(false)} className='flex-1 py-5 border-2 border-gray-100 rounded-2xl font-bold text-gray-500 hover:bg-gray-50 hover:text-gray-700 transition-all active:scale-95'>Close</button>
                                    <button type='submit' className='flex-[2] py-5 bg-gradient-to-r from-indigo-600 to-purple-700 text-white rounded-2xl font-black shadow-xl shadow-indigo-200 hover:shadow-indigo-300 hover:-translate-y-1 transition-all active:scale-95'>
                                        {editingLab ? 'Update Lab Details' : 'Authenticate & Save'}
                                    </button>
                                </div>
                            </form>
                        </div>
                    </div>
                )}
            </div>
        </div>
    )
}

export default ManageLabs
