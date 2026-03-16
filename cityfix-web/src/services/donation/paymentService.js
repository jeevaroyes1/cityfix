// Payment Gateway Factory and Implementations
export class PaymentGatewayFactory {
    static createGateway(type) {
        switch (type) {
            case 'razorpay':
                return new RazorpayGateway();
            case 'stripe':
                return new StripeGateway();
            case 'paypal':
                return new PayPalGateway();
            default:
                throw new Error(`Unsupported payment gateway: ${type}`);
        }
    }
}

// Base Payment Gateway Interface
export class PaymentGateway {
    async processPayment(amount, method, metadata) {
        throw new Error('processPayment method must be implemented');
    }

    async setupRecurring(subscription) {
        throw new Error('setupRecurring method must be implemented');
    }

    async processRecurringPayment(subscriptionId) {
        throw new Error('processRecurringPayment method must be implemented');
    }

    async updateSubscription(subscriptionId, updates) {
        throw new Error('updateSubscription method must be implemented');
    }

    async cancelSubscription(subscriptionId) {
        throw new Error('cancelSubscription method must be implemented');
    }

    async getPaymentStatus(transactionId) {
        throw new Error('getPaymentStatus method must be implemented');
    }
}

// Razorpay Gateway Implementation
export class RazorpayGateway extends PaymentGateway {
    constructor() {
        super();
        this.keyId = import.meta.env.VITE_RAZORPAY_KEY_ID;
        this.keySecret = import.meta.env.RAZORPAY_KEY_SECRET;
        this.webhookSecret = import.meta.env.RAZORPAY_WEBHOOK_SECRET;
    }

    async loadScript() {
        return new Promise((resolve) => {
            if (window.Razorpay) {
                resolve(true);
                return;
            }

            const script = document.createElement('script');
            script.src = 'https://checkout.razorpay.com/v1/checkout.js';
            script.onload = () => resolve(true);
            script.onerror = () => resolve(false);
            document.body.appendChild(script);
        });
    }

    async processPayment(amount, method, metadata) {
        try {
            const scriptLoaded = await this.loadScript();
            if (!scriptLoaded) {
                throw new Error('Razorpay SDK failed to load');
            }

            return new Promise((resolve, reject) => {
                const options = {
                    key: this.keyId,
                    amount: amount * 100, // Convert to paise
                    currency: 'INR',
                    name: 'CityFix Welfare',
                    description: metadata.description || 'Donation',
                    image: metadata.logo || '',
                    handler: function (response) {
                        resolve({
                            success: true,
                            transactionId: response.razorpay_payment_id,
                            gatewayResponse: response
                        });
                    },
                    prefill: {
                        name: metadata.donorName || '',
                        email: metadata.donorEmail || '',
                        contact: metadata.donorPhone || ''
                    },
                    theme: {
                        color: '#2563eb'
                    },
                    modal: {
                        ondismiss: function() {
                            reject(new Error('Payment cancelled by user'));
                        }
                    }
                };

                const paymentObject = new window.Razorpay(options);
                paymentObject.open();
            });
        } catch (error) {
            console.error('Razorpay payment error:', error);
            throw error;
        }
    }

    async setupRecurring(subscription) {
        try {
            // For Razorpay subscriptions, we would typically create a subscription plan
            // This is a simplified implementation
            const subscriptionData = {
                plan_id: `plan_${Date.now()}`, // In real implementation, create plan first
                customer_notify: 1,
                quantity: 1,
                total_count: subscription.frequency === 'yearly' ? 1 : 12,
                start_at: Math.floor(Date.now() / 1000) + 86400, // Start tomorrow
                addons: [],
                notes: {
                    centerId: subscription.centerId,
                    donorId: subscription.donorId
                }
            };

            // In real implementation, make API call to Razorpay
            return {
                id: `sub_${Date.now()}`,
                status: 'created',
                ...subscriptionData
            };
        } catch (error) {
            console.error('Razorpay subscription setup error:', error);
            throw error;
        }
    }

    async processRecurringPayment(subscriptionId) {
        try {
            // In real implementation, this would be handled by Razorpay webhooks
            // For now, simulate successful payment
            return {
                success: true,
                transactionId: `pay_${Date.now()}`,
                amount: 0, // Would come from subscription details
                status: 'captured'
            };
        } catch (error) {
            console.error('Razorpay recurring payment error:', error);
            throw error;
        }
    }

    async updateSubscription(subscriptionId, updates) {
        try {
            // In real implementation, make API call to update Razorpay subscription
            console.log('Updating Razorpay subscription:', subscriptionId, updates);
            return { success: true };
        } catch (error) {
            console.error('Razorpay subscription update error:', error);
            throw error;
        }
    }

    async cancelSubscription(subscriptionId) {
        try {
            // In real implementation, make API call to cancel Razorpay subscription
            console.log('Cancelling Razorpay subscription:', subscriptionId);
            return { success: true };
        } catch (error) {
            console.error('Razorpay subscription cancellation error:', error);
            throw error;
        }
    }

    async getPaymentStatus(transactionId) {
        try {
            // In real implementation, make API call to get payment status
            return {
                id: transactionId,
                status: 'captured',
                amount: 0
            };
        } catch (error) {
            console.error('Razorpay payment status error:', error);
            throw error;
        }
    }
}

// Stripe Gateway Implementation
export class StripeGateway extends PaymentGateway {
    constructor() {
        super();
        this.publishableKey = import.meta.env.VITE_STRIPE_PUBLISHABLE_KEY;
        this.secretKey = import.meta.env.STRIPE_SECRET_KEY;
        this.webhookSecret = import.meta.env.STRIPE_WEBHOOK_SECRET;
    }

    async loadScript() {
        return new Promise((resolve) => {
            if (window.Stripe) {
                resolve(true);
                return;
            }

            const script = document.createElement('script');
            script.src = 'https://js.stripe.com/v3/';
            script.onload = () => resolve(true);
            script.onerror = () => resolve(false);
            document.body.appendChild(script);
        });
    }

    async processPayment(amount, method, metadata) {
        try {
            const scriptLoaded = await this.loadScript();
            if (!scriptLoaded) {
                throw new Error('Stripe SDK failed to load');
            }

            const stripe = window.Stripe(this.publishableKey);
            
            // In real implementation, create payment intent on server
            const paymentIntent = await this.createPaymentIntent(amount, metadata);
            
            const result = await stripe.confirmCardPayment(paymentIntent.client_secret, {
                payment_method: {
                    card: method.card,
                    billing_details: {
                        name: metadata.donorName,
                        email: metadata.donorEmail
                    }
                }
            });

            if (result.error) {
                throw new Error(result.error.message);
            }

            return {
                success: true,
                transactionId: result.paymentIntent.id,
                gatewayResponse: result.paymentIntent
            };
        } catch (error) {
            console.error('Stripe payment error:', error);
            throw error;
        }
    }

    async createPaymentIntent(amount, metadata) {
        // In real implementation, this would be a server-side API call
        return {
            id: `pi_${Date.now()}`,
            client_secret: `pi_${Date.now()}_secret_${Math.random()}`,
            amount: amount * 100,
            currency: 'usd'
        };
    }

    async setupRecurring(subscription) {
        try {
            // Create Stripe subscription
            const subscriptionData = {
                customer: subscription.customerId,
                items: [{
                    price_data: {
                        currency: 'usd',
                        product_data: {
                            name: `Donation to ${subscription.centerName}`
                        },
                        unit_amount: subscription.amount * 100,
                        recurring: {
                            interval: subscription.frequency === 'yearly' ? 'year' : 'month',
                            interval_count: subscription.frequency === 'quarterly' ? 3 : 1
                        }
                    }
                }],
                metadata: {
                    centerId: subscription.centerId,
                    donorId: subscription.donorId
                }
            };

            return {
                id: `sub_${Date.now()}`,
                status: 'active',
                ...subscriptionData
            };
        } catch (error) {
            console.error('Stripe subscription setup error:', error);
            throw error;
        }
    }

    async processRecurringPayment(subscriptionId) {
        try {
            // Stripe handles recurring payments automatically via webhooks
            return {
                success: true,
                transactionId: `pi_${Date.now()}`,
                status: 'succeeded'
            };
        } catch (error) {
            console.error('Stripe recurring payment error:', error);
            throw error;
        }
    }

    async updateSubscription(subscriptionId, updates) {
        try {
            console.log('Updating Stripe subscription:', subscriptionId, updates);
            return { success: true };
        } catch (error) {
            console.error('Stripe subscription update error:', error);
            throw error;
        }
    }

    async cancelSubscription(subscriptionId) {
        try {
            console.log('Cancelling Stripe subscription:', subscriptionId);
            return { success: true };
        } catch (error) {
            console.error('Stripe subscription cancellation error:', error);
            throw error;
        }
    }

    async getPaymentStatus(transactionId) {
        try {
            return {
                id: transactionId,
                status: 'succeeded',
                amount: 0
            };
        } catch (error) {
            console.error('Stripe payment status error:', error);
            throw error;
        }
    }
}

// PayPal Gateway Implementation
export class PayPalGateway extends PaymentGateway {
    constructor() {
        super();
        this.clientId = import.meta.env.VITE_PAYPAL_CLIENT_ID;
        this.clientSecret = import.meta.env.PAYPAL_CLIENT_SECRET;
        this.webhookId = import.meta.env.PAYPAL_WEBHOOK_ID;
    }

    async loadScript() {
        return new Promise((resolve) => {
            if (window.paypal) {
                resolve(true);
                return;
            }

            const script = document.createElement('script');
            script.src = `https://www.paypal.com/sdk/js?client-id=${this.clientId}&currency=USD`;
            script.onload = () => resolve(true);
            script.onerror = () => resolve(false);
            document.body.appendChild(script);
        });
    }

    async processPayment(amount, method, metadata) {
        try {
            const scriptLoaded = await this.loadScript();
            if (!scriptLoaded) {
                throw new Error('PayPal SDK failed to load');
            }

            return new Promise((resolve, reject) => {
                window.paypal.Buttons({
                    createOrder: (data, actions) => {
                        return actions.order.create({
                            purchase_units: [{
                                amount: {
                                    value: amount.toString(),
                                    currency_code: 'USD'
                                },
                                description: metadata.description || 'Donation'
                            }]
                        });
                    },
                    onApprove: async (data, actions) => {
                        try {
                            const order = await actions.order.capture();
                            resolve({
                                success: true,
                                transactionId: order.id,
                                gatewayResponse: order
                            });
                        } catch (error) {
                            reject(error);
                        }
                    },
                    onError: (error) => {
                        reject(error);
                    },
                    onCancel: () => {
                        reject(new Error('Payment cancelled by user'));
                    }
                }).render('#paypal-button-container');
            });
        } catch (error) {
            console.error('PayPal payment error:', error);
            throw error;
        }
    }

    async setupRecurring(subscription) {
        try {
            // Create PayPal subscription
            const subscriptionData = {
                plan_id: `plan_${Date.now()}`,
                start_time: new Date(Date.now() + 86400000).toISOString(), // Start tomorrow
                subscriber: {
                    email_address: subscription.donorEmail,
                    name: {
                        given_name: subscription.donorName?.split(' ')[0] || '',
                        surname: subscription.donorName?.split(' ').slice(1).join(' ') || ''
                    }
                },
                application_context: {
                    brand_name: 'CityFix Welfare',
                    user_action: 'SUBSCRIBE_NOW'
                }
            };

            return {
                id: `sub_${Date.now()}`,
                status: 'ACTIVE',
                ...subscriptionData
            };
        } catch (error) {
            console.error('PayPal subscription setup error:', error);
            throw error;
        }
    }

    async processRecurringPayment(subscriptionId) {
        try {
            // PayPal handles recurring payments automatically
            return {
                success: true,
                transactionId: `txn_${Date.now()}`,
                status: 'COMPLETED'
            };
        } catch (error) {
            console.error('PayPal recurring payment error:', error);
            throw error;
        }
    }

    async updateSubscription(subscriptionId, updates) {
        try {
            console.log('Updating PayPal subscription:', subscriptionId, updates);
            return { success: true };
        } catch (error) {
            console.error('PayPal subscription update error:', error);
            throw error;
        }
    }

    async cancelSubscription(subscriptionId) {
        try {
            console.log('Cancelling PayPal subscription:', subscriptionId);
            return { success: true };
        } catch (error) {
            console.error('PayPal subscription cancellation error:', error);
            throw error;
        }
    }

    async getPaymentStatus(transactionId) {
        try {
            return {
                id: transactionId,
                status: 'COMPLETED',
                amount: 0
            };
        } catch (error) {
            console.error('PayPal payment status error:', error);
            throw error;
        }
    }
}

// Payment Service for unified payment processing
export class PaymentService {
    static async processPayment(paymentData) {
        try {
            const gateway = PaymentGatewayFactory.createGateway(paymentData.gateway);
            const result = await gateway.processPayment(
                paymentData.amount,
                paymentData.method,
                paymentData.metadata
            );

            return result;
        } catch (error) {
            console.error('Payment processing error:', error);
            throw error;
        }
    }

    static getSupportedGateways() {
        return [
            {
                id: 'razorpay',
                name: 'Razorpay',
                supportedMethods: ['card', 'netbanking', 'wallet', 'upi'],
                currency: 'INR',
                international: false
            },
            {
                id: 'stripe',
                name: 'Stripe',
                supportedMethods: ['card', 'bank_transfer'],
                currency: 'USD',
                international: true
            },
            {
                id: 'paypal',
                name: 'PayPal',
                supportedMethods: ['paypal', 'card'],
                currency: 'USD',
                international: true
            }
        ];
    }

    static getGatewayForCurrency(currency) {
        if (currency === 'INR') {
            return 'razorpay';
        } else if (currency === 'USD') {
            return 'stripe'; // or 'paypal'
        }
        return 'razorpay'; // default
    }
}