import React, { useState } from 'react';
import { Link, useNavigate } from 'react-router-dom';
import { useAuth } from '../../contexts/AuthContext';
import ErrorMessage from '../common/ErrorMessage';
import './Auth.css';

const Login = () => {
    const [email, setEmail] = useState('');
    const [password, setPassword] = useState('');
    const [error, setError] = useState('');
    const [loading, setLoading] = useState(false);
    const { signIn, signInWithGoogle } = useAuth();
    const navigate = useNavigate();

    const handleEmailLogin = async (e) => {
        e.preventDefault();

        if (!email || !password) {
            setError('Please fill in all fields');
            return;
        }

        try {
            setError('');
            setLoading(true);
            await signIn(email, password);
            navigate('/dashboard');
        } catch (error) {
            setError('Failed to sign in. Please check your credentials.');
        } finally {
            setLoading(false);
        }
    };

    const handleGoogleLogin = async () => {
        try {
            setError('');
            setLoading(true);
            const { isNewUser } = await signInWithGoogle();

            if (isNewUser) {
                navigate('/complete-profile');
            } else {
                navigate('/dashboard');
            }
        } catch (error) {
            setError('Failed to sign in with Google. Please try again.');
        } finally {
            setLoading(false);
        }
    };

    return (
        <div className="auth-container">
            <div className="auth-card">
                <div className="auth-header">
                    <h1>CityFix</h1>
                    <p>Sign in to your account</p>
                </div>

                <ErrorMessage message={error} onClose={() => setError('')} />

                <button
                    className="google-btn"
                    onClick={handleGoogleLogin}
                    disabled={loading}
                >
                    <img src="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iMTgiIGhlaWdodD0iMTgiIHZpZXdCb3g9IjAgMCAxOCAxOCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPHBhdGggZD0iTTE3LjY0IDkuMjA0NTVDMTcuNjQgOC41NjY0MSAxNy41ODI3IDcuOTUyNzMgMTcuNDc2NCA3LjM2MzY0SDlWMTAuODQ1SDE0LjA0MzZDMTMuODQgMTEuOTcgMTMuMjU0NSAxMi45MjMgMTIuMzYzNiAxMy41NjE0VjE1Ljg5NTVIMTUuMTA5MUMxNi42MTA5IDE0LjUyMjcgMTcuNjQgMTIuMDU5MSAxNy42NCA5LjIwNDU1WiIgZmlsbD0iIzQyODVGNCIvPgo8cGF0aCBkPSJNOSAxOEM5IDEzLjk1IDEyLjA1IDEwLjkgMTYuMSAxMC45QzE3LjEgMTAuOSAxOC4wNSAxMS4xNSAxOC45IDExLjZWOC4yNUgxNi4xVjEwLjlIMTMuMzVWOC4yNUgxMC42VjEwLjlIOVYxOFoiIGZpbGw9IiMzNEE4NTMiLz4KPHBhdGggZD0iTTkgMTguMDAwMUM5IDEzLjk1IDEyLjA1IDEwLjkgMTYuMSAxMC45QzE3LjEgMTAuOSAxOC4wNSAxMS4xNSAxOC45IDExLjZWOC4yNUgxNi4xVjEwLjlIMTMuMzVWOC4yNUgxMC42VjEwLjlIOVYxOC4wMDAxWiIgZmlsbD0iI0ZCQkMwNSIvPgo8cGF0aCBkPSJNOSAxOEMxMy45NSAxOCAxNy45IDE0LjA1IDE3LjkgOUMxNy45IDQuMDUgMTMuOTUgMCA5IDBDNC4wNSAwIDAgNC4wNSAwIDlDMCAxNC4wNSA0LjA1IDE4IDkgMThaIiBmaWxsPSIjRUE0MzM1Ii8+Cjwvc3ZnPgo=" alt="Google" />
                    Continue with Google
                </button>

                <div className="divider">
                    <span>or</span>
                </div>

                <form onSubmit={handleEmailLogin}>
                    <div className="form-group">
                        <label htmlFor="email">Email</label>
                        <input
                            type="email"
                            id="email"
                            value={email}
                            onChange={(e) => setEmail(e.target.value)}
                            placeholder="Enter your email"
                            disabled={loading}
                        />
                    </div>

                    <div className="form-group">
                        <label htmlFor="password">Password</label>
                        <input
                            type="password"
                            id="password"
                            value={password}
                            onChange={(e) => setPassword(e.target.value)}
                            placeholder="Enter your password"
                            disabled={loading}
                        />
                    </div>

                    <button type="submit" className="submit-btn" disabled={loading}>
                        {loading ? 'Signing in...' : 'Sign In'}
                    </button>
                </form>

                <p className="auth-footer">
                    Don't have an account? <Link to="/signup">Sign up</Link>
                </p>
            </div>
        </div>
    );
};

export default Login;
