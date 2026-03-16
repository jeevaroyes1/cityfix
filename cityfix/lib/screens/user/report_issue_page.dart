import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'package:geolocator/geolocator.dart';
import 'user_home_page.dart';
import 'select_location_page.dart';
import '../../utils/notification_service.dart';

class ReportIssuePage extends StatefulWidget {
  final Map<String, dynamic>? initialData;

  const ReportIssuePage({super.key, this.initialData});

  @override
  State<ReportIssuePage> createState() => _ReportIssuePageState();
}

class _ReportIssuePageState extends State<ReportIssuePage> {
  String? selectedProblemType;
  double? latitude;
  double? longitude;
  File? _selectedImage;

  late TextEditingController _locationController;
  late TextEditingController _descriptionController;
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = false;

  String? _selectedCategory;
  final Map<String, List<String>> _categories = {
    "Infrastructure & Roads": [
      "Potholes",
      "Damaged Sidewalks",
      "Broken Street Signs",
      "Illegal Speed Bumps",
      "Road Blockages"
    ],
    "Utilities (Water & Electricity)": [
      "Water Leakage",
      "Sewage Overflow",
      "Street Light Outage",
      "Exposed Wires",
      "Low Water Pressure"
    ],
    "Sanitation & Environment": [
      "Illegal Dumping",
      "Missed Garbage Collection",
      "Overflowing Public Bins",
      "Graffiti/Vandalism",
      "Dead Animals"
    ],
    "Traffic & Public Safety": [
      "Broken Traffic Lights",
      "Abandoned Vehicles",
      "Illegal Parking",
      "Noise Pollution",
      "Stray Animals"
    ],
    "Parks & Recreation": [
      "Broken Playground Equipment",
      "Overgrown Grass/Weeds",
      "Park Vandalism"
    ],
  };

  @override
  void initState() {
    super.initState();
    _locationController = TextEditingController(text: widget.initialData?['location'] ?? '');
    _descriptionController = TextEditingController(text: widget.initialData?['description'] ?? '');
    
    // Attempt to restore category and problem type
    if (widget.initialData != null) {
      selectedProblemType = widget.initialData?['problemType'];
      
      // If we have a stored category, use it
      if (widget.initialData!.containsKey('category')) {
        _selectedCategory = widget.initialData?['category'];
      } else {
        // Fallback: try to find category by issue type if not explicitly stored
        // This supports legacy data or re-reporting old issues
        _selectedCategory = _categories.entries
            .firstWhere(
                (entry) => entry.value.contains(selectedProblemType), 
                orElse: () => const MapEntry("", [])
            ).key;
        if (_selectedCategory == "") _selectedCategory = null; 
      }
    }
  }

  // ✅ Pick image from camera or gallery
  Future<void> _pickImage(ImageSource source) async {
    try {
      final pickedFile = await _picker.pickImage(source: source, imageQuality: 80);
      if (pickedFile != null) {
        setState(() {
          _selectedImage = File(pickedFile.path);
        });
      }
    } catch (e) {
      debugPrint("Image pick error: $e");
    }
  }

  // ✅ Choose image source
  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Color(0xFF5A6F4A)),
                title: const Text("Open Camera"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo, color: Color(0xFF5A6F4A)),
                title: const Text("Choose from Gallery"),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  // ✅ Submit report to Firestore
  Future<void> _submitReport() async {
    if (selectedProblemType == null ||
        _locationController.text.isEmpty ||
        _descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please fill all required fields")),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception("User not logged in");
      }

      // Check if user has agreed to terms and conditions
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!userDoc.exists) {
        throw Exception("User document not found");
      }

      final termsAgreed = userDoc.data()?['termsAgreed'] ?? false;
      if (!termsAgreed) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "You must agree to the Terms and Conditions before submitting a report. Please log out and log in again to accept the terms.",
            ),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      // Check for duplicate incidents
      final bool confirmDuplicate = await _checkForDuplicateIncidents();
      if (!confirmDuplicate) {
         setState(() => _isLoading = false);
         return;
      }

      String imageUrl = "";
      if (_selectedImage != null) {
        debugPrint("Starting image upload to Cloudinary...");
        try {
          imageUrl = await _uploadImageToCloudinary(_selectedImage!);
          debugPrint("Image upload successful. URL: $imageUrl");
        } catch (e) {
          debugPrint("Image upload failed: $e");
          // Optionally rethrow or handle specific upload errors
          throw Exception("Failed to upload image: $e");
        }
      } else {
        debugPrint("No image selected.");
      }

      debugPrint("Submitting report with Image URL: '$imageUrl'");

      await FirebaseFirestore.instance.collection('reports').add({
        'userId': user.uid,
        'panchayat': userDoc.data()?['panchayat'],
        'ward': userDoc.data()?['ward'],
        'category': _selectedCategory,
        'problemType': selectedProblemType,
        'location': _locationController.text,
        'description': _descriptionController.text,
        'imageUrl': imageUrl,
        'status': 'Pending',
        'latitude': latitude,
        'longitude': longitude,
        'createdAt': FieldValue.serverTimestamp(),
      });

      debugPrint("Report added to Firestore successfully.");

      // Show a local push notification
      NotificationService().showInstantNotification(
        title: '✅ Issue Reported Successfully',
        body: 'Your $selectedProblemType issue at ${_locationController.text} has been submitted. We\'ll keep you updated!',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Report submitted successfully!")),
      );

      setState(() {
        selectedProblemType = null;
        _locationController.clear();
        _descriptionController.clear();
        _selectedImage = null;
      });

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error submitting report: $e")),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  /// Checks for reports with same location and problem type within 20 meters
  Future<bool> _checkForDuplicateIncidents() async {
    if (latitude == null || longitude == null || selectedProblemType == null) {
      return true; // Use basic validation if location not precise
    }

    try {
      final snapshot = await FirebaseFirestore.instance
          .collection('reports')
          .where('status', whereIn: ['Pending', 'In Progress'])
          .where('problemType', isEqualTo: selectedProblemType)
          .get();

      for (var doc in snapshot.docs) {
        final data = doc.data();
        final double? reportLat = data['latitude'];
        final double? reportLng = data['longitude'];

        if (reportLat != null && reportLng != null) {
          final double distanceInMeters = Geolocator.distanceBetween(
            latitude!,
            longitude!,
            reportLat,
            reportLng,
          );

          if (distanceInMeters <= 20) {
            // Found a duplicate nearby
            if (!mounted) return true;
            
            final bool? shouldProceed = await showDialog<bool>(
              context: context,
              builder: (context) => AlertDialog(
                title: const Row(
                  children: [
                     Icon(Icons.warning_amber_rounded, color: Colors.orange),
                     SizedBox(width: 8),
                     Text("Similar Issue Found"),
                  ],
                ),
                content: const Text(
                  "A similar issue has already been reported nearby (within 20m). \n\n"
                  "Reporting it again might be a duplicate. Do you still want to proceed?",
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(context, false),
                    child: const Text("Cancel"),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context, true),
                    child: const Text("Proceed Anyway"),
                  ),
                ],
              ),
            );
            return shouldProceed ?? false;
          }
        }
      }
    } catch (e) {
      debugPrint("Error checking duplicates: $e");
    }
    return true; // Proceed if no duplicates found or error checking
  }

  /// Upload image to Cloudinary and return the secure URL
  Future<String> _uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'duau9rsfh';
    const uploadPreset = 'cityfix';
    final uploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', uploadUrl)
      ..fields['upload_preset'] = uploadPreset
      ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

    debugPrint("Sending request to Cloudinary...");
    final response = await request.send();
    debugPrint("Cloudinary response status: ${response.statusCode}");
    
    if (response.statusCode == 200) {
      final resBody = await response.stream.bytesToString();
      debugPrint("Cloudinary response body: $resBody");
      final data = jsonDecode(resBody) as Map<String, dynamic>;
      final secureUrl = data['secure_url'] as String?;
      if (secureUrl == null || secureUrl.isEmpty) {
        throw Exception('Image upload failed: missing URL in response');
      }
      return secureUrl;
    } else {
      final resBody = await response.stream.bytesToString();
      debugPrint("Cloudinary error response: $resBody");
      throw Exception('Image upload failed (${response.statusCode}): $resBody');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A6F4A),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Report Issue",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),

      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            const Text("Category", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: "Select Category",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              value: _selectedCategory,
              items: _categories.keys
                  .map((cat) => DropdownMenuItem(value: cat, child: Text(cat)))
                  .toList(),
              onChanged: (value) {
                setState(() {
                  _selectedCategory = value;
                  selectedProblemType = null; // Reset subcategory
                });
              },
            ),
            const SizedBox(height: 16),
            
            const Text("Problem Type", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              decoration: InputDecoration(
                hintText: "Select specific problem",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                fillColor: _selectedCategory == null ? Colors.grey[200] : null,
                filled: _selectedCategory == null,
              ),
              value: selectedProblemType,
              // Only show items if a category is selected
              items: _selectedCategory == null 
                  ? [] 
                  : _categories[_selectedCategory]!
                      .map((type) => DropdownMenuItem(value: type, child: Text(type)))
                      .toList(),
              onChanged: _selectedCategory == null 
                  ? null // Disable if no category
                  : (value) => setState(() => selectedProblemType = value),
            ),
            const SizedBox(height: 20),

            const Text("Location", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: "Enter address or landmark",
                prefixIcon: const Icon(Icons.location_on, color: Color(0xFF5A6F4A)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 8),

            OutlinedButton.icon(
              onPressed: () async {
                final result = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const SelectLocationPage()),
                );

                if (result != null) {
                  setState(() {
                    latitude = result['lat'];
                    longitude = result['lng'];
                    _locationController.text = result['address'];
                  });

                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        "Location Selected:\n${result['address']}",
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  );
                }
              },
              icon: const Icon(Icons.my_location, color: Color(0xFF5A6F4A)),
              label: const Text("Choose From Maps"),
            ),
            const SizedBox(height: 20),

            const Text("Description", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: InputDecoration(
                hintText: "Describe the issue in detail…",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 20),

            const Text("Photo (Optional)", style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            GestureDetector(
              onTap: _showImageSourceDialog,
              child: Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(12),
                  image: _selectedImage != null
                      ? DecorationImage(
                    image: FileImage(_selectedImage!),
                    fit: BoxFit.cover,
                  )
                      : null,
                ),
                child: _selectedImage == null
                    ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.camera_alt, size: 40, color: Colors.grey),
                      SizedBox(height: 8),
                      Text("Tap to open camera or choose from gallery"),
                      Text(
                        "PNG, JPG up to 10MB",
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                )
                    : null,
              ),
            ),
            const SizedBox(height: 30),

            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A6F4A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: _isLoading ? null : _submitReport,
              icon: _isLoading
                  ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2,
                ),
              )
                  : const Icon(Icons.cloud_upload),
              label: Text(_isLoading ? "Submitting..." : "Submit Report"),
            ),
            const SizedBox(height: 12),
            OutlinedButton(
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),
          ],
        ),
      ),

      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF5A6F4A),
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: 0, // Highlight Home or keep 0 as default since this is a sub-page, but "Home" makes sense or none.
        // Actually, since we are on "Report Issue" which is accessed from Home, maybe highlighting "Home" is confusing if we are not ON Home.
        // However, user asked for "same bottom navigation bar".
        // Let's implement navigation logic.
        onTap: (index) {
          // Navigate to UserHomePage with correct tab index
          Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => UserHomePage(initialIndex: index),
            ),
            (route) => false, // Remove all previous routes to start fresh at Home
          );
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Analytics"),
          BottomNavigationBarItem(icon: Icon(Icons.military_tech), label: "Leaderboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
