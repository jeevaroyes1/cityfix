import React from 'react';
import { Link } from 'react-router-dom';
import './QuickActions.css';

const QuickActions = ({ userProfile, analytics }) => {
    const getRecommendedActions = () => {
        const actions = [];

        // If user has no donations, recommend first donation
        if (!analytics.totalDonations) {
            actions.push({
                title: 'Make Your First Donation',
                description: 'Start your journey of giving back to the community',
                icon: '🎯',
                action: 'donate',
                color: 'primary',
                priority: 1
            });
        }

        // If user has donations but no subscriptions, recommend recurring donation
        if (analytics.totalDonations > 0 && analytics.activeSubscriptions === 0) {
            actions.push({
                title: 'Set Up Recurring Donation',
                description: 'Make a consistent impact with monthly giving',
                icon: '🔄',
                action: 'subscribe',
                color: 'success',
                priority: 2
            });
        }

        // If user has preferred centers, recommend donating to them
        if (analytics.preferredCenters && analytics.preferredCenters.length > 0) {
            const topCenter = analytics.preferredCenters[0];
            actions.push({
                title: `Support ${topCenter.centerName}`,
                description: 'Continue supporting your favorite cause',
                icon: '❤️',
                action: 'donate-preferred',
                color: 'info',
                priority: 3,
                data: { centerId: topCenter.centerId }
            });
        }

        // Tax-related actions
        if (analytics.totalTaxSavings > 0) {
            actions.push({
                title: 'Download Tax Summary',
                description: 'Get your annual tax deduction summary',
                icon: '📊',
                action: 'tax-summary',
                color: 'warning',
                priority: 4
            });
        }

        // Impact sharing
        if (analytics.impactMetrics && analytics.impactMetrics.length > 0) {
            actions.push({
                title: 'Share Your Impact',
                description: 'Show others the difference you\'re making',
                icon: '📢',
                action: 'share-impact',
                color: 'secondary',
                priority: 5
            });
        }

        return actions.sort((a, b) => a.priority - b.priority).slice(0, 4);
    };

    const handleAction = (action) => {
        switch (action.action) {
            case 'donate':
                // Navigate to donation page
                window.location.href = '/donate';
                break;
            case 'subscribe':
                // Navigate to subscription creation
                window.location.href = '/donate?mode=subscription';
                break;
            case 'donate-preferred':
                // Navigate to specific center donation
                window.location.href = `/donate?center=${action.data.centerId}`;
                break;
            case 'tax-summary':
                handleDownloadTaxSummary();
                break;
            case 'share-impact':
                handleShareImpact();
                break;
            default:
                console.log('Unknown action:', action.action);
        }
    };

    const handleDownloadTaxSummary = async () => {
        try {
            // In real implementation, would call receipt service
            console.log('Downloading tax summary...');
            alert('Tax summary download will be implemented');
        } catch (error) {
            console.error('Error downloading tax summary:', error);
            alert('Failed to download tax summary');
        }
    };

    const handleShareImpact = () => {
        const impactText = `I've made a difference! Through CityFix, I've donated ₹${analytics.totalDonated.toLocaleString()} and impacted ${analytics.impactMetrics.length} different areas in our community. Join me in making a positive change! #CityFix #CommunityImpact`;
        
        if (navigator.share) {
            navigator.share({
                title: 'My Community Impact',
                text: impactText,
                url: window.location.origin
            });
        } else {
            // Fallback to clipboard
            navigator.clipboard.writeText(impactText).then(() => {
                alert('Impact summary copied to clipboard!');
            });
        }
    };

    const recommendedActions = getRecommendedActions();

    return (
        <div className="quick-actions">
            <div className="actions-header">
                <h3>Recommended Actions</h3>
                <p>Personalized suggestions based on your giving history</p>
            </div>

            <div className="actions-grid">
                {recommendedActions.map((action, index) => (
                    <div 
                        key={index} 
                        className={`action-card ${action.color}`}
                        onClick={() => handleAction(action)}
                    >
                        <div className="action-icon">
                            <span>{action.icon}</span>
                        </div>
                        <div className="action-content">
                            <h4 className="action-title">{action.title}</h4>
                            <p className="action-description">{action.description}</p>
                        </div>
                        <div className="action-arrow">→</div>
                    </div>
                ))}
            </div>

            <div className="additional-actions">
                <h4>More Actions</h4>
                <div className="additional-actions-list">
                    <Link to="/donate" className="additional-action">
                        <span className="action-icon">💝</span>
                        <span>Make a Donation</span>
                    </Link>
                    <Link to="/donation-history" className="additional-action">
                        <span className="action-icon">📋</span>
                        <span>View Full History</span>
                    </Link>
                    <Link to="/receipts" className="additional-action">
                        <span className="action-icon">📄</span>
                        <span>Manage Receipts</span>
                    </Link>
                    <Link to="/impact-report" className="additional-action">
                        <span className="action-icon">📊</span>
                        <span>Detailed Impact Report</span>
                    </Link>
                    <Link to="/settings" className="additional-action">
                        <span className="action-icon">⚙️</span>
                        <span>Donation Settings</span>
                    </Link>
                </div>
            </div>

            {analytics.donationFrequency && (
                <div className="giving-insights">
                    <h4>Your Giving Pattern</h4>
                    <div className="insights-summary">
                        <div className="insight-item">
                            <span className="insight-label">Giving Frequency:</span>
                            <span className="insight-value">
                                {analytics.donationFrequency.frequency} 
                                {analytics.donationFrequency.averageDaysBetween > 0 && 
                                    ` (every ${analytics.donationFrequency.averageDaysBetween} days)`
                                }
                            </span>
                        </div>
                        <div className="insight-item">
                            <span className="insight-label">Preferred Centers:</span>
                            <span className="insight-value">
                                {analytics.preferredCenters?.slice(0, 2).map(c => c.centerName).join(', ')}
                                {analytics.preferredCenters?.length > 2 && ` +${analytics.preferredCenters.length - 2} more`}
                            </span>
                        </div>
                        <div className="insight-item">
                            <span className="insight-label">Average Donation:</span>
                            <span className="insight-value">
                                ₹{Math.round(analytics.totalDonated / analytics.totalDonations).toLocaleString()}
                            </span>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default QuickActions;