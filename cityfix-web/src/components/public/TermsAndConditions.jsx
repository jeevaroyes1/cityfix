import React from 'react';
import { useNavigate } from 'react-router-dom';
import './TermsAndConditions.css';

const TermsAndConditions = () => {
    const navigate = useNavigate();

    return (
        <div className="terms-container">
            <div className="terms-header">
                <button className="btn-back" onClick={() => navigate(-1)}>
                    ← Back
                </button>
                <h1>Terms and Conditions – CityFix App</h1>
                <p className="last-updated">Last Updated: March 10, 2026</p>
            </div>

            <div className="terms-content">
                <section className="terms-intro">
                    <p>
                        Welcome to CityFix, a mobile application that allows citizens to report and track 
                        city infrastructure problems. By creating an account or logging into the CityFix app, 
                        you agree to comply with the following terms and conditions.
                    </p>
                </section>

                <section className="terms-section">
                    <h2>1. User Agreement</h2>
                    <p>By registering or using the CityFix application, you agree to:</p>
                    <ul>
                        <li>Follow all application rules and community guidelines.</li>
                        <li>Provide accurate and truthful information.</li>
                        <li>Use the platform only for legitimate civic reporting purposes.</li>
                    </ul>
                    <p>Failure to comply with these terms may result in actions against your account.</p>
                </section>

                <section className="terms-section">
                    <h2>2. Community Policy</h2>
                    <p>
                        CityFix maintains a community policy to ensure that the platform is used responsibly 
                        and respectfully.
                    </p>
                    <p>By using the app, users agree that they will not:</p>
                    <ul>
                        <li>Submit fake or misleading reports.</li>
                        <li>Upload irrelevant or manipulated images.</li>
                        <li>Use abusive, offensive, or inappropriate language.</li>
                        <li>Submit spam reports or repeated false complaints.</li>
                        <li>Misuse the application for personal attacks or harassment.</li>
                    </ul>
                    <p>
                        All reports should represent genuine civic issues that require attention from authorities.
                    </p>
                </section>

                <section className="terms-section">
                    <h2>3. Consequences of Violating Community Policy</h2>
                    <p>
                        If a user violates the community policy, CityFix reserves the right to take 
                        appropriate actions, including:
                    </p>
                    <ul>
                        <li>Warning the user</li>
                        <li>Removing the report</li>
                        <li>Temporary suspension of the account</li>
                        <li>Permanent banning of the account</li>
                    </ul>
                    <p>Serious or repeated violations may result in immediate account suspension.</p>
                </section>

                <section className="terms-section">
                    <h2>4. User Responsibility</h2>
                    <p>Users are responsible for the content they submit on the platform, including:</p>
                    <ul>
                        <li>Issue descriptions</li>
                        <li>Uploaded photos</li>
                        <li>Comments or feedback</li>
                    </ul>
                    <p>
                        Users must ensure that all submitted content is truthful, relevant, and respectful.
                    </p>
                </section>

                <section className="terms-section">
                    <h2>5. Data and Privacy</h2>
                    <p>CityFix may collect basic user information such as:</p>
                    <ul>
                        <li>Name</li>
                        <li>Email address</li>
                        <li>Report details</li>
                        <li>Images submitted in reports</li>
                    </ul>
                    <p>This data is used only to operate and improve the CityFix service.</p>
                </section>

                <section className="terms-section">
                    <h2>6. Service Availability</h2>
                    <p>
                        CityFix strives to provide reliable service but does not guarantee uninterrupted 
                        availability. Temporary downtime may occur due to system updates, maintenance, or 
                        technical issues.
                    </p>
                </section>

                <section className="terms-section">
                    <h2>7. Modifications</h2>
                    <p>
                        CityFix reserves the right to update or modify these terms and community policies 
                        at any time. Continued use of the app indicates acceptance of the updated terms.
                    </p>
                </section>
            </div>

            <div className="terms-footer">
                <button className="btn-accept" onClick={() => navigate('/signup')}>
                    I Understand
                </button>
            </div>
        </div>
    );
};

export default TermsAndConditions;
