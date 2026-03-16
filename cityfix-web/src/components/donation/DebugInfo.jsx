import React from 'react';
import { useAuth } from '../../contexts/AuthContext';

const DebugInfo = () => {
    const { currentUser, userProfile, loading } = useAuth();

    if (process.env.NODE_ENV === 'production') return null;

    return (
        <div style={{
            position: 'fixed',
            top: '10px',
            right: '10px',
            background: '#f0f0f0',
            padding: '10px',
            borderRadius: '5px',
            fontSize: '12px',
            zIndex: 9999,
            maxWidth: '300px',
            border: '1px solid #ccc'
        }}>
            <h4>Debug Info</h4>
            <div><strong>Auth Loading:</strong> {loading ? 'Yes' : 'No'}</div>
            <div><strong>Current User:</strong> {currentUser ? 'Logged in' : 'Not logged in'}</div>
            <div><strong>User ID:</strong> {currentUser?.uid || 'None'}</div>
            <div><strong>User Email:</strong> {currentUser?.email || 'None'}</div>
            <div><strong>User Profile:</strong> {userProfile ? 'Loaded' : 'Not loaded'}</div>
            <div><strong>Profile Name:</strong> {userProfile?.displayName || 'None'}</div>
        </div>
    );
};

export default DebugInfo;