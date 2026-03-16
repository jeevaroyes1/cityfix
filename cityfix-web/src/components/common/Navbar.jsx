import React from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import './Navbar.css';

const Navbar = () => {
    const { userProfile, logout } = useAuth();
    const navigate = useNavigate();

    const handleLogout = async () => {
        try {
            await logout();
            navigate('/login');
        } catch (error) {
            console.error('Logout failed:', error);
        }
    };

    return (
        <nav className="navbar">
            <div className="navbar-container">
                <Link to="/dashboard" className="navbar-logo">
                    <img src="/logo.png" alt="CityFix" className="navbar-logo-image" />
                    <span className="navbar-logo-text">CityFix</span>
                </Link>

                <div className="navbar-links">
                    <Link to="/dashboard" className="nav-link active">Home</Link>
                    <Link to="/explore" className="nav-link">Explore</Link>
                    <Link to="/about" className="nav-link">About</Link>
                    <Link to="/how-it-works" className="nav-link">How it Works</Link>
                    <Link to="/sla" className="nav-link sla-pill">SLA</Link>
                </div>

                <div className="navbar-actions">
                    <button className="notification-btn">
                        <span className="bell-icon">🔔</span>
                        <span className="notification-dot"></span>
                    </button>

                    <div className="user-profile">
                        <img
                            src={userProfile?.photoURL || 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNDAiIGhlaWdodD0iNDAiIHZpZXdCb3g9IjAgMCA0MCA0MCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMjAiIGN5PSIyMCIgcj0iMjAiIGZpbGw9IiNFNUU3RUIiLz4KPHN2ZyB4PSI4IiB5PSI4IiB3aWR0aD0iMjQiIGhlaWdodD0iMjQiIHZpZXdCb3g9IjAgMCAyNCAyNCIgZmlsbD0ibm9uZSI+CjxwYXRoIGQ9Ik0xMiAxMkM5Ljc5IDEyIDggMTAuMjEgOCA4UzkuNzkgNDEyIDRTMTQuMjEgNiAxNiA4UzEyIDEwLjIxIDEyIDEyWk0xMiAxNEM3IDEzLjk5IDMgMTcuOTkgMyAyMlYyNEgyMVYyMkMxNyAxNy45OSAxMyAxMy45OSAxMiAxNFoiIGZpbGw9IiM5Q0E0QUYiLz4KPC9zdmc+Cjwvc3ZnPgo='}
                            alt="Profile"
                            className="profile-avatar"
                        />
                        <div className="user-info-text">
                            <span className="profile-name">{userProfile?.displayName}</span>
                            <button onClick={handleLogout} className="logout-link">Logout</button>
                        </div>
                    </div>
                </div>
            </div>
        </nav>
    );
};

export default Navbar;
