import React, { useContext, useEffect, useState } from 'react'
import { AdminContext } from '../../context/AdminContext'
import { AppContext } from '../../context/AppContext'
import GlassCard from '../../components/ui/GlassCard'
import LineChart from '../../components/charts/LineChart'
import BarChart from '../../components/charts/BarChart'
import AnimatedCounter from '../../components/ui/AnimatedCounter'

const RevenueAnalytics = () => {
    const { getRevenueAnalytics, revenueData } = useContext(AdminContext)
    const [loading, setLoading] = useState(true)
    const [selectedOption, setSelectedOption] = useState('today')

    // Dropdown options mapping
    const options = [
        { id: 'today', label: 'Current Day Revenue' },
        { id: 'days15', label: 'Last 15 Days Revenue' },
        { id: 'monthly', label: 'Monthly Revenue (current month daily breakdown)' },
        { id: 'monthWise', label: 'Month-wise Revenue (Jan–Dec of current year)' },
        { id: 'yearWise', label: 'Yearly Revenue' }
    ]

    useEffect(() => {
        const fetchAnalytics = async () => {
            setLoading(true)
            await getRevenueAnalytics()
            setLoading(false)
        }
        fetchAnalytics()
    }, [])

    if (loading || !revenueData) {
        return (
            <div className='flex items-center justify-center min-h-[calc(100vh-64px)]'>
                <div className='text-center'>
                    <div className='animate-spin rounded-full h-12 w-12 border-b-2 border-indigo-600 mx-auto'></div>
                    <p className='mt-4 text-gray-600 font-medium'>Fetching revenue metrics...</p>
                </div>
            </div>
        )
    }

    const currentChartData = revenueData[selectedOption] || { labels: [], values: [], total: 0 }

    return (
        <div className='w-full min-h-screen bg-gray-50 p-4 sm:p-6 lg:p-8'>
            <div className='max-w-4xl mx-auto'>
                {/* Header Section */}
                <header className='flex flex-col md:flex-row justify-between items-start md:items-end gap-4 mb-6'>
                    <div>
                        <h1 className='text-3xl font-black text-gray-900 tracking-tight'>
                            Revenue <span className='text-indigo-600'>Analytics</span>
                        </h1>
                        <p className='text-gray-400 mt-1 text-sm font-medium'>Platform financial performance overview.</p>
                    </div>

                    <div className='w-full md:w-72'>
                        <label htmlFor="revenue-filter" className='block text-[9px] font-black text-gray-400 uppercase tracking-widest mb-1.5'>Timeframe</label>
                        <select
                            id="revenue-filter"
                            value={selectedOption}
                            onChange={(e) => setSelectedOption(e.target.value)}
                            className='w-full bg-white border border-gray-100 rounded-xl px-4 py-3 text-xs font-bold text-gray-600 shadow-sm focus:ring-4 focus:ring-indigo-500/5 focus:border-indigo-200 outline-none transition-all cursor-pointer'
                        >
                            {options.map(opt => (
                                <option key={opt.id} value={opt.id}>{opt.label}</option>
                            ))}
                        </select>
                    </div>
                </header>

                {/* Total Summary Above Graph */}
                <div className='mb-4 bg-white border border-gray-100 rounded-2xl p-6 shadow-sm flex items-center justify-between group transition-all hover:border-indigo-100'>
                    <div>
                        <h2 className='text-gray-400 text-[10px] font-black uppercase tracking-[0.2em] mb-0.5'>Total Revenue</h2>
                        <div className='flex items-baseline gap-2'>
                            <span className='text-3xl font-black text-gray-900 tracking-tight'>
                                ₹<AnimatedCounter value={currentChartData.total} />
                            </span>
                        </div>
                    </div>
                    <div className='w-12 h-12 bg-indigo-600 rounded-xl flex items-center justify-center text-white shadow-lg shadow-indigo-100'>
                        <svg className='w-6 h-6' fill="none" stroke="currentColor" viewBox="0 0 24 24">
                            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2.5} d="M13 7h8m0 0v8m0-8l-8 8-4-4-6 6" />
                        </svg>
                    </div>
                </div>

                {/* Graph Area */}
                <GlassCard className='p-6'>
                    <div className='flex items-center gap-2 mb-6 border-b border-gray-50 pb-3'>
                        <div className='w-1.5 h-1.5 rounded-full bg-indigo-500' />
                        <h3 className='text-[10px] font-black text-gray-400 uppercase tracking-widest'>Revenue Distribution</h3>
                    </div>
                    
                    <div className='h-[300px] w-full transition-all duration-500 ease-in-out'>
                        {/* 
                           We use a single graph container that updates its underlying 
                           Chart component based on the selection. 
                        */}
                        {['monthWise', 'yearWise'].includes(selectedOption) ? (
                            <BarChart 
                                key={`bar-${selectedOption}`} 
                                data={currentChartData} 
                                title="Revenue" 
                                color="#4f46e5" 
                            />
                        ) : (
                            <LineChart 
                                key={`line-${selectedOption}`} 
                                data={currentChartData} 
                                title="Revenue Trend" 
                                color="#4f46e5" 
                            />
                        )}
                    </div>
                </GlassCard>

                {/* Footer Insight */}
                <div className='mt-8 flex items-center justify-center gap-4 text-[10px] font-black text-gray-300 uppercase tracking-[0.3em]'>
                    <span>Real-time Financials</span>
                    <div className='w-1 h-1 rounded-full bg-gray-200' />
                    <span>PostgreSQL Verified</span>
                    <div className='w-1 h-1 rounded-full bg-gray-200' />
                    <span>MediChain+ Official</span>
                </div>
            </div>
        </div>
    )
}

export default RevenueAnalytics
