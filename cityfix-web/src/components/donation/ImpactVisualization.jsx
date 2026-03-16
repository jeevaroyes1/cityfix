import React from 'react';
import { impactService } from '../../services/donation/impactService';
import './ImpactVisualization.css';

const ImpactVisualization = ({ impactMetrics, efficiency }) => {
    const formatImpact = (impact) => {
        return impactService.formatImpactForDisplay(impact);
    };

    const getImpactColor = (category) => {
        const colorMap = {
            meals_served: '#f59e0b',
            children_educated: '#3b82f6',
            trees_planted: '#22c55e',
            animals_rescued: '#8b5cf6',
            medical_checkups: '#ef4444',
            healthcare_support: '#06b6d4',
            park_maintenance: '#84cc16',
            veterinary_treatments: '#f97316',
            awareness_programs: '#6366f1',
            waste_cleanup: '#10b981',
            clothing_provided: '#ec4899',
            food_provided: '#f59e0b',
            animals_adopted: '#8b5cf6',
            recreational_activities: '#14b8a6'
        };
        return colorMap[category] || '#6b7280';
    };

    const formattedImpact = formatImpact(impactMetrics || []);

    return (
        <div className="impact-visualization">
            <div className="impact-header">
                <h3>Your Impact</h3>
                <p>See the difference your donations have made</p>
            </div>

            {formattedImpact.length > 0 ? (
                <>
                    <div className="impact-grid">
                        {formattedImpact.map((impact, index) => (
                            <div key={index} className="impact-card">
                                <div 
                                    className="impact-icon"
                                    style={{ backgroundColor: getImpactColor(impact.category) }}
                                >
                                    <span>{impact.icon}</span>
                                </div>
                                <div className="impact-content">
                                    <div className="impact-quantity">{impact.formattedQuantity}</div>
                                    <div className="impact-label">{impact.label}</div>
                                    <div className="impact-description">{impact.description}</div>
                                </div>
                            </div>
                        ))}
                    </div>

                    {efficiency && efficiency.length > 0 && (
                        <div className="efficiency-section">
                            <h4>Impact Efficiency</h4>
                            <div className="efficiency-bars">
                                {efficiency.map((eff, index) => (
                                    <div key={index} className="efficiency-item">
                                        <div className="efficiency-label">
                                            {eff.category.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase())}
                                        </div>
                                        <div className="efficiency-bar">
                                            <div 
                                                className="efficiency-fill"
                                                style={{ 
                                                    width: `${Math.min(eff.impactPerRupee * 100, 100)}%`,
                                                    backgroundColor: getImpactColor(eff.category)
                                                }}
                                            ></div>
                                        </div>
                                        <div className="efficiency-value">
                                            {eff.impactPerRupee.toFixed(3)} {eff.unit}/₹
                                        </div>
                                    </div>
                                ))}
                            </div>
                        </div>
                    )}

                    <div className="impact-summary">
                        <div className="summary-item">
                            <span className="summary-icon">🎯</span>
                            <div>
                                <div className="summary-value">{formattedImpact.length}</div>
                                <div className="summary-label">Impact Categories</div>
                            </div>
                        </div>
                        <div className="summary-item">
                            <span className="summary-icon">📈</span>
                            <div>
                                <div className="summary-value">
                                    {formattedImpact.reduce((sum, impact) => sum + impact.quantity, 0).toLocaleString()}
                                </div>
                                <div className="summary-label">Total Impact Units</div>
                            </div>
                        </div>
                    </div>
                </>
            ) : (
                <div className="no-impact">
                    <div className="no-impact-icon">🌱</div>
                    <h4>Start Making an Impact</h4>
                    <p>Your donations will create measurable positive change in the community.</p>
                    <button className="btn btn-primary">Make Your First Donation</button>
                </div>
            )}
        </div>
    );
};

export default ImpactVisualization;