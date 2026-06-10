import React, { useContext, useEffect, useState } from 'react'
import { DeanContext } from '../../context/DeanContext'
import { toast } from 'react-toastify'
import GlassCard from '../../components/ui/GlassCard'

const DeanHospital = () => {
  const { deanToken, hospital, getHospital, updateHospital } = useContext(DeanContext)
  const [editing, setEditing] = useState(false)
  const [form, setForm] = useState({})
  const [saving, setSaving] = useState(false)

  useEffect(() => {
    if (deanToken) getHospital()
  }, [deanToken])

  useEffect(() => {
    if (hospital) setForm({ name: hospital.name || '', address: hospital.address || '', contact: hospital.contact || '', specialization: hospital.specialization || '' })
  }, [hospital])

  const handleSave = async () => {
    setSaving(true)
    const ok = await updateHospital(form)
    if (ok) setEditing(false)
    setSaving(false)
  }

  if (!hospital) return (
    <div className='flex items-center justify-center min-h-[60vh]'>
      <div className='animate-spin rounded-full h-10 w-10 border-b-2 border-emerald-600' />
    </div>
  )

  const field = (label, key, placeholder = '') => (
    <div>
      <label className='block text-xs font-bold uppercase tracking-widest text-emerald-700 mb-1.5'>{label}</label>
      {editing ? (
        <input value={form[key] || ''} onChange={e => setForm(f => ({ ...f, [key]: e.target.value }))}
          placeholder={placeholder}
          className='w-full px-4 py-2.5 border-2 border-gray-100 focus:border-emerald-500 focus:ring-4 focus:ring-emerald-500/10 outline-none rounded-xl text-sm transition-all' />
      ) : (
        <p className='text-gray-800 text-sm font-medium py-2'>{hospital[key] || '—'}</p>
      )}
    </div>
  )

  return (
    <div className='w-full bg-gradient-to-br from-gray-50 to-white p-4 sm:p-6 min-h-screen'>
      <div className='max-w-2xl mx-auto space-y-4'>
        {/* Header */}
        <div className='flex items-center justify-between'>
          <div>
            <h1 className='text-2xl font-bold text-gray-900'>Hospital Tie ups</h1>
            <p className='text-sm text-gray-500'>Manage your hospital's information</p>
          </div>
          {!editing ? (
            <button onClick={() => setEditing(true)}
              className='px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-sm font-semibold rounded-xl shadow transition-all'>
              ✏️ Edit
            </button>
          ) : (
            <div className='flex gap-2'>
              <button onClick={() => setEditing(false)}
                className='px-4 py-2 bg-gray-200 hover:bg-gray-300 text-gray-700 text-sm font-semibold rounded-xl transition-all'>
                Cancel
              </button>
              <button onClick={handleSave} disabled={saving}
                className='px-4 py-2 bg-emerald-600 hover:bg-emerald-700 text-white text-sm font-semibold rounded-xl shadow transition-all disabled:opacity-50'>
                {saving ? 'Saving…' : 'Save Changes'}
              </button>
            </div>
          )}
        </div>

        {/* Hospital Hero */}
        <div className='bg-gradient-to-r from-emerald-600 to-teal-600 rounded-2xl p-5 text-white shadow-lg'>
          <div className='flex items-center gap-4'>
            <div className='w-14 h-14 bg-white/20 backdrop-blur rounded-xl flex items-center justify-center text-2xl'>🏥</div>
            <div>
              <p className='text-xs font-semibold uppercase tracking-widest text-emerald-100'>Hospital Account</p>
              <h2 className='text-xl font-bold'>{hospital.name}</h2>
              <p className='text-sm text-emerald-100'>{hospital.specialization}</p>
            </div>
          </div>
        </div>

        {/* Form Card */}
        <GlassCard className='p-6'>
          <div className='space-y-5'>
            {field('Hospital Name', 'name', 'Enter hospital name')}
            {field('Address', 'address', 'Full address')}
            {field('Contact Number', 'contact', 'Phone number')}
            {field('Specialization', 'specialization', 'E.g. Cardiology, General Medicine')}

            {/* Read-only info */}
            <div className='pt-2 border-t border-gray-100'>
              <p className='text-xs text-gray-400'>Hospital Type: <span className='font-medium text-gray-600'>{hospital.type}</span></p>
              <p className='text-xs text-gray-400 mt-1'>Hospital ID: <span className='font-medium text-gray-600'>{hospital.id}</span></p>
            </div>
          </div>
        </GlassCard>
      </div>
    </div>
  )
}

export default DeanHospital
