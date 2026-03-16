// Enhanced welfare centers data with impact metrics and registration details
export const welfareCenters = [
    {
        id: 'hastha-old-age-home',
        name: "Hastha Old Age Home",
        shortDescription: "Care and shelter for the elderly",
        description: "Hastha Old Age Home has been a sanctuary for the elderly since 1998. We provide medical care, recreational activities, and a loving community for seniors who need support in their golden years.",
        category: 'old_age_home',
        icon: "👴",
        images: [
            "https://images.unsplash.com/photo-1559757148-5c350d0d3c56?w=400",
            "https://images.unsplash.com/photo-1576091160399-112ba8d25d1f?w=400"
        ],
        location: {
            address: "North Avenue, Sector 12",
            city: "City",
            state: "State",
            pincode: "123456",
            coordinates: { lat: 28.6139, lng: 77.2090 }
        },
        contact: {
            phone: "+91-9876543210",
            email: "contact@hasthaoldagehome.org",
            website: "https://hasthaoldagehome.org"
        },
        registration: {
            number: "REG/2023/OAH/001",
            type: "Non-Profit Organization",
            taxExemption: true,
            section80G: true
        },
        founded: "1998",
        members: "120+ Residents",
        isActive: true,
        isVerified: true,
        impactMetrics: [
            {
                category: "meals_served",
                unit: "meals",
                costPerUnit: 50,
                description: "Nutritious meals provided to elderly residents"
            },
            {
                category: "medical_checkups",
                unit: "checkups",
                costPerUnit: 200,
                description: "Regular health checkups and medical care"
            },
            {
                category: "recreational_activities",
                unit: "activities",
                costPerUnit: 100,
                description: "Entertainment and recreational programs"
            }
        ],
        totalDonationsReceived: 0,
        totalDonors: 0,
        averageRating: 4.8
    },
    {
        id: 'city-orphanage',
        name: "City Orphanage",
        shortDescription: "A loving home for children",
        description: "City Orphanage is dedicated to providing a nurturing environment for orphaned and vulnerable children. We ensure education, healthcare, and emotional support for every child in our care.",
        category: 'orphanage',
        icon: "👶",
        images: [
            "https://images.unsplash.com/photo-1488521787991-ed7bbaae773c?w=400",
            "https://images.unsplash.com/photo-1503454537195-1dcabb73ffb9?w=400"
        ],
        location: {
            address: "Green Valley, Block A",
            city: "City",
            state: "State",
            pincode: "123457",
            coordinates: { lat: 28.6129, lng: 77.2295 }
        },
        contact: {
            phone: "+91-9876543211",
            email: "info@cityorphanage.org",
            website: "https://cityorphanage.org"
        },
        registration: {
            number: "REG/2023/ORG/002",
            type: "Charitable Trust",
            taxExemption: true,
            section80G: true
        },
        founded: "2005",
        members: "200+ Children",
        isActive: true,
        isVerified: true,
        impactMetrics: [
            {
                category: "children_educated",
                unit: "children",
                costPerUnit: 500,
                description: "Monthly education support per child"
            },
            {
                category: "meals_provided",
                unit: "meals",
                costPerUnit: 30,
                description: "Nutritious meals for growing children"
            },
            {
                category: "healthcare_support",
                unit: "treatments",
                costPerUnit: 300,
                description: "Medical care and health monitoring"
            },
            {
                category: "clothing_provided",
                unit: "sets",
                costPerUnit: 150,
                description: "Clothing and essential items"
            }
        ],
        totalDonationsReceived: 0,
        totalDonors: 0,
        averageRating: 4.9
    },
    {
        id: 'green-earth-initiative',
        name: "Green Earth Initiative",
        shortDescription: "Planting trees for a greener city",
        description: "The Green Earth Initiative works tirelessly to expand the city's green cover. We organize community tree planting drives, maintain public parks, and educate citizens about environmental conservation.",
        category: 'environment',
        icon: "🌳",
        images: [
            "https://images.unsplash.com/photo-1441974231531-c6227db76b6e?w=400",
            "https://images.unsplash.com/photo-1542601906990-b4d3fb778b09?w=400"
        ],
        location: {
            address: "Eco Park, Central District",
            city: "City",
            state: "State",
            pincode: "123458",
            coordinates: { lat: 28.6219, lng: 77.2419 }
        },
        contact: {
            phone: "+91-9876543212",
            email: "contact@greenearthinitiative.org",
            website: "https://greenearthinitiative.org"
        },
        registration: {
            number: "REG/2023/ENV/003",
            type: "Environmental NGO",
            taxExemption: true,
            section80G: true
        },
        founded: "2010",
        members: "5000+ Volunteers",
        isActive: true,
        isVerified: true,
        impactMetrics: [
            {
                category: "trees_planted",
                unit: "trees",
                costPerUnit: 25,
                description: "Native trees planted and maintained"
            },
            {
                category: "park_maintenance",
                unit: "sq_meters",
                costPerUnit: 5,
                description: "Public park area maintained monthly"
            },
            {
                category: "awareness_programs",
                unit: "programs",
                costPerUnit: 1000,
                description: "Environmental awareness workshops"
            },
            {
                category: "waste_cleanup",
                unit: "kg",
                costPerUnit: 10,
                description: "Waste collected and properly disposed"
            }
        ],
        totalDonationsReceived: 0,
        totalDonors: 0,
        averageRating: 4.7
    },
    {
        id: 'paws-care-shelter',
        name: "Paws & Care Shelter",
        shortDescription: "Rescue and rehab for animals",
        description: "Paws & Care Shelter is a safe haven for injured and abandoned animals. Our dedicated team rescues strays, provides veterinary treatment, and works to find loving homes for every animal.",
        category: 'animal_shelter',
        icon: "🐾",
        images: [
            "https://images.unsplash.com/photo-1601758228041-f3b2795255f1?w=400",
            "https://images.unsplash.com/photo-1548199973-03cce0bbc87b?w=400"
        ],
        location: {
            address: "West End, Industrial Area",
            city: "City",
            state: "State",
            pincode: "123459",
            coordinates: { lat: 28.5355, lng: 77.3910 }
        },
        contact: {
            phone: "+91-9876543213",
            email: "help@pawsandcare.org",
            website: "https://pawsandcare.org"
        },
        registration: {
            number: "REG/2023/ANM/004",
            type: "Animal Welfare Society",
            taxExemption: true,
            section80G: true
        },
        founded: "2015",
        members: "350+ Animals",
        isActive: true,
        isVerified: true,
        impactMetrics: [
            {
                category: "animals_rescued",
                unit: "animals",
                costPerUnit: 500,
                description: "Animals rescued and provided initial care"
            },
            {
                category: "veterinary_treatments",
                unit: "treatments",
                costPerUnit: 800,
                description: "Medical treatments and surgeries"
            },
            {
                category: "animals_adopted",
                unit: "adoptions",
                costPerUnit: 200,
                description: "Successful adoptions facilitated"
            },
            {
                category: "food_provided",
                unit: "kg",
                costPerUnit: 20,
                description: "Nutritious food for shelter animals"
            }
        ],
        totalDonationsReceived: 0,
        totalDonors: 0,
        averageRating: 4.6
    }
];

export const getWelfareCenterById = (id) => {
    return welfareCenters.find(center => center.id === id);
};

export const getWelfareCentersByCategory = (category) => {
    return welfareCenters.filter(center => center.category === category);
};

export const getActiveWelfareCenters = () => {
    return welfareCenters.filter(center => center.isActive);
};

export const getVerifiedWelfareCenters = () => {
    return welfareCenters.filter(center => center.isVerified);
};