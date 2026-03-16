import React from 'react';
import './ErrorMessage.css';

const ErrorMessage = ({ message, onClose }) => {
    if (!message) return null;

    return (
        <div className="error-message">
            <div className="error-content">
                <span className="error-icon">⚠️</span>
                <p>{message}</p>
                {onClose && (
                    <button className="error-close" onClick={onClose}>
                        ×
                    </button>
                )}
            </div>
        </div>
    );
};

export default ErrorMessage;
