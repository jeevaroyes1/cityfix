import React from 'react';
import './SLA.css';

const SLA = () => {
    return (
        <div className="sla-page">
            <div className="sla-hero-section">
                <div className="sla-image-panel">
                    <img src="/sla_hero.png" alt="Municipal workers collecting waste" className="sla-hero-img" />
                </div>

                <div className="sla-content-panel">
                    <div className="sla-icon">
                        <img
                            src="data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCA2NCA2NCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMzIiIGN5PSIzMiIgcj0iMzIiIGZpbGw9IiM1QTZGNEEiLz4KPHN2ZyB4PSIxNiIgeT0iMTYiIHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgdmlld0JveD0iMCAwIDMyIDMyIiBmaWxsPSJub25lIj4KPHBhdGggZD0iTTE2IDhDMTIuNjg2MyA4IDEwIDEwLjY4NjMgMTAgMTRWMThIMjJWMTRDMjIgMTAuNjg2MyAxOS4zMTM3IDggMTYgOFpNMTYgMTBDMTguMjA5MSAxMCAyMCAxMS43OTA5IDIwIDE0VjE2SDEyVjE0QzEyIDExLjc5MDkgMTMuNzkwOSAxMCAxNiAxMFpNOCAyMFYyNkM4IDI3LjEwNDYgOC44OTU0MyAyOCAxMCAyOEgyMkMyMy4xMDQ2IDI4IDI0IDI3LjEwNDYgMjQgMjZWMjBIOFpNMTYgMjJuMTcuMTA0NiAyMiAxOCAyMkMxOC44OTU0IDIyIDIwIDIyLjg5NTQgMjAgMjRDMjAgMjUuMTA0NiAxOC44OTU0IDI2IDE4IDI2QzE3LjEwNDYgMjYgMTYgMjUuMTA0NiAxNiAyNFoiIGZpbGw9IndoaXRlIi8+Cjwvc3ZnPgo8L3N2Zz4K"
                            alt="SLA Icon"
                        />
                    </div>

                    <h1 className="sla-title">Service Level Agreements</h1>

                    <p className="sla-lead">
                        CityFix app aims to foster large scale citizen participation.
                    </p>

                    <p className="sla-body">
                        The CityFix city rating system works on the number of complaints resolved by the
                        corporation — with adherence to Service Level Agreements and to the satisfaction
                        of the complainant. Action on the complaints may vary depending on the categories.
                        Action for most complaints will be initiated from 6 hours of registration. There
                        is a detailed escalation process built in the mobile application so that complaints
                        that are not resolved at the lower level are moved to higher levels for action and
                        resolution.
                    </p>
                </div>
            </div>

            <div className="sla-cards-section">
                <h2 className="sla-cards-heading">How SLAs Work</h2>
                <div className="sla-cards">
                    <div className="sla-card">
                        <div className="sla-card-icon">⏱️</div>
                        <h3>6-Hour Response</h3>
                        <p>Action for most complaints will be initiated within 6 hours of registration to ensure timely resolution.</p>
                    </div>
                    <div className="sla-card">
                        <div className="sla-card-icon">📋</div>
                        <h3>Category-Based Action</h3>
                        <p>Action timelines may vary depending on the nature and category of the complaint registered.</p>
                    </div>
                    <div className="sla-card">
                        <div className="sla-card-icon">🔺</div>
                        <h3>Escalation Process</h3>
                        <p>Unresolved complaints are automatically escalated to higher authorities for prompt action.</p>
                    </div>
                    <div className="sla-card">
                        <div className="sla-card-icon">⭐</div>
                        <h3>Satisfaction Rating</h3>
                        <p>Resolutions must meet the satisfaction of the complainant to count toward the city rating system.</p>
                    </div>
                </div>
            </div>
        </div>
    );
};

export default SLA;
