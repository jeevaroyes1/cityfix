import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { subscribeToAllReports } from '../../services/firestore';
import './IssuesNearMe.css';

const IssuesNearMe = () => {
    const navigate = useNavigate();
    const [reports, setReports] = useState([]);
    const [nearbyReports, setNearbyReports] = useState([]);
    const [userLocation, setUserLocation] = useState(null);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');

    // Get user location on mount
    useEffect(() => {
        if (navigator.geolocation) {
            navigator.geolocation.getCurrentPosition(
                (position) => {
                    setUserLocation({
                        lat: position.coords.latitude,
                        lng: position.coords.longitude
                    });
                },
                (error) => {
                    console.log('Geolocation error:', error);
                    setError('Unable to access your location. Please enable location services.');
                    setLoading(false);
                }
            );
        } else {
            setError('Geolocation is not supported by your browser.');
            setLoading(false);
        }
    }, []);

    // Fetch all reports
    useEffect(() => {
        const unsubscribe = subscribeToAllReports(
            (allReports) => {
                setReports(allReports);
                setLoading(false);
            },
            (err) => {
                console.error('Error fetching reports:', err);
                setError('Failed to load nearby issues.');
                setLoading(false);
            }
        );

        return () => unsubscribe();
    }, []);

    // Calculate distance between two coordinates (in km)
    const calculateDistance = (lat1, lon1, lat2, lon2) => {
        const R = 6371; // Earth's radius in km
        const dLat = (lat2 - lat1) * Math.PI / 180;
        const dLon = (lon2 - lon1) * Math.PI / 180;
        const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
            Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
            Math.sin(dLon / 2) * Math.sin(dLon / 2);
        const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
        return R * c;
    };

    // Get nearby reports (within 5 km)
    const getNearbyReports = () => {
        if (!userLocation) return [];
        return reports.filter(report => {
            if (!report.latitude || !report.longitude) return false;
            const distance = calculateDistance(
                userLocation.lat,
                userLocation.lng,
                report.latitude,
                report.longitude
            );
            return distance <= 5; // 5 km radius
        }).sort((a, b) => {
            const distA = calculateDistance(
                userLocation.lat,
                userLocation.lng,
                a.latitude,
                a.longitude
            );
            const distB = calculateDistance(
                userLocation.lat,
                userLocation.lng,
                b.latitude,
                b.longitude
            );
            return distA - distB;
        });
    };

    // Update nearby reports when reports or location changes
    useEffect(() => {
        if (userLocation) {
            setNearbyReports(getNearbyReports());
        }
    }, [reports, userLocation]);

    const getStatusClass = (status) => {
        switch (status) {
            case 'Pending': return 'status-pending';
            case 'In Progress': return 'status-progress';
            case 'Resolved': return 'status-resolved';
            default: return '';
        }
    };

    if (loading) {
        return (
            <div className="issues-near-me-container">
                <div className="loading">Loading nearby issues...</div>
            </div>
        );
    }

    return (
        <div className="issues-near-me-container">
            <div className="inm-header">
                <button className="back-btn" onClick={() => navigate('/dashboard')}>
                    ← Back
                </button>
                <h1>◈ Issues Near You</h1>
                <p className="inm-subtitle">Problems reported within 5 km of your location</p>
            </div>

            {error && (
                <div className="error-message">
                    <p>{error}</p>
                </div>
            )}

            {!userLocation ? (
                <div className="no-location">
                    <p>📍 Please enable location access to see nearby issues</p>
                </div>
            ) : nearbyReports.length === 0 ? (
                <div className="no-issues">
                    <p>No issues reported within 5 km of your location</p>
                </div>
            ) : (
                <div className="issues-list">
                    {nearbyReports.map(report => {
                        const distance = calculateDistance(
                            userLocation.lat,
                            userLocation.lng,
                            report.latitude,
                            report.longitude
                        );
                        return (
                            <div key={report.id} className="issue-item">
                                <div className="issue-image">
                                    <img src={report.imageUrl} alt={report.title} />
                                    <span className={`status-badge ${getStatusClass(report.status)}`}>
                                        {report.status}
                                    </span>
                                </div>
                                <div className="issue-details">
                                    <div className="issue-header">
                                        <h3>{report.title}</h3>
                                        <span className="distance">▬ {distance.toFixed(1)} km away</span>
                                    </div>
                                    <p className="category">{report.category} • {report.problemType}</p>
                                    <p className="location">◈ {report.location}</p>
                                    <p className="description">{report.description}</p>
                                    <div className="issue-meta">
                                        <span className="user">By {report.userName || 'Citizen'}</span>
                                    </div>
                                </div>
                            </div>
                        );
                    })}
                </div>
            )}
        </div>
    );
};

export default IssuesNearMe;
