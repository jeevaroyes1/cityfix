import React, { useState } from 'react';
import { Link, Outlet, useLocation } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import UserNavbar from './UserNavbar';
import './UserLayout.css';

const UserLayout = () => {
    const [sidebarCollapsed, setSidebarCollapsed] = useState(false);
    const location = useLocation();
    const { currentUser, userProfile } = useAuth();

    const services = [
        { id: 'dashboard', title: 'Dashboard', icon: '⊞', path: '/dashboard' },
        { id: 'report-issue', title: 'Report Issue', icon: '⚠', path: '/report-issue' },
        { id: 'lost-found', title: 'Lost and Found', icon: '◉', path: '/lost-found' },
        { id: 'community-hub', title: 'Community Hub', icon: '◈', path: '/community-hub' },
        { id: 'volunteering', title: 'Volunteering', icon: '✦', path: '/volunteering' },
        { id: 'news', title: 'News Updates', icon: '▬', path: '/news' },
        { id: 'donate', title: 'Donate to Welfare', icon: '♡', path: '/donate' },
        { id: 'helpline', title: 'Helpline', icon: '◎', path: '/helpline' },
        { id: 'profile', title: 'My Profile', icon: '◐', path: '/profile' }
    ];

    return (
        <>
            <UserNavbar 
                sidebarCollapsed={sidebarCollapsed} 
                setSidebarCollapsed={setSidebarCollapsed} 
            />
            <div className="user-layout">
                {/* Sidebar */}
                <aside className={`user-sidebar ${sidebarCollapsed ? 'collapsed' : ''}`}>
                    <nav className="sidebar-nav">
                        {services.map(service => (
                            <Link 
                                to={service.path} 
                                key={service.id} 
                                className={`sidebar-item ${location.pathname === service.path ? 'active' : ''}`}
                                title={sidebarCollapsed ? service.title : ''}
                            >
                                <span className="sidebar-icon">{service.icon}</span>
                                {!sidebarCollapsed && (
                                    <div className="sidebar-text">
                                        <strong>{service.title}</strong>
                                    </div>
                                )}
                            </Link>
                        ))}
                    </nav>
                </aside>

                {/* Main Content */}
                <div className={`user-main ${sidebarCollapsed ? 'sidebar-collapsed' : ''}`}>
                    <Outlet />
                </div>
            </div>
        </>
    );
};

export default UserLayout;
