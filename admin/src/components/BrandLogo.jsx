import React from 'react'
import { useNavigate } from 'react-router-dom'
import { assets } from '../assets/assets'

/**
 * BrandLogo Component
 * Reusable component for displaying the official MediChain logo
 * 
 * @param {Object} props
 * @param {string} props.size - Size variant: 'small' (32px), 'medium' (42px), 'large' (48px), or custom height
 * @param {boolean} props.clickable - Whether the logo should be clickable (navigate to home)
 * @param {string} props.className - Additional CSS classes
 * @param {string} props.variant - Variant: 'header' (for headers) or 'sidebar' (for sidebars)
 */
const BrandLogo = ({ 
  size = 'medium', 
  clickable = true, 
  className = '',
  variant = 'header'
}) => {
  const navigate = useNavigate()

  // Size mapping
  const sizeMap = {
    small: 'h-8',      // 32px
    medium: 'h-[42px]', // 42px (desktop header)
    large: 'h-12',     // 48px (sidebar)
    mobile: 'h-7'      // 28px (mobile)
  }

  // Get height class based on size prop
  const heightClass = typeof size === 'string' && sizeMap[size] 
    ? sizeMap[size] 
    : size === 'mobile' 
      ? 'h-7 sm:h-[42px]' // Responsive for mobile
      : `h-[${size}px]`

  // Base classes
  const baseClasses = `
    w-auto
    object-contain
    transition-all duration-300
    ${variant === 'header' ? 'animate-fade-in' : ''}
    ${clickable ? 'cursor-pointer' : ''}
    ${className}
  `

  // Handle click - navigate based on current route
  const handleClick = () => {
    if (clickable) {
      const currentPath = window.location.pathname
      if (currentPath.includes('/doctor')) {
        navigate('/doctor-dashboard')
      } else {
        navigate('/admin-dashboard')
      }
    }
  }

  return (
    <div className={`flex items-center ${className}`}>
      <img
        src={assets.logo}
        alt="MediChain Logo"
        className={`${heightClass} ${baseClasses} block`}
        onClick={handleClick}
        style={{
          maxHeight: variant === 'header' ? '42px' : variant === 'sidebar' ? '48px' : 'auto',
          imageRendering: 'auto',
          display: 'block'
        }}
        onError={(e) => {
          console.error('Logo failed to load:', assets.logo)
          e.target.style.display = 'none'
        }}
      />
    </div>
  )
}

export default BrandLogo

