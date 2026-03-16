import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { getActiveWelfareCenters } from '../../data/welfareCenters';
import { PaymentService } from '../../services/donation/paymentService';
import { createDonation, processDonationWithImpact, subscribeToDonorDonations, subscribeToDonorSubscriptions } from '../../services/donation/donationService';
import { impactService } from '../../services/donation/impactService';
import { receiptGenerator } from '../../services/donation/receiptService';
import { subscriptionManager } from '../../services/donation/subscriptionService';
import { analyticsEngine } from '../../services/donation/analyticsService';
import Loading from '../common/Loading';
import ErrorMessage from '../common/ErrorMessage';
import DonationSummaryCards from '../donation/DonationSummaryCards';
import ImpactVisualization from '../donation/ImpactVisualization';
import RecentDonations from '../donation/RecentDonations';
import SubscriptionOverview from '../donation/SubscriptionOverview';
import './Donation.css';

const Donation = () => {
    const { currentUser: user, userProfile } = useAuth();
    const [selectedCenter, setSelectedCenter] = useState(null);
    const [amount, setAmount] = useState('');
    const [showPaymentModal, setShowPaymentModal] = useState(false);
    const [showSubscriptionModal, setShowSubscriptionModal] = useState(false);
    const [paymentGateway, setPaymentGateway] = useState('razorpay');
    const [isRecurring, setIsRecurring] = useState(false);
    const [frequency, setFrequency] = useState('monthly');
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [welfareCenters, setWelfareCenters] = useState([]);
    
    // Dashboard state
    const [analytics, setAnalytics] = useState(null);
    const [donations, setDonations] = useState([]);
    const [subscriptions, setSubscriptions] = useState([]);
    const [timeFilter, setTimeFilter] = useState('all');
    const [dashboardLoading, setDashboardLoading] = useState(true);

    useEffect(() => {
        const loadWelfareCenters = async () => {
            try {
                const centers = getActiveWelfareCenters();
                setWelfareCenters(centers);
            } catch (err) {
                console.error('Error loading welfare centers:', err);
                setError('Failed to load welfare centers');
            }
        };

        loadWelfareCenters();
    }, []);

    // Load user donations and subscriptions for dashboard
    useEffect(() => {
        if (!user?.uid) {
            setDashboardLoading(false);
            return;
        }

        const unsubscribeDonations = subscribeToDonorDonations(
            user.uid,
            (donationsData) => {
                setDonations(donationsData);
            },
            (err) => {
                console.error('Error fetching donations:', err);
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
                setSubscriptions([]);
            }
        );

        return () => {
            unsubscribeDonations();
            unsubscribeSubscriptions();
        };
    }, [user?.uid]);

    // Load analytics for dashboard
    useEffect(() => {
        if (!user?.uid) return;

        const loadAnalytics = async () => {
            try {
                setDashboardLoading(true);
                
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
            } finally {
                setDashboardLoading(false);
            }
        };

        loadAnalytics();
    }, [user?.uid, donations, subscriptions]);

    const handleDonate = async (center) => {
        setSelectedCenter(center);
        setShowPaymentModal(true);
    };

    const handleSubscribe = async (center) => {
        setSelectedCenter(center);
        setIsRecurring(true);
        setShowSubscriptionModal(true);
    };

    const processPayment = async () => {
        if (!amount || parseFloat(amount) <= 0) {
            setError('Please enter a valid amount');
            return;
        }

        if (!user?.uid) {
            setError('Please log in to make a donation');
            return;
        }

        try {
            setLoading(true);
            setError('');

            const donationAmount = parseFloat(amount);
            
            // Calculate impact
            const impactMetrics = impactService.calculateDonationImpact(donationAmount, selectedCenter.id);

            // Prepare donation data
            const donationData = {
                donorId: user.uid,
                donorEmail: user.email,
                donorName: userProfile?.name || user.displayName || 'Anonymous',
                centerId: selectedCenter.id,
                centerName: selectedCenter.name,
                amount: donationAmount,
                currency: 'INR',
                paymentGateway,
                isRecurring: false,
                impactMetrics
            };

            // Process payment
            const paymentResult = await PaymentService.processPayment({
                amount: donationAmount,
                gateway: paymentGateway,
                method: { type: 'card' }, // This would be selected by user
                metadata: {
                    description: `Donation to ${selectedCenter.name}`,
                    donorName: donationData.donorName,
                    donorEmail: donationData.donorEmail
                }
            });

            if (paymentResult.success) {
                // Create donation record with impact and receipt
                donationData.transactionId = paymentResult.transactionId;
                donationData.status = 'completed';
                donationData.paymentMethod = 'card'; // This would come from payment selection

                const receiptData = {
                    donorId: user.uid,
                    donorDetails: {
                        name: donationData.donorName,
                        email: donationData.donorEmail
                    }
                };

                const donationId = await processDonationWithImpact(donationData, {
                    centerId: selectedCenter.id,
                    impact: impactMetrics
                }, receiptData);

                // Generate receipt
                await receiptGenerator.generateReceipt(donationId);

                alert(`Payment Successful!\nTransaction ID: ${paymentResult.transactionId}\n\nThank you for your donation to ${selectedCenter.name}!\nYour receipt has been sent to your email.`);
                
                setShowPaymentModal(false);
                setAmount('');
                setSelectedCenter(null);
                
                // Scroll to dashboard section to show updated impact
                setTimeout(() => {
                    const dashboardSection = document.getElementById('dashboard-section');
                    if (dashboardSection) {
                        dashboardSection.scrollIntoView({ behavior: 'smooth' });
                    }
                }, 1000);
            } else {
                throw new Error(paymentResult.error || 'Payment failed');
            }
        } catch (err) {
            console.error('Payment error:', err);
            setError(err.message || 'Payment failed. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    const processSubscription = async () => {
        if (!amount || parseFloat(amount) <= 0) {
            setError('Please enter a valid amount');
            return;
        }

        if (!user?.uid) {
            setError('Please log in to create a subscription');
            return;
        }

        try {
            setLoading(true);
            setError('');

            const subscriptionData = {
                donorId: user.uid,
                donorEmail: user.email,
                donorName: userProfile?.name || user.displayName || 'Anonymous',
                centerId: selectedCenter.id,
                centerName: selectedCenter.name,
                amount: parseFloat(amount),
                currency: 'INR',
                frequency,
                paymentGateway,
                paymentMethod: 'card' // This would be selected by user
            };

            const subscriptionId = await subscriptionManager.createSubscription(subscriptionData);

            alert(`Subscription Created Successfully!\nSubscription ID: ${subscriptionId}\n\nYour ${frequency} donation of ₹${amount} to ${selectedCenter.name} has been set up.\nConfirmation email sent to ${user.email}.`);
            
            setShowSubscriptionModal(false);
            setAmount('');
            setSelectedCenter(null);
            setIsRecurring(false);
            
            // Scroll to dashboard section to show updated subscriptions
            setTimeout(() => {
                const dashboardSection = document.getElementById('dashboard-section');
                if (dashboardSection) {
                    dashboardSection.scrollIntoView({ behavior: 'smooth' });
                }
            }, 1000);
        } catch (err) {
            console.error('Subscription error:', err);
            setError(err.message || 'Failed to create subscription. Please try again.');
        } finally {
            setLoading(false);
        }
    };

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

    const supportedGateways = PaymentService.getSupportedGateways();

    if (loading) return <Loading message="Processing your donation..." />;

    return (
        <div className="donation-container">
            <div className="donation-header">
                <h1>Donate to Welfare</h1>
                <p>Support local welfare initiatives and make a difference in your community</p>
                {user && analytics && analytics.totalDonations > 0 && (
                    <div className="header-stats">
                        <div className="stat-item">
                            <span className="stat-value">₹{analytics.totalDonated.toLocaleString()}</span>
                            <span className="stat-label">Total Given</span>
                        </div>
                        <div className="stat-item">
                            <span className="stat-value">{analytics.totalDonations}</span>
                            <span className="stat-label">Donations</span>
                        </div>
                        <div className="stat-item">
                            <span className="stat-value">{analytics.impactMetrics?.length || 0}</span>
                            <span className="stat-label">Lives Impacted</span>
                        </div>
                    </div>
                )}
            </div>

            <ErrorMessage message={error} onClose={() => setError('')} />

            {/* Welcome message for new users */}
            {user && analytics && analytics.totalDonations === 0 && !dashboardLoading && (
                <div className="welcome-section">
                    <div className="welcome-content">
                        <h3>🌟 Welcome to Your Giving Journey!</h3>
                        <p>Start making a difference in your community. Your first donation will unlock your personal impact dashboard.</p>
                    </div>
                </div>
            )}

            {/* Dashboard Section - Show if user has donations */}
            {user && analytics && analytics.totalDonations > 0 && (
                <div id="dashboard-section" className="dashboard-section">
                    <div className="dashboard-header">
                        <div className="header-content">
                            <h2>📊 Your Impact Dashboard</h2>
                            <p>Track your giving journey and see the difference you're making</p>
                        </div>
                        <div className="header-actions">
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
                    </div>

                    <DonationSummaryCards 
                        analytics={analytics}
                        timeFilter={timeFilter}
                    />

                    <div className="dashboard-grid">
                        <div className="dashboard-card">
                            <ImpactVisualization 
                                impactMetrics={analytics.impactMetrics}
                                efficiency={analytics.efficiency}
                            />
                        </div>

                        <div className="dashboard-card">
                            <RecentDonations 
                                donations={getFilteredDonations().slice(0, 5)}
                            />
                        </div>
                    </div>

                    <div className="dashboard-grid">
                        <div className="dashboard-card">
                            <SubscriptionOverview 
                                subscriptions={subscriptions}
                                analytics={analytics}
                            />
                        </div>
                    </div>

                    <div className="continue-giving">
                        <h3>Ready to make another difference?</h3>
                        <p>Continue your giving journey below</p>
                        <div className="scroll-indicator">⬇️</div>
                    </div>
                </div>
            )}

            {/* Donation Centers Section */}
            <div className="donation-centers-section">
                <div className="section-header">
                    <h2>{user && analytics && analytics.totalDonations > 0 ? 'Continue Your Impact' : 'Choose a Cause to Support'}</h2>
                    <p>Every donation creates measurable impact in your community</p>
                </div>

                <div className="centers-grid">
                {welfareCenters.map((center) => (
                    <div key={center.id} className="center-card">
                        <div className="center-icon">{center.icon}</div>
                        <h3>{center.name}</h3>
                        <p className="center-short-desc">{center.shortDescription}</p>
                        <div className="center-info">
                            <span className="info-badge">
                                📅 Est. {center.founded}
                            </span>
                            <span className="info-badge">
                                👥 {center.members}
                            </span>
                            {center.isVerified && (
                                <span className="info-badge verified">
                                    ✅ Verified
                                </span>
                            )}
                        </div>
                        <p className="center-description">{center.description}</p>
                        <div className="center-location">
                            📍 {center.location.address}, {center.location.city}
                        </div>
                        
                        {/* Impact Preview */}
                        {center.impactMetrics && center.impactMetrics.length > 0 && (
                            <div className="impact-preview">
                                <h4>Your ₹100 can provide:</h4>
                                <div className="impact-items">
                                    {center.impactMetrics.slice(0, 2).map((metric, index) => (
                                        <div key={index} className="impact-item">
                                            <span className="impact-quantity">
                                                {Math.floor(100 / metric.costPerUnit)}
                                            </span>
                                            <span className="impact-unit">{metric.unit}</span>
                                        </div>
                                    ))}
                                </div>
                            </div>
                        )}

                        <div className="center-actions">
                            <button 
                                className="btn-donate"
                                onClick={() => handleDonate(center)}
                                disabled={loading}
                            >
                                💝 Donate Now
                            </button>
                            <button 
                                className="btn-subscribe"
                                onClick={() => handleSubscribe(center)}
                                disabled={loading}
                            >
                                🔄 Monthly Giving
                            </button>
                        </div>
                    </div>
                ))}
            </div>
            </div>

            {/* Payment Modal */}
            {showPaymentModal && selectedCenter && (
                <div className="modal-overlay" onClick={() => setShowPaymentModal(false)}>
                    <div className="modal-content payment-modal" onClick={(e) => e.stopPropagation()}>
                        <div className="modal-header">
                            <h2>Donate to {selectedCenter.name}</h2>
                            <button className="modal-close" onClick={() => setShowPaymentModal(false)}>×</button>
                        </div>
                        <div className="payment-form">
                            <div className="center-preview">
                                <div className="preview-icon">{selectedCenter.icon}</div>
                                <div>
                                    <h4>{selectedCenter.name}</h4>
                                    <p>{selectedCenter.shortDescription}</p>
                                </div>
                            </div>

                            {/* Payment Gateway Selection */}
                            <div className="form-group">
                                <label>Payment Method</label>
                                <div className="gateway-options">
                                    {supportedGateways.map(gateway => (
                                        <label key={gateway.id} className="gateway-option">
                                            <input
                                                type="radio"
                                                name="gateway"
                                                value={gateway.id}
                                                checked={paymentGateway === gateway.id}
                                                onChange={(e) => setPaymentGateway(e.target.value)}
                                            />
                                            <span>{gateway.name}</span>
                                            <small>({gateway.currency})</small>
                                        </label>
                                    ))}
                                </div>
                            </div>

                            <div className="form-group">
                                <label>Donation Amount (₹)</label>
                                <input
                                    type="number"
                                    placeholder="Enter amount"
                                    value={amount}
                                    onChange={(e) => setAmount(e.target.value)}
                                    min="1"
                                    step="1"
                                />
                            </div>
                            <div className="quick-amounts">
                                <button onClick={() => setAmount('100')}>₹100</button>
                                <button onClick={() => setAmount('500')}>₹500</button>
                                <button onClick={() => setAmount('1000')}>₹1000</button>
                                <button onClick={() => setAmount('5000')}>₹5000</button>
                            </div>

                            {/* Impact Preview */}
                            {amount && selectedCenter.impactMetrics && (
                                <div className="impact-preview-modal">
                                    <h4>Your Impact:</h4>
                                    <div className="impact-list">
                                        {impactService.calculateDonationImpact(parseFloat(amount) || 0, selectedCenter.id).map((impact, index) => (
                                            <div key={index} className="impact-item">
                                                <span className="impact-quantity">{impact.quantity}</span>
                                                <span className="impact-description">{impact.description}</span>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}

                            <button 
                                className="btn-proceed-payment" 
                                onClick={processPayment}
                                disabled={loading}
                            >
                                {loading ? 'Processing...' : `Proceed to Pay ₹${amount || '0'}`}
                            </button>
                            <p className="payment-note">
                                🔒 Secure payment • 📄 Receipt via email • 💰 Tax benefits under 80G
                            </p>
                        </div>
                    </div>
                </div>
            )}

            {/* Subscription Modal */}
            {showSubscriptionModal && selectedCenter && (
                <div className="modal-overlay" onClick={() => setShowSubscriptionModal(false)}>
                    <div className="modal-content payment-modal" onClick={(e) => e.stopPropagation()}>
                        <div className="modal-header">
                            <h2>Monthly Giving to {selectedCenter.name}</h2>
                            <button className="modal-close" onClick={() => setShowSubscriptionModal(false)}>×</button>
                        </div>
                        <div className="payment-form">
                            <div className="center-preview">
                                <div className="preview-icon">{selectedCenter.icon}</div>
                                <div>
                                    <h4>{selectedCenter.name}</h4>
                                    <p>{selectedCenter.shortDescription}</p>
                                </div>
                            </div>

                            <div className="form-group">
                                <label>Frequency</label>
                                <select 
                                    value={frequency} 
                                    onChange={(e) => setFrequency(e.target.value)}
                                    className="frequency-select"
                                >
                                    <option value="monthly">Monthly</option>
                                    <option value="quarterly">Quarterly</option>
                                    <option value="yearly">Yearly</option>
                                </select>
                            </div>

                            <div className="form-group">
                                <label>Amount per {frequency.slice(0, -2)} (₹)</label>
                                <input
                                    type="number"
                                    placeholder="Enter amount"
                                    value={amount}
                                    onChange={(e) => setAmount(e.target.value)}
                                    min="1"
                                    step="1"
                                />
                            </div>
                            <div className="quick-amounts">
                                <button onClick={() => setAmount('100')}>₹100</button>
                                <button onClick={() => setAmount('500')}>₹500</button>
                                <button onClick={() => setAmount('1000')}>₹1000</button>
                                <button onClick={() => setAmount('2000')}>₹2000</button>
                            </div>

                            {/* Annual Impact Preview */}
                            {amount && selectedCenter.impactMetrics && (
                                <div className="impact-preview-modal">
                                    <h4>Your Annual Impact:</h4>
                                    <div className="impact-list">
                                        {impactService.calculateDonationImpact(
                                            (parseFloat(amount) || 0) * (frequency === 'monthly' ? 12 : frequency === 'quarterly' ? 4 : 1), 
                                            selectedCenter.id
                                        ).map((impact, index) => (
                                            <div key={index} className="impact-item">
                                                <span className="impact-quantity">{impact.quantity}</span>
                                                <span className="impact-description">{impact.description}</span>
                                            </div>
                                        ))}
                                    </div>
                                </div>
                            )}

                            <button 
                                className="btn-proceed-payment" 
                                onClick={processSubscription}
                                disabled={loading}
                            >
                                {loading ? 'Creating...' : `Set up ${frequency} donation of ₹${amount || '0'}`}
                            </button>
                            <p className="payment-note">
                                🔄 Cancel anytime • 📧 Email reminders • 📊 Track your impact
                            </p>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Donation;
