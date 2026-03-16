import {
    collection,
    addDoc,
    setDoc,
    getDocs,
    getDoc,
    doc,
    query,
    where,
    orderBy,
    updateDoc,
    deleteDoc,
    onSnapshot,
    serverTimestamp,
    Timestamp,
    writeBatch,
    increment
} from 'firebase/firestore';
import { db } from '../../config/firebase';

// Donation Operations
export const createDonation = async (donationData) => {
    try {
        const docRef = await addDoc(collection(db, 'donations'), {
            ...donationData,
            status: 'pending',
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp()
        });
        return docRef.id;
    } catch (error) {
        console.error('Error creating donation:', error);
        throw error;
    }
};

export const updateDonation = async (donationId, updates) => {
    try {
        const donationRef = doc(db, 'donations', donationId);
        await updateDoc(donationRef, {
            ...updates,
            updatedAt: serverTimestamp()
        });
    } catch (error) {
        console.error('Error updating donation:', error);
        throw error;
    }
};

export const getDonation = async (donationId) => {
    try {
        const donationDoc = await getDoc(doc(db, 'donations', donationId));
        if (donationDoc.exists()) {
            return { id: donationDoc.id, ...donationDoc.data() };
        }
        return null;
    } catch (error) {
        console.error('Error getting donation:', error);
        throw error;
    }
};

export const getDonorDonations = async (donorId) => {
    try {
        const q = query(
            collection(db, 'donations'),
            where('donorId', '==', donorId),
            orderBy('createdAt', 'desc')
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error('Error getting donor donations:', error);
        throw error;
    }
};

export const getCenterDonations = async (centerId) => {
    try {
        const q = query(
            collection(db, 'donations'),
            where('centerId', '==', centerId),
            orderBy('createdAt', 'desc')
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error('Error getting center donations:', error);
        throw error;
    }
};

// Subscription Operations
export const createSubscription = async (subscriptionData) => {
    try {
        const docRef = await addDoc(collection(db, 'subscriptions'), {
            ...subscriptionData,
            status: 'active',
            failedAttempts: 0,
            totalDonations: 0,
            totalAmount: 0,
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp()
        });
        return docRef.id;
    } catch (error) {
        console.error('Error creating subscription:', error);
        throw error;
    }
};

export const updateSubscription = async (subscriptionId, updates) => {
    try {
        const subscriptionRef = doc(db, 'subscriptions', subscriptionId);
        await updateDoc(subscriptionRef, {
            ...updates,
            updatedAt: serverTimestamp()
        });
    } catch (error) {
        console.error('Error updating subscription:', error);
        throw error;
    }
};

export const getSubscription = async (subscriptionId) => {
    try {
        const subscriptionDoc = await getDoc(doc(db, 'subscriptions', subscriptionId));
        if (subscriptionDoc.exists()) {
            return { id: subscriptionDoc.id, ...subscriptionDoc.data() };
        }
        return null;
    } catch (error) {
        console.error('Error getting subscription:', error);
        throw error;
    }
};

export const getDonorSubscriptions = async (donorId) => {
    try {
        const q = query(
            collection(db, 'subscriptions'),
            where('donorId', '==', donorId),
            orderBy('createdAt', 'desc')
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error('Error getting donor subscriptions:', error);
        throw error;
    }
};

export const getDueSubscriptions = async () => {
    try {
        const now = new Date();
        const q = query(
            collection(db, 'subscriptions'),
            where('status', '==', 'active'),
            where('nextPaymentDate', '<=', now)
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error('Error getting due subscriptions:', error);
        throw error;
    }
};

// Welfare Center Operations
export const createWelfareCenter = async (centerData) => {
    try {
        const docRef = await addDoc(collection(db, 'welfare_centers'), {
            ...centerData,
            totalDonationsReceived: 0,
            totalDonors: 0,
            averageRating: 0,
            isActive: true,
            isVerified: false,
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp()
        });
        return docRef.id;
    } catch (error) {
        console.error('Error creating welfare center:', error);
        throw error;
    }
};

export const updateWelfareCenter = async (centerId, updates) => {
    try {
        const centerRef = doc(db, 'welfare_centers', centerId);
        await updateDoc(centerRef, {
            ...updates,
            updatedAt: serverTimestamp()
        });
    } catch (error) {
        console.error('Error updating welfare center:', error);
        throw error;
    }
};

export const getWelfareCenter = async (centerId) => {
    try {
        const centerDoc = await getDoc(doc(db, 'welfare_centers', centerId));
        if (centerDoc.exists()) {
            return { id: centerDoc.id, ...centerDoc.data() };
        }
        return null;
    } catch (error) {
        console.error('Error getting welfare center:', error);
        throw error;
    }
};

export const getAllWelfareCenters = async () => {
    try {
        const q = query(
            collection(db, 'welfare_centers'),
            where('isActive', '==', true),
            orderBy('createdAt', 'desc')
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error('Error getting welfare centers:', error);
        throw error;
    }
};

// Impact Metrics Operations
export const createImpactMetric = async (metricData) => {
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
};

export const getCenterImpactMetrics = async (centerId) => {
    try {
        const q = query(
            collection(db, 'impact_metrics'),
            where('centerId', '==', centerId),
            orderBy('createdAt', 'desc')
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error('Error getting center impact metrics:', error);
        throw error;
    }
};

export const getDonationImpactMetrics = async (donationId) => {
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
};

// Receipt Operations
export const createReceipt = async (receiptData) => {
    try {
        const docRef = await addDoc(collection(db, 'receipts'), {
            ...receiptData,
            emailSent: false,
            createdAt: serverTimestamp()
        });
        return docRef.id;
    } catch (error) {
        console.error('Error creating receipt:', error);
        throw error;
    }
};

export const updateReceipt = async (receiptId, updates) => {
    try {
        const receiptRef = doc(db, 'receipts', receiptId);
        await updateDoc(receiptRef, updates);
    } catch (error) {
        console.error('Error updating receipt:', error);
        throw error;
    }
};

export const getDonorReceipts = async (donorId) => {
    try {
        const q = query(
            collection(db, 'receipts'),
            where('donorId', '==', donorId),
            orderBy('createdAt', 'desc')
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error('Error getting donor receipts:', error);
        throw error;
    }
};

// Real-time listeners
export const subscribeToDonorDonations = (donorId, callback, onError) => {
    const q = query(
        collection(db, 'donations'),
        where('donorId', '==', donorId),
        orderBy('createdAt', 'desc')
    );

    return onSnapshot(q,
        (snapshot) => {
            const donations = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            callback(donations);
        },
        (error) => {
            console.error('Error in subscribeToDonorDonations:', error);
            if (onError) onError(error);
        }
    );
};

export const subscribeToDonorSubscriptions = (donorId, callback, onError) => {
    const q = query(
        collection(db, 'subscriptions'),
        where('donorId', '==', donorId),
        orderBy('createdAt', 'desc')
    );

    return onSnapshot(q,
        (snapshot) => {
            const subscriptions = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            callback(subscriptions);
        },
        (error) => {
            console.error('Error in subscribeToDonorSubscriptions:', error);
            if (onError) onError(error);
        }
    );
};

// Analytics Operations
export const getDonorAnalytics = async (donorId) => {
    try {
        const donations = await getDonorDonations(donorId);
        const subscriptions = await getDonorSubscriptions(donorId);
        
        const totalDonated = donations.reduce((sum, d) => sum + d.amount, 0);
        const totalTaxSavings = donations.reduce((sum, d) => sum + (d.taxBenefit?.amount || 0), 0);
        
        return {
            totalDonations: donations.length,
            totalDonated,
            totalTaxSavings,
            activeSubscriptions: subscriptions.filter(s => s.status === 'active').length,
            donations,
            subscriptions
        };
    } catch (error) {
        console.error('Error getting donor analytics:', error);
        throw error;
    }
};

// Batch operations for data consistency
export const processDonationWithImpact = async (donationData, impactData, receiptData) => {
    const batch = writeBatch(db);
    
    try {
        // Create donation
        const donationRef = doc(collection(db, 'donations'));
        batch.set(donationRef, {
            ...donationData,
            status: 'completed',
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp()
        });
        
        // Create impact metrics
        const impactRef = doc(collection(db, 'impact_metrics'));
        batch.set(impactRef, {
            ...impactData,
            donationId: donationRef.id,
            verified: false,
            createdAt: serverTimestamp(),
            updatedAt: serverTimestamp()
        });
        
        // Create receipt
        const receiptRef = doc(collection(db, 'receipts'));
        batch.set(receiptRef, {
            ...receiptData,
            donationId: donationRef.id,
            emailSent: false,
            createdAt: serverTimestamp()
        });
        
        // Update welfare center stats
        const centerRef = doc(db, 'welfare_centers', donationData.centerId);
        batch.update(centerRef, {
            totalDonationsReceived: increment(donationData.amount),
            totalDonors: increment(1),
            updatedAt: serverTimestamp()
        });
        
        await batch.commit();
        return donationRef.id;
    } catch (error) {
        console.error('Error processing donation with impact:', error);
        throw error;
    }
};