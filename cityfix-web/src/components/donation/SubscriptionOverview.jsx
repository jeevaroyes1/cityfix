import React, { useState } from 'react';
import { subscriptionManager } from '../../services/donation/subscriptionService';
import './SubscriptionOverview.css';

const SubscriptionOverview = ({ subscriptions, analytics }) => {
    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');

    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(amount);
    };

    const formatDate = (date) => {
        if (!date) return 'N/A';
        const dateObj = date.toDate ? date.toDate() : new Date(date);
        return dateObj.toLocaleDateString('en-IN');
    };

    const getStatusColor = (status) => {
        switch (status) {
            case 'active': return 'success';
            case 'paused': return 'warning';
            case 'cancelled': return 'error';
            default: return 'default';
        }
    };

    const getFrequencyLabel = (frequency) => {
        switch (frequency) {
            case 'monthly': return 'Monthly';
            case 'quarterly': return 'Quarterly';
            case 'yearly': return 'Yearly';
            default: return frequency;
        }
    };

    const handlePauseSubscription = async (subscriptionId) => {
        try {
            setLoading(true);
            const pauseUntil = new Date();
            pauseUntil.setMonth(pauseUntil.getMonth() + 1); // Pause for 1 month
            
            await subscriptionManager.pauseSubscription(subscriptionId, pauseUntil);
            // The subscription will be updated via real-time listener
        } catch (err) {
            console.error('Error pausing subscription:', err);
            setError('Failed to pause subscription');
        } finally {
            setLoading(false);
        }
    };

    const handleResumeSubscription = async (subscriptionId) => {
        try {
            setLoading(true);
            await subscriptionManager.resumeSubscription(subscriptionId);
            // The subscription will be updated via real-time listener
        } catch (err) {
            console.error('Error resuming subscription:', err);
            setError('Failed to resume subscription');
        } finally {
            setLoading(false);
        }
    };

    const handleCancelSubscription = async (subscriptionId) => {
        if (!confirm('Are you sure you want to cancel this subscription?')) {
            return;
        }

        try {
            setLoading(true);
            await subscriptionManager.cancelSubscription(subscriptionId, 'User requested cancellation');
            // The subscription will be updated via real-time listener
        } catch (err) {
            console.error('Error cancelling subscription:', err);
            setError('Failed to cancel subscription');
        } finally {
            setLoading(false);
        }
    };

    const activeSubscriptions = subscriptions.filter(s => s.status === 'active');
    const totalMonthlyCommitment = activeSubscriptions.reduce((sum, sub) => {
        const monthlyAmount = sub.frequency === 'monthly' ? sub.amount :
                            sub.frequency === 'quarterly' ? sub.amount / 3 :
                            sub.amount / 12;
        return sum + monthlyAmount;
    }, 0);

    return (
        <div className="subscription-overview">
            <div className="subscription-header">
                <h3>Recurring Donations</h3>
                <p>Manage your subscription donations</p>
            </div>

            {error && (
                <div className="error-message">
                    {error}
                    <button onClick={() => setError('')} className="error-close">×</button>
                </div>
            )}

            <div className="subscription-summary">
                <div className="summary-card">
                    <div className="summary-icon">🔄</div>
                    <div className="summary-content">
                        <div className="summary-value">{activeSubscriptions.length}</div>
                        <div className="summary-label">Active Subscriptions</div>
                    </div>
                </div>
                <div className="summary-card">
                    <div className="summary-icon">💰</div>
                    <div className="summary-content">
                        <div className="summary-value">{formatCurrency(totalMonthlyCommitment)}</div>
                        <div className="summary-label">Monthly Commitment</div>
                    </div>
                </div>
            </div>

            {subscriptions.length > 0 ? (
                <div className="subscriptions-list">
                    {subscriptions.map((subscription) => (
                        <div key={subscription.id} className="subscription-card">
                            <div className="subscription-info">
                                <div className="subscription-center">
                                    <h4>{subscription.centerName}</h4>
                                    <span className={`status-badge ${getStatusColor(subscription.status)}`}>
                                        {subscription.status}
                                    </span>
                                </div>
                                <div className="subscription-details">
                                    <div className="detail-item">
                                        <span className="detail-label">Amount:</span>
                                        <span className="detail-value">{formatCurrency(subscription.amount)}</span>
                                    </div>
                                    <div className="detail-item">
                                        <span className="detail-label">Frequency:</span>
                                        <span className="detail-value">{getFrequencyLabel(subscription.frequency)}</span>
                                    </div>
                                    <div className="detail-item">
                                        <span className="detail-label">Next Payment:</span>
                                        <span className="detail-value">{formatDate(subscription.nextPaymentDate)}</span>
                                    </div>
                                    <div className="detail-item">
                                        <span className="detail-label">Total Donated:</span>
                                        <span className="detail-value">{formatCurrency(subscription.totalAmount)}</span>
                                    </div>
                                </div>
                            </div>
                            <div className="subscription-actions">
                                {subscription.status === 'active' && (
                                    <>
                                        <button 
                                            onClick={() => handlePauseSubscription(subscription.id)}
                                            disabled={loading}
                                            className="btn btn-outline btn-sm"
                                        >
                                            ⏸️ Pause
                                        </button>
                                        <button 
                                            onClick={() => handleCancelSubscription(subscription.id)}
                                            disabled={loading}
                                            className="btn btn-outline btn-sm btn-danger"
                                        >
                                            ❌ Cancel
                                        </button>
                                    </>
                                )}
                                {subscription.status === 'paused' && (
                                    <button 
                                        onClick={() => handleResumeSubscription(subscription.id)}
                                        disabled={loading}
                                        className="btn btn-primary btn-sm"
                                    >
                                        ▶️ Resume
                                    </button>
                                )}
                                <button className="btn btn-outline btn-sm">
                                    ⚙️ Modify
                                </button>
                            </div>
                        </div>
                    ))}
                </div>
            ) : (
                <div className="no-subscriptions">
                    <div className="no-subscriptions-icon">🔄</div>
                    <h4>No Recurring Donations</h4>
                    <p>Set up recurring donations to make a consistent impact.</p>
                    <button className="btn btn-primary">Create Subscription</button>
                </div>
            )}

            {subscriptions.length > 0 && (
                <div className="subscription-insights">
                    <h4>Subscription Insights</h4>
                    <div className="insights-grid">
                        <div className="insight-item">
                            <span className="insight-icon">📊</span>
                            <div>
                                <div className="insight-value">
                                    {subscriptions.reduce((sum, s) => sum + s.totalDonations, 0)}
                                </div>
                                <div className="insight-label">Total Recurring Donations</div>
                            </div>
                        </div>
                        <div className="insight-item">
                            <span className="insight-icon">💎</span>
                            <div>
                                <div className="insight-value">
                                    {formatCurrency(subscriptions.reduce((sum, s) => sum + s.totalAmount, 0))}
                                </div>
                                <div className="insight-label">Total Recurring Amount</div>
                            </div>
                        </div>
                        <div className="insight-item">
                            <span className="insight-icon">⏱️</span>
                            <div>
                                <div className="insight-value">
                                    {Math.round(subscriptions.reduce((sum, s) => {
                                        const days = (new Date() - (s.createdAt?.toDate ? s.createdAt.toDate() : new Date(s.createdAt))) / (1000 * 60 * 60 * 24);
                                        return sum + days;
                                    }, 0) / subscriptions.length)}
                                </div>
                                <div className="insight-label">Avg. Days Active</div>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default SubscriptionOverview;