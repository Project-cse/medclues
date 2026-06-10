import React, { useState, useEffect, useContext } from 'react';
import { DoctorContext } from '../context/DoctorContext';
import { AppContext } from '../context/AppContext';
import PatientReportsViewer from './PatientReportsViewer';
import axios from 'axios';

const AppointmentDetailModal = ({ appointment, onClose }) => {
    const { slotDateFormat, calculateAge, currency } = useContext(AppContext);
    const [showReports, setShowReports] = useState(false);

    if (!appointment) return null;

    return (
        <div 
            className="fixed inset-0 bg-black/50 backdrop-blur-sm z-50 flex items-center justify-center p-4"
            onClick={onClose}
        >
            <div 
                className="bg-white rounded-xl shadow-2xl max-w-2xl w-full relative animate-scale-in"
                onClick={(e) => e.stopPropagation()}
                style={{ 
                    maxHeight: '90vh',
                    margin: 'auto'
                }}
            >
                <div className="p-4 sm:p-6 overflow-y-auto" style={{ maxHeight: '90vh' }}>
                    {/* Header */}
                    <div className="flex justify-between items-start mb-4">
                        <div>
                            <h2 className="text-xl sm:text-2xl font-bold text-gray-900">Appointment Details</h2>
                            <p className="text-xs sm:text-sm text-gray-600 mt-0.5">
                                {slotDateFormat(appointment.slotDate)} at {appointment.slotTime}
                            </p>
                        </div>
                        <button
                            onClick={onClose}
                            className="text-gray-500 hover:text-gray-700 p-1 rounded-lg hover:bg-gray-100 transition-colors"
                        >
                            <svg className="w-5 h-5 sm:w-6 sm:h-6" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M6 18L18 6M6 6l12 12" />
                            </svg>
                        </button>
                    </div>

                    {/* Patient Info */}
                    <div className="bg-gray-50 rounded-lg p-3 sm:p-4 mb-4">
                        <div className="flex items-center gap-3">
                            <img 
                                src={appointment.userData.image} 
                                className="w-12 h-12 sm:w-14 sm:h-14 rounded-full object-cover ring-2 ring-blue-200" 
                                alt={appointment.userData.name} 
                            />
                            <div>
                                <h3 className="text-base sm:text-lg font-semibold text-gray-900">{appointment.userData.name}</h3>
                                <p className="text-xs sm:text-sm text-gray-600">
                                    Age: {calculateAge(appointment.userData.dob)} • {appointment.userData.gender}
                                </p>
                                {appointment.userData.phone && (
                                    <p className="text-xs sm:text-sm text-gray-600">Phone: {appointment.userData.phone}</p>
                                )}
                            </div>
                        </div>
                    </div>

                    {/* Appointment Info */}
                    <div className="grid grid-cols-2 gap-3 mb-4">
                        <div className="bg-white border border-gray-200 rounded-lg p-3">
                            <p className="text-[10px] text-gray-500 uppercase mb-1 font-medium">Token Number</p>
                            <p className="text-base sm:text-lg font-semibold text-gray-900">
                                {appointment.tokenNumber ? `#${appointment.tokenNumber}` : 'N/A'}
                            </p>
                        </div>
                        <div className="bg-white border border-gray-200 rounded-lg p-3">
                            <p className="text-[10px] text-gray-500 uppercase mb-1 font-medium">Payment</p>
                            <p className="text-base sm:text-lg font-semibold text-gray-900">
                                {appointment.payment ? 'Paid Online' : 'Cash'}
                            </p>
                        </div>
                        <div className="bg-white border border-gray-200 rounded-lg p-3">
                            <p className="text-[10px] text-gray-500 uppercase mb-1 font-medium">Status</p>
                            <p className={`text-base sm:text-lg font-semibold ${
                                appointment.isCompleted ? 'text-green-600' :
                                appointment.cancelled ? 'text-red-600' :
                                'text-yellow-600'
                            }`}>
                                {appointment.isCompleted ? 'Completed' :
                                 appointment.cancelled ? 'Cancelled' :
                                 appointment.status || 'Pending'}
                            </p>
                        </div>
                        <div className="bg-white border border-gray-200 rounded-lg p-3">
                            <p className="text-[10px] text-gray-500 uppercase mb-1 font-medium">Fee</p>
                            <p className="text-base sm:text-lg font-semibold text-gray-900">
                                {currency}{appointment.amount}
                            </p>
                        </div>
                    </div>

                    {/* Patient Reports Section */}
                    <div className="mb-4">
                        <button
                            onClick={() => setShowReports(!showReports)}
                            className="w-full flex items-center justify-between p-3 bg-cyan-50 hover:bg-cyan-100 rounded-lg border border-cyan-200 transition-colors"
                        >
                            <div className="flex items-center gap-2.5">
                                <svg className="w-5 h-5 text-cyan-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9 12h6m-6 4h6m2 5H7a2 2 0 01-2-2V5a2 2 0 012-2h5.586a1 1 0 01.707.293l5.414 5.414a1 1 0 01.293.707V19a2 2 0 01-2 2z" />
                                </svg>
                                <span className="font-semibold text-sm text-gray-900">View Patient Reports</span>
                            </div>
                            <svg 
                                className={`w-4 h-4 text-gray-600 transition-transform ${showReports ? 'rotate-180' : ''}`}
                                fill="none" 
                                stroke="currentColor" 
                                viewBox="0 0 24 24"
                            >
                                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 9l-7 7-7-7" />
                            </svg>
                        </button>
                        
                        {showReports && (
                            <div className="mt-4">
                                <PatientReportsViewer 
                                    appointmentId={appointment._id}
                                    patientName={appointment.userData.name}
                                />
                            </div>
                        )}
                    </div>

                    {/* Actions */}
                    <div className="flex gap-3 pt-4 border-t border-gray-200">
                        <button
                            onClick={onClose}
                            className="flex-1 px-4 py-2.5 bg-gray-100 hover:bg-gray-200 text-gray-700 font-medium rounded-lg transition-colors"
                        >
                            Close
                        </button>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default AppointmentDetailModal;

