import { createContext, useCallback, useContext, useEffect, useMemo, useRef, useState } from "react";
import { toast } from "react-toastify";
import axios from 'axios'
import {
    clearPatientSession,
    isPatientAuthFailure,
    setupPatientAuthInterceptor,
    TOKEN_KEY,
} from '../utils/patientAuth'

export const AppContext = createContext()

// Convenience hook for accessing AppContext
export const useAppContext = () => useContext(AppContext)

const DOCTORS_STALE_MS = 5 * 60 * 1000
const HOSPITALS_STALE_MS = 5 * 60 * 1000

const AppContextProvider = (props) => {

    const currencySymbol = '₹'
    // Dynamically determine backend URL based on current host
    const getBackendUrl = () => {
        // PRIORITY 1: Always check environment variable first (for production deployments)
        const envUrl = import.meta.env.VITE_BACKEND_URL
        if (envUrl) {
            return envUrl
        }

        // PRIORITY 2: For local development, check if accessing from network IP
        const hostname = window.location.hostname
        const isLocalhost = hostname === 'localhost' || hostname === '127.0.0.1'
        const isLocalNetworkIP = /^192\.168\.|^10\.|^172\.(1[6-9]|2[0-9]|3[0-1])\./.test(hostname)
        const backendPort = import.meta.env.VITE_BACKEND_PORT || '5000'

        // If accessing from local network IP (e.g., 192.168.x.x), use that IP for backend
        if (isLocalNetworkIP) {
            return `http://${hostname}:${backendPort}`
        }

        // PRIORITY 3: Default to localhost for local development
        return `http://localhost:${backendPort}`
    }
    const backendUrl = getBackendUrl()

    const [doctors, setDoctors] = useState([])
    const [hospitals, setHospitals] = useState([])
    const [token, setToken] = useState(localStorage.getItem(TOKEN_KEY) || '')
    const [userData, setUserData] = useState(false)

    // Loading states
    const [isLoading, setIsLoading] = useState(false)
    const [isDoctorsLoading, setIsDoctorsLoading] = useState(true)
    const [isHospitalsLoading, setIsHospitalsLoading] = useState(true)
    const [isProfileLoading, setIsProfileLoading] = useState(false)

    const doctorsFetchedAt = useRef(0)
    const hospitalsFetchedAt = useRef(0)
    const doctorsInflight = useRef(null)
    const hospitalsInflight = useRef(null)
    const doctorsRef = useRef([])
    const hospitalsRef = useRef([])
    const skipNextProfileLoad = useRef(false)

    useEffect(() => { doctorsRef.current = doctors }, [doctors])
    useEffect(() => { hospitalsRef.current = hospitals }, [hospitals])

    // Helper to generate a clean avatar image for a doctor (no real photos, initials-based)
    const fixDoctorImage = (doc) => {
        const hasCustomImage = doc.image &&
            !doc.image.includes('data:image/png;base64') &&
            doc.image !== '' &&
            !doc.image.includes('placeholder');

        if (hasCustomImage) {
            return doc.image;
        }

        const name = doc.name || 'Doctor';
        const encoded = encodeURIComponent(name.replace(/\s+/g, '+'));
        // UI-Avatars generates a simple avatar with initials; colors tuned to healthcare palette
        return `https://ui-avatars.com/api/?name=${encoded}&background=0ea5e9&color=ffffff&size=256&rounded=true&bold=true`;
    }

    // Getting Doctors using API (deduped + stale-while-revalidate window)
    const getDoctosData = useCallback(async (opts = {}) => {
        const force = Boolean(opts.force)
        const now = Date.now()
        if (!force && doctorsFetchedAt.current && (now - doctorsFetchedAt.current) < DOCTORS_STALE_MS && doctorsRef.current.length > 0) {
            return doctorsRef.current
        }
        if (doctorsInflight.current) {
            return doctorsInflight.current
        }

        setIsDoctorsLoading(true)
        const run = (async () => {
            try {
                // Fetch both standalone doctors and aggregated hospital doctors
                const [doctorRes, hospitalDoctorsRes] = await Promise.all([
                    axios.get(backendUrl + '/api/doctor/list'),
                    axios.get(backendUrl + '/api/hospital-tieup/public/doctors')
                ])

                let combinedDoctors = []

                // Process Standalone Doctors
                if (doctorRes.data.success) {
                    combinedDoctors = doctorRes.data.doctors.map(doc => ({
                        ...doc,
                        image: fixDoctorImage(doc),
                        available: doc.available !== undefined && doc.available !== null
                            ? (doc.available === true || doc.available === 'true')
                            : true
                    }))
                } else {
                    console.error('Error fetching doctors:', doctorRes.data.message)
                    toast.error(doctorRes.data.message)
                }

                // Process Hospital Doctors
                if (hospitalDoctorsRes.data.success) {
                    let hospitalDoctors = hospitalDoctorsRes.data.doctors

                    hospitalDoctors = hospitalDoctors.map(doc => {
                        return {
                            ...doc,
                            speciality: doc.specialization,
                            image: fixDoctorImage(doc),
                            fees: doc.fees || 50,
                            degree: doc.qualification,
                            about: doc.about || `Dr. ${doc.name} is a specialist in ${doc.specialization} at ${doc.hospitalName}.`,
                            available: doc.available !== undefined && doc.available !== null
                                ? (doc.available === true || doc.available === 'true')
                                : true
                        }
                    })

                    combinedDoctors = [...combinedDoctors, ...hospitalDoctors]
                }

                // Remove duplicate doctors by name (case-insensitive and trimmed)
                const doctorsMap = new Map()
                combinedDoctors.forEach(doc => {
                    if (!doc || !doc.name) return

                    let cleanName = doc.name.trim().toLowerCase()
                    if (cleanName.startsWith('dr.')) {
                        cleanName = cleanName.replace(/^dr\.\s*/, '')
                    } else if (cleanName.startsWith('dr ')) {
                        cleanName = cleanName.replace(/^dr\s+/, '')
                    }

                    const uniqueKey = cleanName

                    if (!doctorsMap.has(uniqueKey)) {
                        doctorsMap.set(uniqueKey, doc)
                    } else {
                        const existing = doctorsMap.get(uniqueKey)
                        const existingIsEmbedded = existing._id && existing._id.toString().startsWith('emb_')
                        const currentIsEmbedded = doc._id && doc._id.toString().startsWith('emb_')

                        if (existingIsEmbedded && !currentIsEmbedded) {
                            doctorsMap.set(uniqueKey, doc)
                        } else {
                            const currentHasCustomImage = doc.image &&
                                !doc.image.includes('ui-avatars.com') &&
                                !doc.image.includes('data:image/png;base64')
                            const existingHasCustomImage = existing.image &&
                                !existing.image.includes('ui-avatars.com') &&
                                !existing.image.includes('data:image/png;base64')

                            if (currentHasCustomImage && !existingHasCustomImage) {
                                doctorsMap.set(uniqueKey, doc)
                            }
                        }
                    }
                })
                combinedDoctors = Array.from(doctorsMap.values())

                setDoctors(combinedDoctors)
                doctorsFetchedAt.current = Date.now()
                return combinedDoctors
            } catch (error) {
                console.error('Error fetching doctors:', error)
                const errorMessage = error?.response?.data?.message || error?.message || 'Failed to load doctors'
                toast.error(errorMessage)
                return []
            } finally {
                setIsDoctorsLoading(false)
                doctorsInflight.current = null
            }
        })()

        doctorsInflight.current = run
        return run
    }, [backendUrl])

    const getHospitalsData = useCallback(async (opts = {}) => {
        const force = Boolean(opts.force)
        const now = Date.now()
        if (!force && hospitalsFetchedAt.current && (now - hospitalsFetchedAt.current) < HOSPITALS_STALE_MS && hospitalsRef.current.length > 0) {
            return hospitalsRef.current
        }
        if (hospitalsInflight.current) {
            return hospitalsInflight.current
        }

        setIsHospitalsLoading(true)
        const run = (async () => {
            try {
                const { data } = await axios.get(backendUrl + '/api/hospital-tieup/public')
                if (data.success) {
                    setHospitals(data.hospitals || [])
                    hospitalsFetchedAt.current = Date.now()
                    return data.hospitals || []
                }
                return []
            } catch (error) {
                console.error('Error fetching hospitals:', error)
                return []
            } finally {
                setIsHospitalsLoading(false)
                hospitalsInflight.current = null
            }
        })()

        hospitalsInflight.current = run
        return run
    }, [backendUrl])

    // Getting User Profile using API
    const loadUserProfileData = useCallback(async (authToken = token) => {
        if (!authToken) return
        setIsProfileLoading(true)
        try {
            const { data } = await axios.get(backendUrl + '/api/user/get-profile', { headers: { token: authToken } })

            if (data.success) {
                setUserData(data.userData)
            } else {
                toast.error(data.message)
                if (data.message === 'Invalid Session. Please login again.') {
                    clearPatientSession()
                    setToken('')
                }
            }
        } catch (error) {
            if (isPatientAuthFailure(error)) return
            console.error('Error loading user profile:', error)
            const errorMessage = error?.response?.data?.detail || error?.response?.data?.message || error?.message || 'Failed to load profile'
            toast.error(errorMessage)
        } finally {
            setIsProfileLoading(false)
        }
    }, [backendUrl, token])

    const handleTokenRefreshed = useCallback((newToken) => {
        // Interceptor already retried the failed request with the new token.
        // Update storage/state without triggering a second get-profile.
        skipNextProfileLoad.current = true
        setToken(newToken)
    }, [])

    useEffect(() => {
        setupPatientAuthInterceptor(backendUrl, handleTokenRefreshed)

        const onSessionExpired = () => {
            setToken('')
            setUserData(false)
            toast.info('Your session expired. Please log in again.')
            const path = window.location.pathname
            if (!path.startsWith('/login')) {
                window.location.href = `/login?redirect=${encodeURIComponent(path)}`
            }
        }

        window.addEventListener('patient:sessionExpired', onSessionExpired)
        return () => window.removeEventListener('patient:sessionExpired', onSessionExpired)
    }, [backendUrl, handleTokenRefreshed])

    useEffect(() => {
        // Home needs both; fire in parallel once on mount.
        getDoctosData()
        getHospitalsData()
    }, [])

    useEffect(() => {
        if (!token) {
            setUserData(false)
            return
        }
        if (skipNextProfileLoad.current) {
            skipNextProfileLoad.current = false
            return
        }
        loadUserProfileData(token)
    }, [token, loadUserProfileData])

    const value = useMemo(() => ({
        doctors, getDoctosData,
        hospitals, getHospitalsData, isHospitalsLoading,
        currencySymbol,
        backendUrl,
        token, setToken,
        userData, setUserData, loadUserProfileData,
        isLoading, setIsLoading,
        isDoctorsLoading,
        isProfileLoading
    }), [
        doctors, getDoctosData,
        hospitals, getHospitalsData, isHospitalsLoading,
        backendUrl, token, userData, loadUserProfileData,
        isLoading, isDoctorsLoading, isProfileLoading
    ])

    return (
        <AppContext.Provider value={value}>
            {props.children}
        </AppContext.Provider>
    )

}

export default AppContextProvider
