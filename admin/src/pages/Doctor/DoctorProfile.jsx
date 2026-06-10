import React, { useContext, useEffect, useState, useRef } from 'react'
import { DoctorContext } from '../../context/DoctorContext'
import { AppContext } from '../../context/AppContext'
import { toast } from 'react-toastify'
import axios from 'axios'

const DoctorProfile = () => {

    const { dToken, profileData, setProfileData, getProfileData } = useContext(DoctorContext)
    const { currency, backendUrl } = useContext(AppContext)
    const [isEdit, setIsEdit] = useState(false)
    const [imagePreview, setImagePreview] = useState(null)
    const [uploadingImage, setUploadingImage] = useState(false)
    const fileInputRef = useRef(null)

    const handleImageChange = (e) => {
        const file = e.target.files[0]
        if (file) {
            // Validate file type
            if (!file.type.startsWith('image/')) {
                toast.error('Please select a valid image file')
                return
            }
            // Validate file size (max 5MB)
            if (file.size > 5 * 1024 * 1024) {
                toast.error('Image size should be less than 5MB')
                return
            }
            // Create preview
            const reader = new FileReader()
            reader.onloadend = () => {
                setImagePreview(reader.result)
            }
            reader.readAsDataURL(file)
        }
    }

    const updateProfile = async () => {
        try {
            setUploadingImage(true)
            
            const formData = new FormData()
            
            // Ensure address is properly formatted
            const addressData = profileData.address || { line1: '', line2: '' }
            formData.append('address', JSON.stringify(addressData))
            formData.append('fees', String(profileData.fees || 0))
            formData.append('about', profileData.about || '')
            formData.append('available', String(profileData.available))
            formData.append('status', profileData.status || 'available')

            // Add image if a new one was selected
            if (fileInputRef.current?.files[0]) {
                formData.append('image', fileInputRef.current.files[0])
            }

            const { data } = await axios.post(backendUrl + '/api/doctor/update-profile', formData, { 
                headers: { 
                    dToken
                } 
            })

            if (data.success) {
                toast.success(data.message)
                setIsEdit(false)
                setImagePreview(null)
                // Clear file input
                if (fileInputRef.current) {
                    fileInputRef.current.value = ''
                }
                // Wait a bit before refreshing to ensure backend has saved
                setTimeout(() => {
                    getProfileData()
                }, 500)
            } else {
                toast.error(data.message)
            }

        } catch (error) {
            console.error('Update profile error:', error)
            toast.error(error.response?.data?.message || error.message || 'Failed to update profile')
        } finally {
            setUploadingImage(false)
        }
    }

    useEffect(() => {
        if (dToken) {
            getProfileData()
        }
    }, [dToken])

    const cancelEdit = () => {
        setIsEdit(false)
        setImagePreview(null)
        if (fileInputRef.current) {
            fileInputRef.current.value = ''
        }
        getProfileData() // Reset to original data
    }

    return profileData && (
        <div className='w-full bg-gray-50 min-h-screen p-4 sm:p-6 lg:p-8'>
            <div className='max-w-6xl mx-auto'>
                <div className='flex flex-col lg:flex-row gap-6 lg:gap-8'>
                    {/* Left Side - Profile Card */}
                    <div className='w-full lg:w-80 flex-shrink-0'>
                        <div className='bg-white rounded-xl shadow-sm border border-gray-200 p-6 lg:sticky lg:top-24'>
                            <div className='relative mx-auto w-36 h-36 mb-6'>
                                <div className='relative w-full h-full group'>
                                    <img 
                                        className='w-full h-full object-cover rounded-full border-4 border-gray-100 shadow-md' 
                                        src={imagePreview || profileData.image} 
                                        alt={profileData.name}
                                    />
                                    <div className={`absolute bottom-2 right-2 w-5 h-5 rounded-full border-4 border-white shadow-sm z-10 ${
                                        (profileData.status === 'available' || (!profileData.status && profileData.available)) ? 'bg-green-500' : 
                                        profileData.status === 'busy' ? 'bg-yellow-500' : 
                                        profileData.status === 'emergency' ? 'bg-red-500' : 
                                        'bg-gray-400'
                                    }`}></div>
                                    {isEdit && (
                                        <div
                                            onClick={() => fileInputRef.current?.click()}
                                            className='absolute inset-0 flex items-center justify-center bg-black bg-opacity-50 rounded-full opacity-0 group-hover:opacity-100 transition-opacity cursor-pointer z-20'
                                        >
                                            <span className='text-white text-sm font-medium'>Change Photo</span>
                                        </div>
                                    )}
                                </div>
                                <input
                                    ref={fileInputRef}
                                    type="file"
                                    accept="image/*"
                                    onChange={handleImageChange}
                                    className="hidden"
                                />
                            </div>
                            <div className='text-center'>
                                <h2 className='text-2xl font-bold text-gray-900 mb-2'>{profileData.name}</h2>
                                <p className='text-sm text-gray-600 mb-3'>{profileData.degree}</p>
                                {profileData.available && (
                                    <p className='text-sm text-green-600 font-semibold'>Available</p>
                                )}
                            </div>
                        </div>
                    </div>

                    {/* Right Side - Profile Information */}
                    <div className='flex-1 bg-white rounded-xl shadow-sm border border-gray-200 p-6 sm:p-8'>
                        {/* Header */}
                        <div className='flex items-center justify-between mb-6 pb-4 border-b border-gray-200'>
                            <h1 className='text-2xl sm:text-3xl font-bold text-gray-900'>Profile</h1>
                            <button
                                onClick={() => isEdit ? cancelEdit() : setIsEdit(true)}
                                className={`px-5 py-2.5 rounded-lg text-sm font-semibold transition-all ${
                                    isEdit
                                        ? 'bg-gray-100 text-gray-700 hover:bg-gray-200'
                                        : 'bg-blue-600 text-white hover:bg-blue-700 shadow-sm hover:shadow-md'
                                }`}
                            >
                                {isEdit ? 'Cancel' : 'Edit Profile'}
                            </button>
                        </div>

                        {/* Badges */}
                        <div className='flex flex-wrap gap-3 mb-6'>
                            <span className='px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm font-medium border border-gray-200'>
                                {profileData.speciality}
                            </span>
                            <span className='px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm font-medium border border-gray-200'>
                                {profileData.experience} Experience
                            </span>
                            <span className='px-4 py-2 bg-gray-100 text-gray-700 rounded-full text-sm font-medium border border-gray-200'>
                                {profileData.degree}
                            </span>
                        </div>

                        {/* Divider */}
                        <div className='h-px bg-gray-200 mb-6'></div>

                        {/* About Doctor */}
                        <div className='mb-6'>
                            <h3 className='text-lg font-semibold text-gray-900 mb-3'>About Doctor</h3>
                            {isEdit ? (
                                <textarea 
                                    onChange={(e) => setProfileData(prev => ({ ...prev, about: e.target.value }))} 
                                    className='w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all bg-white resize-none text-sm text-gray-700' 
                                    rows={4} 
                                    value={profileData.about || ''}
                                    placeholder="Write about your medical background, expertise, and achievements..."
                                />
                            ) : (
                                <div className='px-4 py-3 bg-gray-50 rounded-lg border border-gray-200'>
                                    <p className='text-gray-700 leading-relaxed text-sm'>
                                        {profileData.about || 'No information provided yet.'}
                                    </p>
                                </div>
                            )}
                        </div>

                        {/* Divider */}
                        <div className='h-px bg-gray-200 mb-6'></div>

                        {/* Appointment Fee */}
                        <div className='mb-6'>
                            <h3 className='text-lg font-semibold text-gray-900 mb-3'>Appointment Fee</h3>
                            {isEdit ? (
                                <div className='max-w-xs'>
                                    <input 
                                        type='number' 
                                        onChange={(e) => setProfileData(prev => ({ ...prev, fees: e.target.value }))} 
                                        value={profileData.fees}
                                        className='w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all bg-white text-sm'
                                        placeholder="Enter consultation fee"
                                    />
                                </div>
                            ) : (
                                <div className='inline-block px-6 py-4 bg-gray-50 rounded-lg border border-gray-200'>
                                    <p className='text-2xl font-bold text-gray-900'>
                                        {currency} {profileData.fees}
                                    </p>
                                </div>
                            )}
                        </div>

                        {/* Divider */}
                        <div className='h-px bg-gray-200 mb-6'></div>

                        {/* Address */}
                        <div className='mb-6'>
                            <h3 className='text-lg font-semibold text-gray-900 mb-3'>Address</h3>
                            {isEdit ? (
                                <div className='space-y-3'>
                                    <input 
                                        type='text' 
                                        onChange={(e) => setProfileData(prev => ({ ...prev, address: { ...prev.address, line1: e.target.value } }))} 
                                        value={profileData.address?.line1 || ''}
                                        className='w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all bg-white text-sm'
                                        placeholder="Street Address, Locality"
                                    />
                                    <input 
                                        type='text' 
                                        onChange={(e) => setProfileData(prev => ({ ...prev, address: { ...prev.address, line2: e.target.value } }))} 
                                        value={profileData.address?.line2 || ''}
                                        className='w-full px-4 py-3 border border-gray-300 rounded-lg focus:ring-2 focus:ring-blue-500 focus:border-blue-500 outline-none transition-all bg-white text-sm'
                                        placeholder="City, State, Pincode"
                                    />
                                </div>
                            ) : (
                                <div className='px-4 py-3 bg-gray-50 rounded-lg border border-gray-200'>
                                    <p className='text-gray-700 text-sm font-medium'>{profileData.address?.line1 || 'Not provided'}</p>
                                    {profileData.address?.line2 && (
                                        <p className='text-gray-600 text-sm mt-1'>{profileData.address.line2}</p>
                                    )}
                                </div>
                            )}
                        </div>

                        {/* Divider */}
                        <div className='h-px bg-gray-200 mb-6'></div>

                        {/* Availability Status */}
                        <div className='mb-6'>
                            <h3 className='text-lg font-semibold text-gray-900 mb-3'>Availability Status</h3>
                            <div className='grid grid-cols-2 sm:grid-cols-4 gap-3'>
                                {[
                                    { id: 'available', label: 'Available', color: 'bg-green-500', bg: 'bg-green-50', text: 'text-green-700', border: 'border-green-200' },
                                    { id: 'unavailable', label: 'Unavailable', color: 'bg-gray-400', bg: 'bg-gray-50', text: 'text-gray-700', border: 'border-gray-200' },
                                    { id: 'busy', label: 'Busy', color: 'bg-yellow-500', bg: 'bg-yellow-50', text: 'text-yellow-700', border: 'border-yellow-200' },
                                    { id: 'emergency', label: 'Emergency', color: 'bg-red-500', bg: 'bg-red-50', text: 'text-red-700', border: 'border-red-200' }
                                ].map((status) => (
                                    <div 
                                        key={status.id}
                                        onClick={async () => {
                                            const newAvailable = status.id === 'available' || status.id === 'busy'
                                            setProfileData(prev => ({ ...prev, status: status.id, available: newAvailable }))
                                            
                                            // Auto-save status
                                            try {
                                                const formData = new FormData()
                                                formData.append('address', JSON.stringify(profileData.address))
                                                formData.append('fees', profileData.fees)
                                                formData.append('about', profileData.about || '')
                                                formData.append('available', String(newAvailable))
                                                formData.append('status', status.id)
                                                
                                                const { data } = await axios.post(backendUrl + '/api/doctor/update-profile', formData, { 
                                                    headers: { 
                                                        dToken
                                                    } 
                                                })
                                                if (data.success) {
                                                    toast.success(`Status updated to ${status.label}`)
                                                } else {
                                                    toast.error(data.message)
                                                }
                                            } catch (error) {
                                                toast.error(error.message)
                                            }
                                        }}
                                        className={`cursor-pointer p-4 rounded-xl border-2 transition-all flex flex-col items-center gap-2 group ${
                                            (profileData.status === status.id || (!profileData.status && status.id === (profileData.available ? 'available' : 'unavailable')))
                                                ? `${status.bg} ${status.border} border-current ring-2 ring-offset-2 ${status.id === 'available' ? 'ring-green-500' : status.id === 'busy' ? 'ring-yellow-500' : status.id === 'emergency' ? 'ring-red-500' : 'ring-gray-400'}`
                                                : 'bg-white border-gray-100 hover:border-gray-200 hover:bg-gray-50'
                                        }`}
                                    >
                                        <div className={`w-3 h-3 rounded-full ${status.color} shadow-sm group-hover:scale-110 transition-transform`}></div>
                                        <span className={`text-xs font-bold uppercase tracking-wider ${status.text}`}>{status.label}</span>
                                    </div>
                                ))}
                            </div>
                        </div>
                        {/* Save Button */}
                        {isEdit && (
                            <button 
                                onClick={updateProfile}
                                disabled={uploadingImage}
                                className={`w-full px-6 py-3 bg-blue-600 hover:bg-blue-700 text-white font-semibold rounded-lg transition-all shadow-sm hover:shadow-md ${
                                    uploadingImage ? 'opacity-50 cursor-not-allowed' : ''
                                }`}
                            >
                                {uploadingImage ? 'Saving...' : 'Save Changes'}
                            </button>
                        )}
                    </div>
                </div>
            </div>
        </div>
    )
}

export default DoctorProfile
