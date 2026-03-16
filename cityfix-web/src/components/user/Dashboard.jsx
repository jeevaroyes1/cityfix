import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { subscribeToAllReports } from '../../services/firestore';
import Loading from '../common/Loading';
import ErrorMessage from '../common/ErrorMessage';
import { getCategoryList } from '../../utils/categories';
import './Dashboard.css';

const Dashboard = () => {
    const { userProfile, currentUser } = useAuth();
    const [reports, setReports] = useState([]);
    const [filteredReports, setFilteredReports] = useState([]);
    const [activeFilter, setActiveFilter] = useState('All');
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [userLocation, setUserLocation] = useState(null);
    const [nearbyReports, setNearbyReports] = useState([]);

    const filters = ['All', ...getCategoryList()];

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
                }
            );
        }
    }, []);

    useEffect(() => {
        const unsubscribe = subscribeToAllReports(
            (allReports) => {
                setReports(allReports);
                setFilteredReports(allReports);
                setLoading(false);
            },
            (err) => {
                console.error('Error fetching reports:', err);
                setError('Failed to load community feed.');
                setLoading(false);
            }
        );

        return () => unsubscribe();
    }, []);

    useEffect(() => {
        if (activeFilter === 'All') {
            setFilteredReports(reports);
        } else {
            setFilteredReports(reports.filter(r => r.category === activeFilter));
        }
    }, [activeFilter, reports]);

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

    const getTimeAgo = (timestamp) => {
        if (!timestamp) return 'Just now';
        const seconds = Math.floor((new Date() - (timestamp.toDate ? timestamp.toDate() : new Date(timestamp))) / 1000);
        let interval = seconds / 31536000;
        if (interval > 1) return Math.floor(interval) + " years ago";
        interval = seconds / 2592000;
        if (interval > 1) return Math.floor(interval) + " months ago";
        interval = seconds / 86400;
        if (interval > 1) return Math.floor(interval) + " days ago";
        interval = seconds / 3600;
        if (interval > 1) return Math.floor(interval) + " hours ago";
        interval = seconds / 60;
        if (interval > 1) return Math.floor(interval) + " minutes ago";
        return Math.floor(seconds) + " seconds ago";
    };

    if (loading) return <Loading message="Loading city highlights..." />;

    return (
        <div className="dashboard-container">
            {/* Welcome Section */}
            <section className="dashboard-welcome">
                <div className="welcome-content">
                    <h1>Welcome back, <span className="highlight">{userProfile?.name || 'Citizen'}</span>!</h1>
                    <p>Ready to make a difference in your community today?</p>
                </div>
            </section>

            {/* Nearby Issues Section - Removed */}

            {/* Issues Near You Action Card */}
            {userLocation && nearbyReports.length > 0 && (
                <Link to="/issues-near-me" className="action-card nearby-action">
                    <div className="action-icon">◈</div>
                    <div className="action-content">
                        <h3>Issues Near You</h3>
                        <p>{nearbyReports.length} problem{nearbyReports.length !== 1 ? 's' : ''} reported nearby</p>
                    </div>
                    <button className="action-btn">View All →</button>
                </Link>
            )}

            {/* Stats Cards Section */}
            <div className="stats-cards-section">
                <div className="stat-card">
                    <div className="stat-icon">⚠</div>
                    <div className="stat-content">
                        <h4>Your Reports</h4>
                        <p className="stat-number">{reports.filter(r => r.userId === currentUser?.uid).length}</p>
                        <p className="stat-label">Issues you've reported</p>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon">✓</div>
                    <div className="stat-content">
                        <h4>Resolved This Week</h4>
                        <p className="stat-number">{reports.filter(r => {
                            if (r.status !== 'Resolved') return false;
                            const reportDate = r.createdAt?.toDate ? r.createdAt.toDate() : new Date(r.createdAt);
                            const weekAgo = new Date();
                            weekAgo.setDate(weekAgo.getDate() - 7);
                            return reportDate >= weekAgo;
                        }).length}</p>
                        <p className="stat-label">Issues resolved this week</p>
                    </div>
                </div>
            </div>

            {/* Community Feed */}
            <section className="community-feed">
                <div className="feed-header">
                    <h2>Community Feed</h2>
                    <div className="feed-filters">
                        {filters.map(filter => (
                            <button
                                key={filter}
                                className={`filter-btn ${activeFilter === filter ? 'active' : ''}`}
                                onClick={() => setActiveFilter(filter)}
                            >
                                {filter}
                            </button>
                        ))}
                    </div>
                </div>

                <ErrorMessage message={error} onClose={() => setError('')} />

                <div className="reports-grid">
                    {filteredReports.map(report => (
                        <div key={report.id} className="report-card">
                            <div className="card-media">
                                <img src={report.imageUrl} alt={report.problemType} />
                                <span className={`status-badge ${getStatusClass(report.status)}`}>
                                    {report.status}
                                </span>
                                <div className="card-location">
                                    <span className="icon">◈</span> {report.location}
                                </div>
                            </div>
                            <div className="card-body">
                                <div className="card-meta">
                                    <span className="category">{report.category}</span>
                                    <span className="separator">•</span>
                                    <span className="time">{getTimeAgo(report.createdAt)}</span>
                                </div>
                                <h3 className="card-title">{report.problemType}</h3>
                                <p className="card-description">{report.description}</p>
                            </div>
                            <div className="card-footer">
                                <div className="user-info">
                                    <img src={report.userPhoto || 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMTIiIGN5PSIxMiIgcj0iMTIiIGZpbGw9IiNFNUU3RUIiLz4KPHN2ZyB4PSI0IiB5PSI0IiB3aWR0aD0iMTYiIGhlaWdodD0iMTYiIHZpZXdCb3g9IjAgMCAxNiAxNiIgZmlsbD0ibm9uZSI+CjxwYXRoIGQ9Ik04IDhDNi45IDggNiA3LjEgNiA2UzYuOSA0IDggNFM5LjEgNSAxMCA2UzggNy4xIDggOFpNOCAxMEM1IDkuOTkgMiAxMS45OSAyIDE0VjE2SDE0VjE0QzEwIDExLjk5IDYgOS45OSA4IDEwWiIgZmlsbD0iIzlDQTRBRiIvPgo8L3N2Zz4KPC9zdmc+Cg=='} alt="User" />
                                    <span>{report.userName || 'Citizen'}</span>
                                </div>
                                <div className="card-actions">
                                    <button className="icon-btn"><span className="icon">👍</span> 12</button>
                                    <button className="icon-btn"><span className="icon">💬</span> 3</button>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>

                {filteredReports.length === 0 && (
                    <div className="empty-feed">
                        <p>No reports found in this category.</p>
                    </div>
                )}
            </section>

            {/* Available Services Section */}
            <section className="available-services">
                <div className="services-header">
                    <h2><span className="star-icon">✦</span> Available Services</h2>
                </div>
                
                <div className="services-grid">
                    <Link to="/report-issue" className="service-card">
                        <div className="service-icon">⚠</div>
                        <h3>Report Issue</h3>
                        <p>Report civic problems in your area</p>
                    </Link>

                    <Link to="/community-hub" className="service-card">
                        <div className="service-icon">◈</div>
                        <h3>Community Hub</h3>
                        <p>Connect with your community</p>
                    </Link>

                    <Link to="/lost-found" className="service-card">
                        <div className="service-icon">◉</div>
                        <h3>Lost & Found</h3>
                        <p>Find or report lost items</p>
                    </Link>

                    <Link to="/volunteering" className="service-card">
                        <div className="service-icon">✦</div>
                        <h3>Volunteering</h3>
                        <p>Join community service events</p>
                    </Link>

                    <Link to="/news-updates" className="service-card">
                        <div className="service-icon">▬</div>
                        <h3>News Updates</h3>
                        <p>Stay informed with local news</p>
                    </Link>

                    <Link to="/donation" className="service-card">
                        <div className="service-icon">♡</div>
                        <h3>Donation</h3>
                        <p>Support community causes</p>
                    </Link>

                    <Link to="/helpline" className="service-card">
                        <div className="service-icon">◎</div>
                        <h3>Helpline</h3>
                        <p>Emergency contacts & support</p>
                    </Link>

                    <Link to="/profile" className="service-card">
                        <div className="service-icon">◐</div>
                        <h3>My Profile</h3>
                        <p>Manage your account settings</p>
                    </Link>
                </div>
            </section>

            {/* Nearby Issues Modal - Removed, now on separate page */}
        </div>
    );
};

export default Dashboard;
