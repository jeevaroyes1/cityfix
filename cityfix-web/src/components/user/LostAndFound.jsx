import React, { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { getUserPanchayat, createLostAndFoundItem, updateLostAndFoundItem, getLostAndFoundItems } from '../../services/firestore';
import { uploadImage } from '../../services/cloudinary';
import { Filter } from 'bad-words';
import './LostAndFound.css';

const profanityFilter = new Filter();

const LostAndFound = () => {
    const { currentUser } = useAuth();
    const navigate = useNavigate();

    const [imageFile, setImageFile] = useState(null);
    const [imagePreview, setImagePreview] = useState(null);
    const [itemName, setItemName] = useState('');
    const [foundLocation, setFoundLocation] = useState('');
    const [dateFound, setDateFound] = useState('');
    const [description, setDescription] = useState('');
    const [contactEmail, setContactEmail] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const [activeTab, setActiveTab] = useState('list'); // 'list' or 'report'
    const [items, setItems] = useState([]);
    const [filteredItems, setFilteredItems] = useState([]);
    const [isLoadingItems, setIsLoadingItems] = useState(true);
    const [snackbar, setSnackbar] = useState({ show: false, message: '', type: '' });
    const [editingItem, setEditingItem] = useState(null);
    const [showEditModal, setShowEditModal] = useState(false);
    
    // Search and filter states
    const [searchText, setSearchText] = useState('');
    const [dateFrom, setDateFrom] = useState('');
    const [dateTo, setDateTo] = useState('');
    const [statusFilter, setStatusFilter] = useState('All');
    const [showFilters, setShowFilters] = useState(false);

    const showSnackbar = (message, type = 'error') => {
        setSnackbar({ show: true, message, type });
        setTimeout(() => setSnackbar({ show: false, message: '', type: '' }), 3500);
    };

    useEffect(() => {
        const fetchItems = async () => {
            if (activeTab === 'list') {
                try {
                    setIsLoadingItems(true);
                    const fetchedItems = await getLostAndFoundItems();
                    setItems(fetchedItems);
                    setFilteredItems(fetchedItems);
                } catch (error) {
                    console.error('Error fetching items:', error);
                    showSnackbar('Failed to fetch items');
                } finally {
                    setIsLoadingItems(false);
                }
            }
        };
        fetchItems();
    }, [activeTab]);

    // Filter items based on search criteria
    useEffect(() => {
        let filtered = [...items];

        // Text search
        if (searchText.trim()) {
            filtered = filtered.filter(item =>
                (item.itemName && item.itemName.toLowerCase().includes(searchText.toLowerCase())) ||
                (item.foundLocation && item.foundLocation.toLowerCase().includes(searchText.toLowerCase())) ||
                item.description.toLowerCase().includes(searchText.toLowerCase()) ||
                item.contactEmail.toLowerCase().includes(searchText.toLowerCase())
            );
        }

        // Date range filter
        if (dateFrom) {
            filtered = filtered.filter(item => {
                const itemDate = new Date(item.dateFound);
                const fromDate = new Date(dateFrom);
                return itemDate >= fromDate;
            });
        }

        if (dateTo) {
            filtered = filtered.filter(item => {
                const itemDate = new Date(item.dateFound);
                const toDate = new Date(dateTo);
                return itemDate <= toDate;
            });
        }

        // Status filter
        if (statusFilter !== 'All') {
            filtered = filtered.filter(item => item.status === statusFilter);
        }

        setFilteredItems(filtered);
    }, [items, searchText, dateFrom, dateTo, statusFilter]);

    const clearFilters = () => {
        setSearchText('');
        setDateFrom('');
        setDateTo('');
        setStatusFilter('All');
    };

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

    const validateEmail = (email) => {
        const emailRegex = /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/;
        return emailRegex.test(email);
    };

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (isLoading) return;

        // Validate image
        if (!imageFile) {
            showSnackbar('Please select an image of the found item');
            return;
        }

        // Validate item name
        if (!itemName.trim()) {
            showSnackbar('Please enter the name of the item');
            return;
        }

        // Profanity check for item name
        if (profanityFilter.isProfane(itemName)) {
            showSnackbar('Item name contains inappropriate language. Please revise.');
            return;
        }

        // Validate location
        if (!foundLocation.trim()) {
            showSnackbar('Please enter where you found the item');
            return;
        }

        // Profanity check for location
        if (profanityFilter.isProfane(foundLocation)) {
            showSnackbar('Location contains inappropriate language. Please revise.');
            return;
        }

        // Validate date
        if (!dateFound) {
            showSnackbar('Please select the date found');
            return;
        }

        // Validate description
        if (!description.trim()) {
            showSnackbar('Please enter a description');
            return;
        }

        // Profanity check
        if (profanityFilter.isProfane(description)) {
            showSnackbar('Description contains inappropriate language. Please revise.');
            return;
        }

        // Validate email
        if (!contactEmail.trim()) {
            showSnackbar('Please enter a contact email');
            return;
        }
        if (!validateEmail(contactEmail)) {
            showSnackbar('Please enter a valid email address');
            return;
        }

        try {
            setIsLoading(true);

            // Fetch user panchayat
            const panchayat = await getUserPanchayat(currentUser.uid);
            if (!panchayat) {
                showSnackbar('Could not retrieve your panchayat. Please update your profile.');
                setIsLoading(false);
                return;
            }

            // Upload image to Cloudinary
            let imageUrl;
            try {
                imageUrl = await uploadImage(imageFile, 'report');
            } catch (uploadError) {
                showSnackbar('Failed to upload image. Please try again.');
                setIsLoading(false);
                return;
            }

            // Save to Firestore
            await createLostAndFoundItem({
                itemName: itemName.trim(),
                foundLocation: foundLocation.trim(),
                description: description.trim(),
                dateFound,
                contactEmail: contactEmail.trim(),
                imageUrl,
                status: 'Open',
                userId: currentUser.uid,
                panchayat
            });

            showSnackbar('Lost Item Reported Successfully!', 'success');
            setTimeout(() => navigate(-1), 1500);
        } catch (error) {
            console.error('Error submitting lost item:', error);
            showSnackbar(error.message || 'Failed to submit. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    const today = new Date().toISOString().split('T')[0];

    const handleEditClick = (item) => {
        setEditingItem(item);
        setItemName(item.itemName || '');
        setFoundLocation(item.foundLocation || '');
        setDescription(item.description);
        setDateFound(item.dateFound);
        setContactEmail(item.contactEmail);
        setImagePreview(item.imageUrl);
        setImageFile(null);
        setShowEditModal(true);
    };

    const handleCancelEdit = () => {
        setEditingItem(null);
        setItemName('');
        setFoundLocation('');
        setDescription('');
        setDateFound('');
        setContactEmail('');
        setImagePreview(null);
        setImageFile(null);
        setShowEditModal(false);
    };

    const handleUpdateSubmit = async (e) => {
        e.preventDefault();
        if (isLoading) return;

        // Validate item name
        if (!itemName.trim()) {
            showSnackbar('Please enter the name of the item');
            return;
        }

        // Profanity check for item name
        if (profanityFilter.isProfane(itemName)) {
            showSnackbar('Item name contains inappropriate language. Please revise.');
            return;
        }

        // Validate location
        if (!foundLocation.trim()) {
            showSnackbar('Please enter where you found the item');
            return;
        }

        // Profanity check for location
        if (profanityFilter.isProfane(foundLocation)) {
            showSnackbar('Location contains inappropriate language. Please revise.');
            return;
        }

        // Validate description
        if (!description.trim()) {
            showSnackbar('Please enter a description');
            return;
        }

        // Profanity check
        if (profanityFilter.isProfane(description)) {
            showSnackbar('Description contains inappropriate language. Please revise.');
            return;
        }

        // Validate date
        if (!dateFound) {
            showSnackbar('Please select the date found');
            return;
        }

        // Validate email
        if (!contactEmail.trim()) {
            showSnackbar('Please enter a contact email');
            return;
        }
        if (!validateEmail(contactEmail)) {
            showSnackbar('Please enter a valid email address');
            return;
        }

        try {
            setIsLoading(true);

            let imageUrl = editingItem.imageUrl;

            // Upload new image if changed
            if (imageFile) {
                try {
                    imageUrl = await uploadImage(imageFile, 'report');
                } catch (uploadError) {
                    showSnackbar('Failed to upload image. Please try again.');
                    setIsLoading(false);
                    return;
                }
            }

            // Update in Firestore
            await updateLostAndFoundItem(editingItem.id, {
                itemName: itemName.trim(),
                foundLocation: foundLocation.trim(),
                description: description.trim(),
                dateFound,
                contactEmail: contactEmail.trim(),
                imageUrl
            });

            showSnackbar('Item Updated Successfully!', 'success');
            
            // Refresh items list
            const fetchedItems = await getLostAndFoundItems();
            setItems(fetchedItems);
            setFilteredItems(fetchedItems);
            
            handleCancelEdit();
        } catch (error) {
            console.error('Error updating item:', error);
            showSnackbar(error.message || 'Failed to update. Please try again.');
        } finally {
            setIsLoading(false);
        }
    };

    return (
        <div className="lf-page">
            {/* Page Header */}
            <div className="lf-page-header">
                <div className="lf-header-content">
                    <h1>🔍 Lost & Found</h1>
                    <p>Help reunite lost items with their owners in your community</p>
                </div>
            </div>

            {/* Welcome Card */}
            <div className="lf-welcome-card">
                <div className="lf-welcome-icon">📦</div>
                <div className="lf-welcome-content">
                    <h2>Welcome to Lost & Found</h2>
                    <p>Found something that doesn't belong to you? Report it here and help someone recover their lost items. Browse through items found in your area and reconnect them with their owners.</p>
                </div>
            </div>

            {/* Hero Banner */}
            <div className="lf-hero-banner">
                <div className="lf-hero-content">
                    <h2>🔍 Help Reunite Lost Items with Their Owners</h2>
                    <p>Found something? Report it here and help someone find what they've lost!</p>
                </div>
            </div>

            {/* Info Cards */}
            <div className="lf-info-cards">
                <div className="lf-info-card card-green">
                    <div className="card-icon">✅</div>
                    <div className="card-content">
                        <h3>Items Reported</h3>
                        <p className="card-number">{items.length}</p>
                        <p className="card-desc">Total found items in your area</p>
                    </div>
                </div>
                <div className="lf-info-card card-blue">
                    <div className="card-icon">📋</div>
                    <div className="card-content">
                        <h3>Your Reports</h3>
                        <p className="card-number">{items.filter(item => item.userId === currentUser.uid).length}</p>
                        <p className="card-desc">Items you've reported</p>
                    </div>
                </div>
                <div className="lf-info-card card-orange">
                    <div className="card-icon">🎯</div>
                    <div className="card-content">
                        <h3>Active Cases</h3>
                        <p className="card-number">{items.filter(item => item.status === 'Open').length}</p>
                        <p className="card-desc">Still looking for owners</p>
                    </div>
                </div>
            </div>

            {/* Tabs */}
            <div className="lf-tabs">
                <button
                    className={`lf-tab ${activeTab === 'list' ? 'active' : ''}`}
                    onClick={() => setActiveTab('list')}
                >
                    View Items
                </button>
                <button
                    className={`lf-tab ${activeTab === 'report' ? 'active' : ''}`}
                    onClick={() => setActiveTab('report')}
                >
                    Report Item
                </button>
            </div>

            {activeTab === 'list' ? (
                <div className="lf-list-wrapper">
                    {/* Search and Filter Section */}
                    <div className="lf-search-section">
                        <div className="lf-search-bar">
                            <div className="lf-search-input-wrapper">
                                <input
                                    type="text"
                                    placeholder="Search by item name, location, description, or contact email..."
                                    value={searchText}
                                    onChange={(e) => setSearchText(e.target.value)}
                                    className="lf-search-input"
                                />
                                <span className="lf-search-icon">🔍</span>
                            </div>
                            <button 
                                className={`lf-filter-toggle ${showFilters ? 'active' : ''}`}
                                onClick={() => setShowFilters(!showFilters)}
                            >
                                🔧 Filters
                            </button>
                        </div>

                        {showFilters && (
                            <div className="lf-filters-panel">
                                <div className="lf-filters-row">
                                    <div className="lf-filter-group">
                                        <label>Date From:</label>
                                        <input
                                            type="date"
                                            value={dateFrom}
                                            onChange={(e) => setDateFrom(e.target.value)}
                                            className="lf-date-input"
                                        />
                                    </div>
                                    <div className="lf-filter-group">
                                        <label>Date To:</label>
                                        <input
                                            type="date"
                                            value={dateTo}
                                            onChange={(e) => setDateTo(e.target.value)}
                                            className="lf-date-input"
                                        />
                                    </div>
                                    <div className="lf-filter-group">
                                        <label>Status:</label>
                                        <select
                                            value={statusFilter}
                                            onChange={(e) => setStatusFilter(e.target.value)}
                                            className="lf-status-select"
                                        >
                                            <option value="All">All Status</option>
                                            <option value="Open">Open</option>
                                            <option value="Closed">Closed</option>
                                        </select>
                                    </div>
                                    <div className="lf-filter-actions">
                                        <button 
                                            onClick={clearFilters}
                                            className="lf-clear-filters-btn"
                                        >
                                            Clear All
                                        </button>
                                    </div>
                                </div>
                                <div className="lf-filter-summary">
                                    Showing {filteredItems.length} of {items.length} items
                                    {(searchText || dateFrom || dateTo || statusFilter !== 'All') && (
                                        <span className="lf-active-filters">
                                            {searchText && <span className="lf-filter-tag">Text: "{searchText}"</span>}
                                            {dateFrom && <span className="lf-filter-tag">From: {dateFrom}</span>}
                                            {dateTo && <span className="lf-filter-tag">To: {dateTo}</span>}
                                            {statusFilter !== 'All' && <span className="lf-filter-tag">Status: {statusFilter}</span>}
                                        </span>
                                    )}
                                </div>
                            </div>
                        )}
                    </div>

                    {isLoadingItems ? (
                        <div className="lf-loading-text">Loading items...</div>
                    ) : filteredItems.length === 0 ? (
                        <div className="lf-empty-state">
                            {items.length === 0 ? 
                                'No items have been reported yet.' : 
                                'No items match your search criteria. Try adjusting your filters.'
                            }
                        </div>
                    ) : (
                        <div className="lf-items-grid">
                            {filteredItems.map(item => (
                                <div key={item.id} className="lf-item-card">
                                    <div className="lf-item-image">
                                        <img src={item.imageUrl} alt="Found item" />
                                        {item.status && (
                                            <span className={`lf-item-status ${item.status.toLowerCase()}`}>
                                                {item.status}
                                            </span>
                                        )}
                                    </div>
                                    <div className="lf-item-content">
                                        <div className="lf-item-header">
                                            <h3 className="lf-item-name">{item.itemName || 'Unnamed Item'}</h3>
                                            <div className="lf-item-date">{item.dateFound ? new Date(item.dateFound).toLocaleDateString() : 'Unknown Date'}</div>
                                        </div>
                                        {item.foundLocation && (
                                            <div className="lf-item-location">
                                                <span className="location-icon">📍</span>
                                                <span className="location-text">{item.foundLocation}</span>
                                            </div>
                                        )}
                                        <p className="lf-item-desc">{item.description}</p>
                                        <div className="lf-item-contact">
                                            Contact:{' '}
                                            <a href={`mailto:${item.contactEmail}`} onClick={(e) => e.stopPropagation()}>
                                                {item.contactEmail}
                                            </a>
                                        </div>
                                        {item.userId === currentUser.uid && (
                                            <button 
                                                className="lf-edit-btn"
                                                onClick={() => handleEditClick(item)}
                                            >
                                                ✏️ Edit
                                            </button>
                                        )}
                                    </div>
                                </div>
                            ))}
                        </div>
                    )}
                </div>
            ) : (
                <div className="lf-form-wrapper">
                    <form className="lf-form" onSubmit={handleSubmit}>
                        {/* Image Upload */}
                        <div className="lf-image-section">
                            <span className="lf-image-label">Photo of Item *</span>
                            <div className="lf-image-upload">
                                <input
                                    type="file"
                                    id="lf-photo-upload"
                                    accept="image/*"
                                    onChange={handleImageSelect}
                                    hidden
                                />
                                <label htmlFor="lf-photo-upload" className="lf-upload-trigger">
                                    {imagePreview ? (
                                        <div className="lf-preview-wrapper">
                                            <img src={imagePreview} alt="Preview" />
                                            <div className="lf-preview-overlay">Click to change</div>
                                        </div>
                                    ) : (
                                        <div className="lf-upload-placeholder">
                                            <span className="upload-emoji">📷</span>
                                            <p><span>Upload a photo</span> of the found item</p>
                                            <small>PNG, JPG, GIF up to 10MB</small>
                                        </div>
                                    )}
                                </label>
                            </div>
                        </div>

                        {/* Item Name */}
                        <div className="lf-field">
                            <label htmlFor="lf-item-name">Item Name *</label>
                            <input
                                type="text"
                                id="lf-item-name"
                                placeholder="e.g., iPhone, Wallet, Keys, etc."
                                value={itemName}
                                onChange={(e) => setItemName(e.target.value)}
                                required
                            />
                        </div>

                        {/* Found Location */}
                        <div className="lf-field">
                            <label htmlFor="lf-location">Found Location *</label>
                            <input
                                type="text"
                                id="lf-location"
                                placeholder="e.g., Near City Park, Main Street Bus Stop, etc."
                                value={foundLocation}
                                onChange={(e) => setFoundLocation(e.target.value)}
                                required
                            />
                        </div>

                        {/* Date Found */}
                        <div className="lf-field">
                            <label htmlFor="lf-date">Date Found *</label>
                            <input
                                type="date"
                                id="lf-date"
                                value={dateFound}
                                onChange={(e) => setDateFound(e.target.value)}
                                min="2000-01-01"
                                max={today}
                                required
                            />
                        </div>

                        {/* Description */}
                        <div className="lf-field">
                            <label htmlFor="lf-description">Description *</label>
                            <textarea
                                id="lf-description"
                                placeholder="Describe the found item in detail..."
                                value={description}
                                onChange={(e) => setDescription(e.target.value)}
                                required
                            />
                        </div>

                        {/* Contact Email */}
                        <div className="lf-field">
                            <label htmlFor="lf-email">Contact Email *</label>
                            <input
                                type="email"
                                id="lf-email"
                                placeholder="your.email@example.com"
                                value={contactEmail}
                                onChange={(e) => setContactEmail(e.target.value)}
                                required
                            />
                        </div>

                        {/* Submit Button */}
                        <button type="submit" className="lf-submit-btn" disabled={isLoading}>
                            {isLoading ? (
                                <>
                                    <span className="lf-spinner"></span>
                                    Submitting...
                                </>
                            ) : (
                                'Submit Report'
                            )}
                        </button>
                    </form>
                </div>
            )}

            {/* Snackbar */}
            {snackbar.show && (
                <div className={`lf-snackbar ${snackbar.type}`}>
                    {snackbar.message}
                </div>
            )}

            {/* Edit Modal */}
            {showEditModal && (
                <div className="lf-modal-overlay" onClick={handleCancelEdit}>
                    <div className="lf-modal-content" onClick={(e) => e.stopPropagation()}>
                        <div className="lf-modal-header">
                            <h2>Edit Item</h2>
                            <button className="lf-modal-close" onClick={handleCancelEdit}>×</button>
                        </div>
                        <form className="lf-modal-form" onSubmit={handleUpdateSubmit}>
                            {/* Image Upload */}
                            <div className="lf-image-section">
                                <span className="lf-image-label">Photo of Item</span>
                                <div className="lf-image-upload">
                                    <input
                                        type="file"
                                        id="lf-edit-photo-upload"
                                        accept="image/*"
                                        onChange={handleImageSelect}
                                        hidden
                                    />
                                    <label htmlFor="lf-edit-photo-upload" className="lf-upload-trigger">
                                        {imagePreview ? (
                                            <div className="lf-preview-wrapper">
                                                <img src={imagePreview} alt="Preview" />
                                                <div className="lf-preview-overlay">Click to change</div>
                                            </div>
                                        ) : (
                                            <div className="lf-upload-placeholder">
                                                <span className="upload-emoji">📷</span>
                                                <p>Upload a photo</p>
                                            </div>
                                        )}
                                    </label>
                                </div>
                            </div>

                            {/* Item Name */}
                            <div className="lf-field">
                                <label htmlFor="lf-edit-item-name">Item Name *</label>
                                <input
                                    type="text"
                                    id="lf-edit-item-name"
                                    placeholder="e.g., iPhone, Wallet, Keys, etc."
                                    value={itemName}
                                    onChange={(e) => setItemName(e.target.value)}
                                    required
                                />
                            </div>

                            {/* Found Location */}
                            <div className="lf-field">
                                <label htmlFor="lf-edit-location">Found Location *</label>
                                <input
                                    type="text"
                                    id="lf-edit-location"
                                    placeholder="e.g., Near City Park, Main Street Bus Stop, etc."
                                    value={foundLocation}
                                    onChange={(e) => setFoundLocation(e.target.value)}
                                    required
                                />
                            </div>

                            {/* Date Found */}
                            <div className="lf-field">
                                <label htmlFor="lf-edit-date">Date Found *</label>
                                <input
                                    type="date"
                                    id="lf-edit-date"
                                    value={dateFound}
                                    onChange={(e) => setDateFound(e.target.value)}
                                    min="2000-01-01"
                                    max={today}
                                    required
                                />
                            </div>

                            {/* Description */}
                            <div className="lf-field">
                                <label htmlFor="lf-edit-description">Description *</label>
                                <textarea
                                    id="lf-edit-description"
                                    placeholder="Describe the found item in detail..."
                                    value={description}
                                    onChange={(e) => setDescription(e.target.value)}
                                    required
                                />
                            </div>

                            {/* Contact Email */}
                            <div className="lf-field">
                                <label htmlFor="lf-edit-email">Contact Email *</label>
                                <input
                                    type="email"
                                    id="lf-edit-email"
                                    placeholder="your.email@example.com"
                                    value={contactEmail}
                                    onChange={(e) => setContactEmail(e.target.value)}
                                    required
                                />
                            </div>

                            {/* Action Buttons */}
                            <div className="lf-modal-actions">
                                <button type="button" className="lf-cancel-btn" onClick={handleCancelEdit}>
                                    Cancel
                                </button>
                                <button type="submit" className="lf-update-btn" disabled={isLoading}>
                                    {isLoading ? (
                                        <>
                                            <span className="lf-spinner"></span>
                                            Updating...
                                        </>
                                    ) : (
                                        'Update Item'
                                    )}
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default LostAndFound;
