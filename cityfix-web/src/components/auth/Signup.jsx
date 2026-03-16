import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import ErrorMessage from '../common/ErrorMessage';
import './Auth.css';

const Signup = () => {
    const [formData, setFormData] = useState({
        displayName: '',
        email: '',
        password: '',
        phoneNumber: '',
        panchayat: '',
        ward: '',
        termsAgreed: false
    });
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const { signUp } = useAuth();
    const navigate = useNavigate();

    const handleChange = (e) => {
        const { name, value, type, checked } = e.target;
        setFormData(prev => ({
            ...prev,
            [name]: type === 'checkbox' ? checked : value
        }));
    };

    const validateForm = () => {
        if (!formData.displayName || !formData.email || !formData.password ||
            !formData.phoneNumber || !formData.panchayat || !formData.ward) {
            setError('Please fill in all fields');
            return false;
        }

        if (formData.password.length < 5) {
            setError('Password must be at least 5 characters long');
            return false;
        }

        if (!/^\d{10}$/.test(formData.phoneNumber)) {
            setError('Phone number must be exactly 10 digits');
            return false;
        }

        if (!formData.termsAgreed) {
            setError('You must agree to the terms and conditions');
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

            const { email, password, ...profileData } = formData;
            await signUp(email, password, {
                ...profileData,
                role: 'user',
                profilePicture: ''
            });

            navigate('/dashboard');
        } catch (error) {
            if (error.code === 'auth/email-already-in-use') {
                setError('This email is already registered');
            } else {
                setError('Failed to create account. Please try again.');
            }
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="auth-container">
            <div className="auth-card">
                <div className="auth-header">
                    <h1>CityFix</h1>
                    <p>Create your account</p>
                </div>

                <ErrorMessage message={error} onClose={() => setError('')} />

                <form onSubmit={handleSubmit}>
                    <div className="form-group">
                        <label htmlFor="displayName">Full Name</label>
                        <input
                            type="text"
                            id="displayName"
                            name="displayName"
                            value={formData.displayName}
                            onChange={handleChange}
                            placeholder="Enter your full name"
                            disabled={loading}
                        />
                    </div>

                    <div className="form-group">
                        <label htmlFor="email">Email</label>
                        <input
                            type="email"
                            id="email"
                            name="email"
                            value={formData.email}
                            onChange={handleChange}
                            placeholder="Enter your email"
                            disabled={loading}
                        />
                    </div>

                    <div className="form-group">
                        <label htmlFor="password">Password</label>
                        <input
                            type="password"
                            id="password"
                            name="password"
                            value={formData.password}
                            onChange={handleChange}
                            placeholder="Minimum 5 characters"
                            disabled={loading}
                        />
                    </div>

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

                    <div className="form-group checkbox-group">
                        <label className="checkbox-label">
                            <input
                                type="checkbox"
                                name="termsAgreed"
                                checked={formData.termsAgreed}
                                onChange={handleChange}
                                disabled={loading}
                            />
                            <span>
                                I agree to the{' '}
                                <Link to="/terms" target="_blank" className="terms-link">
                                    Terms and Conditions
                                </Link>
                            </span>
                        </label>
                    </div>

                    <button type="submit" className="submit-btn" disabled={loading}>
                        {loading ? 'Creating Account...' : 'Sign Up'}
                    </button>
                </form>

                <p className="auth-footer">
                    Already have an account? <Link to="/login">Sign in</Link>
                </p>
            </div>
        </div>
    );
};

export default Signup;
