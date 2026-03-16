import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { collection, query, where, getDocs, doc, updateDoc } from 'firebase/firestore';
import { db } from '../../config/firebase';
import { signOut } from 'firebase/auth';
import { auth } from '../../config/firebase';
import { useNavigate } from 'react-router-dom';
import { uploadImage } from '../../services/cloudinary';
import Loading from '../common/Loading';
import ErrorMessage from '../common/ErrorMessage';
import './UserProfile.css';

const UserProfile = () => {
    const { currentUser, userProfile } = useAuth();
    const navigate = useNavigate();
    const [reports, setReports] = useState([]);
    const [loading, setLoading] = useState(true);
    const [showSettings, setShowSettings] = useState(false);
    const [uploadingPhoto, setUploadingPhoto] = useState(false);
    const [error, setError] = useState('');
    const [editMode, setEditMode] = useState(false);
    const [profileData, setProfileData] = useState({
        displayName: '',
        phone: '',
        state: '',
        district: '',
        panchayat: '',
        ward: ''
    });

    useEffect(() => {
        loadUserData();
    }, [currentUser]);

    const loadUserData = async () => {
        if (!currentUser) return;

        try {
            // Load user reports
            const q = query(
                collection(db, 'reports'),
                where('userId', '==', currentUser.uid)
            );
            const snapshot = await getDocs(q);
            const reportsData = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            setReports(reportsData);

            // Load profile data
            if (userProfile) {
                setProfileData({
                    displayName: userProfile.displayName || '',
                    phone: userProfile.phone || '',
                    state: userProfile.state || '',
                    district: userProfile.district || '',
                    panchayat: userProfile.panchayat || '',
                    ward: userProfile.ward || ''
                });
            }

            setLoading(false);
        } catch (err) {
            console.error('Error loading user data:', err);
            setError('Failed to load profile data');
            setLoading(false);
        }
    };

    const handlePhotoUpload = async (e) => {
        const file = e.target.files[0];
        if (!file) return;

        if (file.size > 10 * 1024 * 1024) {
            setError('Image size should be less than 10MB');
            return;
        }

        try {
            setUploadingPhoto(true);
            setError('');
            
            const imageUrl = await uploadImage(file);
            
            const userRef = doc(db, 'users', currentUser.uid);
            await updateDoc(userRef, { photoURL: imageUrl });
            
            // Reload to get updated profile
            window.location.reload();
        } catch (err) {
            console.error('Error uploading photo:', err);
            setError('Failed to upload photo. Please try again.');
        } finally {
            setUploadingPhoto(false);
        }
    };

    const handleSaveProfile = async () => {
        try {
            setError('');
            const userRef = doc(db, 'users', currentUser.uid);
            await updateDoc(userRef, profileData);
            setEditMode(false);
            alert('Profile updated successfully!');
        } catch (err) {
            console.error('Error saving profile:', err);
            setError('Failed to save profile');
        }
    };

    const handleLogout = async () => {
        if (window.confirm('Are you sure you want to logout?')) {
            await signOut(auth);
            navigate('/');
        }
    };

    const totalReports = reports.length;
    const resolvedReports = reports.filter(r => 
        r.status === 'Resolved' || r.status === 'Completed'
    ).length;
    const pendingReports = reports.filter(r => r.status === 'Pending').length;
    const inProgressReports = reports.filter(r => 
        r.status === 'In Progress' || r.status === 'Assigned'
    ).length;

    if (loading) return <Loading message="Loading profile..." />;

    return (
        <div className="user-profile-container">
            <ErrorMessage message={error} onClose={() => setError('')} />

            {/* Profile Header Card */}
            <div className="profile-header-card">
                <div className="profile-cover"></div>
                <div className="profile-main">
                    <div className="profile-photo-section">
                        <div className="profile-photo-wrapper">
                            {userProfile?.photoURL ? (
                                <img src={userProfile.photoURL} alt="Profile" className="profile-photo" />
                            ) : (
                                <div className="profile-photo-placeholder">
                                    {profileData.displayName?.charAt(0)?.toUpperCase() || 
                                     currentUser.email?.charAt(0).toUpperCase()}
                                </div>
                            )}
                            <label className="photo-upload-btn" htmlFor="photo-upload">
                                {uploadingPhoto ? '⏳' : '📷'}
                            </label>
                            <input
                                type="file"
                                id="photo-upload"
                                accept="image/*"
                                onChange={handlePhotoUpload}
                                disabled={uploadingPhoto}
                                hidden
                            />
                        </div>
                    </div>
                    
                    <div className="profile-details">
                        <div className="profile-name-section">
                            <h1>{profileData.displayName || currentUser.email?.split('@')[0]}</h1>
                            <p className="profile-email">{currentUser.email}</p>
                            {profileData.phone && (
                                <p className="profile-phone">📱 {profileData.phone}</p>
                            )}
                            {profileData.panchayat && (
                                <p className="profile-location">📍 {profileData.panchayat}, {profileData.district}</p>
                            )}
                        </div>
                        <button 
                            className="btn-edit-profile"
                            onClick={() => setEditMode(true)}
                        >
                            ✏️ Edit Profile
                        </button>
                    </div>
                </div>
            </div>

            {/* Statistics Grid */}
            <div className="stats-grid">
                <div className="stat-card">
                    <div className="stat-icon total">📊</div>
                    <div className="stat-content">
                        <div className="stat-value">{totalReports}</div>
                        <div className="stat-label">Total Reports</div>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon pending">⏳</div>
                    <div className="stat-content">
                        <div className="stat-value">{pendingReports}</div>
                        <div className="stat-label">Pending</div>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon progress">🔄</div>
                    <div className="stat-content">
                        <div className="stat-value">{inProgressReports}</div>
                        <div className="stat-label">In Progress</div>
                    </div>
                </div>
                <div className="stat-card">
                    <div className="stat-icon resolved">✅</div>
                    <div className="stat-content">
                        <div className="stat-value">{resolvedReports}</div>
                        <div className="stat-label">Resolved</div>
                    </div>
                </div>
            </div>

            {/* Quick Actions */}
            <div className="quick-actions">
                <h3>Quick Actions</h3>
                <div className="actions-grid">
                    <button className="action-card" onClick={() => navigate('/report-issue')}>
                        <span className="action-icon">📷</span>
                        <span className="action-label">Report Issue</span>
                    </button>
                    <button className="action-card" onClick={() => navigate('/community-hub')}>
                        <span className="action-icon">🤝</span>
                        <span className="action-label">Community</span>
                    </button>
                    <button className="action-card" onClick={() => navigate('/volunteering')}>
                        <span className="action-icon">🙌</span>
                        <span className="action-label">Volunteer</span>
                    </button>
                    <button className="action-card logout-action" onClick={handleLogout}>
                        <span className="action-icon">🚪</span>
                        <span className="action-label">Logout</span>
                    </button>
                </div>
            </div>

            {/* Recent Activity */}
            <div className="recent-activity">
                <div className="section-header">
                    <h3>Recent Reports</h3>
                    <button className="btn-view-all" onClick={() => navigate('/dashboard')}>
                        View All →
                    </button>
                </div>
                
                {reports.length === 0 ? (
                    <div className="empty-state">
                        <div className="empty-icon">📋</div>
                        <p>No reports submitted yet</p>
                        <button 
                            className="btn-primary"
                            onClick={() => navigate('/report-issue')}
                        >
                            Report Your First Issue
                        </button>
                    </div>
                ) : (
                    <div className="activity-list">
                        {reports.slice(0, 5).map(report => (
                            <div key={report.id} className="activity-item">
                                {report.imageUrl && (
                                    <img src={report.imageUrl} alt="" className="activity-thumb" />
                                )}
                                <div className="activity-content">
                                    <div className="activity-header">
                                        <strong>{report.title || report.problemType}</strong>
                                        <span className={`status-badge status-${report.status?.toLowerCase().replace(' ', '-')}`}>
                                            {report.status}
                                        </span>
                                    </div>
                                    <p className="activity-location">📍 {report.location}</p>
                                    <p className="activity-category">{report.category} • {report.problemType}</p>
                                </div>
                            </div>
                        ))}
                    </div>
                )}
            </div>

            {/* Edit Profile Modal */}
            {editMode && (
                <div className="modal-overlay" onClick={() => setEditMode(false)}>
                    <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                        <div className="modal-header">
                            <h2>Edit Profile</h2>
                            <button className="modal-close" onClick={() => setEditMode(false)}>×</button>
                        </div>
                        <div className="modal-body">
                            <div className="form-group">
                                <label>Full Name</label>
                                <input
                                    type="text"
                                    value={profileData.displayName}
                                    onChange={(e) => setProfileData({ ...profileData, displayName: e.target.value })}
                                    placeholder="Enter your full name"
                                />
                            </div>
                            <div className="form-group">
                                <label>Phone Number</label>
                                <input
                                    type="tel"
                                    value={profileData.phone}
                                    onChange={(e) => setProfileData({ ...profileData, phone: e.target.value })}
                                    placeholder="Enter your phone number"
                                />
                            </div>
                            <div className="form-row">
                                <div className="form-group">
                                    <label>State</label>
                                    <input
                                        type="text"
                                        value={profileData.state}
                                        onChange={(e) => setProfileData({ ...profileData, state: e.target.value })}
                                        placeholder="State"
                                    />
                                </div>
                                <div className="form-group">
                                    <label>District</label>
                                    <input
                                        type="text"
                                        value={profileData.district}
                                        onChange={(e) => setProfileData({ ...profileData, district: e.target.value })}
                                        placeholder="District"
                                    />
                                </div>
                            </div>
                            <div className="form-row">
                                <div className="form-group">
                                    <label>Panchayat</label>
                                    <input
                                        type="text"
                                        value={profileData.panchayat}
                                        onChange={(e) => setProfileData({ ...profileData, panchayat: e.target.value })}
                                        placeholder="Panchayat"
                                    />
                                </div>
                                <div className="form-group">
                                    <label>Ward</label>
                                    <input
                                        type="text"
                                        value={profileData.ward}
                                        onChange={(e) => setProfileData({ ...profileData, ward: e.target.value })}
                                        placeholder="Ward"
                                    />
                                </div>
                            </div>
                        </div>
                        <div className="modal-actions">
                            <button className="btn-cancel" onClick={() => setEditMode(false)}>
                                Cancel
                            </button>
                            <button className="btn-submit" onClick={handleSaveProfile}>
                                Save Changes
                            </button>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default UserProfile;
