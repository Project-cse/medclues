import React, { useContext, useEffect, useState } from 'react'
import axios from 'axios'
import { AdminContext } from '../../context/AdminContext'
import { toast } from 'react-toastify'
import GlassCard from '../../components/ui/GlassCard'

const DeanPortals = () => {
    const { aToken, getAllHospitals, hospitals } = useContext(AdminContext)
    const backendUrl = import.meta.env.VITE_BACKEND_URL
    const authHeader = { aToken }

    const [deans, setDeans] = useState([])
    const [isLoading, setIsLoading] = useState(false)
    const [showForm, setShowForm] = useState(false)
    const [form, setForm] = useState({ name: '', email: '', password: '', hospital_id: '' })
    const [creating, setCreating] = useState(false)
    const [search, setSearch] = useState('')
    const [showPasswords, setShowPasswords] = useState({})

    const handleCreate = async (e) => {
        e.preventDefault()
        if (!form.hospital_name || !form.email || !form.password) {
            toast.error('All fields are required'); return
        }
        setCreating(true)
        try {
            const { data } = await axios.post(`${backendUrl}/api/admin/deans/create`, form, { headers: authHeader })
            if (data.success) {
                toast.success(data.message)
                setForm({ hospital_name: '', email: '', password: '' })
                setShowForm(false)
                fetchDeans()
            } else { toast.error(data.message) }
        } catch (err) { toast.error(err.response?.data?.message || err.message) }
        finally { setCreating(false) }
    }

    const togglePasswordVisibility = (id) => {
        setShowPasswords(prev => ({ ...prev, [id]: !prev[id] }))
    }

    const fetchDeans = async () => {
        setIsLoading(true)
        try {
            const { data } = await axios.get(`${backendUrl}/api/admin/deans`, { headers: authHeader })
            if (data.success) setDeans(data.deans)
            else toast.error(data.message)
        } catch (err) { toast.error(err.message) }
        finally { setIsLoading(false) }
    }

    useEffect(() => {
        if (aToken) { fetchDeans(); getAllHospitals() }
    }, [aToken])

    const filteredDeans = deans.filter(d =>
        d.name.toLowerCase().includes(search.toLowerCase()) ||
        d.hospital_name?.toLowerCase().includes(search.toLowerCase()) ||
        d.email.toLowerCase().includes(search.toLowerCase())
    ).sort((a, b) => (a.hospital_name || "").localeCompare(b.hospital_name || ""))

    const setPassword = async (id, currentEmail) => {
        const newPassword = prompt(`Enter new password for ${currentEmail}:`)
        if (!newPassword || newPassword.length < 6) {
            toast.error("Password must be at least 6 characters")
            return
        }

        try {
            const { data } = await axios.put(`${backendUrl}/api/admin/deans/${id}`, { password: newPassword }, { headers: authHeader })
            if (data.success) {
                toast.success("Password updated successfully")
                fetchDeans()
            } else {
                toast.error(data.message)
            }
        } catch (err) {
            toast.error(err.message)
        }
    }

    const copyToClipboard = (text, type) => {
        if (!text || text === '••••••••') {
            toast.error(`Cannot copy ${type}: Value is hidden or unavailable`)
            return
        }
        navigator.clipboard.writeText(text)
        toast.success(`${type} copied to clipboard`)
    }

    return (
        <div className='w-full bg-white p-3 sm:p-6 min-h-screen'>
            <div className='max-w-6xl mx-auto space-y-6'>

                {/* Header Section */}
                <div className='flex flex-col md:flex-row md:items-center justify-between gap-4'>
                    <div>
                        <h1 className='text-xl sm:text-2xl font-bold text-gray-900'>Dean Portal Credentials</h1>
                        <p className='text-xs sm:text-sm text-gray-500 mt-1'>Access and manage login details for all hospital administrators</p>
                    </div>
                    <div className='flex flex-col sm:flex-row items-center gap-2 sm:gap-3 w-full md:w-auto'>
                        <button
                            onClick={() => setShowForm(!showForm)}
                            className='w-full sm:w-auto px-5 py-2 bg-indigo-600 text-white font-bold rounded-xl hover:bg-indigo-700 transition-all active:scale-95 text-xs sm:text-sm shadow-lg shadow-indigo-200'
                        >
                            {showForm ? '✕ Close Form' : '+ Create New Portal'}
                        </button>
                        <div className='relative w-full sm:w-64'>
                            <input
                                type="text"
                                placeholder="Search portals..."
                                value={search}
                                onChange={(e) => setSearch(e.target.value)}
                                className='pl-10 pr-4 py-2 border-2 border-gray-100 focus:border-indigo-500 outline-none rounded-xl w-full transition-all text-xs sm:text-sm'
                            />
                            <svg className='absolute left-3 top-1/2 -translate-y-1/2 w-4 h-4 text-gray-400' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z" /></svg>
                        </div>
                    </div>
                </div>

                {/* Simplified Create Form */}
                {showForm && (
                    <div className='bg-indigo-50/50 border-2 border-indigo-100 rounded-2xl p-4 sm:p-6 animate-fade-in'>
                        <h2 className='text-md sm:text-lg font-bold text-indigo-900 mb-4 flex items-center gap-2'>
                            <span className='w-7 h-7 sm:w-8 sm:h-8 bg-indigo-600 text-white rounded-lg flex items-center justify-center text-xs sm:text-sm'>+</span>
                            Create New Portal Access
                        </h2>
                        <form onSubmit={handleCreate} className='grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 gap-4 items-end'>
                            <div className='space-y-1.5'>
                                <label className='text-[10px] font-black uppercase text-indigo-400 ml-1'>Hospital Name</label>
                                <input
                                    type="text"
                                    placeholder="e.g. City General Hospital"
                                    value={form.hospital_name}
                                    onChange={e => setForm({ ...form, hospital_name: e.target.value })}
                                    required
                                    className='w-full px-4 py-2 bg-white border border-indigo-100 rounded-xl text-sm outline-none focus:border-indigo-600 shadow-sm'
                                />
                            </div>
                            <div className='space-y-1.5'>
                                <label className='text-[10px] font-black uppercase text-indigo-400 ml-1'>Login Email</label>
                                <input
                                    type="email"
                                    placeholder="dean@hospital.com"
                                    value={form.email}
                                    onChange={e => setForm({ ...form, email: e.target.value })}
                                    required
                                    className='w-full px-4 py-2 bg-white border border-indigo-100 rounded-xl text-sm outline-none focus:border-indigo-600 shadow-sm'
                                />
                            </div>
                            <div className='space-y-1.5'>
                                <label className='text-[10px] font-black uppercase text-indigo-400 ml-1'>Access Password</label>
                                <div className='flex items-center gap-2'>
                                    <input
                                        type="text"
                                        placeholder="Min. 6 chars"
                                        value={form.password}
                                        onChange={e => setForm({ ...form, password: e.target.value })}
                                        required
                                        className='flex-1 px-4 py-2 bg-white border border-indigo-100 rounded-xl text-sm outline-none focus:border-indigo-600 shadow-sm'
                                    />
                                    <button
                                        type="submit"
                                        disabled={creating}
                                        className='px-6 py-2 bg-indigo-600 text-white font-bold rounded-xl hover:bg-indigo-700 transition-all disabled:opacity-50 h-[38px] text-sm'
                                    >
                                        {creating ? '...' : 'Create'}
                                    </button>
                                </div>
                            </div>
                        </form>
                    </div>
                )}

                {/* Stats Grid */}
                <div className='grid grid-cols-1 sm:grid-cols-3 gap-4'>
                    <div className='p-5 bg-indigo-50 rounded-2xl border border-indigo-100'>
                        <p className='text-indigo-600 text-[10px] font-black uppercase tracking-widest'>Total Portals</p>
                        <h3 className='text-3xl font-bold mt-1 text-indigo-900'>{deans.length}</h3>
                    </div>
                    <div className='p-5 bg-white rounded-2xl border border-gray-100 shadow-sm'>
                        <p className='text-gray-400 text-[10px] font-black uppercase tracking-widest'>Status</p>
                        <h3 className='text-xl font-bold mt-1 text-gray-800 flex items-center gap-2'>
                            <span className='w-2 h-2 bg-green-500 rounded-full' />
                            Live Database
                        </h3>
                    </div>
                    <div className='p-5 bg-white rounded-2xl border border-gray-100 shadow-sm'>
                        <p className='text-gray-400 text-[10px] font-black uppercase tracking-widest'>Security</p>
                        <h3 className='text-xl font-bold mt-1 text-gray-800 flex items-center gap-2'>
                            <svg className='w-5 h-5 text-indigo-500' fill="currentColor" viewBox="0 0 20 20"><path fillRule="evenodd" d="M2.166 4.999A11.954 11.954 0 0010 1.944 11.954 11.954 0 0017.834 5c.11.65.166 1.32.166 2.001 0 4.946-2.567 9.29-6.433 11.714l-.567.355-.567-.355A11.91 11.91 0 012 7c0-.68.056-1.35.166-2.001zm6.541 9.68a1.108 1.108 0 001.586 0L14.3 10.68a1.108 1.108 0 000-1.586 1.108 1.108 0 00-1.586 0l-2.714 2.714-1.014-1.014a1.108 1.108 0 00-1.586 0 1.108 1.108 0 000 1.586l1.807 1.805z" clipRule="evenodd" /></svg>
                            Encrypted
                        </h3>
                    </div>
                </div>

                {/* Credentials Table */}
                <div className='bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden'>
                    {isLoading ? (
                        <div className='p-20 flex flex-col items-center justify-center gap-4'>
                            <div className='w-10 h-10 border-4 border-indigo-100 border-t-indigo-600 rounded-full animate-spin' />
                            <p className='text-gray-500 font-bold'>Loading credentials...</p>
                        </div>
                    ) : filteredDeans.length === 0 ? (
                        <div className='p-20 flex flex-col items-center justify-center text-center'>
                            <div className='w-16 h-16 bg-gray-50 rounded-full flex items-center justify-center text-2xl mb-4'>🔐</div>
                            <h3 className='text-lg font-bold text-gray-800'>No Dean Portals Found</h3>
                            <p className='text-sm text-gray-400 mt-1'>No accounts matching your search criteria.</p>
                        </div>
                    ) : (
                        <div className='overflow-x-auto'>
                            <table className='w-full text-left border-collapse'>
                                <thead>
                                    <tr className='bg-gray-50/80 border-b border-gray-100'>
                                        <th className='px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest'>Hospital & Dean</th>
                                        <th className='px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest'>Portal Email</th>
                                        <th className='px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest'>Access Password</th>
                                        <th className='px-6 py-4 text-[10px] font-black text-gray-400 uppercase tracking-widest text-right'>Quick Actions</th>
                                    </tr>
                                </thead>
                                <tbody className='divide-y divide-gray-50'>
                                    {filteredDeans.map((dean) => (
                                        <tr key={dean.id} className='hover:bg-indigo-50/30 transition-colors group'>
                                            <td className='px-6 py-4'>
                                                <div className='flex items-center gap-3'>
                                                    <div className='w-10 h-10 bg-indigo-600 rounded-xl flex items-center justify-center text-white font-bold'>
                                                        {dean.hospital_name ? dean.hospital_name[0] : 'H'}
                                                    </div>
                                                    <div>
                                                        <p className='font-bold text-gray-900'>{dean.hospital_name}</p>
                                                        <p className='text-[10px] text-gray-500 font-bold uppercase tracking-tight mt-0.5'>
                                                            Dean: {dean.name}
                                                        </p>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className='px-6 py-4'>
                                                <div className='flex items-center gap-2'>
                                                    <span className='text-sm font-medium text-gray-700'>{dean.email}</span>
                                                    <button
                                                        onClick={() => copyToClipboard(dean.email, 'Email')}
                                                        className='p-1.5 text-gray-400 hover:text-indigo-600 transition-all opacity-0 group-hover:opacity-100'
                                                    >
                                                        <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>
                                                    </button>
                                                </div>
                                            </td>
                                            <td className='px-6 py-4'>
                                                <div className='flex items-center gap-3'>
                                                    <div className='relative flex-1 max-w-[140px]'>
                                                        <input
                                                            type={showPasswords[dean.id] ? "text" : "password"}
                                                            readOnly
                                                            value={dean.password_text || (showPasswords[dean.id] ? "N/A (Legacy Account)" : "••••••••")}
                                                            className={`w-full px-3 py-1.5 rounded-lg text-xs font-mono font-bold outline-none transition-all ${showPasswords[dean.id]
                                                                ? (dean.password_text ? 'bg-indigo-50 text-indigo-700 border border-indigo-100' : 'bg-red-50 text-red-500 border border-red-100')
                                                                : 'bg-gray-100 text-gray-700 border border-gray-200'
                                                                }`}
                                                        />
                                                    </div>
                                                    <div className='flex items-center gap-1'>
                                                        {!dean.password_text && (
                                                            <button
                                                                onClick={() => setPassword(dean.id, dean.email)}
                                                                className='px-2 py-1 bg-red-100 text-red-600 text-[9px] font-black uppercase rounded hover:bg-red-200 transition-all'
                                                                title="Set New Password"
                                                            >
                                                                Set
                                                            </button>
                                                        )}
                                                        <button
                                                            onClick={() => togglePasswordVisibility(dean.id)}
                                                            className={`p-2 rounded-lg transition-all ${showPasswords[dean.id] ? 'bg-indigo-100 text-indigo-600' : 'text-gray-400 hover:bg-gray-100 hover:text-indigo-600'}`}
                                                            title={showPasswords[dean.id] ? "Hide Password" : "Show Password"}
                                                        >
                                                            {showPasswords[dean.id] ? (
                                                                <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13.875 18.825A10.05 10.05 0 0112 19c-4.478 0-8.268-2.943-9.543-7a9.97 9.97 0 011.563-3.029m5.858.908a3 3 0 114.243 4.243M9.878 9.878l4.242 4.242M9.88 9.88l-3.29-3.29m7.532 7.532l3.29 3.29M3 3l18 18" /></svg>
                                                            ) : (
                                                                <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" /><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" /></svg>
                                                            )}
                                                        </button>
                                                        <button
                                                            onClick={() => copyToClipboard(dean.password_text, 'Password')}
                                                            className='p-2 rounded-lg text-gray-400 hover:bg-gray-100 hover:text-indigo-600 transition-all opacity-0 group-hover:opacity-100'
                                                            disabled={!dean.password_text}
                                                        >
                                                            <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 002-2v-8a2 2 0 00-2-2h-8a2 2 0 00-2 2v8a2 2 0 002 2z" /></svg>
                                                        </button>
                                                    </div>
                                                </div>
                                            </td>
                                            <td className='px-6 py-4 text-right'>
                                                <button
                                                    onClick={() => window.open('/login', '_blank')}
                                                    className='px-3 py-1.5 bg-gray-900 text-white text-[10px] font-bold rounded-lg hover:bg-gray-800 transition-all active:scale-95'
                                                >
                                                    Open Portal
                                                </button>
                                            </td>
                                        </tr>
                                    ))}
                                </tbody>
                            </table>
                        </div>
                    )}
                </div>

                {/* Security Notice */}
                <div className='bg-red-50 border border-red-100 rounded-xl p-4 flex items-start gap-3'>
                    <div className='text-red-600'>⚠️</div>
                    <div>
                        <h4 className='text-red-800 text-xs font-bold uppercase'>Security Notice</h4>
                        <p className='text-red-700 text-xs mt-0.5'>These credentials provide full access to individual hospital portals. Handle this information with extreme caution.</p>
                    </div>
                </div>

            </div>
        </div>
    )
}

export default DeanPortals
