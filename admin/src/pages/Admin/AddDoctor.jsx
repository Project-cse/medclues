import React, { useContext, useState, useEffect } from 'react'
import { assets } from '../../assets/assets'
import { toast } from 'react-toastify'
import axios from 'axios'
import { AdminContext } from '../../context/AdminContext'
import { AppContext } from '../../context/AppContext'
import GlassCard from '../../components/ui/GlassCard'

const AddDoctor = () => {

    const [uploadMode, setUploadMode] = useState('manual') // 'manual' or 'bulk'
    const [bulkFile, setBulkFile] = useState(null)
    const [bulkUploading, setBulkUploading] = useState(false)
    const [bulkResults, setBulkResults] = useState(null)
    const [bulkPreview, setBulkPreview] = useState(null) // Preview data before saving
    const [showPreview, setShowPreview] = useState(false) // Show preview step

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

    const { backendUrl } = useContext(AppContext)
    const { aToken, doctors, getAllDoctors, getDashData } = useContext(AdminContext)

    useEffect(() => {
        if (aToken) {
            getAllDoctors()
        }
    }, [aToken])

    const onSubmitHandler = async (event) => {
        event.preventDefault()

        try {

            if (!docImg) {
                return toast.error('Image Not Selected')
            }

            const formData = new FormData();

            formData.append('image', docImg)
            formData.append('name', name)
            formData.append('email', email)
            formData.append('password', password)
            formData.append('experience', experience)
            formData.append('fees', Number(fees))
            formData.append('about', about)
            formData.append('speciality', speciality)
            formData.append('degree', degree)
            formData.append('address', JSON.stringify({ line1: address1, line2: address2 }))

            const { data } = await axios.post(backendUrl + '/api/admin/add-doctor', formData, { headers: { aToken } })
            if (data.success) {
                toast.success(data.message)
                setDocImg(false)
                setName('')
                setPassword('')
                setEmail('')
                setAddress1('')
                setAddress2('')
                setDegree('')
                setAbout('')
                setFees('')
                setExperience('1 Year')
                setSpeciality('General physician')
                getAllDoctors() // Refresh doctors list
                getDashData() // Refresh dashboard stats
            } else {
                toast.error(data.message)
            }

        } catch (error) {
            toast.error(error.message)
            console.log(error)
        }

    }

    const handleBulkUploadPreview = async (event) => {
        event.preventDefault()

        if (!bulkFile) {
            return toast.error('Please select a CSV or Excel file')
        }

        const fileExtension = bulkFile.name.split('.').pop().toLowerCase()
        if (!['csv', 'xlsx', 'xls'].includes(fileExtension)) {
            return toast.error('Please upload a CSV or Excel file (.csv, .xlsx, .xls)')
        }

        setBulkUploading(true)
        setBulkPreview(null)
        setBulkResults(null)
        setShowPreview(false)

        try {
            const formData = new FormData()
            formData.append('file', bulkFile)

            const { data } = await axios.post(backendUrl + '/api/admin/bulk-add-doctors-preview', formData, {
                headers: { aToken }
            })

            if (data.success) {
                setBulkPreview(data)
                setShowPreview(true)
                toast.success(`Preview ready: ${data.summary.valid} valid, ${data.summary.invalid} invalid`)
            } else {
                toast.error(data.message)
            }
        } catch (error) {
            toast.error(error.response?.data?.message || error.message || 'Failed to process file')
            console.error(error)
        } finally {
            setBulkUploading(false)
        }
    }

    const handleBulkUploadConfirm = async () => {
        if (!bulkPreview || !bulkPreview.preview || bulkPreview.preview.length === 0) {
            return toast.error('No valid doctors to save')
        }

        setBulkUploading(true)

        try {
            const { data } = await axios.post(backendUrl + '/api/admin/bulk-add-doctors', {
                previewData: bulkPreview.preview
            }, {
                headers: { aToken }
            })

            if (data.success) {
                toast.success(data.message)
                setBulkResults(data.results)
                setBulkPreview(null)
                setShowPreview(false)
                setBulkFile(null)
                getAllDoctors() // Refresh doctors list
                getDashData() // Refresh dashboard stats
            } else {
                toast.error(data.message)
            }
        } catch (error) {
            toast.error(error.response?.data?.message || error.message || 'Failed to save doctors')
            console.error(error)
        } finally {
            setBulkUploading(false)
        }
    }

    // Get recently added doctors (last 3)
    const recentDoctors = doctors && doctors.length > 0
        ? [...doctors].sort((a, b) => new Date(b.date) - new Date(a.date)).slice(0, 3)
        : []

    // Calculate experience preview
    const getExperiencePreview = () => {
        const years = parseInt(experience) || 1
        if (years >= 10) return `${years} Years — Senior Specialist`
        if (years >= 5) return `${years} Years — Experienced Professional`
        if (years >= 3) return `${years} Years — Skilled Practitioner`
        return `${years} Year — Junior Doctor`
    }

    return (
        <div className='w-full bg-gradient-to-br from-gray-50 via-white to-indigo-50/30 flex flex-col lg:flex-row mobile-safe-area pb-6 min-h-screen'>
            <div className='flex flex-col lg:flex-row flex-1 gap-6 items-stretch max-w-7xl mx-auto w-full px-4 sm:px-6 lg:px-8'>
                {/* Main Form Container */}
                <div className='flex-1 w-full pt-6'>
                    <div className='mb-6'>
                        <h2 className='text-2xl sm:text-3xl font-bold text-gray-900 mb-2 flex items-center gap-3'>
                            <div className='bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 rounded-xl p-2 shadow-lg shadow-indigo-500/30'>
                                <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 4v16m8-8H4" />
                                </svg>
                            </div>
                            <span className='bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent'>Add New Doctor</span>
                        </h2>
                        <p className='text-sm text-gray-500 ml-11'>Fill in the details to add a new doctor to the system</p>

                        {/* Upload Mode Toggle */}
                        <div className='mt-4 ml-11 flex gap-4'>
                            <button
                                type="button"
                                onClick={() => {
                                    setUploadMode('manual')
                                    setBulkResults(null)
                                    setBulkFile(null)
                                }}
                                className={`px-4 py-2 rounded-lg font-semibold text-sm transition-all ${uploadMode === 'manual'
                                        ? 'bg-indigo-600 text-white shadow-lg'
                                        : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                                    }`}
                            >
                                Manual Entry
                            </button>
                            <button
                                type="button"
                                onClick={() => {
                                    setUploadMode('bulk')
                                    setBulkResults(null)
                                }}
                                className={`px-4 py-2 rounded-lg font-semibold text-sm transition-all ${uploadMode === 'bulk'
                                        ? 'bg-indigo-600 text-white shadow-lg'
                                        : 'bg-gray-200 text-gray-700 hover:bg-gray-300'
                                    }`}
                            >
                                Bulk Upload (CSV/Excel)
                            </button>
                        </div>
                    </div>

                    {uploadMode === 'manual' ? (
                        <form onSubmit={onSubmitHandler}>
                            <GlassCard className="p-6 sm:p-8 shadow-xl border border-white/50">
                                {/* Decorative top border */}
                                <div className='h-1 w-full bg-gradient-to-r from-indigo-400 via-purple-400 via-pink-400 to-indigo-400 rounded-full mb-6'></div>

                                {/* Image Upload Section */}
                                <div className='flex flex-col sm:flex-row items-center gap-4 mb-8 p-6 bg-gradient-to-br from-indigo-50/50 to-purple-50/50 rounded-2xl border-2 border-dashed border-indigo-200 hover:border-indigo-400 transition-all duration-300'>
                                    <label htmlFor="doc-img" className='cursor-pointer group flex-shrink-0'>
                                        <div className='relative'>
                                            <div className='absolute -inset-1 bg-gradient-to-r from-indigo-400 to-purple-400 rounded-full opacity-0 group-hover:opacity-20 blur transition-opacity duration-300'></div>
                                            <img
                                                className='relative w-24 h-24 sm:w-28 sm:h-28 bg-white rounded-full object-cover ring-4 ring-white shadow-xl group-hover:ring-indigo-300 transition-all duration-300 transform group-hover:scale-105'
                                                src={docImg ? URL.createObjectURL(docImg) : assets.upload_area}
                                                alt="Doctor"
                                            />
                                            {docImg && (
                                                <div className='absolute inset-0 bg-green-500/30 rounded-full flex items-center justify-center backdrop-blur-sm'>
                                                    <div className='bg-white rounded-full p-1.5 shadow-lg'>
                                                        <svg className='w-6 h-6 text-green-600' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                                                        </svg>
                                                    </div>
                                                </div>
                                            )}
                                        </div>
                                    </label>
                                    <input onChange={(e) => setDocImg(e.target.files[0])} type="file" name="" id="doc-img" hidden accept="image/*" />
                                    <div className='text-center sm:text-left flex-1'>
                                        <p className='text-base sm:text-lg font-bold text-gray-800 mb-1'>Upload Doctor Picture</p>
                                        <p className='text-xs sm:text-sm text-gray-500'>Click to select or drag & drop image here</p>
                                    </div>
                                </div>

                                {/* Form Grid */}
                                <div className='grid grid-cols-1 lg:grid-cols-2 gap-5 sm:gap-6 text-gray-700'>
                                    {/* Left Column */}
                                    <div className='w-full flex flex-col gap-5'>
                                        <div className='flex-1 flex flex-col gap-2'>
                                            <label className='text-sm font-bold text-gray-700 flex items-center gap-2'>
                                                <span className='text-indigo-600'>•</span>
                                                Doctor Name
                                            </label>
                                            <input
                                                onChange={e => setName(e.target.value)}
                                                value={name}
                                                className='w-full border-2 border-gray-200 rounded-xl px-4 py-3 text-sm bg-white shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all duration-200 hover:border-indigo-300'
                                                type="text"
                                                placeholder='Enter full name'
                                                required
                                            />
                                        </div>

                                        <div className='flex-1 flex flex-col gap-2'>
                                            <label className='text-sm font-bold text-gray-700 flex items-center gap-2'>
                                                <span className='text-indigo-600'>•</span>
                                                Email Address
                                            </label>
                                            <input
                                                onChange={e => setEmail(e.target.value)}
                                                value={email}
                                                className='w-full border-2 border-gray-200 rounded-xl px-4 py-3 text-sm bg-white shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all duration-200 hover:border-indigo-300'
                                                type="email"
                                                placeholder='Enter email address'
                                                required
                                            />
                                        </div>

                                        <div className='flex-1 flex flex-col gap-2'>
                                            <label className='text-sm font-bold text-gray-700 flex items-center gap-2'>
                                                <span className='text-indigo-600'>•</span>
                                                Password
                                            </label>
                                            <input
                                                onChange={e => setPassword(e.target.value)}
                                                value={password}
                                                className='w-full border-2 border-gray-200 rounded-xl px-4 py-3 text-sm bg-white shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all duration-200 hover:border-indigo-300'
                                                type="password"
                                                placeholder='Minimum 8 characters'
                                                required
                                                minLength={8}
                                            />
                                        </div>

                                        <div className='flex-1 flex flex-col gap-2'>
                                            <label className='text-sm font-bold text-gray-700 flex items-center gap-2'>
                                                <span className='text-indigo-600'>•</span>
                                                Experience
                                            </label>
                                            <select
                                                onChange={e => setExperience(e.target.value)}
                                                value={experience}
                                                className='w-full border-2 border-gray-200 rounded-xl px-4 py-3 text-sm bg-white shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all duration-200 hover:border-indigo-300 cursor-pointer'
                                            >
                                                <option value="1 Year">1 Year</option>
                                                <option value="2 Year">2 Years</option>
                                                <option value="3 Year">3 Years</option>
                                                <option value="4 Year">4 Years</option>
                                                <option value="5 Year">5 Years</option>
                                                <option value="6 Year">6 Years</option>
                                                <option value="8 Year">8 Years</option>
                                                <option value="9 Year">9 Years</option>
                                                <option value="10 Year">10 Years</option>
                                            </select>
                                            {experience && (
                                                <p className='text-xs text-indigo-600 font-semibold mt-1 flex items-center gap-2 bg-indigo-50 px-3 py-2 rounded-lg border border-indigo-100'>
                                                    <svg className='w-4 h-4 flex-shrink-0' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                                    </svg>
                                                    {getExperiencePreview()}
                                                </p>
                                            )}
                                        </div>

                                        <div className='flex-1 flex flex-col gap-2'>
                                            <label className='text-sm font-bold text-gray-700 flex items-center gap-2'>
                                                <span className='text-indigo-600'>•</span>
                                                Consultation Fees
                                            </label>
                                            <input
                                                onChange={e => setFees(e.target.value)}
                                                value={fees}
                                                className='w-full border-2 border-gray-200 rounded-xl px-4 py-3 text-sm bg-white shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all duration-200 hover:border-indigo-300'
                                                type="number"
                                                placeholder='₹ 500'
                                                required
                                                min="0"
                                            />
                                        </div>
                                    </div>

                                    {/* Right Column */}
                                    <div className='w-full flex flex-col gap-5'>
                                        <div className='flex-1 flex flex-col gap-2'>
                                            <label className='text-sm font-bold text-gray-700 flex items-center gap-2'>
                                                <span className='text-indigo-600'>•</span>
                                                Speciality
                                            </label>
                                            <select
                                                onChange={e => setSpeciality(e.target.value)}
                                                value={speciality}
                                                className='w-full border-2 border-gray-200 rounded-xl px-4 py-3 text-sm bg-white shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all duration-200 hover:border-indigo-300 cursor-pointer'
                                            >
                                                <option value="General physician">General Physician</option>
                                                <option value="Gynecologist">Gynecologist</option>
                                                <option value="Dermatologist">Dermatologist</option>
                                                <option value="Pediatricians">Pediatrician</option>
                                                <option value="Neurologist">Neurologist</option>
                                                <option value="Gastroenterologist">Gastroenterologist</option>
                                            </select>
                                        </div>

                                        <div className='flex-1 flex flex-col gap-2'>
                                            <label className='text-sm font-bold text-gray-700 flex items-center gap-2'>
                                                <span className='text-indigo-600'>•</span>
                                                Medical Degree
                                            </label>
                                            <input
                                                onChange={e => setDegree(e.target.value)}
                                                value={degree}
                                                className='w-full border-2 border-gray-200 rounded-xl px-4 py-3 text-sm bg-white shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all duration-200 hover:border-indigo-300'
                                                type="text"
                                                placeholder='e.g., MBBS, MD, MS'
                                                required
                                            />
                                        </div>

                                        <div className='flex-1 flex flex-col gap-2'>
                                            <label className='text-sm font-bold text-gray-700 flex items-center gap-2'>
                                                <span className='text-indigo-600'>•</span>
                                                Address
                                            </label>
                                            <input
                                                onChange={e => setAddress1(e.target.value)}
                                                value={address1}
                                                className='w-full border-2 border-gray-200 rounded-xl px-4 py-3 text-sm bg-white shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all duration-200 hover:border-indigo-300 mb-2'
                                                type="text"
                                                placeholder='Street Address'
                                                required
                                            />
                                            <input
                                                onChange={e => setAddress2(e.target.value)}
                                                value={address2}
                                                className='w-full border-2 border-gray-200 rounded-xl px-4 py-3 text-sm bg-white shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all duration-200 hover:border-indigo-300'
                                                type="text"
                                                placeholder='City, State, ZIP'
                                                required
                                            />
                                        </div>
                                    </div>
                                </div>

                                {/* About Doctor */}
                                <div className='mt-6'>
                                    <label className='text-sm font-bold text-gray-700 mb-2 block flex items-center gap-2'>
                                        <span className='text-indigo-600'>•</span>
                                        About Doctor
                                    </label>
                                    <textarea
                                        onChange={e => setAbout(e.target.value)}
                                        value={about}
                                        className='w-full px-4 py-3 border-2 border-gray-200 rounded-xl focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all duration-200 bg-white shadow-sm resize-none hover:border-indigo-300'
                                        rows={5}
                                        placeholder="Write about the doctor's background, expertise, and achievements..."
                                    ></textarea>
                                </div>

                                {/* Submit Button */}
                                <button
                                    type='submit'
                                    className='mt-8 bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 px-10 py-4 text-white rounded-xl shadow-lg shadow-indigo-500/30 hover:shadow-xl hover:shadow-indigo-500/40 transition-all duration-300 font-bold text-base flex items-center justify-center gap-3 w-full transform hover:scale-[1.02] active:scale-[0.98]'
                                >
                                    <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 4v16m8-8H4" />
                                    </svg>
                                    Add Doctor to System
                                </button>
                            </GlassCard>
                        </form>
                    ) : (
                        <form onSubmit={handleBulkUploadPreview}>
                            <GlassCard className="p-6 sm:p-8 shadow-xl border border-white/50">
                                <div className='h-1 w-full bg-gradient-to-r from-indigo-400 via-purple-400 via-pink-400 to-indigo-400 rounded-full mb-6'></div>

                                <div className='mb-6'>
                                    <h3 className='text-xl font-bold text-gray-900 mb-4 flex items-center gap-2'>
                                        <svg className='w-6 h-6 text-indigo-600' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                                        </svg>
                                        Bulk Upload Doctors
                                    </h3>
                                    <p className='text-sm text-gray-600 mb-4'>
                                        Upload a CSV or Excel file with doctor information. Each doctor will receive login credentials via email.
                                    </p>
                                </div>

                                {/* File Upload */}
                                <div className='mb-6 p-6 bg-gradient-to-br from-indigo-50/50 to-purple-50/50 rounded-2xl border-2 border-dashed border-indigo-200 hover:border-indigo-400 transition-all duration-300'>
                                    <label htmlFor="bulk-file" className='cursor-pointer block text-center'>
                                        <div className='mb-4'>
                                            <svg className='w-16 h-16 mx-auto text-indigo-500' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M7 16a4 4 0 01-.88-7.903A5 5 0 1115.9 6L16 6a5 5 0 011 9.9M15 13l-3-3m0 0l-3 3m3-3v12" />
                                            </svg>
                                        </div>
                                        <p className='text-base font-bold text-gray-800 mb-2'>
                                            {bulkFile ? bulkFile.name : 'Click to select or drag & drop file here'}
                                        </p>
                                        <p className='text-xs text-gray-500'>Supports CSV (.csv) and Excel (.xlsx, .xls) files</p>
                                    </label>
                                    <input
                                        onChange={(e) => setBulkFile(e.target.files[0])}
                                        type="file"
                                        id="bulk-file"
                                        hidden
                                        accept=".csv,.xlsx,.xls"
                                    />
                                </div>

                                {/* CSV Format Guide */}
                                <div className='mb-6 p-5 bg-blue-50 rounded-xl border border-blue-200'>
                                    <h4 className='font-bold text-gray-800 mb-3 flex items-center gap-2'>
                                        <svg className='w-5 h-5 text-blue-600' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                        </svg>
                                        Required CSV/Excel Columns
                                    </h4>
                                    <div className='text-sm text-gray-700 space-y-1'>
                                        <p><strong>Required:</strong> name, email</p>
                                        <p><strong>Optional:</strong> speciality, degree, experience, about, fees, addressLine1, addressLine2</p>
                                        <p className='text-xs text-gray-600 mt-2'>
                                            Passwords will be auto-generated (starting with "pms") and sent via email.
                                        </p>
                                    </div>
                                </div>

                                {/* Upload Button */}
                                {!showPreview ? (
                                    <button
                                        type='submit'
                                        disabled={!bulkFile || bulkUploading}
                                        className='w-full mt-4 bg-gradient-to-r from-indigo-600 via-purple-600 to-pink-600 px-10 py-4 text-white rounded-xl shadow-lg shadow-indigo-500/30 hover:shadow-xl hover:shadow-indigo-500/40 transition-all duration-300 font-bold text-base flex items-center justify-center gap-3 transform hover:scale-[1.02] active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed'
                                    >
                                        {bulkUploading ? (
                                            <>
                                                <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                                </svg>
                                                Processing...
                                            </>
                                        ) : (
                                            <>
                                                <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                                </svg>
                                                Preview Doctors
                                            </>
                                        )}
                                    </button>
                                ) : (
                                    <div className='mt-4 space-y-3'>
                                        <button
                                            type='button'
                                            onClick={handleBulkUploadConfirm}
                                            disabled={bulkUploading || !bulkPreview || bulkPreview.preview.length === 0}
                                            className='w-full bg-gradient-to-r from-green-600 to-emerald-600 px-10 py-4 text-white rounded-xl shadow-lg hover:shadow-xl transition-all duration-300 font-bold text-base flex items-center justify-center gap-3 transform hover:scale-[1.02] active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed'
                                        >
                                            {bulkUploading ? (
                                                <>
                                                    <svg className="animate-spin h-5 w-5 text-white" xmlns="http://www.w3.org/2000/svg" fill="none" viewBox="0 0 24 24">
                                                        <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4"></circle>
                                                        <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4zm2 5.291A7.962 7.962 0 014 12H0c0 3.042 1.135 5.824 3 7.938l3-2.647z"></path>
                                                    </svg>
                                                    Saving...
                                                </>
                                            ) : (
                                                <>
                                                    <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M5 13l4 4L19 7" />
                                                    </svg>
                                                    Confirm & Save to Database ({bulkPreview?.preview?.length || 0} doctors)
                                                </>
                                            )}
                                        </button>
                                        <button
                                            type='button'
                                            onClick={() => {
                                                setShowPreview(false)
                                                setBulkPreview(null)
                                                setBulkFile(null)
                                            }}
                                            className='w-full bg-gray-200 px-10 py-4 text-gray-700 rounded-xl hover:bg-gray-300 transition-all duration-300 font-bold text-base'
                                        >
                                            Cancel
                                        </button>
                                    </div>
                                )}

                                {/* Preview Display */}
                                {showPreview && bulkPreview && (
                                    <div className='mt-6 p-5 bg-blue-50 rounded-xl border-2 border-blue-200'>
                                        <h4 className='font-bold text-gray-800 mb-4 flex items-center gap-2'>
                                            <svg className='w-5 h-5 text-blue-600' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                            </svg>
                                            Preview - Review Before Saving
                                        </h4>
                                        <div className='space-y-2 text-sm mb-4'>
                                            <p><strong>Total Rows:</strong> {bulkPreview.summary.total}</p>
                                            <p className='text-green-600'><strong>Valid:</strong> {bulkPreview.summary.valid} doctors</p>
                                            {bulkPreview.summary.invalid > 0 && (
                                                <p className='text-red-600'><strong>Invalid:</strong> {bulkPreview.summary.invalid} rows</p>
                                            )}
                                        </div>

                                        {bulkPreview.preview && bulkPreview.preview.length > 0 && (
                                            <div className='max-h-96 overflow-y-auto space-y-2 mb-4'>
                                                {bulkPreview.preview.map((doc, idx) => (
                                                    <div key={idx} className='bg-white p-3 rounded-lg border border-gray-200 text-xs'>
                                                        <div className='flex justify-between items-start mb-2'>
                                                            <div>
                                                                <p className='font-bold text-gray-900'>{doc.name}</p>
                                                                <p className='text-gray-600'>{doc.email}</p>
                                                            </div>
                                                            <span className='bg-green-100 text-green-700 px-2 py-1 rounded text-xs font-semibold'>Valid</span>
                                                        </div>
                                                        <div className='grid grid-cols-2 gap-2 text-gray-600 mt-2'>
                                                            <p><strong>Speciality:</strong> {doc.speciality}</p>
                                                            <p><strong>Degree:</strong> {doc.degree}</p>
                                                            <p><strong>Experience:</strong> {doc.experience}</p>
                                                            <p><strong>Fees:</strong> ₹{doc.fees}</p>
                                                        </div>
                                                        <div className='mt-2 pt-2 border-t border-gray-200'>
                                                            <p className='text-gray-500'><strong>Password:</strong> <span className='font-mono bg-gray-100 px-2 py-1 rounded'>{doc.password}</span></p>
                                                            <p className='text-gray-500'><strong>Employee ID:</strong> <span className='font-mono bg-gray-100 px-2 py-1 rounded'>{doc.employeeId}</span></p>
                                                        </div>
                                                    </div>
                                                ))}
                                            </div>
                                        )}

                                        {bulkPreview.errors && bulkPreview.errors.length > 0 && (
                                            <div className='mt-4'>
                                                <p className='text-sm font-semibold text-red-600 mb-2'>Errors Found:</p>
                                                <div className='max-h-40 overflow-y-auto space-y-1'>
                                                    {bulkPreview.errors.map((error, idx) => (
                                                        <div key={idx} className='bg-red-50 p-2 rounded border border-red-200 text-xs'>
                                                            <p><strong>Row {error.row}:</strong> {error.name} ({error.email})</p>
                                                            <p className='text-red-600'>{error.reason}</p>
                                                        </div>
                                                    ))}
                                                </div>
                                            </div>
                                        )}
                                    </div>
                                )}

                                {/* Results Display */}
                                {bulkResults && !showPreview && (
                                    <div className='mt-6 p-5 bg-gray-50 rounded-xl border border-gray-200'>
                                        <h4 className='font-bold text-gray-800 mb-3'>Upload Results</h4>
                                        <div className='space-y-2 text-sm'>
                                            <p><strong>Total:</strong> {bulkResults.total} doctors</p>
                                            <p className='text-green-600'><strong>Successful:</strong> {bulkResults.successful} doctors</p>
                                            {bulkResults.failed > 0 && (
                                                <p className='text-red-600'><strong>Failed:</strong> {bulkResults.failed} doctors</p>
                                            )}
                                        </div>
                                        {bulkResults.details && bulkResults.details.success && bulkResults.details.success.length > 0 && (
                                            <div className='mt-4'>
                                                <p className='text-xs font-semibold text-gray-600 mb-2'>Successfully Created:</p>
                                                <div className='max-h-40 overflow-y-auto space-y-1'>
                                                    {bulkResults.details.success.slice(0, 10).map((doc, idx) => (
                                                        <div key={idx} className='text-xs bg-green-50 p-2 rounded border border-green-200'>
                                                            <p><strong>{doc.name}</strong> ({doc.email})</p>
                                                            <p className='text-gray-600'>Password: {doc.password} | ID: {doc.employeeId}</p>
                                                        </div>
                                                    ))}
                                                    {bulkResults.details.success.length > 10 && (
                                                        <p className='text-xs text-gray-500'>... and {bulkResults.details.success.length - 10} more</p>
                                                    )}
                                                </div>
                                            </div>
                                        )}
                                    </div>
                                )}
                            </GlassCard>
                        </form>
                    )}
                </div>

                {/* Right Sidebar - Preview & Guidelines */}
                <div className='w-full lg:w-96 flex-shrink-0 pt-6 lg:sticky lg:top-24 lg:h-fit'>
                    <GlassCard className="p-6 sm:p-8 shadow-xl border border-white/50">
                        <div className='mb-8'>
                            <h3 className='text-2xl font-bold text-gray-900 mb-3 flex items-center gap-3'>
                                <div className='bg-gradient-to-br from-indigo-500 to-purple-600 rounded-lg p-2 shadow-lg'>
                                    <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                    </svg>
                                </div>
                                <span className='bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent'>Preview & Guidelines</span>
                            </h3>
                            <div className='h-1.5 w-24 bg-gradient-to-r from-indigo-400 via-purple-400 to-pink-400 rounded-full'></div>
                        </div>

                        {/* Quick Instructions */}
                        <div className='mb-6 p-5 bg-gradient-to-br from-indigo-50 via-purple-50 to-pink-50 rounded-2xl border-2 border-indigo-100 shadow-sm'>
                            <h4 className='font-bold text-gray-800 mb-4 flex items-center gap-2 text-base'>
                                <div className='bg-indigo-500 rounded-lg p-1.5'>
                                    <svg className='w-5 h-5 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M13 16h-1v-4h-1m1-4h.01M21 12a9 9 0 11-18 0 9 9 0 0118 0z" />
                                    </svg>
                                </div>
                                Quick Instructions
                            </h4>
                            <ul className='space-y-3 text-sm text-gray-700'>
                                <li className='flex items-start gap-3'>
                                    <span className='text-indigo-600 font-bold text-lg leading-none mt-0.5'>•</span>
                                    <span className='font-medium'>Upload a clear professional photo</span>
                                </li>
                                <li className='flex items-start gap-3'>
                                    <span className='text-indigo-600 font-bold text-lg leading-none mt-0.5'>•</span>
                                    <span className='font-medium'>Fill all required fields accurately</span>
                                </li>
                                <li className='flex items-start gap-3'>
                                    <span className='text-indigo-600 font-bold text-lg leading-none mt-0.5'>•</span>
                                    <span className='font-medium'>Use a strong password (min 8 chars)</span>
                                </li>
                                <li className='flex items-start gap-3'>
                                    <span className='text-indigo-600 font-bold text-lg leading-none mt-0.5'>•</span>
                                    <span className='font-medium'>Verify email format before submission</span>
                                </li>
                            </ul>
                        </div>

                        {/* Live Preview */}
                        {(name || speciality || docImg || experience) && (
                            <div className='mb-6 p-5 bg-gradient-to-br from-white to-purple-50/50 rounded-2xl border-2 border-purple-100 shadow-sm'>
                                <h4 className='font-bold text-gray-800 mb-4 flex items-center gap-2 text-base'>
                                    <div className='bg-purple-500 rounded-lg p-1.5'>
                                        <svg className='w-5 h-5 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M15 12a3 3 0 11-6 0 3 3 0 016 0z" />
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M2.458 12C3.732 7.943 7.523 5 12 5c4.478 0 8.268 2.943 9.542 7-1.274 4.057-5.064 7-9.542 7-4.477 0-8.268-2.943-9.542-7z" />
                                        </svg>
                                    </div>
                                    Live Preview
                                </h4>
                                <div className='space-y-4 text-center'>
                                    {docImg && (
                                        <div className='flex justify-center'>
                                            <img
                                                src={URL.createObjectURL(docImg)}
                                                alt="Preview"
                                                className='w-24 h-24 rounded-full object-cover border-4 border-white shadow-lg ring-2 ring-purple-200'
                                            />
                                        </div>
                                    )}
                                    {name && (
                                        <p className='text-lg font-bold text-gray-900'>{name}</p>
                                    )}
                                    {speciality && (
                                        <p className='text-sm font-semibold text-gray-600 bg-white/60 px-3 py-1 rounded-full inline-block'>{speciality}</p>
                                    )}
                                    {experience && (
                                        <p className='text-xs text-indigo-600 font-bold bg-indigo-50 px-4 py-2 rounded-lg border border-indigo-100'>{getExperiencePreview()}</p>
                                    )}
                                </div>
                            </div>
                        )}

                        {/* Stats Cards */}
                        <div className='space-y-4'>
                            <div className='p-5 bg-gradient-to-br from-blue-50 via-indigo-50 to-purple-50 rounded-2xl border-2 border-blue-100 shadow-sm hover:shadow-md transition-shadow duration-300'>
                                <div className='flex items-center justify-between'>
                                    <div>
                                        <p className='text-xs font-semibold text-gray-600 uppercase tracking-wide mb-1'>Total Doctors</p>
                                        <p className='text-3xl font-bold bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent'>{doctors?.length || 0}</p>
                                    </div>
                                    <div className='bg-gradient-to-br from-indigo-500 to-purple-600 rounded-xl p-3 shadow-lg'>
                                        <svg className='w-7 h-7 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M17 20h5v-2a3 3 0 00-5.356-1.857M17 20H7m10 0v-2c0-.656-.126-1.283-.356-1.857M7 20H2v-2a3 3 0 015.356-1.857M7 20v-2c0-.656.126-1.283.356-1.857m0 0a5.002 5.002 0 019.288 0M15 7a3 3 0 11-6 0 3 3 0 016 0zm6 3a2 2 0 11-4 0 2 2 0 014 0zM7 10a2 2 0 11-4 0 2 2 0 014 0z" />
                                        </svg>
                                    </div>
                                </div>
                            </div>

                            <div className='p-5 bg-gradient-to-br from-purple-50 via-pink-50 to-rose-50 rounded-2xl border-2 border-purple-100 shadow-sm hover:shadow-md transition-shadow duration-300'>
                                <div className='flex items-center justify-between'>
                                    <div>
                                        <p className='text-xs font-semibold text-gray-600 uppercase tracking-wide mb-1'>Active Doctors</p>
                                        <p className='text-3xl font-bold bg-gradient-to-r from-purple-600 to-pink-600 bg-clip-text text-transparent'>
                                            {doctors?.filter(doc => doc.available).length || 0}
                                        </p>
                                    </div>
                                    <div className='bg-gradient-to-br from-purple-500 to-pink-500 rounded-xl p-3 shadow-lg'>
                                        <svg className='w-7 h-7 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M9 12l2 2 4-4m6 2a9 9 0 11-18 0 9 9 0 0118 0z" />
                                        </svg>
                                    </div>
                                </div>
                            </div>

                            {/* Recently Added Doctors */}
                            {recentDoctors.length > 0 && (
                                <div className='p-5 bg-gradient-to-br from-green-50 via-emerald-50 to-teal-50 rounded-2xl border-2 border-green-100 shadow-sm'>
                                    <h4 className='font-bold text-gray-800 mb-4 text-sm flex items-center gap-2'>
                                        <svg className='w-4 h-4 text-green-600' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
                                        </svg>
                                        Recently Added
                                    </h4>
                                    <div className='space-y-3'>
                                        {recentDoctors.map((doc, idx) => (
                                            <div key={idx} className='flex items-center gap-3 p-2 bg-white/60 rounded-lg hover:bg-white transition-colors duration-200'>
                                                <img src={doc.image} alt={doc.name} className='w-10 h-10 rounded-full object-cover border-2 border-green-200 shadow-sm' />
                                                <div className='flex-1 min-w-0'>
                                                    <p className='font-semibold text-gray-800 truncate text-sm'>{doc.name}</p>
                                                    <p className='text-xs text-gray-500 truncate'>{doc.speciality}</p>
                                                </div>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}
                        </div>
                    </GlassCard>
                </div>
            </div>
        </div>
    )
}

export default AddDoctor
