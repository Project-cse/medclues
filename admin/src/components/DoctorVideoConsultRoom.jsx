import React, { useContext, useEffect, useRef, useState } from 'react'
import axios from 'axios'
import AgoraRTC from 'agora-rtc-sdk-ng'
import { AppContext } from '../context/AppContext'
import { toast } from 'react-toastify'
import { getPatientAge, getPatientImage, getPatientName } from '../utils/appointmentDisplay'

function formatCallDuration(totalSeconds) {
  const m = Math.floor(totalSeconds / 60)
  const s = totalSeconds % 60
  return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`
}

async function createLocalTracks(wantCamera) {
  const audioTrack = await AgoraRTC.createMicrophoneAudioTrack()
  if (!wantCamera) {
    return { tracks: [audioTrack], videoTrack: null, cameraBlocked: false }
  }
  try {
    const videoTrack = await AgoraRTC.createCameraVideoTrack()
    return { tracks: [audioTrack, videoTrack], videoTrack, cameraBlocked: false }
  } catch (_) {
    return { tracks: [audioTrack], videoTrack: null, cameraBlocked: true }
  }
}

function ToolbarButton({ label, active, danger, onClick, children }) {
  return (
    <button
      type="button"
      onClick={onClick}
      title={label}
      className={`flex flex-col items-center gap-1 px-4 py-2 rounded-xl transition-all ${
        danger
          ? 'bg-red-600 hover:bg-red-700 text-white'
          : active
            ? 'bg-teal-100 text-teal-800'
            : 'bg-slate-100 hover:bg-slate-200 text-slate-700'
      }`}
    >
      {children}
      <span className="text-[10px] font-medium">{label}</span>
    </button>
  )
}

/**
 * Enterprise doctor telemedicine video room — patient full screen, doctor PIP, clinical sidebar.
 */
const DoctorVideoConsultRoom = ({
  appointmentId,
  authToken,
  appointment,
  scheduledTime,
  publishCameraInitial = false,
  onLeave,
}) => {
  const { backendUrl, calculateAge, currency } = useContext(AppContext)
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState(null)
  const [muted, setMuted] = useState(false)
  const [videoOff, setVideoOff] = useState(false)
  const [speakerOn, setSpeakerOn] = useState(true)
  const [remoteJoined, setRemoteJoined] = useState(false)
  const [remoteVideoActive, setRemoteVideoActive] = useState(false)
  const [tracksReady, setTracksReady] = useState(false)
  const [callSeconds, setCallSeconds] = useState(0)
  const [callStartedAtMs, setCallStartedAtMs] = useState(null)
  const [consultationId, setConsultationId] = useState(null)
  const [callActive, setCallActive] = useState(false)
  const [callEndedMessage, setCallEndedMessage] = useState(null)
  const [publishCamera, setPublishCamera] = useState(publishCameraInitial)
  const [showChat, setShowChat] = useState(false)
  const [chatInput, setChatInput] = useState('')
  const [chatMessages, setChatMessages] = useState([])
  const [prescription, setPrescription] = useState('')
  const [consultNotes, setConsultNotes] = useState('')
  const [cameraHint, setCameraHint] = useState(
    !publishCameraInitial
      ? 'Receive-only: your camera is off so the patient can use the webcam on this device.'
      : null
  )

  const clientRef = useRef(null)
  const localTracksRef = useRef([])
  const localVideoRef = useRef(null)
  const remoteVideoRef = useRef(null)
  const remoteUsersRef = useRef(new Map())
  const callEndedRef = useRef(false)
  const hadRemoteRef = useRef(false)
  const joinAttemptRef = useRef(0)

  const patientName = getPatientName(appointment)
  const patientAge = getPatientAge(appointment, calculateAge)
  const patientImage = getPatientImage(appointment)
  const patientGender =
    appointment?.actualPatient?.gender || appointment?.userData?.gender || '—'
  const symptoms = appointment?.selectedSymptoms || []
  const tokenNo = appointment?.tokenNumber
  const bookingId = appointment?.bookingId || `APP-${appointmentId}`
  const apptLabel = bookingId.startsWith('APP') ? bookingId : `APP-${bookingId}`

  const playRemoteVideo = (user) => {
    if (!user?.videoTrack) return false
    const container = remoteVideoRef.current
    if (!container) return false
    try {
      user.videoTrack.play(container, { fit: 'cover' })
      setRemoteVideoActive(true)
      return true
    } catch (_) {
      return false
    }
  }

  const syncRemoteJoined = () => {
    const hasRemote = remoteUsersRef.current.size > 0
    setRemoteJoined(hasRemote)
    if (hasRemote) {
      hadRemoteRef.current = true
      setCallActive(true)
    }
    const hasVideo = [...remoteUsersRef.current.values()].some((u) => u.videoTrack)
    if (!hasVideo) setRemoteVideoActive(false)
  }

  const refreshRemoteStreams = async () => {
    const client = clientRef.current
    if (!client) return
    for (const user of client.remoteUsers) {
      remoteUsersRef.current.set(user.uid, user)
      if (user.hasAudio && !user.audioTrack) {
        try {
          await client.subscribe(user, 'audio')
        } catch (_) {}
      }
      if (user.hasVideo && !user.videoTrack) {
        try {
          await client.subscribe(user, 'video')
        } catch (_) {}
      }
    }
    requestAnimationFrame(() => {
      remoteUsersRef.current.forEach((user) => playRemoteVideo(user))
    })
    syncRemoteJoined()
  }

  const syncTimerFromServer = async () => {
    try {
      const { data } = await axios.post(
        `${backendUrl}/api/doctor/appointments/${appointmentId}/sync-call-timer`,
        {},
        { headers: { dToken: authToken } }
      )
      if (data?.callStartedAt) {
        setCallStartedAtMs(Number(data.callStartedAt))
      }
    } catch (_) {}
  }

  const handleCallEnded = async (message, { notifyServer = false } = {}) => {
    if (callEndedRef.current) return
    callEndedRef.current = true
    setCallEndedMessage(message)
    setCallActive(false)

    if (notifyServer) {
      try {
        await axios.post(
          `${backendUrl}/api/doctor/appointments/${appointmentId}/end-video-call`,
          { consultationId, prescription, notes: consultNotes },
          { headers: { dToken: authToken } }
        )
      } catch (_) {}
    }

    const client = clientRef.current
    if (client) {
      try {
        await client.leave()
      } catch (_) {}
    }

    setTimeout(() => onLeave?.(), 2500)
  }

  const subscribeRemoteUser = async (client, user) => {
    remoteUsersRef.current.set(user.uid, user)
    if (user.hasAudio) {
      await client.subscribe(user, 'audio')
      user.audioTrack?.play()
    }
    if (user.hasVideo) {
      await client.subscribe(user, 'video')
      playRemoteVideo(user)
    }
    syncRemoteJoined()
  }

  useEffect(() => {
    let cancelled = false

    const cleanup = async () => {
      localTracksRef.current.forEach((t) => {
        try {
          t.stop()
          t.close()
        } catch (_) {}
      })
      localTracksRef.current = []
      remoteUsersRef.current.clear()
      const client = clientRef.current
      if (client) {
        try {
          await client.leave()
        } catch (_) {}
      }
      clientRef.current = null
    }

    const fetchJoinCredentials = async () => {
      const { data } = await axios.post(
        `${backendUrl}/api/doctor/appointments/${appointmentId}/agora-token`,
        {},
        { headers: { dToken: authToken } }
      )
      if (!data?.success) throw new Error(data?.message || 'Could not start video session')
      return data
    }

    const joinChannel = async (client, data) => {
      const uid = Number(data.uid)
      if (!Number.isFinite(uid) || uid <= 0) {
        throw new Error('Invalid Agora uid from server')
      }
      await client.join(data.appId, data.channel, data.token, uid)
    }

    const start = async () => {
      const attempt = ++joinAttemptRef.current
      try {
        const data = await fetchJoinCredentials()
        if (cancelled || attempt !== joinAttemptRef.current) return

        if (data.consultationId) setConsultationId(data.consultationId)

        const client = AgoraRTC.createClient({ mode: 'rtc', codec: 'vp8' })
        clientRef.current = client

        client.on('user-joined', (user) => {
          remoteUsersRef.current.set(user.uid, user)
          syncRemoteJoined()
          syncTimerFromServer()
        })
        client.on('user-published', async (user, mediaType) => {
          await client.subscribe(user, mediaType)
          remoteUsersRef.current.set(user.uid, user)
          if (mediaType === 'video') playRemoteVideo(user)
          if (mediaType === 'audio') user.audioTrack?.play()
          syncRemoteJoined()
          syncTimerFromServer()
        })
        client.on('user-unpublished', (user, mediaType) => {
          if (mediaType === 'video') {
            setRemoteVideoActive(false)
          }
        })
        client.on('user-left', (user) => {
          remoteUsersRef.current.delete(user.uid)
          syncRemoteJoined()
          if (hadRemoteRef.current) {
            handleCallEnded('The call was ended.')
          }
        })

        try {
          await joinChannel(client, data)
        } catch (joinErr) {
          const code = joinErr?.code || joinErr?.name || ''
          const msg = joinErr?.message || ''
          const isUidConflict =
            code === 'UID_CONFLICT' ||
            msg.includes('UID_CONFLICT') ||
            msg.toLowerCase().includes('uid conflict')
          if (!isUidConflict) throw joinErr
          try {
            await client.leave()
          } catch (_) {}
          const fresh = await fetchJoinCredentials()
          if (cancelled || attempt !== joinAttemptRef.current) return
          await joinChannel(client, fresh)
        }
        setCallActive(true)

        for (const user of client.remoteUsers) {
          await subscribeRemoteUser(client, user)
        }
        if (client.remoteUsers.length > 0) {
          syncTimerFromServer()
        }

        const { tracks, videoTrack, cameraBlocked } = await createLocalTracks(publishCameraInitial)
        localTracksRef.current = tracks
        if (cameraBlocked) {
          setPublishCamera(false)
          setCameraHint('Webcam in use — receiving patient video only.')
        }
        await client.publish(tracks)
        if (!videoTrack) setVideoOff(true)

        if (!cancelled) {
          setTracksReady(true)
          setLoading(false)
        }
      } catch (e) {
        if (!cancelled) {
          setError(e?.response?.data?.message || e.message || 'Video call failed')
          setLoading(false)
        }
      }
    }

    start()
    return () => {
      cancelled = true
      joinAttemptRef.current += 1
      cleanup()
    }
  }, [appointmentId, authToken, backendUrl, publishCameraInitial])

  useEffect(() => {
    if (!tracksReady || loading) return
    const videoTrack = localTracksRef.current[1]
    if (videoTrack && localVideoRef.current && publishCamera) {
      try {
        videoTrack.play(localVideoRef.current, { fit: 'cover' })
      } catch (_) {}
    }
    remoteUsersRef.current.forEach((user) => playRemoteVideo(user))
  }, [tracksReady, loading, publishCamera])

  useEffect(() => {
    if (!tracksReady || loading) return undefined
    const id = setInterval(() => {
      remoteUsersRef.current.forEach((user) => playRemoteVideo(user))
    }, 2000)
    return () => clearInterval(id)
  }, [tracksReady, loading])

  useEffect(() => {
    if (!callActive || !callStartedAtMs) return undefined
    const tick = () => {
      setCallSeconds(Math.max(0, Math.floor((Date.now() - callStartedAtMs) / 1000)))
    }
    tick()
    const id = setInterval(tick, 1000)
    return () => clearInterval(id)
  }, [callActive, callStartedAtMs])

  useEffect(() => {
    if (!tracksReady || callEndedMessage) return undefined
    const id = setInterval(async () => {
      try {
        const { data } = await axios.get(
          `${backendUrl}/api/doctor/appointments/${appointmentId}/video-call-status`,
          { headers: { dToken: authToken } }
        )
        if (data?.ended && callActive) {
          handleCallEnded('The call was ended.')
          return
        }
        if (!callStartedAtMs && remoteJoined) {
          await syncTimerFromServer()
        }
      } catch (_) {}
    }, 2000)
    return () => clearInterval(id)
  }, [tracksReady, callEndedMessage, appointmentId, authToken, backendUrl, callStartedAtMs, remoteJoined])

  const toggleMute = async () => {
    const audio = localTracksRef.current[0]
    if (!audio) return
    await audio.setEnabled(muted)
    setMuted(!muted)
  }

  const toggleVideo = async () => {
    const video = localTracksRef.current[1]
    if (!video) return
    await video.setEnabled(videoOff)
    setVideoOff(!videoOff)
  }

  const enableMyCamera = async () => {
    const client = clientRef.current
    if (!client || publishCamera) return
    try {
      const videoTrack = await AgoraRTC.createCameraVideoTrack()
      localTracksRef.current = [localTracksRef.current[0], videoTrack]
      await client.publish(videoTrack)
      setPublishCamera(true)
      setVideoOff(false)
      setCameraHint(null)
      if (localVideoRef.current) videoTrack.play(localVideoRef.current, { fit: 'cover' })
      await refreshRemoteStreams()
      setTimeout(() => refreshRemoteStreams(), 1000)
      setTimeout(() => refreshRemoteStreams(), 3000)
    } catch (_) {
      toast.error('Camera in use. Close the patient tab or use a second browser.')
    }
  }

  const sendChat = () => {
    const text = chatInput.trim()
    if (!text) return
    setChatMessages((prev) => [...prev, { from: 'doctor', text, at: new Date() }])
    setChatInput('')
    toast.info('Chat is local to this session until real-time messaging is connected.')
  }

  if (loading) {
    return (
      <div className="flex flex-col items-center justify-center min-h-[70vh] bg-white rounded-2xl border border-slate-200">
        <div className="w-12 h-12 border-4 border-blue-200 border-t-blue-600 rounded-full animate-spin mb-4" />
        <p className="text-slate-600 font-medium">Connecting secure video consultation…</p>
      </div>
    )
  }

  if (error) {
    return (
      <div className="max-w-lg mx-auto p-8 text-center bg-white rounded-2xl border border-red-100 shadow-sm">
        <p className="text-red-600 font-semibold mb-2">Video consultation unavailable</p>
        <p className="text-slate-600 text-sm mb-4">{error}</p>
        <div className="flex flex-wrap gap-3 justify-center">
          <button
            type="button"
            onClick={() => window.location.reload()}
            className="px-5 py-2.5 bg-teal-600 text-white rounded-lg text-sm font-medium hover:bg-teal-700"
          >
            Retry video
          </button>
          <button type="button" onClick={onLeave} className="px-5 py-2.5 bg-slate-800 text-white rounded-lg text-sm">
            Back to appointments
          </button>
        </div>
      </div>
    )
  }

  return (
    <div className="flex flex-col bg-white rounded-2xl border border-slate-200 shadow-xl overflow-hidden min-h-[calc(100vh-120px)]">
      {/* Header */}
      <div className="flex flex-wrap items-center justify-between gap-3 px-5 py-3 border-b border-slate-100 bg-gradient-to-r from-white via-blue-50/30 to-teal-50/40">
        <div className="flex items-center gap-3 min-w-0">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-blue-600 to-teal-600 flex items-center justify-center text-white font-bold text-sm shadow-md">
            MC+
          </div>
          <div className="min-w-0">
            <p className="font-bold text-slate-900 text-sm truncate">Video Consultation</p>
            <p className="text-xs text-slate-500 truncate">
              {patientName} · {apptLabel}
              {scheduledTime ? ` · ${scheduledTime}` : ''}
            </p>
          </div>
        </div>
        <div className="flex items-center gap-3">
          <span className="inline-flex items-center gap-1.5 px-3 py-1 rounded-full bg-red-50 text-red-700 text-xs font-semibold border border-red-100">
            <span className="w-2 h-2 rounded-full bg-red-500 animate-pulse" />
            {callStartedAtMs ? `LIVE · ${formatCallDuration(callSeconds)}` : 'CONNECTING · 00:00'}
          </span>
          {tokenNo ? (
            <span className="px-3 py-1 rounded-full bg-teal-50 text-teal-800 text-xs font-semibold border border-teal-100">
              Token #{tokenNo}
            </span>
          ) : null}
        </div>
      </div>

      {cameraHint && (
        <div className="px-5 py-2 bg-amber-50 border-b border-amber-100 text-amber-800 text-xs">{cameraHint}</div>
      )}

      <div className="flex flex-1 flex-col lg:flex-row min-h-0">
        {/* Video column — patient full, doctor PIP */}
        <div className="flex-1 flex flex-col min-w-0 min-h-[320px] lg:min-h-[480px]">
          <div className="relative flex-1 bg-slate-900 min-h-[280px]">
            <div ref={remoteVideoRef} className="absolute inset-0 w-full h-full" />

            {!remoteJoined && (
              <div className="absolute inset-0 flex flex-col items-center justify-center text-white/80 px-6 text-center pointer-events-none z-10">
                <div className="w-16 h-16 rounded-full bg-white/10 flex items-center justify-center mb-4">
                  <svg className="w-8 h-8" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                    <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={1.5} d="M16 7a4 4 0 11-8 0 4 4 0 018 0zM12 14a7 7 0 00-7 7h14a7 7 0 00-7-7z" />
                  </svg>
                </div>
                <p className="font-medium">Waiting for patient to join…</p>
              </div>
            )}

            {remoteJoined && !remoteVideoActive && (
              <div className="absolute inset-0 flex items-center justify-center text-white/90 text-sm px-8 text-center pointer-events-none z-10">
                Patient connected — waiting for camera…
              </div>
            )}

            {remoteJoined && (
              <span className="absolute top-4 left-4 z-20 text-xs font-semibold text-white bg-emerald-600/90 px-3 py-1.5 rounded-lg shadow">
                Patient{remoteVideoActive ? ' · video' : ' · audio'}
              </span>
            )}

            {/* Doctor self-view PIP — mirrored */}
            <div className="absolute top-4 right-4 z-20 w-36 sm:w-44 aspect-[3/4] rounded-xl overflow-hidden border-2 border-white/40 shadow-2xl bg-slate-800">
              <div
                ref={localVideoRef}
                className={`w-full h-full ${publishCamera && !videoOff ? 'scale-x-[-1]' : ''}`}
              />
              {!publishCamera || videoOff ? (
                <div className="absolute inset-0 flex items-center justify-center bg-slate-800/90 text-white/70 text-[10px] px-2 text-center">
                  {publishCamera ? 'Camera off' : 'You (camera off)'}
                </div>
              ) : null}
              <span className="absolute bottom-1 left-1 right-1 text-center text-[9px] text-white/90 bg-black/50 rounded py-0.5">
                You (doctor)
              </span>
            </div>
          </div>

          {/* Bottom toolbar */}
          <div className="flex flex-wrap items-center justify-center gap-2 sm:gap-3 px-4 py-3 bg-white border-t border-slate-100">
            <ToolbarButton label={muted ? 'Unmute' : 'Mic'} active={muted} onClick={toggleMute}>
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                {muted ? (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" />
                ) : (
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M19 11a7 7 0 01-7 7m0 0a7 7 0 01-7-7m7 7v4m0 0H8m4 0h4m-4-8a3 3 0 01-3-3V5a3 3 0 116 0v6a3 3 0 01-3 3z" />
                )}
              </svg>
            </ToolbarButton>

            {publishCamera ? (
              <ToolbarButton label={videoOff ? 'Camera on' : 'Camera'} active={videoOff} onClick={toggleVideo}>
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
              </ToolbarButton>
            ) : (
              <ToolbarButton label="Enable cam" onClick={enableMyCamera}>
                <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                  <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15 10l4.553-2.276A1 1 0 0121 8.618v6.764a1 1 0 01-1.447.894L15 14M5 18h8a2 2 0 002-2V8a2 2 0 00-2-2H5a2 2 0 00-2 2v8a2 2 0 002 2z" />
                </svg>
              </ToolbarButton>
            )}

            <ToolbarButton
              label="Speaker"
              active={!speakerOn}
              onClick={() => {
                setSpeakerOn((v) => !v)
                toast.info(speakerOn ? 'Speaker muted (UI)' : 'Speaker on')
              }}
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M15.536 8.464a5 5 0 010 7.072m2.828-9.9a9 9 0 010 12.728M5.586 15H4a1 1 0 01-1-1v-4a1 1 0 011-1h1.586l4.707-4.707C10.923 3.663 12 4.109 12 5v14c0 .891-1.077 1.337-1.707.707L5.586 15z" />
              </svg>
            </ToolbarButton>

            <ToolbarButton label="Screen" onClick={() => toast.info('Screen share coming soon')}>
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M9.75 17L9 20l-1 1h8l-1-1-.75-3M3 13h18M5 17h14a2 2 0 002-2V5a2 2 0 00-2-2H5a2 2 0 00-2 2v10a2 2 0 002 2z" />
              </svg>
            </ToolbarButton>

            <ToolbarButton label="Chat" active={showChat} onClick={() => setShowChat((v) => !v)}>
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M8 12h.01M12 12h.01M16 12h.01M21 12c0 4.418-4.03 8-9 8a9.863 9.863 0 01-4.255-.949L3 20l1.395-3.72C3.512 15.042 3 13.574 3 12c0-4.418 4.03-8 9-8s9 3.582 9 8z" />
              </svg>
            </ToolbarButton>

            <ToolbarButton
              label="End Consultation"
              danger
              onClick={() => handleCallEnded('You ended the consultation.', { notifyServer: true })}
            >
              <svg className="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 8l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2M3 3l1.5 1.5M3 21l1.5-1.5M21 3l-1.5 1.5M21 21l-1.5-1.5" />
              </svg>
            </ToolbarButton>
          </div>
        </div>

        {/* Clinical sidebar */}
        <div className="w-full lg:w-[380px] xl:w-[400px] flex flex-col border-t lg:border-t-0 lg:border-l border-slate-200 bg-slate-50/80 min-h-0 max-h-[50vh] lg:max-h-none overflow-hidden">
          <div className="flex-1 overflow-y-auto p-4 space-y-4">
            {/* Patient profile */}
            <section className="bg-white rounded-xl border border-slate-100 p-4 shadow-sm">
              <h3 className="text-xs font-bold uppercase tracking-wider text-blue-700 mb-3">Patient Profile</h3>
              <div className="flex items-center gap-3 mb-3">
                <img src={patientImage} alt="" className="w-12 h-12 rounded-full object-cover ring-2 ring-blue-100" />
                <div>
                  <p className="font-bold text-slate-900">{patientName}</p>
                  <p className="text-xs text-slate-500">Video consultation</p>
                </div>
              </div>
              <dl className="grid grid-cols-2 gap-2 text-xs">
                <div>
                  <dt className="text-slate-400">Age</dt>
                  <dd className="font-semibold text-slate-800">{patientAge}</dd>
                </div>
                <div>
                  <dt className="text-slate-400">Gender</dt>
                  <dd className="font-semibold text-slate-800 capitalize">{patientGender}</dd>
                </div>
                <div className="col-span-2">
                  <dt className="text-slate-400">Appointment</dt>
                  <dd className="font-semibold text-slate-800">{apptLabel}</dd>
                </div>
                <div className="col-span-2">
                  <dt className="text-slate-400">Fee</dt>
                  <dd className="font-semibold text-teal-700">
                    {currency}
                    {appointment?.amount ?? '—'}
                    {appointment?.payment ? ' · Paid' : ''}
                  </dd>
                </div>
              </dl>
            </section>

            {/* Symptoms */}
            <section className="bg-white rounded-xl border border-slate-100 p-4 shadow-sm">
              <h3 className="text-xs font-bold uppercase tracking-wider text-blue-700 mb-2">Symptoms</h3>
              {symptoms.length > 0 ? (
                <div className="flex flex-wrap gap-1.5">
                  {symptoms.map((s, i) => (
                    <span key={i} className="px-2 py-1 rounded-lg bg-teal-50 text-teal-800 text-xs border border-teal-100">
                      {s}
                    </span>
                  ))}
                </div>
              ) : (
                <p className="text-xs text-slate-400">No symptoms recorded for this booking.</p>
              )}
            </section>

            {/* Medical history placeholder */}
            <section className="bg-white rounded-xl border border-slate-100 p-4 shadow-sm">
              <h3 className="text-xs font-bold uppercase tracking-wider text-blue-700 mb-2">Medical History</h3>
              <p className="text-xs text-slate-500 leading-relaxed">
                Review full records in Patient Reports after the call. Allergies and chronic conditions can be noted below.
              </p>
            </section>

            {/* Uploaded reports */}
            <section className="bg-white rounded-xl border border-slate-100 p-4 shadow-sm">
              <h3 className="text-xs font-bold uppercase tracking-wider text-blue-700 mb-2">Uploaded Reports</h3>
              {appointment?.actualPatient?.prescription ? (
                <a
                  href={appointment.actualPatient.prescription}
                  target="_blank"
                  rel="noreferrer"
                  className="text-xs text-blue-600 hover:underline font-medium"
                >
                  View prescription uploaded at booking
                </a>
              ) : (
                <p className="text-xs text-slate-400">No reports attached to this appointment.</p>
              )}
            </section>

            {/* Prescription editor */}
            <section className="bg-white rounded-xl border border-slate-100 p-4 shadow-sm">
              <h3 className="text-xs font-bold uppercase tracking-wider text-blue-700 mb-2">Prescription Editor</h3>
              <textarea
                value={prescription}
                onChange={(e) => setPrescription(e.target.value)}
                rows={4}
                placeholder="Medicines, dosage, duration…"
                className="w-full text-xs border border-slate-200 rounded-lg p-3 focus:ring-2 focus:ring-blue-500/20 focus:border-blue-400 outline-none resize-y"
              />
            </section>

            {/* Consultation notes */}
            <section className="bg-white rounded-xl border border-slate-100 p-4 shadow-sm">
              <h3 className="text-xs font-bold uppercase tracking-wider text-blue-700 mb-2">Consultation Notes</h3>
              <textarea
                value={consultNotes}
                onChange={(e) => setConsultNotes(e.target.value)}
                rows={4}
                placeholder="Diagnosis, advice, follow-up…"
                className="w-full text-xs border border-slate-200 rounded-lg p-3 focus:ring-2 focus:ring-blue-500/20 focus:border-blue-400 outline-none resize-y"
              />
            </section>

            {/* Chat panel */}
            {showChat && (
              <section className="bg-white rounded-xl border border-blue-100 p-4 shadow-sm">
                <h3 className="text-xs font-bold uppercase tracking-wider text-blue-700 mb-2">Chat</h3>
                <div className="h-32 overflow-y-auto mb-2 space-y-2 bg-slate-50 rounded-lg p-2">
                  {chatMessages.length === 0 ? (
                    <p className="text-xs text-slate-400 text-center py-4">No messages yet</p>
                  ) : (
                    chatMessages.map((m, i) => (
                      <div key={i} className="text-xs bg-blue-50 text-slate-800 rounded-lg px-2 py-1.5 self-end">
                        {m.text}
                      </div>
                    ))
                  )}
                </div>
                <div className="flex gap-2">
                  <input
                    type="text"
                    value={chatInput}
                    onChange={(e) => setChatInput(e.target.value)}
                    onKeyDown={(e) => e.key === 'Enter' && sendChat()}
                    placeholder="Message patient…"
                    className="flex-1 text-xs border border-slate-200 rounded-lg px-3 py-2 outline-none focus:border-blue-400"
                  />
                  <button
                    type="button"
                    onClick={sendChat}
                    className="px-3 py-2 bg-blue-600 text-white text-xs font-semibold rounded-lg hover:bg-blue-700"
                  >
                    Send
                  </button>
                </div>
              </section>
            )}
          </div>
        </div>
      </div>

      {callEndedMessage && (
        <div className="fixed inset-0 z-50 flex items-center justify-center bg-slate-900/80 backdrop-blur-sm">
          <div className="bg-white rounded-2xl shadow-2xl px-8 py-10 text-center max-w-sm mx-4">
            <div className="w-16 h-16 mx-auto mb-4 rounded-full bg-red-100 flex items-center justify-center">
              <svg className="w-8 h-8 text-red-600" fill="none" stroke="currentColor" viewBox="0 0 24 24">
                <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M16 8l2-2m0 0l2-2m-2 2l-2-2m2 2l2 2M3 3l1.5 1.5M3 21l1.5-1.5M21 3l-1.5 1.5M21 21l-1.5-1.5" />
              </svg>
            </div>
            <p className="text-lg font-bold text-slate-900 mb-1">Call ended</p>
            <p className="text-sm text-slate-600">{callEndedMessage}</p>
          </div>
        </div>
      )}
    </div>
  )
}

export default DoctorVideoConsultRoom
