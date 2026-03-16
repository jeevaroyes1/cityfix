import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { createNewsUpdate, getNewsUpdates } from '../../services/firestore';
import { uploadImage } from '../../services/cloudinary';
import { Filter } from 'bad-words';
import './NewsUpdates.css';

const profanityFilter = new Filter();

const NewsUpdates = () => {
    const { currentUser, userProfile } = useAuth();
    const navigate = useNavigate();

    const [activeTab, setActiveTab] = useState('list'); // 'list' or 'report'
    const [newsItems, setNewsItems] = useState([]);
    const [isLoadingNews, setIsLoadingNews] = useState(true);

    const [title, setTitle] = useState('');
    const [description, setDescription] = useState('');
    const [imageFile, setImageFile] = useState(null);
    const [imagePreview, setImagePreview] = useState(null);
    const [isLoading, setIsLoading] = useState(false);

    // Default importance as defined in the rules
    const [importance, setImportance] = useState('Low');

    const [snackbar, setSnackbar] = useState({ show: false, message: '', type: '' });

    const showSnackbar = (message, type = 'error') => {
        setSnackbar({ show: true, message, type });
        setTimeout(() => setSnackbar({ show: false, message: '', type: '' }), 3500);
    };

    useEffect(() => {
        const fetchNews = async () => {
            if (activeTab === 'list') {
                try {
                    setIsLoadingNews(true);
                    const fetchedNews = await getNewsUpdates();
                    setNewsItems(fetchedNews);
                } catch (error) {
                    console.error('Error fetching news:', error);
                    showSnackbar('Failed to fetch news updates');
                } finally {
                    setIsLoadingNews(false);
                }
            }
        };
        fetchNews();
    }, [activeTab]);

    const handleImageSelect = (e) => {
        const file = e.target.files[0];
        if (file) {
            if (file.size > 10 * 1024 * 1024) {
                showSnackbar('Image size should be less than 10MB');
                return;
            }
            setImageFile(file);
            setImagePreview(URL.createObjectURL(file));
        }
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (isLoading) return;

        if (!title.trim()) {
            showSnackbar('Please enter a news title');
            return;
        }

        if (profanityFilter.isProfane(title)) {
            showSnackbar('Title contains inappropriate language. Please revise.');
            return;
        }

        if (!description.trim()) {
            showSnackbar('Please enter a description');
            return;
        }

        if (profanityFilter.isProfane(description)) {
            showSnackbar('Description contains inappropriate language. Please revise.');
            return;
        }

        if (!imageFile) {
            showSnackbar('Please select an image for the news update');
            return;
        }

        try {
            setIsLoading(true);

            // Upload image to Cloudinary
            let imageUrl;
            try {
                imageUrl = await uploadImage(imageFile, 'news');
            } catch (uploadError) {
                showSnackbar('Failed to upload image. Please try again.');
                setIsLoading(false);
                return;
            }

            // Save to Firestore
            await createNewsUpdate({
                title: title.trim(),
                description: description.trim(),
                imageUrl,
                importance, // Store default importance
                userId: currentUser.uid,
                authorName: userProfile?.displayName || 'Anonymous Citizen',
                authorAvatar: userProfile?.photoURL || 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMjAiIGZpbGw9IiNFNUU3RUIiLz4KPHN2ZyB4PSI4IiB5PSI4IiB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSI+CjxwYXRoIGQ9Ik0xMiAxMkM5Ljc5IDEyIDggMTAuMjEgOCA4UzkuNzkgNDEyIDRTMTQuMjEgNiAxNiA4UzEyIDEwLjIxIDEyIDEyWk0xMiAxNEM3IDEzLjk5IDMgMTcuOTkgMyAyMlYyNEgyMVYyMkMxNyAxNy45OSAxMyAxMy45OSAxMiAxNFoiIGZpbGw9IiM5Q0E0QUYiLz4KPC9zdmc+Cjwvc3ZnPgo='
            });

            showSnackbar('News Update Reported Successfully!', 'success');

            // Reset form
            setTitle('');
            setDescription('');
            setImageFile(null);
            setImagePreview(null);

            // Switch to list tab to see the new post
            setTimeout(() => setActiveTab('list'), 1500);
        } catch (error) {
            console.error('Error submitting news update:', error);
            showSnackbar(error.message || 'Failed to submit. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="news-page">
            {/* Page Header */}
            <div className="news-page-header">
                <div className="news-header-content">
                    <h1>📰 News Updates</h1>
                    <p>Stay informed with the latest news from your community</p>
                </div>
            </div>

            {/* Welcome Card */}
            <div className="news-welcome-card">
                <div className="news-welcome-icon">📢</div>
                <div className="news-welcome-content">
                    <h2>Welcome to News Updates</h2>
                    <p>Stay connected with what's happening in your community. Read the latest news, important announcements, and updates from your neighbors. You can also share important news and updates with your community.</p>
                </div>
            </div>

            {/* Hero Banner */}
            <div className="news-hero-banner">
                <div className="news-hero-content">
                    <h2>📰 Stay Informed & Connected</h2>
                    <p>Read and share the latest news and updates from your community</p>
                </div>
            </div>

            <div className="news-appbar">
                <button className="news-back-btn" onClick={() => navigate(-1)}>←</button>
                <h1>{activeTab === 'list' ? 'News Updates' : 'Report News'}</h1>
            </div>

            <div className="news-tabs">
                <button
                    className={`news-tab ${activeTab === 'list' ? 'active' : ''}`}
                    onClick={() => setActiveTab('list')}
                >
                    🗞️ View News
                </button>
                <button
                    className={`news-tab ${activeTab === 'report' ? 'active' : ''}`}
                    onClick={() => setActiveTab('report')}
                >
                    ✍️ Report News
                </button>
            </div>

            {activeTab === 'list' ? (
                <div className="news-list-wrapper">
                    {isLoadingNews ? (
                        <div className="news-loading-text">Loading latest news...</div>
                    ) : newsItems.length === 0 ? (
                        <div className="news-empty-state">No news updates reported yet.</div>
                    ) : (
                        <div className="news-grid">
                            {newsItems.map(item => (
                                <div key={item.id} className="news-card">
                                    <img src={item.imageUrl} alt={item.title} className="news-image" />
                                    <div className="news-content">
                                        <div className="news-meta">
                                            <span className="news-date">
                                                {item.createdAt ? (item.createdAt.toDate ? item.createdAt.toDate().toLocaleDateString() : new Date(item.createdAt).toLocaleDateString()) : 'Just now'}
                                            </span>
                                            <span className={`news-importance ${item.importance}`}>
                                                {item.importance} Priority
                                            </span>
                                        </div>
                                        <h3 className="news-title">{item.title}</h3>
                                        <p className="news-desc">{item.description}</p>
                                        <div className="news-footer">
                                            <img src={item.authorAvatar} alt={item.authorName} className="news-author-avatar" />
                                            <span className="news-author-name">{item.authorName}</span>
                                        </div>
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            ) : (
                <div className="news-form-wrapper">
                    <form className="news-form" onSubmit={handleSubmit}>
                        <div className="news-image-section">
                            <span className="news-image-label">News Cover Image *</span>
                            <div className="news-image-upload">
                                <input
                                    type="file"
                                    id="news-photo-upload"
                                    accept="image/*"
                                    onChange={handleImageSelect}
                                    hidden
                                />
                                <label htmlFor="news-photo-upload" className="news-upload-trigger">
                                    {imagePreview ? (
                                        <div className="news-preview-wrapper">
                                            <img src={imagePreview} alt="Preview" />
                                            <div className="news-preview-overlay">Click to change format</div>
                                        </div>
                                    ) : (
                                        <div className="news-upload-placeholder">
                                            <span className="upload-emoji">📸</span>
                                            <p><span>Upload or capture</span> an image</p>
                                            <small>PNG, JPG up to 10MB</small>
                                        </div>
                                    )}
                                </label>
                            </div>
                        </div>

                        <div className="news-field">
                            <label htmlFor="news-title">Headline *</label>
                            <input
                                type="text"
                                id="news-title"
                                placeholder="Enter a news title..."
                                value={title}
                                onChange={(e) => setTitle(e.target.value)}
                                required
                            />
                        </div>

                        <div className="news-field">
                            <label htmlFor="news-description">Details *</label>
                            <textarea
                                id="news-description"
                                placeholder="Enter a news description..."
                                value={description}
                                onChange={(e) => setDescription(e.target.value)}
                                required
                            />
                        </div>

                        <div className="news-field">
                            <label htmlFor="news-importance">Importance Level</label>
                            <select
                                id="news-importance"
                                value={importance}
                                onChange={(e) => setImportance(e.target.value)}
                            >
                                <option value="Low">Low</option>
                                <option value="Medium">Medium</option>
                                <option value="High">High</option>
                            </select>
                        </div>

                        <button type="submit" className="news-submit-btn" disabled={isLoading}>
                            {isLoading ? (
                                <>
                                    <span className="news-spinner"></span>
                                    Publishing...
                                </>
                            ) : (
                                'Publish News'
                            )}
                        </button>
                    </form>
                </div>
            )}

            {snackbar.show && (
                <div className={`news-snackbar ${snackbar.type}`}>
                    {snackbar.message}
                </div>
            )}
        </div>
    );
};

export default NewsUpdates;
