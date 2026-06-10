import React, { useContext, useState } from 'react'
import { toast } from 'react-toastify'
import axios from 'axios'
import { DeanContext } from '../../context/DeanContext'
import GlassCard from '../../components/ui/GlassCard'
import { useNavigate } from 'react-router-dom'

const DeanAddDoctor = () => {
    const { deanToken, getDoctors } = useContext(DeanContext)
    const navigate = useNavigate()

    const [docImg, setDocImg] = useState(false)
    const [name, setName] = useState('')
    const [email, setEmail] = useState('')
    const [password, setPassword] = useState('')
    const [experience, setExperience] = useState('1 Year')
    const [fees, setFees] = useState('')
    const [about, setAbout] = useState('')
    const [speciality, setSpeciality] = useState('General physician')
    const [degree, setDegree] = useState('')
    const [address1, setAddress1] = useState('')
    const [address2, setAddress2] = useState('')
    const [isSubmitting, setIsSubmitting] = useState(false)

    const backendUrl = import.meta.env.VITE_BACKEND_URL

    const onSubmitHandler = async (event) => {
        event.preventDefault()
        if (isSubmitting) return
        
        setIsSubmitting(true)
        try {
            const formData = new FormData();
            if (docImg) formData.append('image', docImg)
            
            formData.append('name', name)
            formData.append('email', email)
            formData.append('password', password)
            formData.append('experience', experience)
            formData.append('fees', Number(fees))
            formData.append('about', about)
            formData.append('speciality', speciality)
            formData.append('degree', degree)
            formData.append('address', JSON.stringify({ line1: address1, line2: address2 }))

            const { data } = await axios.post(backendUrl + '/api/dean/doctors/add', {
                name, email, password, experience, 
                fees: Number(fees), 
                about, speciality, degree, 
                address: { line1: address1, line2: address2 }
            }, { 
                headers: { deantoken: deanToken } 
            })

            if (data.success) {
                toast.success('Doctor added successfully!')
                await getDoctors()
                navigate('/dean-doctors')
            } else {
                toast.error(data.message)
            }
        } catch (error) {
            toast.error(error.message)
        } finally {
            setIsSubmitting(false)
        }
    }

    return (
        <div className='w-full bg-gradient-to-br from-gray-50 via-white to-emerald-50/30 p-4 sm:p-6 min-h-screen'>
            <div className='max-w-4xl mx-auto'>
                <div className='mb-6'>
                    <h2 className='text-2xl font-bold text-gray-900 flex items-center gap-3'>
                        <div className='bg-emerald-600 rounded-xl p-2 shadow-lg'>
                            <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 4v16m8-8H4" />
                            </svg>
                        </div>
                        Add New Doctor
                    </h2>
                    <p className='text-sm text-gray-500 mt-1'>Fill in the details to add a new doctor to the facility.</p>
                </div>

                <form onSubmit={onSubmitHandler}>
                    <GlassCard className="p-6 sm:p-8">
                        <div className='grid grid-cols-1 md:grid-cols-2 gap-6'>
                            <div className='space-y-4'>
                                <div>
                                    <label className='block text-xs font-bold uppercase tracking-widest text-emerald-700 mb-2'>Doctor Name</label>
                                    <input value={name} onChange={e => setName(e.target.value)} required type="text" placeholder='Dr. Name'
                                        className='w-full px-4 py-2.5 border-2 border-gray-100 rounded-xl focus:border-emerald-500 outline-none transition-all text-sm' />
                                </div>
                                <div>
                                    <label className='block text-xs font-bold uppercase tracking-widest text-emerald-700 mb-2'>Email</label>
                                    <input value={email} onChange={e => setEmail(e.target.value)} required type="email" placeholder='doctor@hospital.com'
                                        className='w-full px-4 py-2.5 border-2 border-gray-100 rounded-xl focus:border-emerald-500 outline-none transition-all text-sm' />
                                </div>
                                <div>
                                    <label className='block text-xs font-bold uppercase tracking-widest text-emerald-700 mb-2'>Password</label>
                                    <input value={password} onChange={e => setPassword(e.target.value)} required type="password" placeholder='••••••••'
                                        className='w-full px-4 py-2.5 border-2 border-gray-100 rounded-xl focus:border-emerald-500 outline-none transition-all text-sm' />
                                </div>
                                <div>
                                    <label className='block text-xs font-bold uppercase tracking-widest text-emerald-700 mb-2'>Speciality</label>
                                    <select value={speciality} onChange={e => setSpeciality(e.target.value)}
                                        className='w-full px-4 py-2.5 border-2 border-gray-100 rounded-xl focus:border-emerald-500 outline-none transition-all text-sm bg-white'>
                                        <option value="General physician">General Physician</option>
                                        <option value="Gynecologist">Gynecologist</option>
                                        <option value="Dermatologist">Dermatologist</option>
                                        <option value="Pediatricians">Pediatrician</option>
                                        <option value="Neurologist">Neurologist</option>
                                        <option value="Gastroenterologist">Gastroenterologist</option>
                                    </select>
                                </div>
                            </div>

                            <div className='space-y-4'>
                                <div>
                                    <label className='block text-xs font-bold uppercase tracking-widest text-emerald-700 mb-2'>Medical Degree</label>
                                    <input value={degree} onChange={e => setDegree(e.target.value)} required type="text" placeholder='MBBS, MD'
                                        className='w-full px-4 py-2.5 border-2 border-gray-100 rounded-xl focus:border-emerald-500 outline-none transition-all text-sm' />
                                </div>
                                <div>
                                    <label className='block text-xs font-bold uppercase tracking-widest text-emerald-700 mb-2'>Experience</label>
                                    <select value={experience} onChange={e => setExperience(e.target.value)}
                                        className='w-full px-4 py-2.5 border-2 border-gray-100 rounded-xl focus:border-emerald-500 outline-none transition-all text-sm bg-white'>
                                        {[1,2,3,4,5,6,7,8,9,10].map(yr => <option key={yr} value={`${yr} Year`}>{yr} Year{yr > 1 ? 's' : ''}</option>)}
                                    </select>
                                </div>
                                <div>
                                    <label className='block text-xs font-bold uppercase tracking-widest text-emerald-700 mb-2'>Consultation Fees (₹)</label>
                                    <input value={fees} onChange={e => setFees(e.target.value)} required type="number" placeholder='500'
                                        className='w-full px-4 py-2.5 border-2 border-gray-100 rounded-xl focus:border-emerald-500 outline-none transition-all text-sm' />
                                </div>
                                <div>
                                    <label className='block text-xs font-bold uppercase tracking-widest text-emerald-700 mb-2'>Address</label>
                                    <input value={address1} onChange={e => setAddress1(e.target.value)} required placeholder='Line 1'
                                        className='w-full px-4 py-2.5 border-2 border-gray-100 rounded-xl focus:border-emerald-500 outline-none transition-all text-sm mb-2' />
                                    <input value={address2} onChange={e => setAddress2(e.target.value)} required placeholder='Line 2'
                                        className='w-full px-4 py-2.5 border-2 border-gray-100 rounded-xl focus:border-emerald-500 outline-none transition-all text-sm' />
                                </div>
                            </div>
                        </div>

                        <div className='mt-8 flex flex-col sm:flex-row items-center gap-4 bg-emerald-50 p-4 rounded-xl border border-emerald-100'>
                            <div className='bg-emerald-600 p-2 rounded-lg text-white'>
                                <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24"><path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 8l7.89 5.26a2 2 0 002.22 0L21 8M5 19h14a2 2 0 002-2V7a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" /></svg>
                            </div>
                            <p className='text-xs text-emerald-800 font-medium'>
                                <strong>Automated Delivery:</strong> Once submitted, the system will instantly send login credentials to the doctor's email address.
                            </p>
                        </div>

                        <button type='submit' disabled={isSubmitting}
                            className='mt-6 w-full py-4 bg-gradient-to-r from-emerald-600 to-teal-600 text-white font-bold rounded-xl shadow-lg hover:shadow-emerald-500/20 active:scale-95 transition-all flex items-center justify-center gap-2'>
                            {isSubmitting ? (
                                <>
                                    <svg className="animate-spin h-5 w-5 text-white" fill="none" viewBox="0 0 24 24"><circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle><path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path></svg>
                                    Processing...
                                </>
                            ) : 'Create & Send Credentials'}
                        </button>
                    </GlassCard>
                </form>
            </div>
        </div>
    )
}

export default DeanAddDoctor
