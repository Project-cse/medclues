import React, { useState, useEffect } from 'react'
import axios from 'axios'
import { toast } from 'react-toastify'
import GlassCard from '../../components/ui/GlassCard'

const SpecialtyHelpline = () => {
  const [specialties, setSpecialties] = useState([])
  const [loading, setLoading] = useState(true)
  const [showModal, setShowModal] = useState(false)
  const [editingSpecialty, setEditingSpecialty] = useState(null)
  const [formData, setFormData] = useState({
    specialtyName: '',
    helplineNumber: '',
    availability: '24x7',
    status: 'Active'
  })

  const backendUrl = import.meta.env.VITE_BACKEND_URL || 'http://localhost:4000'
  const aToken = sessionStorage.getItem('aToken')

  useEffect(() => {
    fetchSpecialties()
  }, [])

  const fetchSpecialties = async () => {
    try {
      setLoading(true)
      const response = await axios.get(`${backendUrl}/api/specialty/all`, {
        headers: { atoken: aToken }
      })
      if (response.data.success) {
        setSpecialties(response.data.data)

        // If no specialties exist, seed default ones
        if (response.data.data.length === 0) {
          await seedDefaultSpecialties()
        }
      } else {
        toast.error(response.data.message || 'Failed to fetch specialties')
      }
    } catch (error) {
      toast.error('Error fetching specialties')
      console.error(error)
    } finally {
      setLoading(false)
    }
  }

  const generateRandomHelpline = () => {
    // Generate random toll-free number in format 1800-XXX-XXXX
    const part1 = Math.floor(Math.random() * 900) + 100 // 100-999
    const part2 = Math.floor(Math.random() * 9000) + 1000 // 1000-9999
    return `1800-${part1}-${part2}`
  }

  const seedDefaultSpecialties = async () => {
    const defaultSpecialties = [
      { specialtyName: 'General physician', helplineNumber: generateRandomHelpline(), availability: '24x7' },
      { specialtyName: 'Gynecologist', helplineNumber: generateRandomHelpline(), availability: '24x7' },
      { specialtyName: 'Dermatologist', helplineNumber: generateRandomHelpline(), availability: 'Working Hours' },
      { specialtyName: 'Pediatricians', helplineNumber: generateRandomHelpline(), availability: '24x7' },
      { specialtyName: 'Neurologist', helplineNumber: generateRandomHelpline(), availability: 'Working Hours' },
      { specialtyName: 'Gastroenterologist', helplineNumber: generateRandomHelpline(), availability: 'Working Hours' }
    ]

    try {
      const createPromises = defaultSpecialties.map(specialty =>
        axios.post(
          `${backendUrl}/api/specialty/create`,
          { ...specialty, status: 'Active' },
          { headers: { atoken: aToken } }
        ).catch(err => {
          // Ignore errors for duplicates
          if (err.response?.data?.message?.includes('already exists')) {
            return null
          }
          throw err
        })
      )

      await Promise.all(createPromises)
      toast.success('Default specialty helplines initialized with random numbers')
      fetchSpecialties() // Refresh the list
    } catch (error) {
      console.error('Error seeding default specialties:', error)
      toast.error('Error initializing default specialties')
    }
  }

  const handleSubmit = async (e) => {
    e.preventDefault()

    // Validate phone number
    const phoneRegex = /^[\d\s\-\+\(\)]+$/
    if (!phoneRegex.test(formData.helplineNumber)) {
      toast.error('Invalid phone number format')
      return
    }

    try {
      if (editingSpecialty) {
        // Update existing
        const response = await axios.put(
          `${backendUrl}/api/specialty/update/${editingSpecialty._id}`,
          formData,
          { headers: { atoken: aToken } }
        )
        if (response.data.success) {
          toast.success('Specialty helpline updated successfully')
          setShowModal(false)
          resetForm()
          fetchSpecialties()
        } else {
          toast.error(response.data.message || 'Update failed')
        }
      } else {
        // Create new
        const response = await axios.post(
          `${backendUrl}/api/specialty/create`,
          formData,
          { headers: { atoken: aToken } }
        )
        if (response.data.success) {
          toast.success('Specialty helpline created successfully')
          setShowModal(false)
          resetForm()
          fetchSpecialties()
        } else {
          toast.error(response.data.message || 'Creation failed')
        }
      }
    } catch (error) {
      toast.error('Error saving specialty helpline')
      console.error(error)
    }
  }

  const handleEdit = (specialty) => {
    setEditingSpecialty(specialty)
    setFormData({
      specialtyName: specialty.specialtyName,
      helplineNumber: specialty.helplineNumber,
      availability: specialty.availability,
      status: specialty.status
    })
    setShowModal(true)
  }

  const handleDelete = async (id) => {
    if (!window.confirm('Are you sure you want to delete this specialty helpline?')) {
      return
    }

    try {
      const response = await axios.delete(
        `${backendUrl}/api/specialty/delete/${id}`,
        { headers: { atoken: aToken } }
      )
      if (response.data.success) {
        toast.success('Specialty helpline deleted successfully')
        fetchSpecialties()
      } else {
        toast.error(response.data.message || 'Delete failed')
      }
    } catch (error) {
      toast.error('Error deleting specialty helpline')
      console.error(error)
    }
  }

  const resetForm = () => {
    setFormData({
      specialtyName: '',
      helplineNumber: '',
      availability: '24x7',
      status: 'Active'
    })
    setEditingSpecialty(null)
  }

  const handleModalClose = () => {
    setShowModal(false)
    resetForm()
  }

  return (
    <div className='p-4 sm:p-6 lg:p-8 mobile-safe-area pb-6'>
      {/* Page Header */}
      <div className='mb-6'>
        <h1 className='text-2xl sm:text-3xl font-semibold text-gray-800 mb-2'>
          Specialty Helpline Management
        </h1>
        <p className='text-sm text-gray-600'>
          Manage toll-free and helpline numbers for each medical specialty
        </p>
      </div>

      {/* Action Buttons */}
      <div className='mb-6 flex flex-col sm:flex-row gap-3'>
        <button
          onClick={() => {
            resetForm()
            setShowModal(true)
          }}
          className='px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors text-sm font-medium flex items-center gap-2'
        >
          <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 4v16m8-8H4" />
          </svg>
          Add New Specialty Helpline
        </button>
        {specialties.length === 0 && (
          <button
            onClick={seedDefaultSpecialties}
            className='px-4 py-2 bg-green-600 text-white rounded-md hover:bg-green-700 transition-colors text-sm font-medium flex items-center gap-2'
          >
            <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15" />
            </svg>
            Initialize Default Specialties
          </button>
        )}
      </div>

      {/* Specialties Table */}
      {loading ? (
        <div className='text-center py-12'>
          <p className='text-gray-500'>Loading...</p>
        </div>
      ) : specialties.length === 0 ? (
        <GlassCard className='p-8 text-center'>
          <p className='text-gray-500'>No specialty helplines found. Add one to get started.</p>
        </GlassCard>
      ) : (
        <>
          {/* Desktop Table */}
          <GlassCard className='hidden lg:block overflow-x-auto'>
            <table className='w-full'>
              <thead>
                <tr className='border-b border-gray-200'>
                  <th className='text-left py-3 px-4 font-semibold text-gray-700 text-sm'>Specialty</th>
                  <th className='text-left py-3 px-4 font-semibold text-gray-700 text-sm'>Helpline Number</th>
                  <th className='text-center py-3 px-4 font-semibold text-gray-700 text-sm'>Availability</th>
                  <th className='text-center py-3 px-4 font-semibold text-gray-700 text-sm'>Status</th>
                  <th className='text-center py-3 px-4 font-semibold text-gray-700 text-sm'>Last Updated</th>
                  <th className='text-center py-3 px-4 font-semibold text-gray-700 text-sm'>Actions</th>
                </tr>
              </thead>
              <tbody>
                {specialties.map((specialty) => (
                  <tr key={specialty._id} className='border-b border-gray-100 hover:bg-gray-50'>
                    <td className='py-3 px-4 text-sm text-gray-800 font-medium'>{specialty.specialtyName}</td>
                    <td className='py-3 px-4 text-sm text-gray-700'>
                      <a
                        href={`tel:${specialty.helplineNumber.replace(/\s/g, '')}`}
                        className='text-blue-600 hover:text-blue-700 flex items-center gap-1'
                      >
                        <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                        </svg>
                        {specialty.helplineNumber}
                      </a>
                    </td>
                    <td className='py-3 px-4 text-sm text-gray-600 text-center'>{specialty.availability}</td>
                    <td className='py-3 px-4 text-center'>
                      <span className={`inline-flex items-center px-2.5 py-0.5 rounded-full text-xs font-medium ${specialty.status === 'Active'
                          ? 'bg-green-100 text-green-800'
                          : 'bg-gray-100 text-gray-800'
                        }`}>
                        {specialty.status}
                      </span>
                    </td>
                    <td className='py-3 px-4 text-sm text-gray-500 text-center'>
                      {new Date(specialty.lastUpdated).toLocaleDateString()}
                    </td>
                    <td className='py-3 px-4 text-center'>
                      <div className='flex items-center justify-center gap-2'>
                        <button
                          onClick={() => handleEdit(specialty)}
                          className='p-1.5 text-blue-600 hover:bg-blue-50 rounded transition-colors'
                          title='Edit'
                        >
                          <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                          </svg>
                        </button>
                        <button
                          onClick={() => handleDelete(specialty._id)}
                          className='p-1.5 text-red-600 hover:bg-red-50 rounded transition-colors'
                          title='Delete'
                        >
                          <svg className='w-4 h-4' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                          </svg>
                        </button>
                      </div>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          </GlassCard>

          {/* Mobile Cards */}
          <div className='lg:hidden space-y-4 sm:space-y-5'>
            {specialties.map((specialty) => (
              <GlassCard key={specialty._id} className='p-5 sm:p-6'>
                <div className='space-y-4'>
                  <div className='flex items-start justify-between'>
                    <div className='flex-1'>
                      <h3 className='font-semibold text-gray-800 text-lg sm:text-xl mb-2'>{specialty.specialtyName}</h3>
                      <a
                        href={`tel:${specialty.helplineNumber.replace(/\s/g, '')}`}
                        className='text-blue-600 hover:text-blue-700 flex items-center gap-2.5 text-sm sm:text-base font-medium mt-2'
                      >
                        <svg className='w-5 h-5 sm:w-6 sm:h-6' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M3 5a2 2 0 012-2h3.28a1 1 0 01.948.684l1.498 4.493a1 1 0 01-.502 1.21l-2.257 1.13a11.042 11.042 0 005.516 5.516l1.13-2.257a1 1 0 011.21-.502l4.493 1.498a1 1 0 01.684.949V19a2 2 0 01-2 2h-1C9.716 21 3 14.284 3 6V5z" />
                        </svg>
                        {specialty.helplineNumber}
                      </a>
                    </div>
                    <span className={`inline-flex items-center px-3 sm:px-4 py-1.5 rounded-full text-xs sm:text-sm font-medium ${specialty.status === 'Active'
                        ? 'bg-green-100 text-green-700'
                        : 'bg-gray-100 text-gray-700'
                      }`}>
                      {specialty.status}
                    </span>
                  </div>

                  <div className='flex items-center justify-between pt-3 border-t border-gray-200'>
                    <div className='text-xs text-gray-500'>
                      <p>Availability: {specialty.availability}</p>
                      <p className='mt-1'>Updated: {new Date(specialty.lastUpdated).toLocaleDateString()}</p>
                    </div>
                    <div className='flex items-center gap-2'>
                      <button
                        onClick={() => handleEdit(specialty)}
                        className='p-2 text-blue-600 hover:bg-blue-50 rounded-lg transition-colors'
                        title='Edit'
                      >
                        <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M11 5H6a2 2 0 00-2 2v11a2 2 0 002 2h11a2 2 0 002-2v-5m-1.414-9.414a2 2 0 112.828 2.828L11.828 15H9v-2.828l8.586-8.586z" />
                        </svg>
                      </button>
                      <button
                        onClick={() => handleDelete(specialty._id)}
                        className='p-2 text-red-600 hover:bg-red-50 rounded-lg transition-colors'
                        title='Delete'
                      >
                        <svg className='w-5 h-5' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                          <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 7l-.867 12.142A2 2 0 0116.138 21H7.862a2 2 0 01-1.995-1.858L5 7m5 4v6m4-6v6m1-10V4a1 1 0 00-1-1h-4a1 1 0 00-1 1v3M4 7h16" />
                        </svg>
                      </button>
                    </div>
                  </div>
                </div>
              </GlassCard>
            ))}
          </div>
        </>
      )}

      {/* Add/Edit Modal */}
      {showModal && (
        <div
          className='fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4'
          onClick={handleModalClose}
        >
          <div
            className='bg-white rounded-xl shadow-2xl w-full max-w-md'
            onClick={(e) => e.stopPropagation()}
          >
            <div className='p-6'>
              <h2 className='text-xl font-semibold text-gray-800 mb-4'>
                {editingSpecialty ? 'Edit Specialty Helpline' : 'Add New Specialty Helpline'}
              </h2>

              <form onSubmit={handleSubmit} className='space-y-4'>
                <div>
                  <label className='block text-sm font-medium text-gray-700 mb-1'>
                    Specialty Name *
                  </label>
                  <input
                    type='text'
                    value={formData.specialtyName}
                    onChange={(e) => setFormData({ ...formData, specialtyName: e.target.value })}
                    className='w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500'
                    required
                    disabled={!!editingSpecialty}
                  />
                </div>

                <div>
                  <label className='block text-sm font-medium text-gray-700 mb-1'>
                    Helpline Number *
                  </label>
                  <input
                    type='text'
                    value={formData.helplineNumber}
                    onChange={(e) => setFormData({ ...formData, helplineNumber: e.target.value })}
                    className='w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500'
                    placeholder='e.g., 1800-123-456'
                    required
                  />
                </div>

                <div>
                  <label className='block text-sm font-medium text-gray-700 mb-1'>
                    Availability
                  </label>
                  <select
                    value={formData.availability}
                    onChange={(e) => setFormData({ ...formData, availability: e.target.value })}
                    className='w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500'
                  >
                    <option value='24x7'>24x7</option>
                    <option value='Working Hours'>Working Hours</option>
                  </select>
                </div>

                <div>
                  <label className='block text-sm font-medium text-gray-700 mb-1'>
                    Status
                  </label>
                  <select
                    value={formData.status}
                    onChange={(e) => setFormData({ ...formData, status: e.target.value })}
                    className='w-full px-3 py-2 border border-gray-300 rounded-md focus:outline-none focus:ring-2 focus:ring-blue-500'
                  >
                    <option value='Active'>Active</option>
                    <option value='Inactive'>Inactive</option>
                  </select>
                </div>

                <div className='flex gap-3 pt-4'>
                  <button
                    type='button'
                    onClick={handleModalClose}
                    className='flex-1 px-4 py-2 border border-gray-300 text-gray-700 rounded-md hover:bg-gray-50 transition-colors'
                  >
                    Cancel
                  </button>
                  <button
                    type='submit'
                    className='flex-1 px-4 py-2 bg-blue-600 text-white rounded-md hover:bg-blue-700 transition-colors'
                  >
                    {editingSpecialty ? 'Update' : 'Create'}
                  </button>
                </div>
              </form>
            </div>
          </div>
        </div>
      )}
    </div>
  )
}

export default SpecialtyHelpline

