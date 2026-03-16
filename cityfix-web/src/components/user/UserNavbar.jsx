import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { signOut } from 'firebase/auth';
import { auth } from '../../config/firebase';
import './UserNavbar.css';

const UserNavbar = ({ sidebarCollapsed, setSidebarCollapsed }) => {
    const { currentUser, userProfile } = useAuth();
    const navigate = useNavigate();
    const [showProfileMenu, setShowProfileMenu] = useState(false);
    const [showNotifications, setShowNotifications] = useState(false);
    const [showMessages, setShowMessages] = useState(false);
    const [darkMode, setDarkMode] = useState(false);

    const handleLogout = async () => {
        if (window.confirm('Are you sure you want to logout?')) {
            await signOut(auth);
            navigate('/');
        }
    };

    const toggleDarkMode = () => {
        setDarkMode(!darkMode);
        // You can implement actual dark mode logic here
        document.body.classList.toggle('dark-mode');
    };

    const getInitials = () => {
        if (userProfile?.displayName) {
            return userProfile.displayName.charAt(0).toUpperCase();
        }
        return currentUser?.email?.charAt(0).toUpperCase() || 'U';
    };

    const getUserName = () => {
        if (userProfile?.displayName) {
            return userProfile.displayName;
        }
        return currentUser?.email?.split('@')[0] || 'User';
    };

    // Sample notifications data
    const notifications = [
        { id: 1, title: 'Report Updated', message: 'Your pothole report has been assigned', time: '5 min ago', unread: true },
        { id: 2, title: 'Issue Resolved', message: 'Street light issue marked as resolved', time: '1 hour ago', unread: true },
        { id: 3, title: 'New Comment', message: 'Someone commented on your report', time: '2 hours ago', unread: false }
    ];

    // Sample messages data
    const messages = [
        { id: 1, from: 'Municipal Office', message: 'Thank you for reporting the issue', time: '10 min ago', unread: true },
        { id: 2, from: 'Community Admin', message: 'Your report is under review', time: '1 day ago', unread: false }
    ];

    return (
        <nav className="user-navbar">
            <div className="user-navbar-inner">
                {/* Left Section - Hamburger + Logo */}
                <div className="navbar-left">
                    {/* Hamburger Menu */}
                    <button 
                        className="hamburger-btn"
                        onClick={() => setSidebarCollapsed(!sidebarCollapsed)}
                        aria-label={sidebarCollapsed ? 'Expand sidebar' : 'Collapse sidebar'}
                    >
                        <span className={`hamburger ${sidebarCollapsed ? 'hamburger--collapsed' : ''}`}>
                            <span></span>
                            <span></span>
                            <span></span>
                        </span>
                    </button>

                    {/* Logo */}
                    <Link to="/dashboard" className="logo-link">
                        <img src="/logo.png" alt="CityFix" className="logo-image" />
                        <span className="logo-text">CityFix</span>
                    </Link>
                </div>

                {/* Right Section */}
                <div className="navbar-right">
                    {/* Dark Mode Toggle */}
                    <button 
                        className="navbar-icon-btn" 
                        onClick={toggleDarkMode}
                        aria-label="Toggle dark mode" 
                        title="Dark Mode"
                    >
                        {darkMode ? '◉' : '◎'}
                    </button>

                    {/* Messages */}
                    <div className="navbar-dropdown-wrapper">
                        <button 
                            className="navbar-icon-btn" 
                            onClick={() => {
                                setShowMessages(!showMessages);
                                setShowNotifications(false);
                            }}
                            aria-label="Messages" 
                            title="Messages"
                        >
                            ✉
                            {messages.some(m => m.unread) && <span className="notification-dot"></span>}
                        </button>

                        {showMessages && (
                            <>
                                <div 
                                    className="dropdown-overlay" 
                                    onClick={() => setShowMessages(false)}
                                ></div>
                                <div className="navbar-dropdown messages-dropdown">
                                    <div className="dropdown-header-title">
                                        <h3>Messages</h3>
                                        <span className="badge">{messages.filter(m => m.unread).length}</span>
                                    </div>
                                    <div className="dropdown-list">
                                        {messages.length > 0 ? (
                                            messages.map(msg => (
                                                <div key={msg.id} className={`dropdown-list-item ${msg.unread ? 'unread' : ''}`}>
                                                    <div className="item-icon">✉</div>
                                                    <div className="item-content">
                                                        <strong>{msg.from}</strong>
                                                        <p>{msg.message}</p>
                                                        <span className="item-time">{msg.time}</span>
                                                    </div>
                                                </div>
                                            ))
                                        ) : (
                                            <div className="empty-state">No messages</div>
                                        )}
                                    </div>
                                    <div className="dropdown-footer">
                                        <button onClick={() => setShowMessages(false)}>View All Messages</button>
                                    </div>
                                </div>
                            </>
                        )}
                    </div>

                    {/* Notifications */}
                    <div className="navbar-dropdown-wrapper">
                        <button 
                            className="navbar-icon-btn" 
                            onClick={() => {
                                setShowNotifications(!showNotifications);
                                setShowMessages(false);
                            }}
                            aria-label="Notifications" 
                            title="Notifications"
                        >
                            ◐
                            {notifications.some(n => n.unread) && <span className="notification-dot"></span>}
                        </button>

                        {showNotifications && (
                            <>
                                <div 
                                    className="dropdown-overlay" 
                                    onClick={() => setShowNotifications(false)}
                                ></div>
                                <div className="navbar-dropdown notifications-dropdown">
                                    <div className="dropdown-header-title">
                                        <h3>Notifications</h3>
                                        <span className="badge">{notifications.filter(n => n.unread).length}</span>
                                    </div>
                                    <div className="dropdown-list">
                                        {notifications.length > 0 ? (
                                            notifications.map(notif => (
                                                <div key={notif.id} className={`dropdown-list-item ${notif.unread ? 'unread' : ''}`}>
                                                    <div className="item-icon">◐</div>
                                                    <div className="item-content">
                                                        <strong>{notif.title}</strong>
                                                        <p>{notif.message}</p>
                                                        <span className="item-time">{notif.time}</span>
                                                    </div>
                                                </div>
                                            ))
                                        ) : (
                                            <div className="empty-state">No notifications</div>
                                        )}
                                    </div>
                                    <div className="dropdown-footer">
                                        <button onClick={() => setShowNotifications(false)}>View All Notifications</button>
                                    </div>
                                </div>
                            </>
                        )}
                    </div>

                    {/* User Profile */}
                    <div className="navbar-user-section">
                        <button 
                            className="user-profile-btn"
                            onClick={() => setShowProfileMenu(!showProfileMenu)}
                        >
                            <div className="user-info">
                                <span className="user-name">{getUserName()}</span>
                                <span className="user-role">public_user</span>
                            </div>
                            {userProfile?.photoURL ? (
                                <img 
                                    src={userProfile.photoURL} 
                                    alt="Profile" 
                                    className="user-avatar"
                                />
                            ) : (
                                <div className="user-avatar-placeholder">
                                    {getInitials()}
                                </div>
                            )}
                        </button>

                        {/* Dropdown Menu */}
                        {showProfileMenu && (
                            <>
                                <div 
                                    className="profile-menu-overlay" 
                                    onClick={() => setShowProfileMenu(false)}
                                ></div>
                                <div className="profile-dropdown">
                                    <div className="dropdown-header">
                                        <div className="dropdown-user-info">
                                            <strong>{getUserName()}</strong>
                                            <span>{currentUser?.email}</span>
                                        </div>
                                    </div>
                                    <div className="dropdown-divider"></div>
                                    <Link 
                                        to="/profile" 
                                        className="dropdown-item"
                                        onClick={() => setShowProfileMenu(false)}
                                    >
                                        <span className="dropdown-icon">◐</span>
                                        My Profile
                                    </Link>
                                    <Link 
                                        to="/settings" 
                                        className="dropdown-item"
                                        onClick={() => setShowProfileMenu(false)}
                                    >
                                        <span className="dropdown-icon">⚙</span>
                                        Settings
                                    </Link>
                                    <Link 
                                        to="/help" 
                                        className="dropdown-item"
                                        onClick={() => setShowProfileMenu(false)}
                                    >
                                        <span className="dropdown-icon">?</span>
                                        Help & Support
                                    </Link>
                                    <div className="dropdown-divider"></div>
                                    <button 
                                        className="dropdown-item logout-item"
                                        onClick={handleLogout}
                                    >
                                        <span className="dropdown-icon">⊗</span>
                                        Logout
                                    </button>
                                </div>
                            </>
                        )}
                    </div>
                </div>
            </div>
        </nav>
    );
};

export default UserNavbar;
