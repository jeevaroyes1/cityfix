import {
    collection,
    addDoc,
    getDoc,
    doc,
    updateDoc,
    serverTimestamp
} from 'firebase/firestore';
import { db } from '../../config/firebase';
import { getWelfareCenterById } from '../../data/welfareCenters';

export class TaxCalculator {
    static calculate80GBenefit(donationAmount, centerRegistration) {
        if (!centerRegistration?.section80G) {
            return { eligible: false, amount: 0, section: '80G', description: 'Center not eligible for 80G benefits' };
        }
        
        // 100% deduction for eligible donations under Section 80G
        // Note: Actual limits may vary based on current tax laws
        const maxDeduction = 10000; // As per current tax laws (this should be configurable)
        const eligibleAmount = Math.min(donationAmount, maxDeduction);
        
        return {
            eligible: true,
            amount: eligibleAmount,
            section: '80G',
            description: `Eligible for 100% deduction up to ₹${maxDeduction} under Section 80G`
        };
    }

    static generateAnnualTaxSummary(donations, financialYear) {
        const eligibleDonations = donations.filter(d => d.taxBenefit?.eligible);
        const totalDeduction = eligibleDonations.reduce((sum, d) => sum + d.taxBenefit.amount, 0);
        
        // Group by welfare center
        const centerBreakdown = new Map();
        eligibleDonations.forEach(donation => {
            const centerId = donation.centerId;
            if (!centerBreakdown.has(centerId)) {
                centerBreakdown.set(centerId, {
                    centerId,
                    centerName: donation.centerName,
                    totalAmount: 0,
                    totalDeduction: 0,
                    donationCount: 0
                });
            }
            
            const center = centerBreakdown.get(centerId);
            center.totalAmount += donation.amount;
            center.totalDeduction += donation.taxBenefit.amount;
            center.donationCount++;
        });
        
        return {
            financialYear,
            totalDonations: donations.length,
            totalAmount: donations.reduce((sum, d) => sum + d.amount, 0),
            eligibleDonations: eligibleDonations.length,
            totalDeduction,
            estimatedTaxSaving: totalDeduction * 0.3, // Assuming 30% tax bracket
            centerBreakdown: Array.from(centerBreakdown.values()),
            generatedAt: new Date()
        };
    }

    static getCurrentFinancialYear() {
        const now = new Date();
        const year = now.getFullYear();
        const month = now.getMonth(); // 0-based
        
        // Indian financial year: April 1 to March 31
        if (month >= 3) { // April onwards
            return `${year}-${year + 1}`;
        } else { // January to March
            return `${year - 1}-${year}`;
        }
    }

    static getFinancialYearDates(financialYear) {
        const [startYear, endYear] = financialYear.split('-').map(Number);
        return {
            startDate: new Date(startYear, 3, 1), // April 1
            endDate: new Date(endYear, 2, 31)    // March 31
        };
    }
}

export class ReceiptGenerator {
    constructor() {
        this.receiptCounter = 0;
    }

    async generateReceipt(donationId) {
        try {
            // Get donation details
            const donation = await this.getDonation(donationId);
            if (!donation) {
                throw new Error('Donation not found');
            }

            // Get welfare center details
            const center = getWelfareCenterById(donation.centerId);
            if (!center) {
                throw new Error('Welfare center not found');
            }

            // Calculate tax benefits
            const taxBenefit = TaxCalculator.calculate80GBenefit(donation.amount, center.registration);

            // Generate receipt data
            const receiptData = {
                donationId,
                donorId: donation.donorId,
                donorDetails: {
                    name: donation.donorName,
                    email: donation.donorEmail,
                    phone: donation.donorPhone || '',
                    address: donation.donorAddress || '',
                    panNumber: donation.donorPAN || ''
                },
                centerDetails: {
                    name: center.name,
                    registrationNumber: center.registration.number,
                    address: `${center.location.address}, ${center.location.city}, ${center.location.state} - ${center.location.pincode}`,
                    section80G: center.registration.section80G,
                    phone: center.contact.phone,
                    email: center.contact.email
                },
                amount: donation.amount,
                currency: donation.currency || 'INR',
                transactionId: donation.transactionId,
                paymentMethod: donation.paymentMethod,
                taxBenefit,
                receiptNumber: this.generateReceiptNumber(),
                financialYear: TaxCalculator.getCurrentFinancialYear(),
                donationDate: donation.createdAt,
                emailSent: false
            };

            // Generate PDF (placeholder - would use actual PDF library)
            const pdfUrl = await this.createPDF(receiptData);
            receiptData.pdfUrl = pdfUrl;

            // Save receipt record
            const receiptId = await this.saveReceiptRecord(receiptData);

            // Send email
            await this.emailReceipt(donation.donorEmail, pdfUrl, receiptData);

            // Update receipt as sent
            await this.updateReceiptEmailStatus(receiptId, true);

            return { receiptId, pdfUrl, receiptNumber: receiptData.receiptNumber };
        } catch (error) {
            console.error('Error generating receipt:', error);
            throw error;
        }
    }

    async getDonation(donationId) {
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
    }

    generateReceiptNumber() {
        const year = new Date().getFullYear();
        const sequence = this.getNextSequenceNumber();
        return `CF-${year}-${sequence.toString().padStart(6, '0')}`;
    }

    getNextSequenceNumber() {
        // In a real implementation, this would be stored in database
        // For now, use timestamp-based sequence
        return Date.now() % 1000000;
    }

    async createPDF(receiptData) {
        try {
            // Placeholder for PDF generation
            // In real implementation, would use libraries like jsPDF, PDFKit, or server-side PDF generation
            
            const pdfContent = this.generatePDFContent(receiptData);
            
            // For now, return a placeholder URL
            // In real implementation, upload to Firebase Storage or similar
            const pdfUrl = `https://storage.googleapis.com/cityfix-receipts/${receiptData.receiptNumber}.pdf`;
            
            console.log('PDF generated:', pdfUrl);
            console.log('PDF Content:', pdfContent);
            
            return pdfUrl;
        } catch (error) {
            console.error('Error creating PDF:', error);
            throw error;
        }
    }

    generatePDFContent(receiptData) {
        return {
            header: {
                title: 'DONATION RECEIPT',
                subtitle: 'Tax Deduction Receipt under Section 80G',
                receiptNumber: receiptData.receiptNumber,
                date: new Date().toLocaleDateString('en-IN')
            },
            donorInfo: {
                title: 'Donor Information',
                name: receiptData.donorDetails.name,
                email: receiptData.donorDetails.email,
                phone: receiptData.donorDetails.phone,
                address: receiptData.donorDetails.address,
                panNumber: receiptData.donorDetails.panNumber
            },
            centerInfo: {
                title: 'Recipient Organization',
                name: receiptData.centerDetails.name,
                registrationNumber: receiptData.centerDetails.registrationNumber,
                address: receiptData.centerDetails.address,
                phone: receiptData.centerDetails.phone,
                email: receiptData.centerDetails.email
            },
            donationInfo: {
                title: 'Donation Details',
                amount: receiptData.amount,
                currency: receiptData.currency,
                transactionId: receiptData.transactionId,
                paymentMethod: receiptData.paymentMethod,
                donationDate: receiptData.donationDate,
                financialYear: receiptData.financialYear
            },
            taxInfo: {
                title: 'Tax Benefit Information',
                eligible: receiptData.taxBenefit.eligible,
                section: receiptData.taxBenefit.section,
                deductibleAmount: receiptData.taxBenefit.amount,
                description: receiptData.taxBenefit.description
            },
            footer: {
                disclaimer: 'This is a computer-generated receipt and does not require a signature.',
                note: 'Please retain this receipt for your tax records.',
                qrCode: this.generateQRCode(receiptData),
                digitalSignature: 'Digitally signed by CityFix Welfare Platform'
            }
        };
    }

    generateQRCode(receiptData) {
        // Generate QR code data for verification
        const qrData = {
            receiptNumber: receiptData.receiptNumber,
            donationId: receiptData.donationId,
            amount: receiptData.amount,
            date: receiptData.donationDate,
            centerId: receiptData.centerDetails.registrationNumber
        };
        
        // In real implementation, would generate actual QR code
        return `QR:${JSON.stringify(qrData)}`;
    }

    async saveReceiptRecord(receiptData) {
        try {
            const docRef = await addDoc(collection(db, 'receipts'), {
                ...receiptData,
                createdAt: serverTimestamp()
            });
            return docRef.id;
        } catch (error) {
            console.error('Error saving receipt record:', error);
            throw error;
        }
    }

    async updateReceiptEmailStatus(receiptId, emailSent) {
        try {
            await updateDoc(doc(db, 'receipts', receiptId), {
                emailSent,
                emailSentAt: emailSent ? serverTimestamp() : null
            });
        } catch (error) {
            console.error('Error updating receipt email status:', error);
            throw error;
        }
    }

    async emailReceipt(email, pdfUrl, receiptData) {
        try {
            // Placeholder for email sending
            // In real implementation, would use Firebase Functions with email service
            
            const emailContent = {
                to: email,
                subject: `Donation Receipt - ${receiptData.receiptNumber}`,
                html: this.generateEmailTemplate(receiptData),
                attachments: [
                    {
                        filename: `receipt-${receiptData.receiptNumber}.pdf`,
                        url: pdfUrl
                    }
                ]
            };
            
            console.log('Email sent:', emailContent);
            
            // In real implementation, would call email service API
            return true;
        } catch (error) {
            console.error('Error sending receipt email:', error);
            throw error;
        }
    }

    generateEmailTemplate(receiptData) {
        return `
            <div style="font-family: Arial, sans-serif; max-width: 600px; margin: 0 auto;">
                <h2 style="color: #2563eb;">Thank you for your donation!</h2>
                
                <p>Dear ${receiptData.donorDetails.name},</p>
                
                <p>Thank you for your generous donation of ₹${receiptData.amount} to ${receiptData.centerDetails.name}.</p>
                
                <div style="background-color: #f8f9fa; padding: 20px; border-radius: 8px; margin: 20px 0;">
                    <h3>Donation Details:</h3>
                    <ul>
                        <li><strong>Receipt Number:</strong> ${receiptData.receiptNumber}</li>
                        <li><strong>Amount:</strong> ₹${receiptData.amount}</li>
                        <li><strong>Transaction ID:</strong> ${receiptData.transactionId}</li>
                        <li><strong>Date:</strong> ${new Date(receiptData.donationDate).toLocaleDateString('en-IN')}</li>
                    </ul>
                </div>
                
                ${receiptData.taxBenefit.eligible ? `
                    <div style="background-color: #e8f5e8; padding: 20px; border-radius: 8px; margin: 20px 0;">
                        <h3 style="color: #22c55e;">Tax Benefit Information:</h3>
                        <p>Your donation is eligible for tax deduction under Section ${receiptData.taxBenefit.section}.</p>
                        <p><strong>Deductible Amount:</strong> ₹${receiptData.taxBenefit.amount}</p>
                        <p><em>${receiptData.taxBenefit.description}</em></p>
                    </div>
                ` : ''}
                
                <p>Your donation receipt is attached to this email. Please retain it for your tax records.</p>
                
                <p>Your contribution makes a real difference in our community. Thank you for your support!</p>
                
                <hr style="margin: 30px 0;">
                <p style="color: #666; font-size: 12px;">
                    This is an automated email from CityFix Welfare Platform. 
                    If you have any questions, please contact us at support@cityfix.com
                </p>
            </div>
        `;
    }

    // Method to generate annual tax summary
    async generateAnnualTaxSummary(donorId, financialYear = null) {
        try {
            if (!financialYear) {
                financialYear = TaxCalculator.getCurrentFinancialYear();
            }

            // Get donor donations for the financial year
            const { startDate, endDate } = TaxCalculator.getFinancialYearDates(financialYear);
            
            // This would typically be a more complex query
            // For now, we'll get all donations and filter
            const donationsQuery = query(
                collection(db, 'donations'),
                where('donorId', '==', donorId),
                orderBy('createdAt', 'desc')
            );
            const donationsSnapshot = await getDocs(donationsQuery);
            const allDonations = donationsSnapshot.docs.map(doc => ({ id: doc.id, ...doc.data() }));

            // Filter by financial year
            const yearDonations = allDonations.filter(donation => {
                const donationDate = donation.createdAt?.toDate ? donation.createdAt.toDate() : new Date(donation.createdAt);
                return donationDate >= startDate && donationDate <= endDate;
            });

            const summary = TaxCalculator.generateAnnualTaxSummary(yearDonations, financialYear);
            
            // Generate PDF for tax summary
            const summaryPdfUrl = await this.createTaxSummaryPDF(summary, donorId);
            
            return {
                ...summary,
                pdfUrl: summaryPdfUrl
            };
        } catch (error) {
            console.error('Error generating annual tax summary:', error);
            throw error;
        }
    }

    async createTaxSummaryPDF(summary, donorId) {
        try {
            // Placeholder for tax summary PDF generation
            const pdfUrl = `https://storage.googleapis.com/cityfix-tax-summaries/${donorId}-${summary.financialYear}.pdf`;
            
            console.log('Tax summary PDF generated:', pdfUrl);
            console.log('Tax summary data:', summary);
            
            return pdfUrl;
        } catch (error) {
            console.error('Error creating tax summary PDF:', error);
            throw error;
        }
    }
}

export const receiptGenerator = new ReceiptGenerator();