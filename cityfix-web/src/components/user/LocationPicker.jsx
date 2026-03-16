import React, { useState } from 'react';
import { MapContainer, TileLayer, Marker, useMapEvents } from 'react-leaflet';
import L from 'leaflet';
import 'leaflet/dist/leaflet.css';
import './LocationPicker.css';

// Fix for default markers in react-leaflet
delete L.Icon.Default.prototype._getIconUrl;
L.Icon.Default.mergeOptions({
    iconRetinaUrl: 'data:image/png;base64,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',
    iconUrl: 'data:image/png;base64,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',
    shadowUrl: 'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAACkAAAApCAQAAAACach9AAACMUlEQVR4Ae3ShY7jQBAE0Aoz/f9/HTMzhg1zrdKUrJbdx+Kd2nD8VNudfsL/Th///dyQN2TH6f3y/BGpC379rV+S+qqetBOxImNQXL8JCAr2V4iMQXHGNJxeCfZXhSRBcQMfvkOWUdtfzlLBSsViXnYLqUNS/HQlVpSmLS+lSU5fjbM0+u7j5tMSgBe+cKrVBfVu6ixHkVLLa+4UOt/cQSfWNmuIlWXWx0vdu+BZSWl/5DuTfQPAIBHkViCnImyVpQnfzwHwEQDX9wJQvBdC/+YAHwGrKbpOBFYiAeAiAOAiAOAiAOAiAOAiAOAiAOAiAOAiAOAiAOAiAOAiAOAiAP//2Q=='
});

const defaultCenter = [10.8505, 76.2711]; // Kerala, India

function LocationMarker({ position, setPosition, setAddress }) {
    useMapEvents({
        click(e) {
            const newPos = [e.latlng.lat, e.latlng.lng];
            setPosition(newPos);
            
            // Simple reverse geocoding using Nominatim (OpenStreetMap)
            fetch(`https://nominatim.openstreetmap.org/reverse?format=json&lat=${e.latlng.lat}&lon=${e.latlng.lng}`)
                .then(response => response.json())
                .then(data => {
                    if (data.display_name) {
                        setAddress(data.display_name);
                    }
                })
                .catch(error => {
                    console.error('Reverse geocoding error:', error);
                    setAddress(`${e.latlng.lat.toFixed(6)}, ${e.latlng.lng.toFixed(6)}`);
                });
        },
    });

    return position ? <Marker position={position} /> : null;
}

const LocationPicker = ({ onLocationSelect, onClose }) => {
    const [selectedLocation, setSelectedLocation] = useState(null);
    const [address, setAddress] = useState('');
    const [searchQuery, setSearchQuery] = useState('');

    const handleSearch = async () => {
        if (!searchQuery.trim()) return;

        try {
            const response = await fetch(`https://nominatim.openstreetmap.org/search?format=json&q=${encodeURIComponent(searchQuery)}&limit=1`);
            const data = await response.json();
            
            if (data && data.length > 0) {
                const result = data[0];
                const newPos = [parseFloat(result.lat), parseFloat(result.lon)];
                setSelectedLocation(newPos);
                setAddress(result.display_name);
            } else {
                alert('Location not found. Please try a different search or click on the map.');
            }
        } catch (error) {
            console.error('Search error:', error);
            alert('Search failed. Please try clicking on the map instead.');
        }
    };

    const handleConfirm = () => {
        if (selectedLocation && address) {
            onLocationSelect({
                lat: selectedLocation[0],
                lng: selectedLocation[1],
                address: address
            });
        } else {
            alert('Please select a location on the map');
        }
    };

    const handleManualEntry = () => {
        if (searchQuery.trim()) {
            onLocationSelect({
                lat: defaultCenter[0],
                lng: defaultCenter[1],
                address: searchQuery.trim()
            });
        } else {
            alert('Please enter a location address');
        }
    };

    return (
        <div className="location-picker-modal">
            <div className="location-picker-content">
                <div className="location-picker-header">
                    <h2>📍 Select Location</h2>
                    <button className="close-btn" onClick={onClose}>×</button>
                </div>

                <div className="search-box">
                    <input
                        type="text"
                        placeholder="Search for a location or click on the map..."
                        value={searchQuery}
                        onChange={(e) => setSearchQuery(e.target.value)}
                        onKeyPress={(e) => e.key === 'Enter' && handleSearch()}
                    />
                    <button onClick={handleSearch} className="search-btn">🔍 Search</button>
                </div>

                <div className="map-container">
                    <MapContainer
                        center={selectedLocation || defaultCenter}
                        zoom={13}
                        style={{ height: '400px', width: '100%' }}
                        key={selectedLocation ? `${selectedLocation[0]}-${selectedLocation[1]}` : 'default'}
                    >
                        <TileLayer
                            attribution='&copy; <a href="https://www.openstreetmap.org/copyright">OpenStreetMap</a> contributors'
                            url="https://{s}.tile.openstreetmap.org/{z}/{x}/{y}.png"
                        />
                        <LocationMarker 
                            position={selectedLocation} 
                            setPosition={setSelectedLocation}
                            setAddress={setAddress}
                        />
                    </MapContainer>
                </div>

                {selectedLocation && (
                    <div className="selected-location">
                        <p><strong>📍 Selected Location:</strong></p>
                        <p className="address">{address || 'Loading address...'}</p>
                        <p className="coordinates">
                            Coordinates: {selectedLocation[0].toFixed(6)}, {selectedLocation[1].toFixed(6)}
                        </p>
                    </div>
                )}

                <div className="manual-entry-section">
                    <p className="manual-entry-text">
                        Can't find your location? 
                        <button 
                            onClick={handleManualEntry}
                            className="manual-entry-btn"
                            disabled={!searchQuery.trim()}
                        >
                            Use "{searchQuery}" as address
                        </button>
                    </p>
                </div>

                <div className="location-picker-actions">
                    <button onClick={onClose} className="cancel-btn">Cancel</button>
                    <button 
                        onClick={handleConfirm} 
                        className="confirm-btn" 
                        disabled={!selectedLocation && !searchQuery.trim()}
                    >
                        Confirm Location
                    </button>
                </div>
            </div>
        </div>
    );
};

export default LocationPicker;