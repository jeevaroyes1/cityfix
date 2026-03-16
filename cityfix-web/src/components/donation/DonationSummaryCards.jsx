import React from 'react';
import './DonationSummaryCards.css';

const DonationSummaryCards = ({ analytics, timeFilter }) => {
    const formatCurrency = (amount) => {
        return new Intl.NumberFormat('en-IN', {
            style: 'currency',
            currency: 'INR',
            minimumFractionDigits: 0,
            maximumFractionDigits: 0
        }).format(amount);
    };

    const getTimeFilterLabel = () => {
        switch (timeFilter) {
            case '30days': return 'Last 30 Days';
            case '90days': return 'Last 90 Days';
            case 'year': return 'This Year';
            default: return 'All Time';
        }
    };

    const cards = [
        {
            title: 'Total Donated',
            value: formatCurrency(analytics.totalDonated),
            icon: '💝',
            color: 'primary',
            subtitle: `${analytics.totalDonations} donations ${getTimeFilterLabel().toLowerCase()}`
        },
        {
            title: 'Tax Savings',
            value: formatCurrency(analytics.totalTaxSavings),
            icon: '💰',
            color: 'success',
            subtitle: 'Under Section 80G'
        },
        {
            title: 'Active Subscriptions',
            value: analytics.activeSubscriptions,
            icon: '🔄',
            color: 'info',
            subtitle: 'Recurring donations'
        },
        {
            title: 'Impact Score',
            value: analytics.impactMetrics?.length || 0,
            icon: '🌟',
            color: 'warning',
            subtitle: 'Categories impacted'
        }
    ];

    return (
        <div className="summary-cards">
            {cards.map((card, index) => (
                <div key={index} className={`summary-card ${card.color}`}>
                    <div className="card-icon">
                        <span>{card.icon}</span>
                    </div>
                    <div className="card-content">
                        <h3 className="card-title">{card.title}</h3>
                        <div className="card-value">{card.value}</div>
                        <p className="card-subtitle">{card.subtitle}</p>
                    </div>
                </div>
            ))}
        </div>
    );
};

export default DonationSummaryCards;