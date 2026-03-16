# CityFix Web App - Setup Guide

## Prerequisites
- Node.js (v16 or higher)
- npm or yarn
- Firebase account
- Cloudinary account
- Razorpay account (for payments)

## 1. Environment Setup

### Step 1: Clone and Install Dependencies
```bash
npm install
```

### Step 2: Configure Environment Variables
Create a `.env` file in the root directory:

```env
# Firebase Configuration
VITE_FIREBASE_API_KEY=your_firebase_api_key
VITE_FIREBASE_AUTH_DOMAIN=your_project.firebaseapp.com
VITE_FIREBASE_PROJECT_ID=your_project_id
VITE_FIREBASE_STORAGE_BUCKET=your_project.appspot.com
VITE_FIREBASE_MESSAGING_SENDER_ID=your_sender_id
VITE_FIREBASE_APP_ID=your_app_id

# Cloudinary Configuration
VITE_CLOUDINARY_CLOUD_NAME=your_cloud_name
VITE_CLOUDINARY_UPLOAD_PRESET=your_upload_preset

# Razorpay Configuration
VITE_RAZORPAY_KEY_ID=your_razorpay_key_id
```

## 2. Firebase Setup

### Step 1: Create Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Create a new project or use existing one
3. Enable Authentication (Email/Password)
4. Create Firestore Database

### Step 2: Firestore Collections Structure
Create these collections in Firestore:

```
users/
  - uid (document ID)
  - email
  - displayName
  - photoURL
  - panchayat
  - state
  - district
  - ward
  - createdAt

reports/
  - userId
  - userName
  - userPhoto
  - title
  - category
  - problemType
  - location
  - latitude
  - longitude
  - description
  - imageUrl
  - status (Pending, In Progress, Resolved, Completed)
  - upvotes (array)
  - createdAt

community_notes/
  - authorId
  - authorEmail
  - content
  - imageUrl
  - panchayat
  - likes (array)
  - createdAt

volunteering_events/
  - title
  - category
  - description
  - location
  - contactInfo
  - eventDate
  - panchayat
  - createdAt

lost_and_found_items/
  - userId
  - description
  - imageUrl
  - dateFound
  - contactEmail
  - panchayat
  - createdAt

news/
  - title
  - content
  - category
  - imageUrl
  - panchayat
  - createdAt
```

### Step 3: Firestore Security Rules
```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users collection
    match /users/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth.uid == userId;
    }
    
    // Reports collection
    match /reports/{reportId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update: if request.auth.uid == resource.data.userId || 
                      request.auth.token.role == 'admin';
      allow delete: if request.auth.uid == resource.data.userId;
    }
    
    // Community notes
    match /community_notes/{noteId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.authorId;
      
      // Comments subcollection
      match /comments/{commentId} {
        allow read: if request.auth != null;
        allow create: if request.auth != null;
      }
    }
    
    // Volunteering events
    match /volunteering_events/{eventId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow update, delete: if request.auth.uid == resource.data.createdBy;
    }
    
    // Lost and found items
    match /lost_and_found_items/{itemId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
      allow delete: if request.auth.uid == resource.data.userId;
    }
    
    // News
    match /news/{newsId} {
      allow read: if request.auth != null;
      allow create: if request.auth != null;
    }
  }
}
```

## 3. Cloudinary Setup

### Step 1: Create Cloudinary Account
1. Go to [Cloudinary](https://cloudinary.com/)
2. Sign up for a free account
3. Note your Cloud Name from the dashboard

### Step 2: Create Upload Preset
1. Go to Settings → Upload
2. Scroll to "Upload presets"
3. Click "Add upload preset"
4. Set:
   - Preset name: `cityfix` (or your choice)
   - Signing Mode: `Unsigned`
   - Folder: `cityfix` (optional)
5. Save the preset

### Step 3: Add to Environment Variables
```env
VITE_CLOUDINARY_CLOUD_NAME=your_cloud_name
VITE_CLOUDINARY_UPLOAD_PRESET=cityfix
```

## 4. Razorpay Setup

### Step 1: Create Razorpay Account
1. Go to [Razorpay](https://razorpay.com/)
2. Sign up for an account
3. Complete KYC verification (for live mode)

### Step 2: Get API Keys
1. Go to Settings → API Keys
2. Generate Test/Live Keys
3. Copy the Key ID (NOT the secret)

### Step 3: Add to Environment Variables
```env
VITE_RAZORPAY_KEY_ID=rzp_test_xxxxxxxxxx
```

**Important:** 
- Use `rzp_test_` keys for testing
- Use `rzp_live_` keys for production
- NEVER expose your secret key in frontend code

### Step 4: Test Payment
1. Use Razorpay test cards:
   - Card: 4111 1111 1111 1111
   - CVV: Any 3 digits
   - Expiry: Any future date

## 5. Running the Application

### Development Mode
```bash
npm run dev
```

### Production Build
```bash
npm run build
npm run preview
```

## 6. Features Implemented

### ✅ Image Upload
- **Report Issue**: Upload photos of civic issues
- **Community Hub**: Attach images to posts
- **Lost & Found**: Upload images of found items
- Uses Cloudinary for storage
- Max file size: 10MB
- Supported formats: PNG, JPG, GIF

### ✅ Payment Integration
- **Donation Page**: Razorpay payment gateway
- Quick amount selection (₹100, ₹500, ₹1000, ₹5000)
- Custom amount input
- Secure payment processing
- Payment confirmation

## 7. Testing Checklist

- [ ] User registration and login
- [ ] Profile completion with location
- [ ] Report issue with image upload
- [ ] Community post with image
- [ ] Lost & found item with image
- [ ] Volunteering event creation
- [ ] Donation with Razorpay payment
- [ ] Helpline call/copy functionality
- [ ] Sidebar collapse/expand
- [ ] Mobile responsiveness

## 8. Deployment

### Vercel Deployment
```bash
npm install -g vercel
vercel
```

### Netlify Deployment
```bash
npm run build
# Upload dist folder to Netlify
```

### Environment Variables in Production
Make sure to add all environment variables in your hosting platform:
- Vercel: Settings → Environment Variables
- Netlify: Site settings → Build & deploy → Environment

## 9. Troubleshooting

### Image Upload Issues
- Check Cloudinary cloud name and preset
- Verify upload preset is set to "Unsigned"
- Check file size (max 10MB)
- Check browser console for errors

### Payment Issues
- Verify Razorpay key ID is correct
- Check if Razorpay script is loaded
- Use test cards for testing
- Check browser console for errors

### Firebase Issues
- Verify all environment variables are set
- Check Firestore security rules
- Ensure collections exist
- Check Firebase console for errors

## 10. Support

For issues or questions:
1. Check browser console for errors
2. Verify all environment variables
3. Check Firebase/Cloudinary/Razorpay dashboards
4. Review setup steps above

---

**Last Updated:** 2026-03-05
**Version:** 1.0.0
