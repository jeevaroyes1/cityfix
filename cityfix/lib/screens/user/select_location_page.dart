import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SelectLocationPage extends StatefulWidget {
  const SelectLocationPage({super.key});

  @override
  State<SelectLocationPage> createState() => _SelectLocationPageState();
}

class _SelectLocationPageState extends State<SelectLocationPage> {
  GoogleMapController? mapController;
  LatLng? selectedLocation;
  LatLng? currentLocation;
  String? selectedAddress;

  @override
  void initState() {
    super.initState();
    _determinePosition();
  }

  /// Get the user's current position
  Future<void> _determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location services are disabled')),
      );
      return;
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.deniedForever) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permissions are permanently denied')),
      );
      return;
    }

    Position position = await Geolocator.getCurrentPosition(
      desiredAccuracy: LocationAccuracy.high,
    );

    setState(() {
      currentLocation = LatLng(position.latitude, position.longitude);
      selectedLocation = currentLocation; // default selection
      _getAddressFromLatLng(currentLocation!);
    });
  }

  /// Convert coordinates to a readable address
  Future<void> _getAddressFromLatLng(LatLng position) async {
    try {
      List<Placemark> placemarks =
      await placemarkFromCoordinates(position.latitude, position.longitude);
      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          selectedAddress =
          "${place.name}, ${place.locality}, ${place.administrativeArea}, ${place.country}";
        });
      }
    } catch (e) {
      debugPrint("Error getting address: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Select Location',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF5A6F4A),
        iconTheme: const IconThemeData(color: Color(0xFF5A6F4A)),
        centerTitle: true,
      ),
      body: currentLocation == null
          ? const Center(
        child: CircularProgressIndicator(
          color: Color(0xFF5A6F4A),
        ),
      )
          : Container(
        color: Colors.white, // ✅ ensures white background
        child: Stack(
          children: [
            GoogleMap(
              initialCameraPosition: CameraPosition(
                target: currentLocation!,
                zoom: 16,
              ),
              onMapCreated: (controller) => mapController = controller,
              myLocationEnabled: true,
              myLocationButtonEnabled: true,
              onTap: (LatLng position) {
                setState(() {
                  selectedLocation = position;
                  selectedAddress = null;
                });
                _getAddressFromLatLng(position);
              },
              markers: {
                if (selectedLocation != null)
                  Marker(
                    markerId: const MarkerId("selected"),
                    position: selectedLocation!,
                  ),
              },
            ),

            // Address display at bottom
            if (selectedAddress != null)
              Positioned(
                bottom: 70,
                left: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        blurRadius: 6,
                      ),
                    ],
                  ),
                  child: Text(
                    selectedAddress!,
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),

            // ✅ Confirm button (not floating, bottom-left)
            if (selectedLocation != null)
              Positioned(
                bottom: 16,
                left: 16,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A6F4A),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  onPressed: () {
                    Navigator.pop(context, {
                      'lat': selectedLocation!.latitude,
                      'lng': selectedLocation!.longitude,
                      'address': selectedAddress ?? 'Unknown location',
                    });
                  },
                  icon: const Icon(Icons.check),
                  label: const Text('Confirm Location'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
