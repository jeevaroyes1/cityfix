import React from 'react';
import './RecentDonations.css';

const RecentDonations = ({ donations }) => {
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
        return dateObj.toLocaleDateString('en-IN', {
            year: 'numeric',
            month: 'short',
            day: 'numeric'
        });
    };

    const getStatusColor = (status) => {
        switch (status) {
            case 'completed': return 'success';
            case 'pending': return 'warning';
            case 'failed': return 'error';
            default: return 'default';
        }
    };

    const getPaymentMethodIcon = (method) => {
        switch (method?.toLowerCase()) {
            case 'card': return '💳';
            case 'upi': return '📱';
            case 'netbanking': return '🏦';
            case 'wallet': return '👛';
            case 'paypal': return '🅿️';
            default: return '💰';
        }
    };

    const handleViewReceipt = (donation) => {
        if (donation.receiptId) {
            // In real implementation, would open receipt viewer or download PDF
            console.log('Viewing receipt for donation:', donation.id);
            alert('Receipt viewer will be implemented');
        } else {
            alert('Receipt not available for this donation');
        }
    };

    const handleViewImpact = (donation) => {
        // In real implementation, would show detailed impact breakdown
        console.log('Viewing impact for donation:', donation.id);
        alert('Impact details will be shown in a modal');
    };

    return (
        <div className="recent-donations">
            <div className="donations-header">
                <h3>Recent Donations</h3>
                <p>Your latest contributions</p>
            </div>

            {donations.length > 0 ? (
                <div className="donations-list">
                    {donations.map((donation) => (
                        <div key={donation.id} className="donation-item">
                            <div className="donation-main">
                                <div className="donation-center">
                                    <h4>{donation.centerName}</h4>
                                    <span className={`status-badge ${getStatusColor(donation.status)}`}>
                                        {donation.status}
                                    </span>
                                </div>
                                <div className="donation-details">
                                    <div className="donation-amount">
                                        {formatCurrency(donation.amount)}
                                    </div>
                                    <div className="donation-meta">
                                        <span className="donation-date">
                                            📅 {formatDate(donation.createdAt)}
                                        </span>
                                        <span className="donation-method">
                                            {getPaymentMethodIcon(donation.paymentMethod)} {donation.paymentMethod}
                                        </span>
                                        {donation.isRecurring && (
                                            <span className="recurring-badge">🔄 Recurring</span>
                                        )}
                                    </div>
                                </div>
                            </div>
                            
                            {donation.impactMetrics && donation.impactMetrics.length > 0 && (
                                <div className="donation-impact">
                                    <div className="impact-preview">
                                        {donation.impactMetrics.slice(0, 2).map((impact, index) => (
                                            <div key={index} className="impact-item">
                                                <span className="impact-quantity">{impact.quantity}</span>
                                                <span className="impact-unit">{impact.unit}</span>
                                                <span className="impact-category">
                                                    {impact.category.replace(/_/g, ' ')}
                                                </span>
                                            </div>
                                        ))}
                                        {donation.impactMetrics.length > 2 && (
                                            <div className="impact-more">
                                                +{donation.impactMetrics.length - 2} more
                                            </div>
                                        )}
                                    </div>
                                </div>
                            )}

                            <div className="donation-actions">
                                <button 
                                    onClick={() => handleViewReceipt(donation)}
                                    className="btn btn-outline btn-sm"
                                    disabled={!donation.receiptId}
                                >
                                    📄 Receipt
                                </button>
                                <button 
                                    onClick={() => handleViewImpact(donation)}
                                    className="btn btn-outline btn-sm"
                                >
                                    🌟 Impact
                                </button>
                                {donation.transactionId && (
                                    <div className="transaction-id">
                                        ID: {donation.transactionId.slice(-8)}
                                    </div>
                                )}
                            </div>
                        </div>
                    ))}
                </div>
            ) : (
                <div className="no-donations">
                    <div className="no-donations-icon">💝</div>
                    <h4>No Donations Yet</h4>
                    <p>Start making a difference in your community today.</p>
                    <button className="btn btn-primary">Make Your First Donation</button>
                </div>
            )}

            {donations.length > 0 && (
                <div className="donations-footer">
                    <button className="btn btn-outline">
                        View All Donations
                    </button>
                    <button className="btn btn-outline">
                        Download History
                    </button>
                </div>
            )}
        </div>
    );
};

export default RecentDonations;