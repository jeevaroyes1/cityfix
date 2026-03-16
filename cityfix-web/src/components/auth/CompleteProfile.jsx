import React, { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import { createUserProfile } from '../../services/firestore';
import ErrorMessage from '../common/ErrorMessage';
import './Auth.css';

const CompleteProfile = () => {
    const { currentUser, refreshUserProfile } = useAuth();
    const [formData, setFormData] = useState({
        phoneNumber: '',
        panchayat: '',
        ward: ''
    });
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const navigate = useNavigate();

    const handleChange = (e) => {
        const { name, value } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: value
        }));
    };

    const validateForm = () => {
        if (!formData.phoneNumber || !formData.panchayat || !formData.ward) {
            setError('Please fill in all fields');
            return false;
        }

        if (!/^\d{10}$/.test(formData.phoneNumber)) {
            setError('Phone number must be exactly 10 digits');
            return false;
        }

        return true;
    };

    const handleSubmit = async (e) => {
        e.preventDefault();

        if (!validateForm()) {
            return;
        }

        try {
            setError('');
            setLoading(true);

            await createUserProfile(currentUser.uid, {
                displayName: currentUser.displayName,
                email: currentUser.email,
                phoneNumber: formData.phoneNumber,
                panchayat: formData.panchayat,
                ward: formData.ward,
                role: 'user',
                profilePicture: currentUser.photoURL || ''
            });

            await refreshUserProfile(currentUser);

            navigate('/dashboard');
        } catch (error) {
            console.error('Error completing profile:', error);
            setError('Failed to update profile. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="auth-container">
            <div className="auth-card">
                <div className="auth-header">
                    <h1>Complete Profile</h1>
                    <p>Tell us a bit more about yourself to get started</p>
                </div>

                <ErrorMessage message={error} onClose={() => setError('')} />

                <form onSubmit={handleSubmit}>
                    <div className="form-group">
                        <label htmlFor="phoneNumber">Phone Number</label>
                        <input
                            type="tel"
                            id="phoneNumber"
                            name="phoneNumber"
                            value={formData.phoneNumber}
                            onChange={handleChange}
                            placeholder="10-digit phone number"
                            disabled={loading}
                        />
                    </div>

                    <div className="form-group">
                        <label htmlFor="panchayat">Panchayat</label>
                        <input
                            type="text"
                            id="panchayat"
                            name="panchayat"
                            value={formData.panchayat}
                            onChange={handleChange}
                            placeholder="Enter your panchayat"
                            disabled={loading}
                        />
                    </div>

                    <div className="form-group">
                        <label htmlFor="ward">Ward</label>
                        <input
                            type="text"
                            id="ward"
                            name="ward"
                            value={formData.ward}
                            onChange={handleChange}
                            placeholder="Enter your ward"
                            disabled={loading}
                        />
                    </div>

                    <button type="submit" className="submit-btn" disabled={loading}>
                        {loading ? 'Updating...' : 'Finish Registration'}
                    </button>
                </form>
            </div>
        </div>
    );
};

export default CompleteProfile;
