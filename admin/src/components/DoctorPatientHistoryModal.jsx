import React, { useState, useEffect, useContext } from 'react'
import axios from 'axios'
import { toast } from 'react-toastify'
import { DoctorContext } from '../context/DoctorContext'
import PatientReportsViewer from './PatientReportsViewer'

const formatSlotDate = (slotDate) => {
  if (!slotDate) return 'N/A'
  const parts = slotDate.split('_')
  if (parts.length === 3) {
    const [d, m, y] = parts
    return new Date(`${y}-${m}-${d}`).toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    })
  }
  return slotDate
}

const DoctorPatientHistoryModal = ({ isOpen, onClose, appointmentId, userId, patientName }) => {
  const { backendUrl, dToken } = useContext(DoctorContext)
  const [loading, setLoading] = useState(false)
  const [data, setData] = useState(null)
  const [activeTab, setActiveTab] = useState('visits')

  useEffect(() => {
    if (isOpen && (appointmentId || userId)) {
      fetchHistory()
      setActiveTab('visits')
    } else {
      setData(null)
    }
  }, [isOpen, appointmentId, userId])

  const fetchHistory = async () => {
    setLoading(true)
    try {
      const url = appointmentId
        ? `${backendUrl}/api/doctor/appointments/${appointmentId}/patient-history`
        : `${backendUrl}/api/doctor/patients/${userId}/history`
      const { data: res } = await axios.get(url, { headers: { dToken } })
      if (res.success) {
        setData(res)
      } else {
        toast.error(res.message || 'Failed to load patient history')
      }
    } catch (error) {
      console.error('Error fetching patient history:', error)
      toast.error('Failed to load patient history')
    } finally {
      setLoading(false)
    }
  }

  if (!isOpen) return null

  const patient = data?.patient
  const pastVisits = data?.pastVisits || []
  const healthRecords = data?.healthRecords || []
  const currentVisit = data?.currentVisit
  const summary = data?.summary

  return (
    <div className="fixed inset-0 bg-black/50 flex items-center justify-center z-50 p-4">
      <div className="bg-white rounded-xl shadow-2xl max-w-3xl w-full max-h-[90vh] overflow-hidden flex flex-col">
        <div className="bg-gradient-to-r from-slate-800 to-slate-700 text-white px-5 py-4 flex items-center justify-between">
          <div>
            <h2 className="text-lg font-bold">{patientName || patient?.name || 'Patient History'}</h2>
            <p className="text-sm text-white/70 mt-0.5">
              {summary
                ? `${summary.totalPastVisits} past visit${summary.totalPastVisits !== 1 ? 's' : ''} · ${summary.totalHealthRecords} record${summary.totalHealthRecords !== 1 ? 's' : ''}`
                : 'Past visits, prescriptions & records'}
            </p>
          </div>
          <button
            onClick={onClose}
            className="text-white/70 hover:text-white p-1.5 rounded-lg hover:bg-white/10"
            aria-label="Close"
          >
            <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
              <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
            </svg>
          </button>
        </div>

        {currentVisit && (
          <div className="px-5 py-3 bg-blue-50 border-b border-blue-100 text-sm">
            <span className="font-semibold text-blue-900">Today's visit: </span>
            <span className="text-blue-800">
              {formatSlotDate(currentVisit.slotDate)} at {currentVisit.slotTime || '—'}
              {currentVisit.tokenNumber ? ` · Token #${currentVisit.tokenNumber}` : ''}
            </span>
            {currentVisit.symptoms?.length > 0 && (
              <div className="flex flex-wrap gap-1 mt-2">
                {currentVisit.symptoms.filter((s) => !String(s).startsWith('Note:')).map((s, i) => (
                  <span key={i} className="px-2 py-0.5 bg-white text-blue-700 rounded text-xs border border-blue-200">
                    {s}
                  </span>
                ))}
              </div>
            )}
          </div>
        )}

        <div className="border-b border-gray-200 flex overflow-x-auto">
          {[
            { id: 'profile', label: 'Profile' },
            { id: 'visits', label: `Past Visits (${pastVisits.length})` },
            { id: 'records', label: `Medical Records (${healthRecords.length})` },
            { id: 'reports', label: 'Uploaded Reports' },
          ].map((tab) => (
            <button
              key={tab.id}
              onClick={() => setActiveTab(tab.id)}
              className={`px-4 py-3 text-sm font-medium whitespace-nowrap transition-colors ${
                activeTab === tab.id
                  ? 'text-blue-600 border-b-2 border-blue-600'
                  : 'text-gray-600 hover:text-gray-900'
              }`}
            >
              {tab.label}
            </button>
          ))}
        </div>

        <div className="flex-1 overflow-y-auto p-5">
          {loading ? (
            <div className="flex items-center justify-center py-16">
              <div className="animate-spin rounded-full h-10 w-10 border-b-2 border-blue-600" />
            </div>
          ) : (
            <>
              {activeTab === 'profile' && patient && (
                <div className="space-y-4">
                  <div className="flex items-start gap-4">
                    {patient.image && (
                      <img
                        src={patient.image}
                        alt={patient.name}
                        className="w-20 h-20 rounded-full border-2 border-gray-200 object-cover"
                      />
                    )}
                    <div className="grid grid-cols-2 gap-3 flex-1">
                      <div>
                        <p className="text-xs text-gray-500">Name</p>
                        <p className="text-sm font-semibold">{patient.name}</p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500">Phone</p>
                        <p className="text-sm font-semibold">{patient.phone || 'N/A'}</p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500">Gender</p>
                        <p className="text-sm font-semibold">{patient.gender || 'N/A'}</p>
                      </div>
                      <div>
                        <p className="text-xs text-gray-500">Age</p>
                        <p className="text-sm font-semibold">
                          {patient.age || (patient.dob ? new Date().getFullYear() - new Date(patient.dob).getFullYear() : 'N/A')}
                        </p>
                      </div>
                      {patient.bloodGroup && (
                        <div>
                          <p className="text-xs text-gray-500">Blood Group</p>
                          <p className="text-sm font-semibold">{patient.bloodGroup}</p>
                        </div>
                      )}
                      {patient.relationship && patient.relationship !== 'Self' && (
                        <div>
                          <p className="text-xs text-gray-500">Relationship</p>
                          <p className="text-sm font-semibold">{patient.relationship}</p>
                        </div>
                      )}
                    </div>
                  </div>
                  {patient.completedVisits > 0 && (
                    <p className="text-sm text-gray-600">
                      Total completed visits on platform: <strong>{patient.completedVisits}</strong>
                    </p>
                  )}
                </div>
              )}

              {activeTab === 'visits' && (
                <div className="space-y-4">
                  {pastVisits.length === 0 ? (
                    <div className="text-center py-12 text-gray-500">
                      <p className="font-medium">No past visits with you</p>
                      <p className="text-sm mt-1">This may be the patient's first consultation.</p>
                    </div>
                  ) : (
                    pastVisits.map((visit) => (
                      <div key={visit.appointmentId} className="border border-gray-200 rounded-lg p-4">
                        <div className="flex items-center justify-between mb-3">
                          <div>
                            <p className="font-semibold text-gray-900">
                              {formatSlotDate(visit.slotDate)} · {visit.slotTime || '—'}
                            </p>
                            {visit.tokenNumber && (
                              <p className="text-xs text-gray-500 mt-0.5">Token #{visit.tokenNumber}</p>
                            )}
                          </div>
                          <span className={`px-2 py-1 rounded text-xs font-medium ${
                            visit.isCompleted ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'
                          }`}>
                            {visit.isCompleted ? 'Completed' : 'Past'}
                          </span>
                        </div>

                        {visit.symptoms?.length > 0 && (
                          <div className="mb-3">
                            <p className="text-xs text-gray-500 mb-1">Symptoms reported</p>
                            <div className="flex flex-wrap gap-1">
                              {visit.symptoms.filter((s) => !String(s).startsWith('Note:')).map((s, i) => (
                                <span key={i} className="px-2 py-0.5 bg-gray-100 text-gray-700 rounded text-xs">{s}</span>
                              ))}
                            </div>
                          </div>
                        )}

                        {visit.diagnosis && (
                          <div className="mb-2">
                            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Diagnosis</p>
                            <p className="text-sm text-gray-800 mt-0.5 whitespace-pre-wrap">{visit.diagnosis}</p>
                          </div>
                        )}

                        {visit.prescription && (
                          <div className="mb-2 p-3 bg-emerald-50 border border-emerald-100 rounded-lg">
                            <p className="text-xs font-semibold text-emerald-700 uppercase tracking-wide mb-1">Prescription Given</p>
                            <p className="text-sm text-gray-800 whitespace-pre-wrap">{visit.prescription}</p>
                          </div>
                        )}

                        {visit.advice && (
                          <div className="mb-2">
                            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Advice</p>
                            <p className="text-sm text-gray-700 mt-0.5 whitespace-pre-wrap">{visit.advice}</p>
                          </div>
                        )}

                        {visit.notes && (
                          <div className="mb-2">
                            <p className="text-xs font-semibold text-gray-500 uppercase tracking-wide">Notes</p>
                            <p className="text-sm text-gray-600 mt-0.5 whitespace-pre-wrap">{visit.notes}</p>
                          </div>
                        )}

                        {visit.followupDate && (
                          <p className="text-xs text-blue-600 mt-2">Follow-up: {visit.followupDate}</p>
                        )}

                        {!visit.diagnosis && !visit.prescription && !visit.notes && !visit.advice && (
                          <p className="text-sm text-gray-400 italic">No clinical notes recorded for this visit.</p>
                        )}
                      </div>
                    ))
                  )}
                </div>
              )}

              {activeTab === 'records' && (
                <div className="space-y-3">
                  {healthRecords.length === 0 ? (
                    <div className="text-center py-12 text-gray-500">
                      <p>No medical records on file</p>
                    </div>
                  ) : (
                    healthRecords.map((record) => (
                      <div key={record._id} className="border border-gray-200 rounded-lg p-4">
                        <div className="flex items-start justify-between">
                          <div>
                            <h4 className="font-semibold text-gray-900">{record.title}</h4>
                            <p className="text-xs text-gray-500 mt-0.5">
                              {record.date ? new Date(record.date).toLocaleDateString() : ''} · {record.recordType?.replace('_', ' ')}
                            </p>
                          </div>
                          {record.recordType === 'prescription' && (
                            <span className="px-2 py-0.5 bg-emerald-100 text-emerald-700 rounded text-xs font-medium">Rx</span>
                          )}
                        </div>
                        {record.description && (
                          <p className="text-sm text-gray-700 mt-2 whitespace-pre-wrap">{record.description}</p>
                        )}
                        {record.doctorName && (
                          <p className="text-xs text-gray-500 mt-2">By: {record.doctorName}</p>
                        )}
                        {record.files?.length > 0 && (
                          <div className="flex flex-wrap gap-2 mt-2">
                            {record.files.map((file, i) => (
                              <a
                                key={i}
                                href={file.url}
                                target="_blank"
                                rel="noopener noreferrer"
                                className="text-xs text-blue-600 hover:underline"
                              >
                                {file.fileName}
                              </a>
                            ))}
                          </div>
                        )}
                      </div>
                    ))
                  )}
                </div>
              )}

              {activeTab === 'reports' && appointmentId && (
                <PatientReportsViewer
                  appointmentId={appointmentId}
                  patientName={patientName || patient?.name}
                />
              )}
            </>
          )}
        </div>

        <div className="px-5 py-3 border-t border-gray-100 bg-gray-50">
          <button
            onClick={onClose}
            className="w-full px-4 py-2.5 bg-slate-800 hover:bg-slate-900 text-white font-medium rounded-lg text-sm transition-colors"
          >
            Close
          </button>
        </div>
      </div>
    </div>
  )
}

export default DoctorPatientHistoryModal
