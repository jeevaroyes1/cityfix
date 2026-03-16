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
import { createDonation, updateWelfareCenter } from './donationService';
import { PaymentGatewayFactory } from './paymentService';

export class SubscriptionManager {
    constructor() {
        this.retryDelays = [1, 3, 7]; // Days for retry attempts
    }

    async createSubscription(subscriptionData) {
        try {
            // Validate subscription data
            this.validateSubscriptionData(subscriptionData);

            // Create gateway subscription
            const gateway = PaymentGatewayFactory.createGateway(subscriptionData.paymentGateway);
            const gatewaySubscription = await gateway.setupRecurring(subscriptionData);

            // Calculate next payment date
            const nextPaymentDate = this.calculateNextPaymentDate(subscriptionData.frequency);

            // Store in Firestore
            const docRef = await addDoc(collection(db, 'subscriptions'), {
                ...subscriptionData,
                gatewaySubscriptionId: gatewaySubscription.id,
                status: 'active',
                nextPaymentDate,
                failedAttempts: 0,
                totalDonations: 0,
                totalAmount: 0,
                notifications: {
                    emailEnabled: true,
                    reminderDays: 3
                },
                createdAt: serverTimestamp(),
                updatedAt: serverTimestamp()
            });

            // Send confirmation email
            await this.sendConfirmationEmail(subscriptionData.donorEmail, {
                subscriptionId: docRef.id,
                amount: subscriptionData.amount,
                frequency: subscriptionData.frequency,
                centerName: subscriptionData.centerName
            });

            return docRef.id;
        } catch (error) {
            console.error('Error creating subscription:', error);
            throw error;
        }
    }

    async updateSubscription(subscriptionId, updates) {
        try {
            const subscription = await this.getSubscription(subscriptionId);
            if (!subscription) {
                throw new Error('Subscription not found');
            }

            // Update gateway subscription if payment details changed
            if (updates.amount || updates.frequency || updates.paymentMethod) {
                const gateway = PaymentGatewayFactory.createGateway(subscription.paymentGateway);
                await gateway.updateSubscription(subscription.gatewaySubscriptionId, updates);
            }

            // Calculate new next payment date if frequency changed
            if (updates.frequency) {
                updates.nextPaymentDate = this.calculateNextPaymentDate(updates.frequency);
            }

            // Update in Firestore
            await updateDoc(doc(db, 'subscriptions', subscriptionId), {
                ...updates,
                updatedAt: serverTimestamp()
            });

            // Send confirmation email
            await this.sendUpdateConfirmationEmail(subscription.donorEmail, {
                subscriptionId,
                updates
            });

            return true;
        } catch (error) {
            console.error('Error updating subscription:', error);
            throw error;
        }
    }

    async cancelSubscription(subscriptionId, reason = '') {
        try {
            const subscription = await this.getSubscription(subscriptionId);
            if (!subscription) {
                throw new Error('Subscription not found');
            }

            // Cancel gateway subscription
            const gateway = PaymentGatewayFactory.createGateway(subscription.paymentGateway);
            await gateway.cancelSubscription(subscription.gatewaySubscriptionId);

            // Update in Firestore
            await updateDoc(doc(db, 'subscriptions', subscriptionId), {
                status: 'cancelled',
                cancellationReason: reason,
                cancelledAt: serverTimestamp(),
                updatedAt: serverTimestamp()
            });

            // Send cancellation confirmation
            await this.sendCancellationEmail(subscription.donorEmail, {
                subscriptionId,
                centerName: subscription.centerName,
                reason
            });

            return true;
        } catch (error) {
            console.error('Error cancelling subscription:', error);
            throw error;
        }
    }

    async pauseSubscription(subscriptionId, pauseUntil) {
        try {
            const pauseDate = new Date(pauseUntil);
            const maxPauseDate = new Date();
            maxPauseDate.setMonth(maxPauseDate.getMonth() + 6); // Max 6 months

            if (pauseDate > maxPauseDate) {
                throw new Error('Pause duration cannot exceed 6 months');
            }

            await updateDoc(doc(db, 'subscriptions', subscriptionId), {
                status: 'paused',
                pausedUntil: Timestamp.fromDate(pauseDate),
                updatedAt: serverTimestamp()
            });

            return true;
        } catch (error) {
            console.error('Error pausing subscription:', error);
            throw error;
        }
    }

    async resumeSubscription(subscriptionId) {
        try {
            const nextPaymentDate = this.calculateNextPaymentDate('monthly'); // Resume with monthly

            await updateDoc(doc(db, 'subscriptions', subscriptionId), {
                status: 'active',
                pausedUntil: null,
                nextPaymentDate,
                updatedAt: serverTimestamp()
            });

            return true;
        } catch (error) {
            console.error('Error resuming subscription:', error);
            throw error;
        }
    }

    async processRecurringPayments() {
        try {
            const dueSubscriptions = await this.getDueSubscriptions();
            const results = [];

            for (const subscription of dueSubscriptions) {
                try {
                    const result = await this.processSubscriptionPayment(subscription);
                    results.push({ subscriptionId: subscription.id, success: true, result });
                } catch (error) {
                    console.error(`Failed to process subscription ${subscription.id}:`, error);
                    await this.handleFailedPayment(subscription.id, error);
                    results.push({ subscriptionId: subscription.id, success: false, error: error.message });
                }
            }

            return results;
        } catch (error) {
            console.error('Error processing recurring payments:', error);
            throw error;
        }
    }

    async processSubscriptionPayment(subscription) {
        try {
            // Create donation record
            const donationData = {
                donorId: subscription.donorId,
                donorEmail: subscription.donorEmail,
                donorName: subscription.donorName,
                centerId: subscription.centerId,
                centerName: subscription.centerName,
                amount: subscription.amount,
                currency: subscription.currency,
                paymentMethod: subscription.paymentMethod,
                paymentGateway: subscription.paymentGateway,
                isRecurring: true,
                subscriptionId: subscription.id
            };

            // Process payment through gateway
            const gateway = PaymentGatewayFactory.createGateway(subscription.paymentGateway);
            const paymentResult = await gateway.processRecurringPayment(subscription.gatewaySubscriptionId);

            if (paymentResult.success) {
                // Create donation record
                donationData.transactionId = paymentResult.transactionId;
                donationData.status = 'completed';
                const donationId = await createDonation(donationData);

                // Update subscription
                const nextPaymentDate = this.calculateNextPaymentDate(subscription.frequency);
                await updateDoc(doc(db, 'subscriptions', subscription.id), {
                    lastPaymentDate: serverTimestamp(),
                    nextPaymentDate,
                    totalDonations: subscription.totalDonations + 1,
                    totalAmount: subscription.totalAmount + subscription.amount,
                    failedAttempts: 0,
                    updatedAt: serverTimestamp()
                });

                // Send success notification
                await this.sendPaymentSuccessEmail(subscription.donorEmail, {
                    amount: subscription.amount,
                    centerName: subscription.centerName,
                    transactionId: paymentResult.transactionId
                });

                return { donationId, transactionId: paymentResult.transactionId };
            } else {
                throw new Error(paymentResult.error || 'Payment failed');
            }
        } catch (error) {
            console.error('Error processing subscription payment:', error);
            throw error;
        }
    }

    async handleFailedPayment(subscriptionId, error) {
        try {
            const subscription = await this.getSubscription(subscriptionId);
            const failureCount = subscription.failedAttempts + 1;

            if (failureCount >= 3) {
                // Pause subscription after 3 failures
                await this.pauseSubscription(subscriptionId, 'payment_failures');
                await this.sendSubscriptionPausedEmail(subscription.donorEmail, {
                    subscriptionId,
                    centerName: subscription.centerName,
                    reason: 'Multiple payment failures'
                });
            } else {
                // Schedule retry
                const nextRetry = this.calculateNextRetry(failureCount);
                await updateDoc(doc(db, 'subscriptions', subscriptionId), {
                    failedAttempts: failureCount,
                    nextPaymentDate: nextRetry,
                    updatedAt: serverTimestamp()
                });

                // Send failure notification
                await this.sendPaymentFailureEmail(subscription.donorEmail, {
                    subscriptionId,
                    centerName: subscription.centerName,
                    attemptNumber: failureCount,
                    nextRetryDate: nextRetry,
                    error: error.message
                });
            }
        } catch (error) {
            console.error('Error handling failed payment:', error);
            throw error;
        }
    }

    async getDueSubscriptions() {
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
    }

    async getSubscription(subscriptionId) {
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
    }

    // Helper methods
    validateSubscriptionData(data) {
        const required = ['donorId', 'donorEmail', 'centerId', 'amount', 'frequency', 'paymentGateway'];
        for (const field of required) {
            if (!data[field]) {
                throw new Error(`Missing required field: ${field}`);
            }
        }

        if (!['monthly', 'quarterly', 'yearly'].includes(data.frequency)) {
            throw new Error('Invalid frequency. Must be monthly, quarterly, or yearly');
        }

        if (data.amount <= 0) {
            throw new Error('Amount must be greater than 0');
        }
    }

    calculateNextPaymentDate(frequency) {
        const now = new Date();
        switch (frequency) {
            case 'monthly':
                now.setMonth(now.getMonth() + 1);
                break;
            case 'quarterly':
                now.setMonth(now.getMonth() + 3);
                break;
            case 'yearly':
                now.setFullYear(now.getFullYear() + 1);
                break;
            default:
                throw new Error('Invalid frequency');
        }
        return Timestamp.fromDate(now);
    }

    calculateNextRetry(attemptNumber) {
        const delayDays = this.retryDelays[attemptNumber - 1] || 7;
        const retryDate = new Date();
        retryDate.setDate(retryDate.getDate() + delayDays);
        return Timestamp.fromDate(retryDate);
    }

    // Email notification methods (to be implemented with actual email service)
    async sendConfirmationEmail(email, data) {
        console.log('Sending subscription confirmation email to:', email, data);
        // TODO: Implement with Firebase Functions or email service
    }

    async sendUpdateConfirmationEmail(email, data) {
        console.log('Sending subscription update confirmation email to:', email, data);
        // TODO: Implement with Firebase Functions or email service
    }

    async sendCancellationEmail(email, data) {
        console.log('Sending subscription cancellation email to:', email, data);
        // TODO: Implement with Firebase Functions or email service
    }

    async sendPaymentSuccessEmail(email, data) {
        console.log('Sending payment success email to:', email, data);
        // TODO: Implement with Firebase Functions or email service
    }

    async sendPaymentFailureEmail(email, data) {
        console.log('Sending payment failure email to:', email, data);
        // TODO: Implement with Firebase Functions or email service
    }

    async sendSubscriptionPausedEmail(email, data) {
        console.log('Sending subscription paused email to:', email, data);
        // TODO: Implement with Firebase Functions or email service
    }
}

export const subscriptionManager = new SubscriptionManager();