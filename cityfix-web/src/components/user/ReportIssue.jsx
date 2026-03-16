import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { createReport, checkDuplicateReport, getReportsByUser, updateReport, deleteReport } from '../../services/firestore';
import { uploadImage } from '../../services/cloudinary';
import { getCategoryList, getProblemTypes } from '../../utils/categories';
import LocationPicker from './LocationPicker';
import ErrorMessage from '../common/ErrorMessage';
import './ReportIssue.css';

const ReportIssue = () => {
    const { userProfile } = useAuth();
    const navigate = useNavigate();

    const [activeTab, setActiveTab] = useState('report');
    const [userReports, setUserReports] = useState([]);
    const [loadingReports, setLoadingReports] = useState(false);
    const [editingReportId, setEditingReportId] = useState(null);
    const [showReportIgnoredModal, setShowReportIgnoredModal] = useState(false);
    const [selectedReportForIgnored, setSelectedReportForIgnored] = useState(null);
    const [ignoredReason, setIgnoredReason] = useState('');

    const [formData, setFormData] = useState({
        category: '',
        problemType: '',
        location: '',
        latitude: null,
        longitude: null,
        description: '',
        imageFile: null,
        imagePreview: null
    });

    const [loading, setLoading] = useState(false);
    const [error, setError] = useState('');
    const [uploadingImage, setUploadingImage] = useState(false);
    const [showLocationPicker, setShowLocationPicker] = useState(false);

    // Load user reports
    useEffect(() => {
        if (activeTab === 'my-reports' && userProfile?.uid) {
            loadUserReports();
        }
    }, [activeTab, userProfile]);

    const loadUserReports = async () => {
        try {
            setLoadingReports(true);
            const reports = await getReportsByUser(userProfile.uid);
            setUserReports(reports);
        } catch (err) {
            console.error('Error loading reports:', err);
            setError('Failed to load your reports');
        } finally {
            setLoadingReports(false);
        }
    };

    const handleDeleteReport = async (reportId) => {
        if (!window.confirm('Are you sure you want to delete this report? This action cannot be undone.')) {
            return;
        }

        try {
            await deleteReport(reportId);
            setUserReports(prev => prev.filter(r => r.id !== reportId));
            alert('Report deleted successfully!');
        } catch (error) {
            console.error('Error deleting report:', error);
            setError('Failed to delete report. Please try again.');
        }
    };

    const handleEditReport = (report) => {
        setEditingReportId(report.id);
        setFormData({
            category: report.category,
            problemType: report.problemType,
            location: report.location,
            latitude: report.latitude,
            longitude: report.longitude,
            description: report.description,
            imageFile: null,
            imagePreview: report.imageUrl
        });
        setActiveTab('report');
        window.scrollTo(0, 0);
    };

    const handleReportIgnored = async () => {
        if (!ignoredReason.trim()) {
            setError('Please provide a reason for reporting this issue as ignored');
            return;
        }

        try {
            await updateReport(selectedReportForIgnored.id, {
                ignoredReport: true,
                ignoredReason: ignoredReason,
                ignoredAt: new Date(),
                status: 'Ignored'
            });

            setUserReports(prev => prev.map(r => 
                r.id === selectedReportForIgnored.id 
                    ? { ...r, ignoredReport: true, ignoredReason, status: 'Ignored' }
                    : r
            ));

            alert('Thank you for reporting this issue as ignored. We will review it.');
            setShowReportIgnoredModal(false);
            setIgnoredReason('');
            setSelectedReportForIgnored(null);
        } catch (error) {
            console.error('Error reporting ignored issue:', error);
            setError('Failed to report ignored issue. Please try again.');
        }
    };

    const handleCategoryChange = (e) => {
        setFormData(prev => ({
            ...prev,
            category: e.target.value,
            problemType: ''
        }));
    };

    const handleImageSelect = (e) => {
        const file = e.target.files[0];
        if (file) {
            if (file.size > 10 * 1024 * 1024) {
                setError('Image size should be less than 10MB');
                return;
            }

            setFormData(prev => ({
                ...prev,
                imageFile: file,
                imagePreview: URL.createObjectURL(file)
            }));
        }
    };

    const handleLocationSelect = (locationData) => {
        setFormData(prev => ({
            ...prev,
            location: locationData.address,
            latitude: locationData.lat,
            longitude: locationData.lng
        }));
        setShowLocationPicker(false);
    };

    const validateForm = () => {
        if (!formData.category) {
            setError('Please select a category');
            return false;
        }
        if (!formData.problemType) {
            setError('Please select a subcategory');
            return false;
        }
        if (!formData.location) {
            setError('Please select a location');
            return false;
        }
        if (!formData.description.trim()) {
            setError('Please provide a description');
            return false;
        }
        if (!formData.imageFile) {
            setError('Please upload an image of the issue');
            return false;
        }
        return true;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!validateForm()) return;

        try {
            setLoading(true);
            setError('');

            if (editingReportId) {
                // Update existing report
                let imageUrl = formData.imagePreview;
                if (formData.imageFile) {
                    setUploadingImage(true);
                    imageUrl = await uploadImage(formData.imageFile);
                    setUploadingImage(false);
                }

                await updateReport(editingReportId, {
                    title: formData.problemType,
                    category: formData.category,
                    problemType: formData.problemType,
                    location: formData.location,
                    latitude: formData.latitude,
                    longitude: formData.longitude,
                    description: formData.description,
                    imageUrl: imageUrl,
                    updatedAt: new Date()
                });

                setUserReports(prev => prev.map(r => 
                    r.id === editingReportId 
                        ? { ...r, ...formData, imageUrl }
                        : r
                ));

                alert('Report updated successfully!');
                setEditingReportId(null);
            } else {
                // Create new report
                const duplicateCheck = await checkDuplicateReport(
                    formData.latitude,
                    formData.longitude,
                    formData.problemType
                );

                if (duplicateCheck.isDuplicate) {
                    const existingReport = duplicateCheck.existingReport;
                    const message = `A similar issue has already been reported at this location:\n\n` +
                        `Type: ${existingReport.problemType}\n` +
                        `Location: ${existingReport.location}\n` +
                        `Status: ${existingReport.status || 'Pending'}\n` +
                        `Reported: ${existingReport.createdAt?.toDate?.().toLocaleDateString() || 'Recently'}\n\n` +
                        `Do you still want to submit a new report?`;
                    
                    if (!window.confirm(message)) {
                        setLoading(false);
                        setError('Report submission cancelled. A similar issue already exists at this location.');
                        return;
                    }
                }

                setUploadingImage(true);
                const imageUrl = await uploadImage(formData.imageFile);
                setUploadingImage(false);

                await createReport({
                    userId: userProfile.uid,
                    userName: userProfile.displayName,
                    userPhoto: userProfile.photoURL,
                    title: formData.problemType,
                    category: formData.category,
                    problemType: formData.problemType,
                    location: formData.location,
                    latitude: formData.latitude,
                    longitude: formData.longitude,
                    description: formData.description,
                    imageUrl: imageUrl
                });

                alert('Report submitted successfully!');
                setActiveTab('my-reports');
            }

            setFormData({
                category: '',
                problemType: '',
                location: '',
                latitude: null,
                longitude: null,
                description: '',
                imageFile: null,
                imagePreview: null
            });

            loadUserReports();
        } catch (error) {
            console.error('Error submitting report:', error);
            setError('Failed to submit report. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="report-issue-container">
            {/* Page Header */}
            <div className="ri-page-header">
                <div className="ri-header-content">
                    <h1>Report an Issue</h1>
                    <p>Help make your city better by reporting civic problems</p>
                </div>
            </div>

            {/* Welcome Card */}
            <div className="ri-welcome-card">
                <div className="ri-welcome-icon">
                    <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                        <path d="M9 11l3 3L22 4"></path>
                        <path d="M21 12a9 9 0 11-18 0 9 9 0 0118 0z"></path>
                    </svg>
                </div>
                <div className="ri-welcome-content">
                    <h2>Report Civic Issues</h2>
                    <p>Found a pothole, broken streetlight, or other civic issue? Report it here with photos and location details. Your reports help authorities prioritize maintenance and improvements.</p>
                </div>
            </div>

            {/* Info Cards */}
            <div className="ri-info-cards">
                <div className="ri-info-card card-blue">
                    <div className="card-icon">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <line x1="12" y1="2" x2="12" y2="22"></line>
                            <path d="M17 5H9.5a3.5 3.5 0 0 0 0 7h5a3.5 3.5 0 0 1 0 7H6"></path>
                        </svg>
                    </div>
                    <div className="card-content">
                        <h3>Total Reports</h3>
                        <p className="card-number">{userReports.length}</p>
                        <p className="card-desc">Issues you've reported</p>
                    </div>
                </div>
                <div className="ri-info-card card-green">
                    <div className="card-icon">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <polyline points="20 6 9 17 4 12"></polyline>
                        </svg>
                    </div>
                    <div className="card-content">
                        <h3>Resolved</h3>
                        <p className="card-number">{userReports.filter(r => r.status === 'Resolved').length}</p>
                        <p className="card-desc">Issues fixed</p>
                    </div>
                </div>
                <div className="ri-info-card card-orange">
                    <div className="card-icon">
                        <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <circle cx="12" cy="12" r="10"></circle>
                            <polyline points="12 6 12 12 16 14"></polyline>
                        </svg>
                    </div>
                    <div className="card-content">
                        <h3>In Progress</h3>
                        <p className="card-number">{userReports.filter(r => r.status === 'In Progress').length}</p>
                        <p className="card-desc">Being worked on</p>
                    </div>
                </div>
            </div>

            {/* Tabs */}
            <div className="ri-tabs">
                <button
                    className={`ri-tab ${activeTab === 'report' ? 'active' : ''}`}
                    onClick={() => setActiveTab('report')}
                >
                    <span className="tab-icon">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                        </svg>
                    </span>
                    Report Issue
                </button>
                <button
                    className={`ri-tab ${activeTab === 'my-reports' ? 'active' : ''}`}
                    onClick={() => setActiveTab('my-reports')}
                >
                    <span className="tab-icon">
                        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                            <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                            <polyline points="17 21 17 13 7 13 7 21"></polyline>
                            <polyline points="7 3 7 8 15 8"></polyline>
                        </svg>
                    </span>
                    My Reports
                </button>
            </div>

            <ErrorMessage message={error} onClose={() => setError('')} />

            {activeTab === 'report' ? (
                <div className="ri-form-card">
                    <form onSubmit={handleSubmit} className="report-form">
                        {editingReportId && (
                            <div className="edit-mode-banner">
                                <span>✎ Editing Report</span>
                                <button 
                                    type="button"
                                    className="cancel-edit-btn"
                                    onClick={() => {
                                        setEditingReportId(null);
                                        setFormData({
                                            category: '',
                                            problemType: '',
                                            location: '',
                                            latitude: null,
                                            longitude: null,
                                            description: '',
                                            imageFile: null,
                                            imagePreview: null
                                        });
                                    }}
                                >
                                    Cancel Edit
                                </button>
                            </div>
                        )}
                        <div className="form-section">
                            <h3>Basic Information</h3>
                            <div className="form-row">
                                <div className="form-group half">
                                    <label>Category *</label>
                                    <select value={formData.category} onChange={handleCategoryChange} required>
                                        <option value="">Select Category</option>
                                        {getCategoryList().map(cat => (
                                            <option key={cat} value={cat}>{cat}</option>
                                        ))}
                                    </select>
                                </div>
                                <div className="form-group half">
                                    <label>Subcategory *</label>
                                    <select
                                        value={formData.problemType}
                                        onChange={(e) => setFormData({ ...formData, problemType: e.target.value })}
                                        required
                                        disabled={!formData.category}
                                    >
                                        <option value="">Select Subcategory</option>
                                        {formData.category && getProblemTypes(formData.category).map(type => (
                                            <option key={type} value={type}>{type}</option>
                                        ))}
                                    </select>
                                </div>
                            </div>
                        </div>

                        <div className="form-section">
                            <h3>Location Details</h3>
                            <div className="form-row">
                                <div className="form-group full">
                                    <label>Location *</label>
                                    <div className="location-input-wrapper" onClick={() => setShowLocationPicker(true)}>
                                        <span className="icon">
                                            <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                                <path d="M21 10c0 7-9 13-9 13s-9-6-9-13a9 9 0 0 1 18 0z"></path>
                                                <circle cx="12" cy="10" r="3"></circle>
                                            </svg>
                                        </span>
                                        <input
                                            type="text"
                                            placeholder="Click to select location"
                                            value={formData.location}
                                            readOnly
                                            required
                                        />
                                    </div>
                                </div>
                            </div>
                        </div>

                        <div className="form-section">
                            <h3>Issue Description</h3>
                            <div className="form-row">
                                <div className="form-group full">
                                    <label>Description *</label>
                                    <textarea
                                        placeholder="Describe the issue in detail..."
                                        value={formData.description}
                                        onChange={(e) => setFormData({ ...formData, description: e.target.value })}
                                        rows="5"
                                        required
                                    />
                                </div>
                            </div>
                        </div>

                        <div className="form-section">
                            <h3>Photo Evidence</h3>
                            <div className="form-group full">
                                <label>Upload Photo *</label>
                                <div className="image-upload-zone">
                                    <input
                                        type="file"
                                        id="photo-upload"
                                        accept="image/*"
                                        onChange={handleImageSelect}
                                        hidden
                                    />
                                    <label htmlFor="photo-upload" className="upload-label">
                                        {formData.imagePreview ? (
                                            <div className="preview-container">
                                                <img src={formData.imagePreview} alt="Preview" />
                                                <div className="change-hint">Click to change image</div>
                                            </div>
                                        ) : (
                                            <div className="upload-placeholder">
                                                <span className="upload-icon">
                                                    <svg width="32" height="32" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                                        <path d="M21 15v4a2 2 0 0 1-2 2H5a2 2 0 0 1-2-2v-4"></path>
                                                        <polyline points="17 8 12 3 7 8"></polyline>
                                                        <line x1="12" y1="3" x2="12" y2="15"></line>
                                                    </svg>
                                                </span>
                                                <p><span>Upload a file</span> or drag and drop</p>
                                                <small>PNG, JPG, GIF up to 10MB</small>
                                            </div>
                                        )}
                                    </label>
                                </div>
                            </div>
                        </div>

                        <div className="form-actions">
                            <button 
                                type="button" 
                                className="btn-cancel" 
                                onClick={() => navigate('/dashboard')}
                            >
                                Cancel
                            </button>
                            <button type="submit" className="btn-submit" disabled={loading}>
                                {uploadingImage ? 'Uploading Image...' : loading ? 'Submitting...' : editingReportId ? 'Update Report' : 'Submit Report'}
                            </button>
                        </div>
                    </form>
                </div>
            ) : (
                <div className="ri-reports-list">
                    {loadingReports ? (
                        <div className="loading-text">Loading your reports...</div>
                    ) : userReports.length === 0 ? (
                        <div className="empty-state">
                            <div className="empty-icon">
                                <svg width="48" height="48" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                    <path d="M19 21H5a2 2 0 0 1-2-2V5a2 2 0 0 1 2-2h11l5 5v11a2 2 0 0 1-2 2z"></path>
                                    <polyline points="17 21 17 13 7 13 7 21"></polyline>
                                    <polyline points="7 3 7 8 15 8"></polyline>
                                </svg>
                            </div>
                            <h3>No reports yet</h3>
                            <p>Start by reporting your first issue to help improve your community!</p>
                        </div>
                    ) : (
                        <div className="reports-grid">
                            {userReports.map(report => (
                                <div key={report.id} className="report-card">
                                    <div className="report-header">
                                        <h3>{report.title}</h3>
                                        <span className={`status-badge status-${report.status?.toLowerCase().replace(' ', '-')}`}>
                                            {report.status || 'Pending'}
                                        </span>
                                    </div>
                                    {report.imageUrl && (
                                        <img src={report.imageUrl} alt={report.title} className="report-image" />
                                    )}
                                    <div className="report-details">
                                        <p><strong>Category:</strong> {report.category}</p>
                                        <p><strong>Type:</strong> {report.problemType}</p>
                                        <p><strong>Location:</strong> {report.location}</p>
                                        <p className="report-description">{report.description}</p>
                                        <p className="report-date">
                                            Reported: {report.createdAt?.toDate?.().toLocaleDateString() || 'Recently'}
                                        </p>
                                        {report.ignoredReport && (
                                            <div className="ignored-badge">
                                                ⚠ Reported as Ignored: {report.ignoredReason}
                                            </div>
                                        )}
                                    </div>
                                    <div className="report-actions">
                                        <button 
                                            className="action-btn edit-btn"
                                            onClick={() => handleEditReport(report)}
                                            title="Edit this report"
                                        >
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                                <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"></path>
                                                <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"></path>
                                            </svg>
                                            Edit
                                        </button>
                                        <button 
                                            className="action-btn delete-btn"
                                            onClick={() => handleDeleteReport(report.id)}
                                            title="Delete this report"
                                        >
                                            <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                                <polyline points="3 6 5 6 21 6"></polyline>
                                                <path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"></path>
                                                <line x1="10" y1="11" x2="10" y2="17"></line>
                                                <line x1="14" y1="11" x2="14" y2="17"></line>
                                            </svg>
                                            Delete
                                        </button>
                                        {report.status !== 'Resolved' && !report.ignoredReport && (
                                            <button 
                                                className="action-btn ignored-btn"
                                                onClick={() => {
                                                    setSelectedReportForIgnored(report);
                                                    setShowReportIgnoredModal(true);
                                                }}
                                                title="Report this issue as ignored"
                                            >
                                                <svg width="16" height="16" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                                    <path d="M10.29 3.86L1.82 18a2 2 0 0 0 1.71 3.05h16.94a2 2 0 0 0 1.71-3.05L13.71 3.86a2 2 0 0 0-3.42 0z"></path>
                                                    <line x1="12" y1="9" x2="12" y2="13"></line>
                                                    <line x1="12" y1="17" x2="12.01" y2="17"></line>
                                                </svg>
                                                Report Ignored
                                            </button>
                                        )}
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            )}

            {showLocationPicker && (
                <LocationPicker
                    onLocationSelect={handleLocationSelect}
                    onClose={() => setShowLocationPicker(false)}
                />
            )}

            {/* Report Ignored Modal */}
            {showReportIgnoredModal && (
                <div className="modal-overlay" onClick={() => setShowReportIgnoredModal(false)}>
                    <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                        <div className="modal-header">
                            <h2>Report Issue as Ignored</h2>
                            <button 
                                className="modal-close"
                                onClick={() => setShowReportIgnoredModal(false)}
                            >
                                <svg width="20" height="20" viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth="2">
                                    <line x1="18" y1="6" x2="6" y2="18"></line>
                                    <line x1="6" y1="6" x2="18" y2="18"></line>
                                </svg>
                            </button>
                        </div>
                        <div className="modal-body">
                            <p className="modal-description">
                                Help us improve by reporting issues that haven't received any action. Please provide details about why you believe this issue has been ignored.
                            </p>
                            <div className="form-group">
                                <label>Reason for reporting as ignored *</label>
                                <textarea
                                    placeholder="e.g., This pothole has been reported for 3 months with no repairs..."
                                    value={ignoredReason}
                                    onChange={(e) => setIgnoredReason(e.target.value)}
                                    rows="5"
                                />
                            </div>
                            <div className="modal-actions">
                                <button 
                                    className="btn-cancel"
                                    onClick={() => setShowReportIgnoredModal(false)}
                                >
                                    Cancel
                                </button>
                                <button 
                                    className="btn-submit"
                                    onClick={handleReportIgnored}
                                >
                                    Submit Report
                                </button>
                            </div>
                        </div>
                    </div>
                </div>
            )}
        </div>
    );
};

export default ReportIssue;
