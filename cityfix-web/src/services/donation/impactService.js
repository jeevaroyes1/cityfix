import {
    collection,
    addDoc,
    getDocs,
    getDoc,
    doc,
    query,
    where,
    orderBy,
    updateDoc,
    serverTimestamp,
    Timestamp
} from 'firebase/firestore';
import { db } from '../../config/firebase';
import { getWelfareCenterById } from '../../data/welfareCenters';

export class ImpactCalculator {
    static calculateImpact(donationAmount, centerMetrics) {
        if (!centerMetrics || !Array.isArray(centerMetrics)) {
            return [];
        }

        return centerMetrics.map(metric => ({
            category: metric.category,
            quantity: Math.floor(donationAmount / metric.costPerUnit),
            unit: metric.unit,
            description: metric.description,
            costPerUnit: metric.costPerUnit
        }));
    }

    static aggregateImpact(donations, period = null) {
        const impactMap = new Map();

        donations.forEach(donation => {
            if (period) {
                const donationDate = donation.createdAt?.toDate ? donation.createdAt.toDate() : new Date(donation.createdAt);
                if (donationDate < period.startDate || donationDate > period.endDate) {
                    return;
                }
            }

            if (donation.impactMetrics && Array.isArray(donation.impactMetrics)) {
                donation.impactMetrics.forEach(impact => {
                    const key = `${impact.category}_${impact.unit}`;
                    if (impactMap.has(key)) {
                        const existing = impactMap.get(key);
                        existing.quantity += impact.quantity;
                    } else {
                        impactMap.set(key, { ...impact });
                    }
                });
            }
        });

        return Array.from(impactMap.values());
    }

    static calculateTrends(donations, periods = 6) {
        const now = new Date();
        const trends = [];

        for (let i = periods - 1; i >= 0; i--) {
            const periodStart = new Date(now.getFullYear(), now.getMonth() - i, 1);
            const periodEnd = new Date(now.getFullYear(), now.getMonth() - i + 1, 0);

            const periodDonations = donations.filter(donation => {
                const donationDate = donation.createdAt?.toDate ? donation.createdAt.toDate() : new Date(donation.createdAt);
                return donationDate >= periodStart && donationDate <= periodEnd;
            });

            const totalAmount = periodDonations.reduce((sum, d) => sum + d.amount, 0);
            const totalImpact = this.aggregateImpact(periodDonations);

            trends.push({
                period: periodStart.toISOString().slice(0, 7), // YYYY-MM format
                totalAmount,
                donationCount: periodDonations.length,
                impact: totalImpact
            });
        }

        return trends;
    }

    static calculateEfficiency(donations) {
        const totalAmount = donations.reduce((sum, d) => sum + d.amount, 0);
        const totalImpact = this.aggregateImpact(donations);

        return totalImpact.map(impact => ({
            category: impact.category,
            impactPerRupee: totalAmount > 0 ? impact.quantity / totalAmount : 0,
            totalQuantity: impact.quantity,
            unit: impact.unit
        }));
    }
}

export class ImpactService {
    async createImpactMetric(metricData) {
        try {
            const docRef = await addDoc(collection(db, 'impact_metrics'), {
                ...metricData,
                verified: false,
                createdAt: serverTimestamp(),
                updatedAt: serverTimestamp()
            });
            return docRef.id;
        } catch (error) {
            console.error('Error creating impact metric:', error);
            throw error;
        }
    }

    async updateImpactMetric(metricId, updates) {
        try {
            await updateDoc(doc(db, 'impact_metrics', metricId), {
                ...updates,
                updatedAt: serverTimestamp()
            });
        } catch (error) {
            console.error('Error updating impact metric:', error);
            throw error;
        }
    }

    async getCenterImpactMetrics(centerId, period = null) {
        try {
            let q = query(
                collection(db, 'impact_metrics'),
                where('centerId', '==', centerId),
                orderBy('createdAt', 'desc')
            );

            const querySnapshot = await getDocs(q);
            let metrics = querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            if (period) {
                metrics = metrics.filter(metric => {
                    const metricDate = metric.createdAt?.toDate ? metric.createdAt.toDate() : new Date(metric.createdAt);
                    return metricDate >= period.startDate && metricDate <= period.endDate;
                });
            }

            return metrics;
        } catch (error) {
            console.error('Error getting center impact metrics:', error);
            throw error;
        }
    }

    async getDonationImpactMetrics(donationId) {
        try {
            const q = query(
                collection(db, 'impact_metrics'),
                where('donationId', '==', donationId)
            );
            const querySnapshot = await getDocs(q);
            return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
        } catch (error) {
            console.error('Error getting donation impact metrics:', error);
            throw error;
        }
    }

    async generateImpactReport(donorId, period) {
        try {
            // Get donor donations
            const donationsQuery = query(
                collection(db, 'donations'),
                where('donorId', '==', donorId),
                orderBy('createdAt', 'desc')
            );
            const donationsSnapshot = await getDocs(donationsQuery);
            const donations = donationsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            // Filter by period if provided
            const filteredDonations = period ? donations.filter(donation => {
                const donationDate = donation.createdAt?.toDate ? donation.createdAt.toDate() : new Date(donation.createdAt);
                return donationDate >= period.startDate && donationDate <= period.endDate;
            }) : donations;

            // Calculate aggregate impact
            const aggregateImpact = ImpactCalculator.aggregateImpact(filteredDonations, period);
            const trends = ImpactCalculator.calculateTrends(donations);
            const efficiency = ImpactCalculator.calculateEfficiency(filteredDonations);

            // Group by welfare center
            const centerImpact = new Map();
            filteredDonations.forEach(donation => {
                if (!centerImpact.has(donation.centerId)) {
                    centerImpact.set(donation.centerId, {
                        centerId: donation.centerId,
                        centerName: donation.centerName,
                        totalDonated: 0,
                        donationCount: 0,
                        impact: []
                    });
                }

                const center = centerImpact.get(donation.centerId);
                center.totalDonated += donation.amount;
                center.donationCount += 1;

                if (donation.impactMetrics) {
                    center.impact = ImpactCalculator.aggregateImpact([
                        ...center.impact.map(i => ({ impactMetrics: [i] })),
                        donation
                    ]);
                }
            });

            return {
                period,
                totalDonations: filteredDonations.length,
                totalAmount: filteredDonations.reduce((sum, d) => sum + d.amount, 0),
                aggregateImpact,
                trends,
                efficiency,
                centerBreakdown: Array.from(centerImpact.values()),
                generatedAt: new Date()
            };
        } catch (error) {
            console.error('Error generating impact report:', error);
            throw error;
        }
    }

    async getAggregateImpact(filters = {}) {
        try {
            let q = query(collection(db, 'donations'), orderBy('createdAt', 'desc'));

            // Apply filters
            if (filters.centerId) {
                q = query(q, where('centerId', '==', filters.centerId));
            }
            if (filters.donorId) {
                q = query(q, where('donorId', '==', filters.donorId));
            }

            const querySnapshot = await getDocs(q);
            const donations = querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            // Filter by date range if provided
            const filteredDonations = filters.period ? donations.filter(donation => {
                const donationDate = donation.createdAt?.toDate ? donation.createdAt.toDate() : new Date(donation.createdAt);
                return donationDate >= filters.period.startDate && donationDate <= filters.period.endDate;
            }) : donations;

            return ImpactCalculator.aggregateImpact(filteredDonations, filters.period);
        } catch (error) {
            console.error('Error getting aggregate impact:', error);
            throw error;
        }
    }

    async updateCenterMetrics(centerId, metrics) {
        try {
            // Verify center exists
            const center = getWelfareCenterById(centerId);
            if (!center) {
                throw new Error('Welfare center not found');
            }

            // Create impact metric records
            const metricPromises = metrics.map(metric => 
                this.createImpactMetric({
                    centerId,
                    ...metric,
                    verified: false // Requires admin verification
                })
            );

            const metricIds = await Promise.all(metricPromises);
            return metricIds;
        } catch (error) {
            console.error('Error updating center metrics:', error);
            throw error;
        }
    }

    // Helper method to calculate impact for a specific donation
    calculateDonationImpact(donationAmount, centerId) {
        const center = getWelfareCenterById(centerId);
        if (!center || !center.impactMetrics) {
            return [];
        }

        return ImpactCalculator.calculateImpact(donationAmount, center.impactMetrics);
    }

    // Method to get impact categories for a center
    getCenterImpactCategories(centerId) {
        const center = getWelfareCenterById(centerId);
        if (!center || !center.impactMetrics) {
            return [];
        }

        return center.impactMetrics.map(metric => ({
            category: metric.category,
            unit: metric.unit,
            costPerUnit: metric.costPerUnit,
            description: metric.description
        }));
    }

    // Method to format impact for display
    formatImpactForDisplay(impact) {
        const formatMap = {
            meals_served: { icon: '🍽️', label: 'Meals Served' },
            children_educated: { icon: '📚', label: 'Children Educated' },
            trees_planted: { icon: '🌳', label: 'Trees Planted' },
            animals_rescued: { icon: '🐾', label: 'Animals Rescued' },
            medical_checkups: { icon: '🏥', label: 'Medical Checkups' },
            healthcare_support: { icon: '💊', label: 'Healthcare Support' },
            park_maintenance: { icon: '🌿', label: 'Park Area Maintained' },
            veterinary_treatments: { icon: '🩺', label: 'Veterinary Treatments' },
            awareness_programs: { icon: '📢', label: 'Awareness Programs' },
            waste_cleanup: { icon: '♻️', label: 'Waste Cleaned' },
            clothing_provided: { icon: '👕', label: 'Clothing Sets' },
            food_provided: { icon: '🥘', label: 'Food Provided' },
            animals_adopted: { icon: '🏠', label: 'Animals Adopted' },
            recreational_activities: { icon: '🎭', label: 'Recreational Activities' }
        };

        return impact.map(item => ({
            ...item,
            icon: formatMap[item.category]?.icon || '📊',
            label: formatMap[item.category]?.label || item.category.replace(/_/g, ' ').replace(/\b\w/g, l => l.toUpperCase()),
            formattedQuantity: this.formatQuantity(item.quantity, item.unit)
        }));
    }

    formatQuantity(quantity, unit) {
        if (quantity >= 1000000) {
            return `${(quantity / 1000000).toFixed(1)}M ${unit}`;
        } else if (quantity >= 1000) {
            return `${(quantity / 1000).toFixed(1)}K ${unit}`;
        } else {
            return `${quantity} ${unit}`;
        }
    }
}

export const impactService = new ImpactService();