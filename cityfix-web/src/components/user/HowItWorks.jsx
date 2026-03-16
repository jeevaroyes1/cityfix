import React from 'react';
import './HowItWorks.css';

const portals = [
    {
        id: 1,
        title: 'Municipal Administrator Portal',
        description: 'A website for Municipal Commissioners and their digital teams to monitor the complaints received in their cities and towns.',
        img: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCA2NCA2NCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMzIiIGN5PSIzMiIgcj0iMzIiIGZpbGw9IiM1QTZGNEEiLz4KPHN2ZyB4PSIxNiIgeT0iMTYiIHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgdmlld0JveD0iMCAwIDMyIDMyIiBmaWxsPSJub25lIj4KPHBhdGggZD0iTTQgNEg2VjI4SDRWNFpNOCA0SDI4VjZIOFY0Wk04IDhIMjhWMTBIOFY4Wk04IDEySDI4VjE0SDhWMTJaTTggMTZIMjhWMThIOFYxNlpNOCAyMEgyOFYyMkg4VjIwWk04IDI0SDI4VjI2SDhWMjRaIiBmaWxsPSJ3aGl0ZSIvPgo8L3N2Zz4KPC9zdmc+Cg==',
    },
    {
        id: 2,
        title: 'Engineer Application',
        description: 'A mobile application in Android for the ULBs to see the complaints uploaded by the citizen and take action.',
        img: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCA2NCA2NCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMzIiIGN5PSIzMiIgcj0iMzIiIGZpbGw9IiM1QTZGNEEiLz4KPHN2ZyB4PSIxNiIgeT0iMTYiIHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgdmlld0JveD0iMCAwIDMyIDMyIiBmaWxsPSJub25lIj4KPHBhdGggZD0iTTggNEgyNFYyOEg4VjRaTTEwIDZWMjZIMjJWNkgxMFpNMTIgOEgyMFYxMEgxMlY4Wk0xMiAxMkgyMFYxNEgxMlYxMlpNMTIgMTZIMjBWMThIMTJWMTZaTTEyIDIwSDIwVjIySDEyVjIwWiIgZmlsbD0id2hpdGUiLz4KPC9zdmc+Cjwvc3ZnPgo=',
    },
    {
        id: 3,
        title: 'Citizen Application',
        description: 'A mobile application on Android and iOS for citizens to upload CityFix complaints.',
        img: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCA2NCA2NCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMzIiIGN5PSIzMiIgcj0iMzIiIGZpbGw9IiM1QTZGNEEiLz4KPHN2ZyB4PSIxNiIgeT0iMTYiIHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgdmlld0JveD0iMCAwIDMyIDMyIiBmaWxsPSJub25lIj4KPHBhdGggZD0iTTE2IDhDMTIuNjg2MyA4IDEwIDEwLjY4NjMgMTAgMTRWMThIMjJWMTRDMjIgMTAuNjg2MyAxOS4zMTM3IDggMTYgOFpNMTYgMTBDMTguMjA5MSAxMCAyMCAxMS43OTA5IDIwIDE0VjE2SDEyVjE0QzEyIDExLjc5MDkgMTMuNzkwOSAxMCAxNiAxMFpNOCAyMFYyNkM4IDI3LjEwNDYgOC44OTU0MyAyOCAxMCAyOEgyMkMyMy4xMDQ2IDI4IDI0IDI3LjEwNDYgMjQgMjZWMjBIOFoiIGZpbGw9IndoaXRlIi8+Cjwvc3ZnPgo8L3N2Zz4K',
    },
    {
        id: 4,
        title: 'Ranking & Rating Portal',
        description: 'This is a website open to all citizens, it will provide the ratings and rankings for all the cities on the CityFix platform based on the resolution rate of each ward in the city.',
        img: 'data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjQiIGhlaWdodD0iNjQiIHZpZXdCb3g9IjAgMCA2NCA2NCIgZmlsbD0ibm9uZSIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj4KPGNpcmNsZSBjeD0iMzIiIGN5PSIzMiIgcj0iMzIiIGZpbGw9IiM1QTZGNEEiLz4KPHN2ZyB4PSIxNiIgeT0iMTYiIHdpZHRoPSIzMiIgaGVpZ2h0PSIzMiIgdmlld0JveD0iMCAwIDMyIDMyIiBmaWxsPSJub25lIj4KPHBhdGggZD0iTTE2IDhMMTggMTJIMjZMMjAgMTZMMjIgMjRMMTYgMjBMMTAgMjRMMTIgMTZMNiAxMkgxNEwxNiA4WiIgZmlsbD0id2hpdGUiLz4KPC9zdmc+Cjwvc3ZnPgo=',
    },
];

const HowItWorks = () => {
    return (
        <div className="hiw-page">
            <div className="hiw-header">
                <h1 className="hiw-title">How It Works</h1>
                <p className="hiw-subtitle">
                    The key to the working of mobile applications such as CityFix is large scale citizen participation
                </p>
            </div>

            <div className="hiw-grid">
                {portals.map((portal) => (
                    <div className="hiw-card" key={portal.id}>
                        <div className="hiw-img-wrap">
                            <div className="hiw-img-ring hiw-img-ring--outer">
                                <div className="hiw-img-ring hiw-img-ring--inner">
                                    <img src={portal.img} alt={portal.title} />
                                </div>
                            </div>
                        </div>
                        <h3 className="hiw-card-title">{portal.title}</h3>
                        <p className="hiw-card-desc">{portal.description}</p>
                    </div>
                ))}
            </div>
        </div>
    );
};

export default HowItWorks;
