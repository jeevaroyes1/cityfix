import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { analyticsEngine } from '../../services/donation/analyticsService';
import { subscribeToDonorDonations, subscribeToDonorSubscriptions } from '../../services/donation/donationService';
import Loading from '../common/Loading';
import ErrorMessage from '../common/ErrorMessage';
import DonationSummaryCards from './DonationSummaryCards';
import ImpactVisualization from './ImpactVisualization';
import RecentDonations from './RecentDonations';
import SubscriptionOverview from './SubscriptionOverview';
import QuickActions from './QuickActions';
import DebugInfo from './DebugInfo';
import './DonationDashboard.css';

const DonationDashboard = () => {
    const { currentUser: user, userProfile } = useAuth();
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [analytics, setAnalytics] = useState(null);
    const [donations, setDonations] = useState([]);
    const [subscriptions, setSubscriptions] = useState([]);
    const [timeFilter, setTimeFilter] = useState('all'); // all, 30days, 90days, year

    useEffect(() => {
        if (!user?.uid) {
            setLoading(false);
            setError('Please log in to view your donation dashboard.');
            return;
        }

        const unsubscribeDonations = subscribeToDonorDonations(
            user.uid,
            (donationsData) => {
                setDonations(donationsData);
            },
            (err) => {
                console.error('Error fetching donations:', err);
                // Don't set error for empty donations, just use empty array
                setDonations([]);
            }
        );

        const unsubscribeSubscriptions = subscribeToDonorSubscriptions(
            user.uid,
            (subscriptionsData) => {
                setSubscriptions(subscriptionsData);
            },
            (err) => {
                console.error('Error fetching subscriptions:', err);
                // Don't set error for empty subscriptions, just use empty array
                setSubscriptions([]);
            }
        );

        return () => {
            unsubscribeDonations();
            unsubscribeSubscriptions();
        };
    }, [user?.uid]);

    useEffect(() => {
        if (!user?.uid) return;

        const loadAnalytics = async () => {
            try {
                setLoading(true);
                setError('');
                
                // Generate analytics with empty data fallback
                const analyticsData = await analyticsEngine.generateDonorInsights(user.uid);
                setAnalytics(analyticsData);
            } catch (err) {
                console.error('Error loading analytics:', err);
                
                // Create fallback analytics data for new users
                const fallbackAnalytics = {
                    totalDonations: 0,
                    totalDonated: 0,
                    totalTaxSavings: 0,
                    activeSubscriptions: 0,
                    donationFrequency: { frequency: 'none', averageDaysBetween: 0 },
                    preferredCenters: [],
                    impactMetrics: [],
                    trends: { monthly: [], growth: 0 },
                    givingPatterns: {
                        byMonth: new Array(12).fill(0),
                        byDayOfWeek: new Array(7).fill(0),
                        byHour: new Array(24).fill(0),
                        byAmount: { small: 0, medium: 0, large: 0, major: 0 }
                    },
                    efficiency: { averageProcessingTime: 0, successRate: 100 },
                    donations: [],
                    subscriptions: [],
                    generatedAt: new Date()
                };
                
                setAnalytics(fallbackAnalytics);
                setError('Welcome! Start making donations to see your impact analytics.');
            } finally {
                setLoading(false);
            }
        };

        loadAnalytics();
    }, [user?.uid, donations, subscriptions]);

    const getFilteredDonations = () => {
        if (timeFilter === 'all') return donations;

        const now = new Date();
        let filterDate;

        switch (timeFilter) {
            case '30days':
                filterDate = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
                break;
            case '90days':
                filterDate = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);
                break;
            case 'year':
                filterDate = new Date(now.getTime() - 365 * 24 * 60 * 60 * 1000);
                break;
            default:
                return donations;
        }

        return donations.filter(donation => {
            const donationDate = donation.createdAt?.toDate ? donation.createdAt.toDate() : new Date(donation.createdAt);
            return donationDate >= filterDate;
        });
    };

    const handleExportData = async (format) => {
        try {
            const filteredDonations = getFilteredDonations();
            
            if (format === 'csv') {
                await exportToCSV(filteredDonations);
            } else if (format === 'pdf') {
                await exportToPDF(filteredDonations, analytics);
            }
        } catch (err) {
            console.error('Error exporting data:', err);
            setError('Failed to export data.');
        }
    };

    const exportToCSV = (donations) => {
        const headers = ['Date', 'Center', 'Amount', 'Payment Method', 'Status', 'Transaction ID'];
        const csvContent = [
            headers.join(','),
            ...donations.map(donation => [
                new Date(donation.createdAt?.toDate ? donation.createdAt.toDate() : donation.createdAt).toLocaleDateString(),
                donation.centerName,
                donation.amount,
                donation.paymentMethod,
                donation.status,
                donation.transactionId
            ].join(','))
        ].join('\n');

        const blob = new Blob([csvContent], { type: 'text/csv' });
        const url = window.URL.createObjectURL(blob);
        const a = document.createElement('a');
        a.href = url;
        a.download = `donations-${timeFilter}-${new Date().toISOString().split('T')[0]}.csv`;
        a.click();
        window.URL.revokeObjectURL(url);
    };

    const exportToPDF = async (donations, analytics) => {
        // Placeholder for PDF export
        // In real implementation, would use jsPDF or similar library
        console.log('Exporting to PDF:', { donations, analytics });
        alert('PDF export functionality will be implemented with jsPDF library');
    };

    if (loading) return <Loading message="Loading your donation dashboard..." />;

    if (!user?.uid) {
        return (
            <div className="donation-dashboard">
                <div className="dashboard-header">
                    <div className="header-content">
                        <h1>My Donation Dashboard</h1>
                        <p>Please log in to view your donation analytics and impact tracking.</p>
                    </div>
                </div>
                <ErrorMessage message="Authentication required. Please log in to continue." />
            </div>
        );
    }

    return (
        <div className="donation-dashboard">
            <DebugInfo />
            <div className="dashboard-header">
                <div className="header-content">
                    <h1>My Donation Dashboard</h1>
                    <p>Track your impact and manage your giving</p>
                </div>
                <div className="header-actions">
                    <div className="time-filter">
                        <select 
                            value={timeFilter} 
                            onChange={(e) => setTimeFilter(e.target.value)}
                            className="filter-select"
                        >
                            <option value="all">All Time</option>
                            <option value="30days">Last 30 Days</option>
                            <option value="90days">Last 90 Days</option>
                            <option value="year">This Year</option>
                        </select>
                    </div>
                    <div className="export-actions">
                        <button 
                            onClick={() => handleExportData('csv')}
                            className="btn btn-outline"
                        >
                            📊 Export CSV
                        </button>
                        <button 
                            onClick={() => handleExportData('pdf')}
                            className="btn btn-outline"
                        >
                            📄 Export PDF
                        </button>
                    </div>
                </div>
            </div>

            <ErrorMessage message={error} onClose={() => setError('')} />

            {analytics && (
                <>
                    <DonationSummaryCards 
                        analytics={analytics}
                        timeFilter={timeFilter}
                    />

                    {analytics.totalDonations === 0 ? (
                        <div className="dashboard-section" style={{ textAlign: 'center', padding: '40px', margin: '20px 0' }}>
                            <h3>Welcome to Your Donation Dashboard! 🎉</h3>
                            <p>You haven't made any donations yet. Start your giving journey to see your impact analytics here.</p>
                            <div style={{ marginTop: '20px' }}>
                                <a href="/donate" className="btn btn-primary">Make Your First Donation</a>
                            </div>
                        </div>
                    ) : (
                        <>
                            <div className="dashboard-grid">
                                <div className="dashboard-section">
                                    <div className="chart-placeholder">
                                        <h3>Donation Analytics</h3>
                                        <p>Chart visualization will be available once Chart.js is properly configured.</p>
                                        <div className="simple-stats">
                                            <div className="stat-item">
                                                <span className="stat-label">Total Donations:</span>
                                                <span className="stat-value">{analytics.totalDonations}</span>
                                            </div>
                                            <div className="stat-item">
                                                <span className="stat-label">Average Donation:</span>
                                                <span className="stat-value">₹{Math.round(analytics.totalDonated / analytics.totalDonations || 0)}</span>
                                            </div>
                                        </div>
                                    </div>
                                </div>

                                <div className="dashboard-section">
                                    <ImpactVisualization 
                                        impactMetrics={analytics.impactMetrics}
                                        efficiency={analytics.efficiency}
                                    />
                                </div>
                            </div>

                            <div className="dashboard-grid">
                                <div className="dashboard-section">
                                    <SubscriptionOverview 
                                        subscriptions={subscriptions}
                                        analytics={analytics}
                                    />
                                </div>

                                <div className="dashboard-section">
                                    <RecentDonations 
                                        donations={getFilteredDonations().slice(0, 10)}
                                    />
                                </div>
                            </div>

                            <QuickActions 
                                userProfile={userProfile}
                                analytics={analytics}
                            />
                        </>
                    )}
                </>
            )}
        </div>
    );
};

export default DonationDashboard;