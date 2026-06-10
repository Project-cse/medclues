import React, { useContext, useState, useEffect } from 'react'
import { assets } from '../assets/assets'
import { DoctorContext } from '../context/DoctorContext'
import { AdminContext } from '../context/AdminContext'
import { DeanContext } from '../context/DeanContext'
import { AppContext } from '../context/AppContext'
import { useNavigate } from 'react-router-dom'
import BrandLogo from './BrandLogo'
import { logoutWithApi } from '../services/authApi'

const Navbar = () => {
  const { dToken, setDToken, profileData, getProfileData } = useContext(DoctorContext)
  const { aToken, setAToken } = useContext(AdminContext)
  const { deanToken, setDeanToken, setDeanInfo } = useContext(DeanContext)
  const { sidebarOpen, setSidebarOpen, darkMode, toggleDarkMode } = useContext(AppContext)
  const navigate = useNavigate()
  const [currentTime, setCurrentTime] = useState(new Date())
  const [scrolled, setScrolled] = useState(false)

  useEffect(() => {
    const timer = setInterval(() => {
      setCurrentTime(new Date())
    }, 1000)
    return () => clearInterval(timer)
  }, [])

  // Fetch doctor profile data if not already loaded
  useEffect(() => {
    if (dToken && !profileData) {
      getProfileData()
    }
  }, [dToken, profileData, getProfileData])

  // Handle scroll for blur effect - only apply to main content area, not window
  useEffect(() => {
    const handleScroll = () => {
      const mainContent = document.querySelector('.main-content-area')
      if (mainContent) {
        setScrolled(mainContent.scrollTop > 10)
      }
    }

    // Use a small delay to ensure DOM is ready
    const timeoutId = setTimeout(() => {
      const mainContent = document.querySelector('.main-content-area')
      if (mainContent) {
        mainContent.addEventListener('scroll', handleScroll)
      }
    }, 100)

    return () => {
      clearTimeout(timeoutId)
      const mainContent = document.querySelector('.main-content-area')
      if (mainContent) {
        mainContent.removeEventListener('scroll', handleScroll)
      }
    }
  }, [])

  const formatTime = (date) => {
    return date.toLocaleTimeString('en-US', {
      hour: '2-digit',
      minute: '2-digit',
      second: '2-digit',
      hour12: true
    })
  }

  const logout = async () => {
    if (dToken) {
      await logoutWithApi('doctor')
      setDToken('')
    }
    if (aToken) {
      await logoutWithApi('admin')
      setAToken('')
    }
    if (deanToken) {
      await logoutWithApi('dean')
      setDeanToken('')
      setDeanInfo(null)
    }
    navigate('/')
  }

  // Get doctor/admin name and photo
  const adminName = aToken ? 'Super Admin' : (dToken && profileData) ? profileData.name : 'User'
  const adminPhoto = aToken
    ? 'https://ui-avatars.com/api/?name=' + encodeURIComponent(adminName) + '&background=667eea&color=fff&size=128'
    : (dToken && profileData && profileData.image)
      ? profileData.image
      : 'https://ui-avatars.com/api/?name=' + encodeURIComponent(adminName) + '&background=667eea&color=fff&size=128'

  return (
    <div
      className={`sticky top-0 z-20 flex justify-between items-center px-4 sm:px-4 lg:px-8 py-2.5 border-b border-mc-border transition-all duration-300 header ${scrolled
          ? 'bg-mc-surface/95 shadow-lg'
          : 'bg-mc-surface/90 shadow-sm'
        }`}
      style={{
        WebkitBackdropFilter: scrolled ? 'blur(8px)' : 'blur(4px)',
        backdropFilter: scrolled ? 'blur(8px)' : 'blur(4px)',
        height: '64px',
        minHeight: '64px',
        maxHeight: '64px'
      }}
    >
      <div className='flex items-center gap-2 sm:gap-3'>
        {/* Hamburger Menu - Only on Mobile/Tablet */}
        <button 
          onClick={() => setSidebarOpen(!sidebarOpen)}
          className='lg:hidden p-2 rounded-lg hover:bg-mc-surface-elevated transition-colors'
          aria-label="Toggle Menu"
        >
          <svg className='w-6 h-6 text-mc-text' fill="none" stroke="currentColor" viewBox="0 0 24 24">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d={sidebarOpen ? "M6 18L18 6M6 6l12 12" : "M4 6h16M4 12h16M4 18h16"} />
          </svg>
        </button>

        {/* Official MediChain Logo only (status + profile moved to sidebar) */}
        <div className='flex items-center'>
          <BrandLogo
            size="medium"
            variant="header"
            clickable={true}
            className="mr-1 sm:mr-2"
          />
        </div>
      </div>

      <div className='flex items-center gap-2 sm:gap-3 text-[11px] sm:text-xs text-mc-text-muted'>
        <button
          type="button"
          onClick={toggleDarkMode}
          className='p-2 rounded-lg border border-mc-border bg-mc-surface-elevated hover:bg-mc-surface transition-colors'
          aria-label={darkMode ? 'Switch to light mode' : 'Switch to dark mode'}
          title={darkMode ? 'Light mode' : 'Dark mode'}
        >
          {darkMode ? (
            <svg className='w-5 h-5 text-amber-300' fill="currentColor" viewBox="0 0 20 20"><path d="M10 2a1 1 0 011 1v1a1 1 0 11-2 0V3a1 1 0 011-1zm4 8a4 4 0 11-8 0 4 4 0 018 0zm-.464 4.95l.707.707a1 1 0 01-1.414 1.414l-.707-.707a1 1 0 011.414-1.414zm2.12-10.607a1 1 0 010 1.414l-.706.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.413 0zm2.829 2.829a1 1 0 010 1.414l-.707.707a1 1 0 11-1.414-1.414l.707-.707a1 1 0 011.414 0zM17 11a1 1 0 100-2h-1a1 1 0 100 2h1zm-7 4a1 1 0 011 1v1a1 1 0 11-2 0v-1a1 1 0 011-1zM5.05 15.536l.707.707a1 1 0 01-1.414 1.414l-.707-.707a1 1 0 011.414-1.414zm-2.829-2.829a1 1 0 011.414 0l.707.707a1 1 0 11-1.414 1.414l-.707-.707a1 1 0 010-1.414zM4 11a1 1 0 100-2H3a1 1 0 000 2h1z"/></svg>
          ) : (
            <svg className='w-5 h-5 text-slate-600' fill="currentColor" viewBox="0 0 20 20"><path d="M17.293 13.293A8 8 0 016.707 2.707a8.001 8.001 0 1010.586 10.586z"/></svg>
          )}
        </button>
        <span className='hidden sm:inline'>Welcome back,</span>
        <span className='font-semibold text-mc-text'>{adminName}</span>
      </div>
    </div>
  )
}

export default Navbar
