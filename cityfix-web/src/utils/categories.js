export const CATEGORIES = {
    'Infrastructure & Roads': [
        'Potholes',
        'Damaged Sidewalks',
        'Broken Street Signs',
        'Illegal Speed Bumps',
        'Road Blockages'
    ],
    'Utilities (Water & Electricity)': [
        'Water Leakage',
        'Sewage Overflow',
        'Street Light Outage',
        'Exposed Wires',
        'Low Water Pressure'
    ],
    'Sanitation & Environment': [
        'Illegal Dumping',
        'Missed Garbage Collection',
        'Overflowing Public Bins',
        'Graffiti/Vandalism',
        'Dead Animals'
    ],
    'Traffic & Public Safety': [
        'Broken Traffic Lights',
        'Abandoned Vehicles',
        'Illegal Parking',
        'Noise Pollution',
        'Stray Animals'
    ],
    'Parks & Recreation': [
        'Broken Playground Equipment',
        'Overgrown Grass/Weeds',
        'Park Vandalism'
    ]
};

export const getCategoryList = () => Object.keys(CATEGORIES);

export const getProblemTypes = (category) => CATEGORIES[category] || [];
