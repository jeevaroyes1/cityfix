import React from 'react';
import './Helpline.css';

const Helpline = () => {
    const emergencyContacts = [
        { name: 'Police Control', number: '100', icon: '🚓' },
        { name: 'Fire Station', number: '101', icon: '🚒' },
        { name: 'Ambulance', number: '102', icon: '🚑' },
        { name: 'Women Helpline', number: '1091', icon: '👩' },
        { name: 'Traffic Helpline', number: '1095', icon: '🚦' },
        { name: 'Disaster Mgmt', number: '108', icon: '⚠️' }
    ];

    const handleCall = (number) => {
        window.location.href = `tel:${number}`;
    };

    const handleCopy = (number) => {
        navigator.clipboard.writeText(number);
        alert(`Copied ${number} to clipboard`);
    };

    return (
        <div className="helpline-container">
            <div className="helpline-header">
                <h1>Emergency Helpline</h1>
                <p>Quick access to essential services. Tap to call or copy number.</p>
            </div>

            <div className="contacts-grid">
                {emergencyContacts.map((contact, index) => (
                    <div key={index} className="contact-card">
                        <div className="contact-icon">{contact.icon}</div>
                        <h3>{contact.name}</h3>
                        <div className="contact-number">{contact.number}</div>
                        <div className="contact-actions">
                            <button 
                                className="btn-call"
                                onClick={() => handleCall(contact.number)}
                            >
                                📞 Call
                            </button>
                            <button 
                                className="btn-copy"
                                onClick={() => handleCopy(contact.number)}
                            >
                                📋 Copy
                            </button>
                        </div>
                    </div>
                ))}
            </div>
        </div>
    );
};

export default Helpline;
