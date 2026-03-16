import React from 'react';
import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './contexts/AuthContext';
import ProtectedRoute from './components/auth/ProtectedRoute';
import Login from './components/auth/Login';
import Signup from './components/auth/Signup';
import CompleteProfile from './components/auth/CompleteProfile';
import LandingPage from './components/public/LandingPage';
import TermsAndConditions from './components/public/TermsAndConditions';
import Dashboard from './components/user/Dashboard';
import ReportIssue from './components/user/ReportIssue';
import IssuesNearMe from './components/user/IssuesNearMe';
import LostAndFound from './components/user/LostAndFound';
import NewsUpdates from './components/user/NewsUpdates';
import AboutUs from './components/common/AboutUs';
import SLA from './components/user/SLA';
import HowItWorks from './components/user/HowItWorks';
import Navbar from './components/common/Navbar';
import UserLayout from './components/user/UserLayout';
import CommunityHub from './components/user/CommunityHub';
import Volunteering from './components/user/Volunteering';
import Donation from './components/user/Donation';
import DonationDashboard from './components/donation/DonationDashboard';
import Helpline from './components/user/Helpline';
import UserProfile from './components/user/UserProfile';
import AIChat from './components/common/AIChat';
import './App.css';

// Simple layout component to include Navbar on specific protected pages
const NavbarLayout = ({ children }) => {
  return (
    <>
      <Navbar />
      <main className="main-content">
        {children}
      </main>
    </>
  );
};

// Redirect authenticated users away from public pages (login, signup, landing)
const PublicRoute = ({ children }) => {
  const { currentUser } = useAuth();

  if (currentUser) {
    return <Navigate to="/dashboard" replace />;
  }

  return children;
};

function App() {
  return (
    <AuthProvider>
      <Router>
        <div className="app">
          <Routes>
            {/* Public Routes */}
            <Route path="/" element={<PublicRoute><LandingPage /></PublicRoute>} />
            <Route path="/login" element={<PublicRoute><Login /></PublicRoute>} />
            <Route path="/signup" element={<PublicRoute><Signup /></PublicRoute>} />
            <Route path="/terms" element={<TermsAndConditions />} />

            {/* Protected Routes with UserLayout (Sidebar) */}
            <Route element={<ProtectedRoute><UserLayout /></ProtectedRoute>}>
              <Route path="/dashboard" element={<Dashboard />} />
              <Route path="/report-issue" element={<ReportIssue />} />
              <Route path="/issues-near-me" element={<IssuesNearMe />} />
              <Route path="/lost-found" element={<LostAndFound />} />
              <Route path="/community-hub" element={<CommunityHub />} />
              <Route path="/volunteering" element={<Volunteering />} />
              <Route path="/news" element={<NewsUpdates />} />
              <Route path="/donate" element={<Donation />} />
              <Route path="/donation-dashboard" element={<DonationDashboard />} />
              <Route path="/helpline" element={<Helpline />} />
              <Route path="/profile" element={<UserProfile />} />
              <Route path="/sla" element={<SLA />} />
              <Route path="/how-it-works" element={<HowItWorks />} />
            </Route>

            {/* Protected Routes with Navbar (No Sidebar) */}
            <Route path="/about" element={<ProtectedRoute><NavbarLayout><AboutUs /></NavbarLayout></ProtectedRoute>} />
            <Route path="/complete-profile" element={<ProtectedRoute><NavbarLayout><CompleteProfile /></NavbarLayout></ProtectedRoute>} />

            {/* Default Route — redirect to landing */}
            <Route path="*" element={<Navigate to="/" replace />} />
          </Routes>
          <AIChat />
        </div>
      </Router>
    </AuthProvider>
  );
}

export default App;
