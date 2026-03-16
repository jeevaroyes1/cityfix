import React, { useState, useEffect } from 'react';
import { Link } from 'react-router-dom';
import './LandingPage.css';

const features = [
    {
        icon: '📸',
        title: 'Report Issues Instantly',
        desc: 'Snap a photo, describe the problem, and submit — your city officials will be notified immediately.',
    },
    {
        icon: '📊',
        title: 'Track Resolution Progress',
        desc: 'Follow the status of every complaint from submission to resolution in real time.',
    },
    {
        icon: '🏆',
        title: 'City Rankings & Ratings',
        desc: 'See how your city performs compared to others based on complaint resolution rates.',
    },
    {
        icon: '🤝',
        title: 'Community Driven',
        desc: 'Join thousands of citizens making their neighborhoods cleaner and safer every day.',
    },
    {
        icon: '🔔',
        title: 'Instant Notifications',
        desc: 'Get real-time updates when your reported issue status changes or gets resolved.',
    },
    {
        icon: '📍',
        title: 'GPS Location Tracking',
        desc: 'Automatically pinpoint issue locations for faster and more accurate departmental assignment.',
    },
];

const stats = [
    { value: '10,000+', label: 'Issues Reported' },
    { value: '85%', label: 'Resolution Rate' },
    { value: '50+', label: 'Cities Covered' },
    { value: '25,000+', label: 'Active Citizens' },
];

const testimonials = [
    {
        quote: 'CityFix made it incredibly easy to report the broken streetlight near my house. It was fixed within 48 hours!',
        name: 'Priya Sharma',
        role: 'Resident, Bangalore',
        avatar: '👩‍💼',
    },
    {
        quote: 'As a municipal officer, CityFix has streamlined our complaint management. We can now prioritize issues effectively.',
        name: 'Rajesh Kumar',
        role: 'Municipal Officer, Delhi',
        avatar: '👨‍💼',
    },
    {
        quote: 'The transparency this platform brings is amazing. I can track every complaint I\'ve ever filed.',
        name: 'Anita Desai',
        role: 'Resident, Mumbai',
        avatar: '👩‍🔬',
    },
];

const LandingPage = () => {
    const [scrolled, setScrolled] = useState(false);
    const [mobileMenuOpen, setMobileMenuOpen] = useState(false);

    useEffect(() => {
        const handleScroll = () => {
            setScrolled(window.scrollY > 20);
        };
        window.addEventListener('scroll', handleScroll);
        return () => window.removeEventListener('scroll', handleScroll);
    }, []);

    return (
        <div className="landing">
            {/* ─── Public Navbar ─── */}
            <nav className={`landing-nav ${scrolled ? 'landing-nav--scrolled' : ''}`}>
                <div className="landing-nav-inner">
                    <Link to="/" className="landing-logo">
                        <img src="/logo.png" alt="CityFix" className="landing-logo-image" />
                        <span className="landing-logo-text">CityFix</span>
                    </Link>

                    <button
                        className="mobile-menu-btn"
                        onClick={() => setMobileMenuOpen(!mobileMenuOpen)}
                        aria-label="Toggle menu"
                    >
                        <span className={`hamburger ${mobileMenuOpen ? 'hamburger--open' : ''}`}>
                            <span></span>
                            <span></span>
                            <span></span>
                        </span>
                    </button>

                    <div className={`landing-nav-links ${mobileMenuOpen ? 'landing-nav-links--open' : ''}`}>
                        <a href="#features" onClick={() => setMobileMenuOpen(false)}>Features</a>
                        <a href="#about" onClick={() => setMobileMenuOpen(false)}>About</a>
                        <a href="#stats" onClick={() => setMobileMenuOpen(false)}>Impact</a>
                        <a href="#how-it-works" onClick={() => setMobileMenuOpen(false)}>How it Works</a>
                        <a href="#sla" onClick={() => setMobileMenuOpen(false)}>SLA</a>
                        <a href="#testimonials" onClick={() => setMobileMenuOpen(false)}>Testimonials</a>
                        <div className="nav-auth-btns">
                            <Link to="/login" className="landing-btn-outline" onClick={() => setMobileMenuOpen(false)}>Login</Link>
                            <Link to="/signup" className="landing-btn-solid" onClick={() => setMobileMenuOpen(false)}>Get Started</Link>
                        </div>
                    </div>
                </div>
            </nav>

            {/* ─── Hero ─── */}
            <section className="landing-hero">
                <div className="hero-bg-shapes">
                    <div className="shape shape--1"></div>
                    <div className="shape shape--2"></div>
                    <div className="shape shape--3"></div>
                </div>
                <div className="landing-hero-content">
                    <span className="landing-badge">
                        <span className="badge-dot"></span>
                        Building Better Cities Together
                    </span>
                    <h1>
                        Report Civic Issues.<br />
                        <span className="hero-accent">Get Them Resolved.</span>
                    </h1>
                    <p className="landing-hero-sub">
                        CityFix empowers citizens to report infrastructure problems, track resolutions,
                        and hold local governments accountable — all from one simple platform.
                    </p>
                    <div className="landing-hero-btns">
                        <Link to="/signup" className="landing-btn-solid landing-btn-lg">
                            Start Reporting — It's Free
                            <span className="btn-arrow">→</span>
                        </Link>
                        <a href="#how-it-works" className="landing-btn-outline landing-btn-lg">
                            See How it Works
                        </a>
                    </div>
                    <div className="hero-trust">
                        <div className="trust-avatars">
                            <span className="trust-avatar">◐</span>
                            <span className="trust-avatar">◐</span>
                            <span className="trust-avatar">◐</span>
                            <span className="trust-avatar">◐</span>
                        </div>
                        <span className="trust-text">Trusted by <strong>25,000+</strong> citizens</span>
                    </div>
                </div>
                <div className="landing-hero-visual">
                    <div className="hero-phone-mockup">
                        <div className="phone-screen">
                            <div className="phone-header">
                                <span className="phone-status-bar">CityFix</span>
                            </div>
                            <div className="hero-card hero-card--1 animate-float-1">
                                <span className="hc-icon">🚧</span>
                                <div>
                                    <strong>Pothole on MG Road</strong>
                                    <span className="hc-status hc-status--progress">In Progress</span>
                                </div>
                            </div>
                            <div className="hero-card hero-card--2 animate-float-2">
                                <span className="hc-icon">💡</span>
                                <div>
                                    <strong>Street Light Not Working</strong>
                                    <span className="hc-status hc-status--resolved">Resolved ✓</span>
                                </div>
                            </div>
                            <div className="hero-card hero-card--3 animate-float-3">
                                <span className="hc-icon">🗑️</span>
                                <div>
                                    <strong>Garbage Not Collected</strong>
                                    <span className="hc-status hc-status--new">New</span>
                                </div>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* ─── Stats ─── */}
            <section className="landing-stats" id="stats">
                <div className="stats-inner">
                    {stats.map((s, i) => (
                        <div className="stat-item" key={i}>
                            <span className="stat-value">{s.value}</span>
                            <span className="stat-label">{s.label}</span>
                        </div>
                    ))}
                </div>
            </section>

            {/* ─── Features ─── */}
            <section className="landing-features" id="features">
                <span className="section-badge">Features</span>
                <h2 className="section-title">Why Citizens Love CityFix</h2>
                <p className="section-sub">
                    A powerful, easy-to-use platform designed for real impact in your community.
                </p>
                <div className="features-grid">
                    {features.map((f, i) => (
                        <div className="feature-card" key={i}>
                            <div className="feature-icon">{f.icon}</div>
                            <h3>{f.title}</h3>
                            <p>{f.desc}</p>
                        </div>
                    ))}
                </div>
            </section>

            {/* ─── About Section ─── */}
            <section className="landing-about" id="about">
                <div className="about-container">
                    <div className="about-image">
                        <img 
                            src="/about-cityfix.jpg" 
                            alt="Citizens using CityFix platform" 
                            className="about-img"
                        />
                        <div className="about-badge-overlay">
                            <div className="badge-item">
                                <span className="badge-icon">🏙️</span>
                                <span className="badge-text">Smart Cities</span>
                            </div>
                            <div className="badge-item">
                                <span className="badge-icon">👥</span>
                                <span className="badge-text">Community First</span>
                            </div>
                        </div>
                    </div>
                    <div className="about-content">
                        <span className="section-badge">About CityFix</span>
                        <h2 className="section-title">Connecting Citizens with Local Authorities</h2>
                        <div className="about-text">
                            <p>
                                The CityFix application is a modern complaint redressal mobile and web platform 
                                designed to improve communication between citizens and local authorities. It enables 
                                people to easily report civic issues such as waste management problems, road damage, 
                                public safety concerns, and other community-related complaints directly to the 
                                concerned authorities.
                            </p>
                            <p>
                                The CityFix platform aims to enhance transparency, accountability, and efficiency 
                                in resolving public grievances. Citizens can submit reports, track the status of 
                                their complaints, and stay informed about the actions taken by municipal or 
                                panchayat officials.
                            </p>
                            <p>
                                CityFix also promotes community participation by allowing users to support existing 
                                complaints, share them with other residents, and provide feedback or comments on 
                                ongoing work. This collaborative approach helps prioritize important issues and 
                                ensures that community concerns receive timely attention.
                            </p>
                            <p className="about-highlight">
                                By connecting citizens, local staff, and administrators on a single platform, 
                                CityFix helps create cleaner, safer, and better-managed communities.
                            </p>
                        </div>
                        <div className="about-features">
                            <div className="about-feature-item">
                                <span className="feature-check">✓</span>
                                <span>Direct communication with authorities</span>
                            </div>
                            <div className="about-feature-item">
                                <span className="feature-check">✓</span>
                                <span>Real-time complaint tracking</span>
                            </div>
                            <div className="about-feature-item">
                                <span className="feature-check">✓</span>
                                <span>Community collaboration</span>
                            </div>
                            <div className="about-feature-item">
                                <span className="feature-check">✓</span>
                                <span>Transparent resolution process</span>
                            </div>
                        </div>
                    </div>
                </div>
            </section>

            {/* ─── How It Works Preview ─── */}
            <section className="landing-hiw" id="how-it-works">
                <span className="section-badge">Process</span>
                <h2 className="section-title">How It Works</h2>
                <p className="section-sub">
                    Four simple steps to make your city better
                </p>
                <div className="hiw-steps">
                    <div className="hiw-step">
                        <div className="step-num">1</div>
                        <h3>Report</h3>
                        <p>Take a photo, describe the issue, and submit your complaint in seconds.</p>
                    </div>
                    <div className="hiw-connector">
                        <div className="connector-line"></div>
                    </div>
                    <div className="hiw-step">
                        <div className="step-num">2</div>
                        <h3>Assign</h3>
                        <p>City officials receive the report and assign it to the right department.</p>
                    </div>
                    <div className="hiw-connector">
                        <div className="connector-line"></div>
                    </div>
                    <div className="hiw-step">
                        <div className="step-num">3</div>
                        <h3>Resolve</h3>
                        <p>Engineers take action within 6 hours, with automatic escalation built in.</p>
                    </div>
                    <div className="hiw-connector">
                        <div className="connector-line"></div>
                    </div>
                    <div className="hiw-step">
                        <div className="step-num">4</div>
                        <h3>Rate</h3>
                        <p>Confirm resolution and rate your city's performance transparently.</p>
                    </div>
                </div>
            </section>

            {/* ─── SLA Section ─── */}
            <section className="landing-sla" id="sla">
                <div className="sla-container">
                    <div className="sla-content">
                        <span className="section-badge">Our Commitment</span>
                        <h2 className="section-title">Service Level Agreements</h2>
                        <p className="sla-text">
                            CityFix app aims to foster large scale citizen participation.
                        </p>
                        <p className="sla-text">
                            The CityFix city rating system works on the number of complaints resolved by 
                            the corporation - with adherence to Service Level Agreements and to the 
                            satisfaction of the complainant. Action on the complaints may vary depending 
                            on the categories.
                        </p>
                        <p className="sla-text">
                            Action for most complaints will be initiated from <strong>6 hours of registration</strong>. 
                            There is a detailed escalation process built in the mobile application so that 
                            complaints that are not resolved at the lower level are moved to higher levels 
                            for action and resolution.
                        </p>
                    </div>
                    <div className="sla-image">
                        <img 
                            src="/sla_hero.png" 
                            alt="Waste management worker with recycling bins" 
                            className="sla-img"
                        />
                    </div>
                </div>
            </section>

            {/* ─── Onboarding Section ─── */}
            <section className="landing-onboarding" id="onboarding">
                <div className="onboarding-container">
                    <span className="section-badge">For Service Providers</span>
                    <h2 className="section-title">Onboarding of New Service Sector</h2>
                    <p className="section-sub">
                        Are you a service provider looking to join the CityFix platform? 
                        Download our comprehensive onboarding guide to learn how to integrate 
                        your services and start serving citizens effectively.
                    </p>
                    <div className="onboarding-card">
                        <div className="onboarding-icon">📄</div>
                        <div className="onboarding-content">
                            <h3>Service Sector Onboarding Guide</h3>
                            <p>Complete documentation for new service providers joining CityFix</p>
                            <a 
                                href="/onboarding-service-sector.pdf" 
                                target="_blank" 
                                rel="noopener noreferrer"
                                className="onboarding-btn"
                            >
                                <span>Download PDF Guide</span>
                                <span className="btn-icon">📥</span>
                            </a>
                        </div>
                    </div>
                </div>
            </section>

            {/* ─── Testimonials ─── */}
            <section className="landing-testimonials" id="testimonials">
                <span className="section-badge">Testimonials</span>
                <h2 className="section-title">What Our Users Say</h2>
                <p className="section-sub">
                    Real stories from real citizens making a difference
                </p>
                <div className="testimonials-grid">
                    {testimonials.map((t, i) => (
                        <div className="testimonial-card" key={i}>
                            <div className="testimonial-stars">★★★★★</div>
                            <p className="testimonial-quote">"{t.quote}"</p>
                            <div className="testimonial-author">
                                <span className="testimonial-avatar">{t.avatar}</span>
                                <div>
                                    <strong>{t.name}</strong>
                                    <span>{t.role}</span>
                                </div>
                            </div>
                        </div>
                    ))}
                </div>
            </section>

            {/* ─── CTA ─── */}
            <section className="landing-cta">
                <div className="cta-inner">
                    <div className="cta-glow"></div>
                    <h2>Ready to Make Your City Better?</h2>
                    <p>Join thousands of citizens who are already making a difference in their communities.</p>
                    <div className="cta-btns">
                        <Link to="/signup" className="landing-btn-solid landing-btn-lg cta-main-btn">
                            Create Your Free Account
                            <span className="btn-arrow">→</span>
                        </Link>
                        <Link to="/login" className="landing-btn-outline landing-btn-lg cta-secondary-btn">
                            Already have an account? Login
                        </Link>
                    </div>
                </div>
            </section>

            {/* ─── Footer ─── */}
            <footer className="landing-footer">
                <div className="footer-inner">
                    <div className="footer-brand">
                        <div className="landing-logo">
                            <img src="/logo.png" alt="CityFix" className="landing-logo-image" />
                            <span className="landing-logo-text">CityFix</span>
                        </div>
                        <p>Empowering citizens to build better cities through technology and civic participation.</p>
                        <div className="footer-social">
                            <a href="#!" aria-label="Twitter" className="social-link">𝕏</a>
                            <a href="#!" aria-label="LinkedIn" className="social-link">in</a>
                            <a href="#!" aria-label="Instagram" className="social-link">📷</a>
                        </div>
                    </div>
                    <div className="footer-links">
                        <h4>Platform</h4>
                        <Link to="/login">Login</Link>
                        <Link to="/signup">Sign Up</Link>
                        <a href="#features">Features</a>
                    </div>
                    <div className="footer-links">
                        <h4>Learn More</h4>
                        <a href="#how-it-works">How it Works</a>
                        <a href="#testimonials">Testimonials</a>
                        <a href="#stats">Our Impact</a>
                    </div>
                    <div className="footer-links">
                        <h4>Legal</h4>
                        <a href="#!">Privacy Policy</a>
                        <a href="#!">Terms of Service</a>
                        <a href="#!">Cookie Policy</a>
                    </div>
                </div>
                <div className="footer-bottom">
                    <p>© {new Date().getFullYear()} CityFix. All rights reserved. Made with ❤️ for better cities.</p>
                </div>
            </footer>
        </div>
    );
};

export default LandingPage;
