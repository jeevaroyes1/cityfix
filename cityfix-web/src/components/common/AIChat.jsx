import React, { useState, useRef, useEffect } from 'react';
import './AIChat.css';

const AIChat = () => {
    const [isOpen, setIsOpen] = useState(false);
    const [messages, setMessages] = useState([
        {
            id: 1,
            text: "Hello! 👋 I'm CityFix AI Assistant. How can I help you today?",
            sender: 'bot',
            timestamp: new Date()
        }
    ]);
    const [inputValue, setInputValue] = useState('');
    const [isLoading, setIsLoading] = useState(false);
    const messagesEndRef = useRef(null);

    const scrollToBottom = () => {
        messagesEndRef.current?.scrollIntoView({ behavior: 'smooth' });
    };

    useEffect(() => {
        scrollToBottom();
    }, [messages]);

    const generateBotResponse = (userMessage) => {
        const lowerMessage = userMessage.toLowerCase();

        // Knowledge base for common questions - ordered by specificity
        const responses = [
            // Specific multi-word phrases first
            { keywords: ['how to make donation', 'how to donate', 'make donation', 'donate money'], response: "We accept donations to support various welfare centers. Visit our Donation page to contribute. Your donations help us serve the community better! You can choose from different welfare centers and set up one-time or recurring donations." },
            { keywords: ['report issue', 'report problem', 'report civic'], response: "You can report civic issues by going to the Report Issue page. Simply provide details about the problem, upload a photo, and select the location. Our community will help track and resolve it!" },
            { keywords: ['volunteer', 'volunteering', 'volunteer opportunity'], response: "Interested in volunteering? Check out our Volunteering page to see available opportunities and events in your area. You can join community service events and make a real difference!" },
            { keywords: ['lost and found', 'lost item', 'found item', 'lost something'], response: "Lost something? Visit our Lost & Found section to post about lost items or search for found items in your area. Our community helps reunite people with their belongings!" },
            { keywords: ['community hub', 'community', 'connect'], response: "Join our Community Hub to connect with neighbors, share updates, and stay informed about local events. It's a great way to engage with your community!" },
            { keywords: ['news', 'updates', 'news updates'], response: "Stay updated with the latest local news and announcements on our News Updates page. Get informed about what's happening in your area!" },
            { keywords: ['nearby', 'near me', 'issues near'], response: "You can view issues reported near you on the Dashboard. We show all civic problems within 5 km of your location. This helps you stay aware of what's happening around you!" },
            { keywords: ['location', 'gps', 'geolocation'], response: "We use your location to show nearby issues and help you report problems accurately. You can enable location access in your browser settings. Your privacy is important to us!" },
            { keywords: ['profile', 'account', 'settings'], response: "Visit your Profile page to manage your account settings, view your activity, and update your information. You can customize your preferences there!" },
            { keywords: ['help', 'what can you do', 'what can you help'], response: "I can help you with:\n• Reporting civic issues\n• Making donations\n• Finding volunteering opportunities\n• Lost & Found items\n• Community updates\n• Local news\n• Account settings\n\nWhat would you like to know more about?" },
            { keywords: ['hello', 'hi', 'hey', 'greetings'], response: "Hello! 👋 Welcome to CityFix. How can I assist you today?" },
            { keywords: ['thanks', 'thank you', 'appreciate'], response: "You're welcome! Feel free to ask if you need anything else. I'm here to help!" },
        ];

        // Find matching response based on keywords
        for (const item of responses) {
            for (const keyword of item.keywords) {
                if (lowerMessage.includes(keyword)) {
                    return item.response;
                }
            }
        }

        // Default response if no match found
        return "That's a great question! I can help you with reporting issues, donations, volunteering, lost & found, community updates, and more. What would you like to know?";
    };

    const handleSendMessage = async (e) => {
        e.preventDefault();
        if (!inputValue.trim()) return;

        // Add user message
        const userMessage = {
            id: messages.length + 1,
            text: inputValue,
            sender: 'user',
            timestamp: new Date()
        };

        setMessages(prev => [...prev, userMessage]);
        setInputValue('');
        setIsLoading(true);

        // Simulate bot thinking time
        setTimeout(() => {
            const botResponse = {
                id: messages.length + 2,
                text: generateBotResponse(inputValue),
                sender: 'bot',
                timestamp: new Date()
            };
            setMessages(prev => [...prev, botResponse]);
            setIsLoading(false);
        }, 500);
    };

    const handleQuickAction = (action) => {
        const quickMessages = {
            'report': 'How do I report an issue?',
            'donate': 'How can I donate?',
            'volunteer': 'Tell me about volunteering',
            'help': 'Can you help me?'
        };

        const message = quickMessages[action];
        if (message) {
            setInputValue(message);
        }
    };

    return (
        <>
            {/* Chat Widget */}
            <div className={`ai-chat-widget ${isOpen ? 'open' : ''}`}>
                {/* Chat Header */}
                <div className="chat-header">
                    <div className="header-content">
                        <div className="header-title">
                            <span className="bot-icon">🤖</span>
                            <div>
                                <h3>CityFix AI</h3>
                                <p>Always here to help</p>
                            </div>
                        </div>
                    </div>
                    <button 
                        className="close-btn"
                        onClick={() => setIsOpen(false)}
                    >
                        ✕
                    </button>
                </div>

                {/* Chat Messages */}
                <div className="chat-messages">
                    {messages.map(message => (
                        <div key={message.id} className={`message ${message.sender}`}>
                            <div className="message-content">
                                {message.sender === 'bot' && <span className="bot-avatar">🤖</span>}
                                <div className="message-text">
                                    {message.text}
                                </div>
                            </div>
                        </div>
                    ))}
                    {isLoading && (
                        <div className="message bot">
                            <div className="message-content">
                                <span className="bot-avatar">🤖</span>
                                <div className="message-text typing">
                                    <span></span>
                                    <span></span>
                                    <span></span>
                                </div>
                            </div>
                        </div>
                    )}
                    <div ref={messagesEndRef} />
                </div>

                {/* Quick Actions */}
                {messages.length === 1 && (
                    <div className="quick-actions">
                        <button onClick={() => handleQuickAction('report')}>📷 Report Issue</button>
                        <button onClick={() => handleQuickAction('donate')}>💝 Donate</button>
                        <button onClick={() => handleQuickAction('volunteer')}>🤝 Volunteer</button>
                        <button onClick={() => handleQuickAction('help')}>❓ Help</button>
                    </div>
                )}

                {/* Chat Input */}
                <form className="chat-input-form" onSubmit={handleSendMessage}>
                    <input
                        type="text"
                        placeholder="Ask me anything..."
                        value={inputValue}
                        onChange={(e) => setInputValue(e.target.value)}
                        disabled={isLoading}
                    />
                    <button type="submit" disabled={isLoading || !inputValue.trim()}>
                        <span>📤</span>
                    </button>
                </form>
            </div>

            {/* Floating Button */}
            {!isOpen && (
                <button 
                    className="chat-toggle-btn"
                    onClick={() => setIsOpen(true)}
                    title="Open AI Chat"
                >
                    <span className="chat-icon">💬</span>
                    <span className="pulse"></span>
                </button>
            )}
        </>
    );
};

export default AIChat;
