import React, { useContext, useEffect, useState } from 'react'
import { AdminContext } from '../../context/AdminContext'
import { AppContext } from '../../context/AppContext'
import { toast } from 'react-toastify'
import axios from 'axios'
import { assets } from '../../assets/assets'
import GlassCard from '../../components/ui/GlassCard'
import { useSearchParams } from 'react-router-dom'

const DoctorsList = () => {

  const { doctors, changeAvailability, aToken, getAllDoctors, getDashData } = useContext(AdminContext)
  const { backendUrl } = useContext(AppContext)
  const [searchParams, setSearchParams] = useSearchParams()
  const [showEditModal, setShowEditModal] = useState(false)
  const [editingDoctor, setEditingDoctor] = useState(null)
  const [docImg, setDocImg] = useState(null)
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    speciality: 'General physician',
    degree: '',
    experience: '1 Year',
    fees: '',
    about: '',
    address1: '',
    address2: ''
  })

  // Search & filter state
  const [searchTerm, setSearchTerm] = useState('')
  const [availabilityFilter, setAvailabilityFilter] = useState('all') // all | available | offline
  const [specialityFilter, setSpecialityFilter] = useState('all')

  useEffect(() => {
    if (aToken) {
      getAllDoctors()
    }
  }, [aToken])

  // Read URL parameter on mount and when it changes
  useEffect(() => {
    const filterParam = searchParams.get('filter')
    if (filterParam === 'available') {
      setAvailabilityFilter('available')
    } else {
      // Default view (no param or unknown) should show all doctors
      setAvailabilityFilter('all')
    }
  }, [searchParams])

  const handleEdit = (doctor) => {
    setEditingDoctor(doctor)
    setFormData({
      name: doctor.name || '',
      email: doctor.email || '',
      speciality: doctor.speciality || 'General physician',
      degree: doctor.degree || '',
      experience: doctor.experience || '1 Year',
      fees: doctor.fees?.toString() || '',
      about: doctor.about || '',
      address1: doctor.address?.line1 || '',
      address2: doctor.address?.line2 || ''
    })
    setDocImg(null)
    setShowEditModal(true)
  }

  const handleCloseModal = () => {
    setShowEditModal(false)
    setEditingDoctor(null)
    setDocImg(null)
    setFormData({
      name: '',
      email: '',
      speciality: 'General physician',
      degree: '',
      experience: '1 Year',
      fees: '',
      about: '',
      address1: '',
      address2: ''
    })
  }

  const handleUpdate = async (e) => {
    e.preventDefault()

    try {
      const formDataToSend = new FormData()

      formDataToSend.append('docId', editingDoctor._id)
      formDataToSend.append('name', formData.name)
      formDataToSend.append('email', formData.email)
      formDataToSend.append('speciality', formData.speciality)
      formDataToSend.append('degree', formData.degree)
      formDataToSend.append('experience', formData.experience)
      formDataToSend.append('fees', Number(formData.fees))
      formDataToSend.append('about', formData.about)
      formDataToSend.append('address', JSON.stringify({ line1: formData.address1, line2: formData.address2 }))

      if (docImg) {
        formDataToSend.append('image', docImg)
      }

      const { data } = await axios.post(backendUrl + '/api/admin/update-doctor', formDataToSend, {
        headers: { aToken }
      })

      if (data.success) {
        toast.success(data.message)
        getAllDoctors()
        getDashData()
        handleCloseModal()
      } else {
        toast.error(data.message)
      }
    } catch (error) {
      console.error(error)
      toast.error(error.response?.data?.message || error.message || 'Failed to update doctor')
    }
  }

  const specialties = [
    'General physician', 'Gynecologist', 'Dermatologist', 'Pediatricians',
    'Neurologist', 'Gastroenterologist', 'Cardiologist', 'Orthopedics',
    'Psychiatrist', 'Ophthalmologist', 'ENT', 'Dentist'
  ]

  // Derived list with search + filters applied
  const filteredDoctors = (doctors || []).filter((doc) => {
    const matchesSearch =
      !searchTerm ||
      doc.name?.toLowerCase().includes(searchTerm.toLowerCase()) ||
      doc.speciality?.toLowerCase().includes(searchTerm.toLowerCase())

    const matchesAvailability =
      availabilityFilter === 'all' ||
      (availabilityFilter === 'available' && doc.available) ||
      (availabilityFilter === 'offline' && !doc.available)

    const matchesSpeciality =
      specialityFilter === 'all' || doc.speciality === specialityFilter

    return matchesSearch && matchesAvailability && matchesSpeciality
  })

  return (
    <>
      <div className='w-full bg-gradient-to-br from-gray-50 via-white to-indigo-50/40 p-4 sm:p-6 mobile-safe-area pb-8 min-h-screen'>
        {/* Header + Filters */}
        <div className='max-w-7xl mx-auto'>
          <div className='flex flex-col sm:flex-row sm:items-end sm:justify-between gap-4 mb-6'>
            <div>
              <h1 className='text-2xl sm:text-3xl font-bold text-gray-900 mb-1 flex items-center gap-3'>
                <div className='bg-gradient-to-br from-indigo-500 via-purple-500 to-pink-500 rounded-xl p-2 shadow-lg shadow-indigo-500/30'>
                  <svg className='w-6 h-6 text-white' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M9 5l7 7-7 7" />
                  </svg>
                </div>
                <span className='bg-gradient-to-r from-indigo-600 to-purple-600 bg-clip-text text-transparent'>
                  All Doctors
                </span>
              </h1>
              <p className='text-xs sm:text-sm text-gray-500'>
                Manage doctor availability, edit profiles, and quickly find doctors using search & filters.
              </p>
            </div>

            {/* Search input */}
            <div className='w-full sm:w-72'>
              <div className='relative'>
                <span className='absolute inset-y-0 left-3 flex items-center text-gray-400'>
                  <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M21 21l-4.35-4.35M11 18a7 7 0 100-14 7 7 0 000 14z" />
                  </svg>
                </span>
                <input
                  type="text"
                  value={searchTerm}
                  onChange={(e) => setSearchTerm(e.target.value)}
                  placeholder="Search by name or speciality..."
                  className='w-full pl-9 pr-3 py-2.5 text-sm rounded-xl border-2 border-gray-200 bg-white shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all'
                />
              </div>
            </div>
          </div>

          {/* Filters row */}
          <div className='flex flex-col md:flex-row md:items-center md:justify-between gap-3 mb-6'>
            <div className='flex flex-wrap items-center gap-2 text-xs sm:text-sm'>
              <span className='text-gray-500 font-medium mr-1'>Availability:</span>
              <div className='inline-flex rounded-full bg-gray-100 p-1'>
                <button
                  type="button"
                  onClick={() => setAvailabilityFilter('all')}
                  className={`px-3 py-1.5 rounded-full font-medium transition-colors ${availabilityFilter === 'all'
                    ? 'bg-white text-indigo-600 shadow-sm'
                    : 'text-gray-500 hover:text-gray-800'
                    }`}
                >
                  All
                </button>
                <button
                  type="button"
                  onClick={() => setAvailabilityFilter('available')}
                  className={`px-3 py-1.5 rounded-full font-medium transition-colors flex items-center gap-1 ${availabilityFilter === 'available'
                    ? 'bg-white text-green-600 shadow-sm'
                    : 'text-gray-500 hover:text-gray-800'
                    }`}
                >
                  <span className='w-2 h-2 rounded-full bg-green-500'></span>
                  Available
                </button>
                <button
                  type="button"
                  onClick={() => setAvailabilityFilter('offline')}
                  className={`px-3 py-1.5 rounded-full font-medium transition-colors flex items-center gap-1 ${availabilityFilter === 'offline'
                    ? 'bg-white text-red-600 shadow-sm'
                    : 'text-gray-500 hover:text-gray-800'
                    }`}
                >
                  <span className='w-2 h-2 rounded-full bg-red-500'></span>
                  Unavailable
                </button>
              </div>
            </div>

            <div className='flex flex-wrap gap-3'>
              {/* Speciality filter */}
              <div className='flex items-center gap-2'>
                <span className='text-xs sm:text-sm text-gray-500 font-medium'>Speciality:</span>
                <select
                  value={specialityFilter}
                  onChange={(e) => setSpecialityFilter(e.target.value)}
                  className='text-xs sm:text-sm border-2 border-gray-200 rounded-xl px-3 py-2 bg-white shadow-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none'
                >
                  <option value="all">All Specialities</option>
                  {specialties.map((spec) => (
                    <option key={spec} value={spec}>
                      {spec}
                    </option>
                  ))}
                </select>
              </div>

              {/* Count pill */}
              <div className='px-3 py-1.5 rounded-full bg-white border border-gray-200 text-xs sm:text-sm text-gray-600 shadow-sm'>
                Showing <span className='font-semibold text-indigo-600'>{filteredDoctors.length}</span> of{' '}
                <span className='font-semibold'>{doctors?.length || 0}</span> doctors
              </div>
            </div>
          </div>

          {/* Doctors grid */}
          <div className='w-full grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-4 sm:gap-5'>
            {filteredDoctors.map((item, index) => (
              <div key={index} className='border border-gray-200 rounded-2xl overflow-hidden group bg-white shadow-sm hover:shadow-md transition hover-lift'>
                <div className='relative flex items-center justify-center pt-8 pb-4 bg-gradient-to-b from-gray-50 to-white'>
                  <div className='relative'>
                    <img className='bg-[#EAEFFF] transition-all duration-500 w-32 h-32 sm:w-36 sm:h-36 object-cover rounded-full border-4 border-white shadow-lg' src={item.image} alt={item.name} />
                    <span className={`absolute -top-2 right-0 text-xs px-3 py-1 rounded-full font-semibold shadow-sm ${item.available ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'
                      }`}>
                      {item.available ? 'Available' : 'Unavailable'}
                    </span>
                  </div>
                </div>
                <div className='p-4'>
                  <p className='text-[#262626] text-base font-semibold truncate'>{item.name}</p>
                  <p className='text-[#5C5C5C] text-[11px] mb-1 truncate'>{item.speciality}</p>
                  
                  {item.hospital_name && (
                    <p className='text-indigo-600 text-[10px] font-bold mb-2 truncate flex items-center gap-1'>
                      <svg className='w-3 h-3' fill='none' stroke='currentColor' viewBox='0 0 24 24'>
                        <path strokeLinecap='round' strokeLinejoin='round' strokeWidth={2} d='M19 21V5a2 2 0 00-2-2H7a2 2 0 00-2 2v16m14 0h2m-2 0h-5m-9 0H3m2 0h5M9 7h1m-1 4h1m4-4h1m-1 4h1m-5 10v-5a1 1 0 011-1h2a1 1 0 011 1v5m-4 0h4' />
                      </svg>
                      {item.hospital_name}
                    </p>
                  )}

                  <div className='flex items-center justify-between gap-2 border-t border-gray-100 pt-3'>
                    <label className='flex items-center gap-2 cursor-pointer'>
                      <input onChange={() => changeAvailability(item._id)} type="checkbox" checked={item.available} className='cursor-pointer w-4 h-4' />
                      <span className='text-sm text-gray-700'>Toggle</span>
                    </label>
                    <button
                      onClick={() => handleEdit(item)}
                      className='p-2 text-gray-500 hover:text-blue-600 hover:bg-blue-50 rounded-lg transition-colors'
                      title='Edit Doctor'
                    >
                      <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                        <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                      </svg>
                    </button>
                  </div>
                </div>
              </div>
            ))}
          </div>
        </div>
      </div>

      {/* Edit Doctor Modal */}
      {showEditModal && editingDoctor && (
        <div className='fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4'>
          <div className='bg-white rounded-2xl shadow-2xl w-full max-w-4xl max-h-[90vh] overflow-y-auto relative'>
            {/* Header */}
            <div className='sticky top-0 bg-gradient-to-r from-indigo-500 to-purple-600 px-6 py-4 rounded-t-2xl flex items-center justify-between z-10'>
              <h2 className='text-xl font-bold text-white'>Update Doctor Profile</h2>
              <button
                onClick={handleCloseModal}
                className='text-white/80 hover:text-white transition-colors p-1 rounded-full hover:bg-white/20'
              >
                <svg className='w-6 h-6' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                </svg>
              </button>
            </div>

            {/* Form */}
            <form onSubmit={handleUpdate} className='p-6'>
              <GlassCard className="p-3 sm:p-4">
                <div className='h-0.5 w-full bg-gradient-to-r from-indigo-400 via-fuchsia-400 to-indigo-400 rounded-full mb-3 sm:mb-4 opacity-60'></div>

                {/* Image Upload Section */}
                <div className='flex flex-col sm:flex-row items-center gap-2 sm:gap-3 mb-4 sm:mb-5'>
                  <label htmlFor="doc-img-edit" className='cursor-pointer group flex-shrink-0'>
                    <div className='relative'>
                      <img
                        className='w-16 h-16 sm:w-20 sm:h-20 bg-gray-100 rounded-full object-cover ring-2 ring-indigo-200 group-hover:ring-indigo-400 transition-all shadow-lg'
                        src={docImg ? URL.createObjectURL(docImg) : editingDoctor.image || assets.upload_area}
                        alt="Doctor"
                      />
                      {docImg && (
                        <div className='absolute inset-0 bg-green-500/20 rounded-full flex items-center justify-center'>
                          <svg className='w-5 h-5 sm:w-6 sm:h-6 text-green-600' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5 13l4 4L19 7" />
                          </svg>
                        </div>
                      )}
                    </div>
                  </label>
                  <input
                    onChange={(e) => setDocImg(e.target.files[0])}
                    type="file"
                    name=""
                    id="doc-img-edit"
                    hidden
                    accept="image/*"
                  />
                  <div className='text-center sm:text-left'>
                    <p className='text-sm sm:text-base font-semibold text-gray-700'>Update Doctor Picture</p>
                    <p className='text-[10px] sm:text-xs text-gray-500'>Click to select new image (optional)</p>
                  </div>
                </div>

                {/* Form Grid */}
                <div className='grid grid-cols-1 lg:grid-cols-2 gap-3 sm:gap-4 text-gray-700'>
                  {/* Left Column */}
                  <div className='w-full flex flex-col gap-3'>
                    <div className='flex-1 flex flex-col gap-1.5'>
                      <label className='text-xs font-semibold text-gray-600'>Doctor Name *</label>
                      <input
                        onChange={e => setFormData({ ...formData, name: e.target.value })}
                        value={formData.name}
                        className='border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white/50'
                        type="text"
                        placeholder='Enter full name'
                        required
                      />
                    </div>

                    <div className='flex-1 flex flex-col gap-1.5'>
                      <label className='text-xs font-semibold text-gray-600'>Email Address *</label>
                      <input
                        onChange={e => setFormData({ ...formData, email: e.target.value })}
                        value={formData.email}
                        className='border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white/50'
                        type="email"
                        placeholder='Enter email address'
                        required
                      />
                    </div>

                    <div className='flex-1 flex flex-col gap-2'>
                      <label className='text-sm font-semibold text-gray-600'>Speciality *</label>
                      <select
                        onChange={e => setFormData({ ...formData, speciality: e.target.value })}
                        value={formData.speciality}
                        className='border border-gray-300 rounded-xl px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white/50'
                        required
                      >
                        {specialties.map((spec) => (
                          <option key={spec} value={spec}>{spec}</option>
                        ))}
                      </select>
                    </div>

                    <div className='flex-1 flex flex-col gap-2'>
                      <label className='text-sm font-semibold text-gray-600'>Experience *</label>
                      <select
                        onChange={e => setFormData({ ...formData, experience: e.target.value })}
                        value={formData.experience}
                        className='border border-gray-300 rounded-xl px-4 py-3 focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white/50'
                        required
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
                    </div>
                  </div>

                  {/* Right Column */}
                  <div className='w-full flex flex-col gap-3'>
                    <div className='flex-1 flex flex-col gap-1.5'>
                      <label className='text-xs font-semibold text-gray-600'>Degree/Qualification *</label>
                      <input
                        onChange={e => setFormData({ ...formData, degree: e.target.value })}
                        value={formData.degree}
                        className='border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white/50'
                        type="text"
                        placeholder='e.g., MBBS, MD, MS'
                        required
                      />
                    </div>

                    <div className='flex-1 flex flex-col gap-1.5'>
                      <label className='text-xs font-semibold text-gray-600'>Consultation Fees (₹) *</label>
                      <input
                        onChange={e => setFormData({ ...formData, fees: e.target.value })}
                        value={formData.fees}
                        className='border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white/50'
                        type="number"
                        placeholder='e.g., 500'
                        required
                        min="0"
                      />
                    </div>

                    <div className='flex-1 flex flex-col gap-1.5'>
                      <label className='text-xs font-semibold text-gray-600'>Address Line 1 *</label>
                      <input
                        onChange={e => setFormData({ ...formData, address1: e.target.value })}
                        value={formData.address1}
                        className='border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white/50'
                        type="text"
                        placeholder='Street, Building'
                        required
                      />
                    </div>

                    <div className='flex-1 flex flex-col gap-1.5'>
                      <label className='text-xs font-semibold text-gray-600'>Address Line 2</label>
                      <input
                        onChange={e => setFormData({ ...formData, address2: e.target.value })}
                        value={formData.address2}
                        className='border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white/50'
                        type="text"
                        placeholder='City, State, Pincode'
                      />
                    </div>
                  </div>
                </div>

                {/* About Section */}
                <div className='mt-4 flex flex-col gap-1.5'>
                  <label className='text-xs font-semibold text-gray-600'>About Doctor *</label>
                  <textarea
                    onChange={e => setFormData({ ...formData, about: e.target.value })}
                    value={formData.about}
                    className='border border-gray-300 rounded-lg px-3 py-2 text-sm focus:ring-2 focus:ring-indigo-500 focus:border-indigo-500 outline-none transition-all bg-white/50 min-h-[100px] resize-y'
                    placeholder='Brief description about the doctor...'
                    required
                  />
                </div>

                {/* Action Buttons */}
                <div className='flex items-center justify-end gap-3 mt-6 pt-4 border-t border-gray-200'>
                  <button
                    type="button"
                    onClick={handleCloseModal}
                    className='px-4 py-2 text-gray-700 bg-gray-100 hover:bg-gray-200 rounded-lg font-medium transition-colors'
                  >
                    Cancel
                  </button>
                  <button
                    type="submit"
                    className='px-6 py-2 bg-gradient-to-r from-indigo-500 to-purple-600 text-white rounded-lg font-semibold hover:from-indigo-600 hover:to-purple-700 transition-all shadow-lg hover:shadow-xl'
                  >
                    Update Doctor
                  </button>
                </div>
              </GlassCard>
            </form>
          </div>
        </div>
      )}
    </>
  )
}

export default DoctorsList
