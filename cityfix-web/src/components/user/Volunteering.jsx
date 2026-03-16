import React, { useState, useEffect } from 'react';
import { useAuth } from '../../contexts/AuthContext';
import { collection, query, where, orderBy, onSnapshot, addDoc, serverTimestamp } from 'firebase/firestore';
import { db } from '../../config/firebase';
import Loading from '../common/Loading';
import ErrorMessage from '../common/ErrorMessage';
import './Volunteering.css';

const Volunteering = () => {
    const { userProfile } = useAuth();
    const [events, setEvents] = useState([]);
    const [loading, setLoading] = useState(true);
    const [error, setError] = useState('');
    const [showCreateModal, setShowCreateModal] = useState(false);
    const [selectedEvent, setSelectedEvent] = useState(null);
    const [newEvent, setNewEvent] = useState({
        title: '',
        category: 'Community Service',
        description: '',
        location: '',
        contactInfo: '',
        eventDate: ''
    });

    useEffect(() => {
        if (!userProfile?.panchayat) {
            console.log('No panchayat found in user profile');
            setLoading(false);
            return;
        }

        console.log('Fetching events for panchayat:', userProfile.panchayat);

        const q = query(
            collection(db, 'volunteering_events'),
            where('panchayat', '==', userProfile.panchayat)
        );

        const unsubscribe = onSnapshot(q, (snapshot) => {
            console.log('Events snapshot received, count:', snapshot.docs.length);
            const eventsData = snapshot.docs.map(doc => ({
                id: doc.id,
                ...doc.data()
            }));
            console.log('Events data:', eventsData);
            setEvents(eventsData);
            setLoading(false);
        }, (err) => {
            console.error('Error fetching events:', err);
            setError('Failed to load events: ' + err.message);
            setLoading(false);
        });

        return () => unsubscribe();
    }, [userProfile]);

    const handleCreateEvent = async (e) => {
        e.preventDefault();

        try {
            const eventData = {
                ...newEvent,
                panchayat: userProfile.panchayat,
                eventDate: new Date(newEvent.eventDate),
                createdAt: serverTimestamp(),
                createdBy: userProfile.uid,
                createdByName: userProfile.name || 'Anonymous'
            };
            
            console.log('Creating event with data:', eventData);
            
            const docRef = await addDoc(collection(db, 'volunteering_events'), eventData);
            
            console.log('Event created successfully with ID:', docRef.id);

            setNewEvent({
                title: '',
                category: 'Community Service',
                description: '',
                location: '',
                contactInfo: '',
                eventDate: ''
            });
            setShowCreateModal(false);
            setError('');
        } catch (err) {
            console.error('Error creating event:', err);
            setError('Failed to create event: ' + err.message);
        }
    };

    if (loading) return <Loading message="Loading volunteering opportunities..." />;

    return (
        <div className="volunteering-container">
            {/* Page Header */}
            <div className="vol-page-header">
                <div className="vol-header-content">
                    <h1>🙌 Volunteering Opportunities</h1>
                    <p>Make a difference by volunteering in your community</p>
                </div>
            </div>

            {/* Welcome Card */}
            <div className="vol-welcome-card">
                <div className="vol-welcome-icon">🤝</div>
                <div className="vol-welcome-content">
                    <h2>Welcome to Volunteering</h2>
                    <p>Discover meaningful opportunities to contribute to your community. Whether you want to organize an event or participate in existing drives, you can make a real impact. Browse upcoming events or create your own initiative.</p>
                </div>
            </div>

            {/* Hero Banner */}
            <div className="vol-hero-banner">
                <div className="vol-hero-content">
                    <h2>🙌 Make a Difference Together</h2>
                    <p>Find events to participate in or organize your own drive to make a difference</p>
                </div>
            </div>

            <div className="volunteering-header">
                <div>
                    <h2>Upcoming Events</h2>
                    <p>Find events to participate in or organize your own drive to make a difference</p>
                </div>
                <button className="btn-create-event" onClick={() => setShowCreateModal(true)}>
                    <span>+</span> Organize Event
                </button>
            </div>

            <ErrorMessage message={error} onClose={() => setError('')} />

            <div className="events-grid">
                {events.length === 0 ? (
                    <div className="empty-state">
                        <div className="empty-icon">🙌</div>
                        <h3>No upcoming events</h3>
                        <p>Be the first to organize a drive!</p>
                    </div>
                ) : (
                    events.map(event => (
                        <div key={event.id} className="event-card">
                            <div className="event-header">
                                <span className="event-category">{event.category}</span>
                                <span className="event-date">
                                    {event.eventDate?.toDate().toLocaleDateString()}
                                </span>
                            </div>
                            <h3 className="event-title">{event.title}</h3>
                            <div className="event-details">
                                <div className="event-detail">
                                    <span className="detail-icon">📍</span>
                                    <span>{event.location}</span>
                                </div>
                                {event.eventDate && (
                                    <div className="event-detail">
                                        <span className="detail-icon">🕐</span>
                                        <span>{event.eventDate.toDate().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}</span>
                                    </div>
                                )}
                            </div>
                            <p className="event-description">{event.description}</p>
                            <button 
                                className="btn-read-more"
                                onClick={() => setSelectedEvent(event)}
                            >
                                Read More
                            </button>
                            <div className="event-footer">
                                <span className="contact-info">
                                    <span className="detail-icon">👤</span>
                                    Contact: {event.contactInfo}
                                </span>
                            </div>
                        </div>
                    ))
                )}
            </div>

            {/* Event Details Modal */}
            {selectedEvent && (
                <div className="modal-overlay" onClick={() => setSelectedEvent(null)}>
                    <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                        <div className="modal-header">
                            <h2>{selectedEvent.title}</h2>
                            <button className="modal-close" onClick={() => setSelectedEvent(null)}>×</button>
                        </div>
                        <div className="event-details-modal">
                            <div className="event-meta">
                                <span className="event-category-badge">{selectedEvent.category}</span>
                                <span className="event-date-badge">
                                    {selectedEvent.eventDate?.toDate().toLocaleDateString()}
                                </span>
                            </div>

                            <div className="detail-section">
                                <h3>📍 Location</h3>
                                <p>{selectedEvent.location}</p>
                            </div>

                            <div className="detail-section">
                                <h3>🕐 Date & Time</h3>
                                <p>
                                    {selectedEvent.eventDate?.toDate().toLocaleDateString()} at {selectedEvent.eventDate?.toDate().toLocaleTimeString([], { hour: '2-digit', minute: '2-digit' })}
                                </p>
                            </div>

                            <div className="detail-section">
                                <h3>📝 Description</h3>
                                <p>{selectedEvent.description}</p>
                            </div>

                            <div className="detail-section">
                                <h3>👤 Contact Information</h3>
                                <p>{selectedEvent.contactInfo}</p>
                            </div>

                            <button 
                                className="btn-close-modal"
                                onClick={() => setSelectedEvent(null)}
                            >
                                Close
                            </button>
                        </div>
                    </div>
                </div>
            )}

            {/* Create Event Modal */}
            {showCreateModal && (
                <div className="modal-overlay" onClick={() => setShowCreateModal(false)}>
                    <div className="modal-content" onClick={(e) => e.stopPropagation()}>
                        <div className="modal-header">
                            <h2>Organize Event</h2>
                            <button className="modal-close" onClick={() => setShowCreateModal(false)}>×</button>
                        </div>
                        <form onSubmit={handleCreateEvent}>
                            <div className="form-group">
                                <label>Event Title *</label>
                                <input
                                    type="text"
                                    value={newEvent.title}
                                    onChange={(e) => setNewEvent({ ...newEvent, title: e.target.value })}
                                    required
                                />
                            </div>
                            <div className="form-group">
                                <label>Category *</label>
                                <select
                                    value={newEvent.category}
                                    onChange={(e) => setNewEvent({ ...newEvent, category: e.target.value })}
                                    required
                                >
                                    <option>Community Service</option>
                                    <option>Environmental</option>
                                    <option>Education</option>
                                    <option>Healthcare</option>
                                    <option>Other</option>
                                </select>
                            </div>
                            <div className="form-group">
                                <label>Description *</label>
                                <textarea
                                    value={newEvent.description}
                                    onChange={(e) => setNewEvent({ ...newEvent, description: e.target.value })}
                                    rows="4"
                                    required
                                />
                            </div>
                            <div className="form-group">
                                <label>Location *</label>
                                <input
                                    type="text"
                                    value={newEvent.location}
                                    onChange={(e) => setNewEvent({ ...newEvent, location: e.target.value })}
                                    required
                                />
                            </div>
                            <div className="form-group">
                                <label>Event Date & Time *</label>
                                <input
                                    type="datetime-local"
                                    value={newEvent.eventDate}
                                    onChange={(e) => setNewEvent({ ...newEvent, eventDate: e.target.value })}
                                    required
                                />
                            </div>
                            <div className="form-group">
                                <label>Contact Info *</label>
                                <input
                                    type="text"
                                    value={newEvent.contactInfo}
                                    onChange={(e) => setNewEvent({ ...newEvent, contactInfo: e.target.value })}
                                    placeholder="Email or phone number"
                                    required
                                />
                            </div>
                            <div className="modal-actions">
                                <button type="button" className="btn-cancel" onClick={() => setShowCreateModal(false)}>
                                    Cancel
                                </button>
                                <button type="submit" className="btn-submit">
                                    Create Event
                                </button>
                            </div>
                        </form>
                    </div>
                </div>
            )}
        </div>
    );
};

export default Volunteering;
