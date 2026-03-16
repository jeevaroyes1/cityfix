import React from 'react';
import './AboutUs.css';

const AboutUs = () => {
    return (
        <div className="about-page">
            <div className="about-header">
                <h1>About CityFix</h1>
                <p>Empowering Communities, One Report at a Time</p>
            </div>

            <div className="about-content">
                <section className="about-section">
                    <h2>Our Mission</h2>
                    <p>
                        CityFix is dedicated to bridging the gap between citizens and local authorities.
                        We believe that a well-maintained community is a foundation for a happy, healthy
                        society. Our platform empowers you to easily report civic issues, track their
                        progress, and stay informed about your neighborhood.
                    </p>
                </section>

                <div className="about-grid">
                    <div className="about-card">
                        <div className="card-icon">🚀</div>
                        <h3>Report Issues Fast</h3>
                        <p>Spot a pothole, broken streetlight, or garbage dump? Snap a picture and report it instantly to the concerned department.</p>
                    </div>

                    <div className="about-card">
                        <div className="card-icon">🔍</div>
                        <h3>Lost & Found</h3>
                        <p>Reconnect with your lost items or help someone find theirs through our community-driven Lost and Found feature.</p>
                    </div>

                    <div className="about-card">
                        <div className="card-icon">📊</div>
                        <h3>Track Progress</h3>
                        <p>Stay updated with real-time status changes on your reported issues until they are successfully resolved.</p>
                    </div>

                    <div className="about-card">
                        <div className="card-icon">🤝</div>
                        <h3>Community Hub</h3>
                        <p>Connect with your neighbors, share updates, volunteer for local drives, and make your city a better place together.</p>
                    </div>
                </div>

                <section className="about-section team-section">
                    <h2>Why Choose Us?</h2>
                    <p>
                        Built with a vision of a cleaner and safer environment, CityFix leverages modern
                        technology to ensure transparency and accountability in local governance. By providing
                        a unified platform for all civic needs, we streamline communication and foster a
                        sense of responsibility among citizens.
                    </p>
                </section>
            </div>
        </div>
    );
};

export default AboutUs;
