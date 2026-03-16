import {
    collection,
    getDocs,
    query,
    where,
    orderBy,
    limit
} from 'firebase/firestore';
import { db } from '../../config/firebase';
import { ImpactCalculator } from './impactService';

export class AnalyticsEngine {
    async generateDonorInsights(donorId) {
        try {
            // Get donor donations
            const donationsQuery = query(
                collection(db, 'donations'),
                where('donorId', '==', donorId),
                orderBy('createdAt', 'desc')
            );
            const donationsSnapshot = await getDocs(donationsQuery);
            const donations = donationsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            // Get donor subscriptions
            const subscriptionsQuery = query(
                collection(db, 'subscriptions'),
                where('donorId', '==', donorId),
                orderBy('createdAt', 'desc')
            );
            const subscriptionsSnapshot = await getDocs(subscriptionsQuery);
            const subscriptions = subscriptionsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            // Calculate basic metrics
            const totalDonated = donations.reduce((sum, d) => sum + d.amount, 0);
            const totalTaxSavings = donations.reduce((sum, d) => sum + (d.taxBenefit?.amount || 0), 0);
            const activeSubscriptions = subscriptions.filter(s => s.status === 'active').length;

            // Calculate donation frequency
            const donationFrequency = this.calculateDonationFrequency(donations);

            // Get preferred centers
            const preferredCenters = this.getPreferredCenters(donations);

            // Calculate impact metrics
            const impactMetrics = ImpactCalculator.aggregateImpact(donations);

            // Calculate trends
            const trends = ImpactCalculator.calculateTrends(donations);

            // Calculate giving patterns
            const givingPatterns = this.analyzeGivingPatterns(donations);

            // Calculate efficiency metrics
            const efficiency = ImpactCalculator.calculateEfficiency(donations);

            return {
                totalDonations: donations.length,
                totalDonated,
                totalTaxSavings,
                activeSubscriptions,
                donationFrequency,
                preferredCenters,
                impactMetrics,
                trends,
                givingPatterns,
                efficiency,
                donations,
                subscriptions,
                generatedAt: new Date()
            };
        } catch (error) {
            console.error('Error generating donor insights:', error);
            throw error;
        }
    }

    async generateCenterAnalytics(centerId) {
        try {
            // Get center donations
            const donationsQuery = query(
                collection(db, 'donations'),
                where('centerId', '==', centerId),
                orderBy('createdAt', 'desc')
            );
            const donationsSnapshot = await getDocs(donationsQuery);
            const donations = donationsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            // Get center subscriptions
            const subscriptionsQuery = query(
                collection(db, 'subscriptions'),
                where('centerId', '==', centerId),
                orderBy('createdAt', 'desc')
            );
            const subscriptionsSnapshot = await getDocs(subscriptionsQuery);
            const subscriptions = subscriptionsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            // Calculate basic metrics
            const totalReceived = donations.reduce((sum, d) => sum + d.amount, 0);
            const uniqueDonors = new Set(donations.map(d => d.donorId)).size;
            const activeSubscriptions = subscriptions.filter(s => s.status === 'active').length;

            // Calculate donor demographics
            const donorDemographics = this.analyzeDonorDemographics(donations);

            // Calculate donation patterns
            const donationPatterns = this.analyzeDonationPatterns(donations);

            // Calculate impact metrics
            const impactMetrics = ImpactCalculator.aggregateImpact(donations);

            // Calculate trends
            const trends = ImpactCalculator.calculateTrends(donations);

            // Calculate retention metrics
            const retentionMetrics = this.calculateRetentionMetrics(donations);

            return {
                totalDonations: donations.length,
                totalReceived,
                uniqueDonors,
                activeSubscriptions,
                averageDonation: donations.length > 0 ? totalReceived / donations.length : 0,
                donorDemographics,
                donationPatterns,
                impactMetrics,
                trends,
                retentionMetrics,
                donations,
                subscriptions,
                generatedAt: new Date()
            };
        } catch (error) {
            console.error('Error generating center analytics:', error);
            throw error;
        }
    }

    async generatePlatformAnalytics(period = null) {
        try {
            // Get all donations
            const donationsQuery = query(
                collection(db, 'donations'),
                orderBy('createdAt', 'desc')
            );
            const donationsSnapshot = await getDocs(donationsQuery);
            let donations = donationsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            // Filter by period if provided
            if (period) {
                donations = donations.filter(donation => {
                    const donationDate = donation.createdAt?.toDate ? donation.createdAt.toDate() : new Date(donation.createdAt);
                    return donationDate >= period.startDate && donationDate <= period.endDate;
                });
            }

            // Get all subscriptions
            const subscriptionsQuery = query(
                collection(db, 'subscriptions'),
                orderBy('createdAt', 'desc')
            );
            const subscriptionsSnapshot = await getDocs(subscriptionsQuery);
            const subscriptions = subscriptionsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            // Calculate platform metrics
            const totalDonated = donations.reduce((sum, d) => sum + d.amount, 0);
            const uniqueDonors = new Set(donations.map(d => d.donorId)).size;
            const uniqueCenters = new Set(donations.map(d => d.centerId)).size;
            const activeSubscriptions = subscriptions.filter(s => s.status === 'active').length;

            // Calculate center performance
            const centerPerformance = this.analyzeCenterPerformance(donations);

            // Calculate payment method distribution
            const paymentMethodDistribution = this.analyzePaymentMethods(donations);

            // Calculate geographic distribution
            const geographicDistribution = this.analyzeGeographicDistribution(donations);

            // Calculate impact metrics
            const impactMetrics = ImpactCalculator.aggregateImpact(donations);

            // Calculate trends
            const trends = ImpactCalculator.calculateTrends(donations);

            return {
                period,
                totalDonations: donations.length,
                totalDonated,
                uniqueDonors,
                uniqueCenters,
                activeSubscriptions,
                averageDonation: donations.length > 0 ? totalDonated / donations.length : 0,
                centerPerformance,
                paymentMethodDistribution,
                geographicDistribution,
                impactMetrics,
                trends,
                generatedAt: new Date()
            };
        } catch (error) {
            console.error('Error generating platform analytics:', error);
            throw error;
        }
    }

    // Helper methods for analysis
    calculateDonationFrequency(donations) {
        if (donations.length === 0) return { frequency: 'none', averageDaysBetween: 0 };

        const sortedDonations = donations.sort((a, b) => {
            const dateA = a.createdAt?.toDate ? a.createdAt.toDate() : new Date(a.createdAt);
            const dateB = b.createdAt?.toDate ? b.createdAt.toDate() : new Date(b.createdAt);
            return dateA - dateB;
        });

        if (sortedDonations.length < 2) {
            return { frequency: 'single', averageDaysBetween: 0 };
        }

        const intervals = [];
        for (let i = 1; i < sortedDonations.length; i++) {
            const prevDate = sortedDonations[i - 1].createdAt?.toDate ? sortedDonations[i - 1].createdAt.toDate() : new Date(sortedDonations[i - 1].createdAt);
            const currDate = sortedDonations[i].createdAt?.toDate ? sortedDonations[i].createdAt.toDate() : new Date(sortedDonations[i].createdAt);
            const daysDiff = Math.abs((currDate - prevDate) / (1000 * 60 * 60 * 24));
            intervals.push(daysDiff);
        }

        const averageDaysBetween = intervals.reduce((sum, interval) => sum + interval, 0) / intervals.length;

        let frequency;
        if (averageDaysBetween <= 7) frequency = 'weekly';
        else if (averageDaysBetween <= 30) frequency = 'monthly';
        else if (averageDaysBetween <= 90) frequency = 'quarterly';
        else frequency = 'occasional';

        return { frequency, averageDaysBetween: Math.round(averageDaysBetween) };
    }

    getPreferredCenters(donations) {
        const centerCounts = new Map();
        const centerAmounts = new Map();

        donations.forEach(donation => {
            const centerId = donation.centerId;
            const centerName = donation.centerName;

            centerCounts.set(centerId, (centerCounts.get(centerId) || 0) + 1);
            centerAmounts.set(centerId, (centerAmounts.get(centerId) || 0) + donation.amount);
        });

        const centers = Array.from(centerCounts.keys()).map(centerId => ({
            centerId,
            centerName: donations.find(d => d.centerId === centerId)?.centerName || 'Unknown',
            donationCount: centerCounts.get(centerId),
            totalAmount: centerAmounts.get(centerId),
            percentage: (centerCounts.get(centerId) / donations.length) * 100
        }));

        return centers.sort((a, b) => b.donationCount - a.donationCount);
    }

    analyzeGivingPatterns(donations) {
        const patterns = {
            byMonth: new Array(12).fill(0),
            byDayOfWeek: new Array(7).fill(0),
            byHour: new Array(24).fill(0),
            byAmount: {
                small: 0,    // < 500
                medium: 0,   // 500-2000
                large: 0,    // 2000-10000
                major: 0     // > 10000
            }
        };

        donations.forEach(donation => {
            const date = donation.createdAt?.toDate ? donation.createdAt.toDate() : new Date(donation.createdAt);
            
            patterns.byMonth[date.getMonth()]++;
            patterns.byDayOfWeek[date.getDay()]++;
            patterns.byHour[date.getHours()]++;

            if (donation.amount < 500) patterns.byAmount.small++;
            else if (donation.amount < 2000) patterns.byAmount.medium++;
            else if (donation.amount < 10000) patterns.byAmount.large++;
            else patterns.byAmount.major++;
        });

        return patterns;
    }

    analyzeDonorDemographics(donations) {
        const demographics = {
            totalDonors: new Set(donations.map(d => d.donorId)).size,
            repeatDonors: 0,
            newDonors: 0,
            topDonors: []
        };

        const donorCounts = new Map();
        const donorAmounts = new Map();

        donations.forEach(donation => {
            const donorId = donation.donorId;
            donorCounts.set(donorId, (donorCounts.get(donorId) || 0) + 1);
            donorAmounts.set(donorId, (donorAmounts.get(donorId) || 0) + donation.amount);
        });

        donorCounts.forEach((count, donorId) => {
            if (count > 1) demographics.repeatDonors++;
            else demographics.newDonors++;
        });

        demographics.topDonors = Array.from(donorAmounts.entries())
            .map(([donorId, amount]) => ({
                donorId,
                donorName: donations.find(d => d.donorId === donorId)?.donorName || 'Anonymous',
                totalAmount: amount,
                donationCount: donorCounts.get(donorId)
            }))
            .sort((a, b) => b.totalAmount - a.totalAmount)
            .slice(0, 10);

        return demographics;
    }

    analyzeDonationPatterns(donations) {
        const patterns = this.analyzeGivingPatterns(donations);
        
        // Add seasonal analysis
        const seasons = { spring: 0, summer: 0, autumn: 0, winter: 0 };
        donations.forEach(donation => {
            const month = (donation.createdAt?.toDate ? donation.createdAt.toDate() : new Date(donation.createdAt)).getMonth();
            if (month >= 2 && month <= 4) seasons.spring++;
            else if (month >= 5 && month <= 7) seasons.summer++;
            else if (month >= 8 && month <= 10) seasons.autumn++;
            else seasons.winter++;
        });

        return { ...patterns, bySeason: seasons };
    }

    calculateRetentionMetrics(donations) {
        const donorFirstDonation = new Map();
        const donorLastDonation = new Map();

        donations.forEach(donation => {
            const donorId = donation.donorId;
            const donationDate = donation.createdAt?.toDate ? donation.createdAt.toDate() : new Date(donation.createdAt);

            if (!donorFirstDonation.has(donorId) || donationDate < donorFirstDonation.get(donorId)) {
                donorFirstDonation.set(donorId, donationDate);
            }

            if (!donorLastDonation.has(donorId) || donationDate > donorLastDonation.get(donorId)) {
                donorLastDonation.set(donorId, donationDate);
            }
        });

        const now = new Date();
        const thirtyDaysAgo = new Date(now.getTime() - 30 * 24 * 60 * 60 * 1000);
        const ninetyDaysAgo = new Date(now.getTime() - 90 * 24 * 60 * 60 * 1000);

        let activeDonors30 = 0;
        let activeDonors90 = 0;

        donorLastDonation.forEach(lastDonation => {
            if (lastDonation >= thirtyDaysAgo) activeDonors30++;
            if (lastDonation >= ninetyDaysAgo) activeDonors90++;
        });

        return {
            totalDonors: donorFirstDonation.size,
            activeDonors30,
            activeDonors90,
            retentionRate30: donorFirstDonation.size > 0 ? (activeDonors30 / donorFirstDonation.size) * 100 : 0,
            retentionRate90: donorFirstDonation.size > 0 ? (activeDonors90 / donorFirstDonation.size) * 100 : 0
        };
    }

    analyzeCenterPerformance(donations) {
        const centerMetrics = new Map();

        donations.forEach(donation => {
            const centerId = donation.centerId;
            if (!centerMetrics.has(centerId)) {
                centerMetrics.set(centerId, {
                    centerId,
                    centerName: donation.centerName,
                    totalAmount: 0,
                    donationCount: 0,
                    uniqueDonors: new Set()
                });
            }

            const metrics = centerMetrics.get(centerId);
            metrics.totalAmount += donation.amount;
            metrics.donationCount++;
            metrics.uniqueDonors.add(donation.donorId);
        });

        return Array.from(centerMetrics.values())
            .map(metrics => ({
                ...metrics,
                uniqueDonors: metrics.uniqueDonors.size,
                averageDonation: metrics.totalAmount / metrics.donationCount
            }))
            .sort((a, b) => b.totalAmount - a.totalAmount);
    }

    analyzePaymentMethods(donations) {
        const methods = new Map();

        donations.forEach(donation => {
            const method = donation.paymentMethod || 'unknown';
            methods.set(method, (methods.get(method) || 0) + 1);
        });

        const total = donations.length;
        return Array.from(methods.entries()).map(([method, count]) => ({
            method,
            count,
            percentage: (count / total) * 100
        }));
    }

    analyzeGeographicDistribution(donations) {
        // This would require donor location data
        // For now, return a placeholder
        return {
            byState: new Map(),
            byCity: new Map(),
            international: 0
        };
    }
}

export const analyticsEngine = new AnalyticsEngine();