import React from 'react';
import { Navigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import Loading from '../common/Loading';

const ProtectedRoute = ({ children }) => {
    const { currentUser, loading } = useAuth();

    if (loading) {
        return <Loading message="Checking authentication..." />;
    }

    if (!currentUser) {
        return <Navigate to="/" replace />;
    }

    return children;
};

export default ProtectedRoute;
