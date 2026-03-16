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
    Timestamp
} from 'firebase/firestore';
import { db } from '../config/firebase';

// ... calculateDistance remains same ...

// User Profile Operations
export const createUserProfile = async (uid, userData) => {
    try {
        // Use setDoc with uid as document ID to be consistent with Flutter app
        await setDoc(doc(db, 'users', uid), {
            uid,
            ...userData,
            updatedAt: serverTimestamp(),
            createdAt: userData.createdAt || serverTimestamp()
        });
    } catch (error) {
        console.error('Error creating user profile:', error);
        throw error;
    }
};

export const getUserProfile = async (uid) => {
    try {
        // 1. Try to get document by ID (consistent with Flutter and new Web structure)
        const userDocRef = doc(db, 'users', uid);
        const userDoc = await getDoc(userDocRef);

        if (userDoc.exists()) {
            return { id: userDoc.id, ...userDoc.data() };
        }

        // 2. Fallback: Query by uid field (for legacy web profiles)
        const q = query(collection(db, 'users'), where('uid', '==', uid));
        const querySnapshot = await getDocs(q);

        if (!querySnapshot.empty) {
            return { id: querySnapshot.docs[0].id, ...querySnapshot.docs[0].data() };
        }

        return null;
    } catch (error) {
        console.error('Error getting user profile:', error);
        throw error;
    }
};

export const updateUserProfile = async (docId, updates) => {
    try {
        const userRef = doc(db, 'users', docId);
        await updateDoc(userRef, updates);
    } catch (error) {
        console.error('Error updating user profile:', error);
        throw error;
    }
};

// Report Operations
export const createReport = async (reportData) => {
    try {
        const docRef = await addDoc(collection(db, 'reports'), {
            ...reportData,
            status: 'Pending',
            createdAt: serverTimestamp()
        });
        return docRef.id;
    } catch (error) {
        console.error('Error creating report:', error);
        throw error;
    }
};

export const getUserReports = async (userId) => {
    try {
        const q = query(
            collection(db, 'reports'),
            where('userId', '==', userId),
            orderBy('createdAt', 'desc')
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error('Error getting user reports:', error);
        throw error;
    }
};

// Alias for consistency with component imports
export const getReportsByUser = getUserReports;

export const getAllReports = async () => {
    try {
        const q = query(
            collection(db, 'reports'),
            orderBy('createdAt', 'desc')
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error('Error getting all reports:', error);
        throw error;
    }
};

export const updateReport = async (reportId, updates) => {
    try {
        const reportRef = doc(db, 'reports', reportId);
        await updateDoc(reportRef, updates);
    } catch (error) {
        console.error('Error updating report:', error);
        throw error;
    }
};

export const deleteReport = async (reportId) => {
    try {
        await deleteDoc(doc(db, 'reports', reportId));
    } catch (error) {
        console.error('Error deleting report:', error);
        throw error;
    }
};

// Duplicate Detection
export const checkDuplicateReport = async (latitude, longitude, problemType) => {
    try {
        const reportsSnapshot = await getDocs(collection(db, 'reports'));

        for (const reportDoc of reportsSnapshot.docs) {
            const report = reportDoc.data();

            // Check if same problem type
            if (report.problemType === problemType) {
                const distance = calculateDistance(
                    latitude,
                    longitude,
                    report.latitude,
                    report.longitude
                );

                // Check if within 20 meters
                if (distance <= 20) {
                    return {
                        isDuplicate: true,
                        existingReport: { id: reportDoc.id, ...report }
                    };
                }
            }
        }

        return { isDuplicate: false };
    } catch (error) {
        console.error('Error checking duplicate report:', error);
        throw error;
    }
};

// Real-time listeners
export const subscribeToUserReports = (userId, callback, onError) => {
    const q = query(
        collection(db, 'reports'),
        where('userId', '==', userId),
        orderBy('createdAt', 'desc')
    );

    return onSnapshot(q,
        (snapshot) => {
            const reports = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            callback(reports);
        },
        (error) => {
            console.error('Error in subscribeToUserReports:', error);
            if (onError) onError(error);
        }
    );
};

export const subscribeToAllReports = (callback, onError) => {
    const q = query(
        collection(db, 'reports'),
        orderBy('createdAt', 'desc')
    );

    return onSnapshot(q,
        (snapshot) => {
            const reports = snapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
            callback(reports);
        },
        (error) => {
            console.error('Error in subscribeToAllReports:', error);
            if (onError) onError(error);
        }
    );
};

export const getReportStats = async (userId) => {
    try {
        const reports = await getUserReports(userId);

        return {
            total: reports.length,
            pending: reports.filter(r => r.status === 'Pending').length,
            inProgress: reports.filter(r => r.status === 'In Progress').length,
            resolved: reports.filter(r => r.status === 'Resolved').length
        };
    } catch (error) {
        console.error('Error getting report stats:', error);
        throw error;
    }
};

// Lost and Found Operations
export const getUserPanchayat = async (uid) => {
    try {
        const userDoc = await getDoc(doc(db, 'users', uid));
        if (userDoc.exists()) {
            return userDoc.data().panchayat || null;
        }
        return null;
    } catch (error) {
        console.error('Error getting user panchayat:', error);
        throw error;
    }
};

export const createLostAndFoundItem = async (itemData) => {
    try {
        const docRef = await addDoc(collection(db, 'lost_and_found_items'), {
            ...itemData,
            createdAt: serverTimestamp()
        });
        return docRef.id;
    } catch (error) {
        console.error('Error creating lost and found item:', error);
        throw error;
    }
};

export const updateLostAndFoundItem = async (itemId, updates) => {
    try {
        const itemRef = doc(db, 'lost_and_found_items', itemId);
        await updateDoc(itemRef, {
            ...updates,
            updatedAt: serverTimestamp()
        });
    } catch (error) {
        console.error('Error updating lost and found item:', error);
        throw error;
    }
};

export const getLostAndFoundItems = async () => {
    try {
        const q = query(
            collection(db, 'lost_and_found_items'),
            orderBy('createdAt', 'desc')
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error('Error getting lost and found items:', error);
        throw error;
    }
};

// News Updates Operations
export const createNewsUpdate = async (newsData) => {
    try {
        const docRef = await addDoc(collection(db, 'news_updates'), {
            ...newsData,
            createdAt: serverTimestamp()
        });
        return docRef.id;
    } catch (error) {
        console.error('Error creating news update:', error);
        throw error;
    }
};

export const getNewsUpdates = async () => {
    try {
        const q = query(
            collection(db, 'news_updates'),
            orderBy('createdAt', 'desc')
        );
        const querySnapshot = await getDocs(q);
        return querySnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));
    } catch (error) {
        console.error('Error getting news updates:', error);
        throw error;
    }
};
