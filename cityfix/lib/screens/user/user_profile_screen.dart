import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../auth/landing_page.dart';
import 'report_issue_page.dart';
import 'donation_page.dart';
import 'policies_page.dart';
import 'user_alerts_screen.dart';
import 'issue_history_page.dart';

class UserProfileScreen extends StatefulWidget {
  const UserProfileScreen({super.key});

  @override
  State<UserProfileScreen> createState() => _UserProfileScreenState();
}

class _UserProfileScreenState extends State<UserProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final ImagePicker _imagePicker = ImagePicker();

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'duau9rsfh';
    const uploadPreset = 'cityfix';
    final uploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    try {
      final request = http.MultipartRequest('POST', uploadUrl)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final data = jsonDecode(resBody);
        return data['secure_url'];
      }
      return null;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _uploadProfilePicture() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
      );

      if (pickedFile != null) {
        final user = _auth.currentUser;
        if (user == null) return;

        // Show loading or feedback if needed (optional optimization)
        
        final downloadUrl = await _uploadImageToCloudinary(File(pickedFile.path));
        
        if (downloadUrl != null) {
           await _firestore.collection('users').doc(user.uid).set(
            {'profilePicture': downloadUrl},
            SetOptions(merge: true),
          );

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Profile picture updated')),
            );
          }
        } else {
           if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Failed to upload image')),
            );
          }
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading picture: $e')),
      );
    }
  }

  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _auth.signOut();
              if (mounted) {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (context) => const LandingPage()),
                  (route) => false,
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteReport(String reportId) async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Report'),
        content: const Text('Are you sure you want to delete this report?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await _firestore.collection('reports').doc(reportId).delete();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _editReport(String reportId, Map<String, dynamic> reportData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditReportPage(
          reportId: reportId,
          reportData: reportData,
        ),
      ),
    );
  }

  void _reportAgain(Map<String, dynamic> reportData) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ReportIssuePage(initialData: reportData),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Profile', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserAlertsScreen()),
              );
            },
            icon: const Icon(Icons.notifications_outlined, color: Colors.black),
            tooltip: "Alerts",
          ),
        ],
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 30),
                  const Text(
                    "Account",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
                  ),
                  const SizedBox(height: 15),
                  _buildMenuSection(),
                  const SizedBox(height: 30),
                  _buildStatisticsSection(),
                  const SizedBox(height: 30),
                  _buildMyReportsSection(),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').doc(user.uid).snapshots(),
      builder: (context, snapshot) {
        final userData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
        final profilePictureUrl = userData['profilePicture'] as String?;

        return Center(
          child: Column(
            children: [
              GestureDetector(
                onTap: _uploadProfilePicture,
                child: Stack(
                  children: [
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: const Color(0xFF5A6F4A), width: 3),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.grey[200],
                        backgroundImage: profilePictureUrl != null
                            ? NetworkImage(profilePictureUrl)
                            : null,
                        child: profilePictureUrl == null
                            ? Text(
                                user.email?.substring(0, 1).toUpperCase() ?? 'U',
                                style: const TextStyle(
                                  color: Color(0xFF5A6F4A),
                                  fontSize: 40,
                                  fontWeight: FontWeight.bold,
                                ),
                              )
                            : null,
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Color(0xFF5A6F4A),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          size: 18,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                user.email?.split('@')[0] ?? 'User',
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                user.email ?? 'No email',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[600],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildMenuSection() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          _buildMenuItem(
            icon: Icons.settings_outlined,
            text: "Settings",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const SettingsPage()),
              );
            },
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),
          _buildMenuItem(
            icon: Icons.history,
            text: "Reports History",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const IssueHistoryPage()));
            },
          ),
          const Divider(height: 1, indent: 20, endIndent: 20),

          _buildMenuItem(
            icon: Icons.policy_outlined,
            text: "Policies",
            onTap: () {
              Navigator.push(context, MaterialPageRoute(builder: (context) => const PoliciesPage()));
            },
          ),
           const Divider(height: 1, indent: 20, endIndent: 20),
          _buildMenuItem(
            icon: Icons.logout,
            text: "Logout",
            textColor: Colors.red,
            iconColor: Colors.red,
            onTap: _logout,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String text,
    required VoidCallback onTap,
    Color textColor = Colors.black87,
    Color iconColor = Colors.grey,
  }) {
    return ListTile(
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: iconColor.withOpacity(0.1),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: iconColor, size: 20),
      ),
      title: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
      trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
      onTap: onTap,
      contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
    );
  }

  Widget _buildStatisticsSection() {
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('reports')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data!.docs;
        int totalReports = reports.length;
        int resolvedReports = 0;

        for (var doc in reports) {
          final data = doc.data() as Map<String, dynamic>;
          if (data['status'] == 'Resolved' || data['status'] == 'Completed') {
            resolvedReports++;
          }
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Highlights',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 15),
            Row(
              children: [
                _statisticCard('Total Reports', totalReports.toString(), Colors.blueAccent, Icons.assignment),
                const SizedBox(width: 15),
                _statisticCard('Resolutions', resolvedReports.toString(), Colors.green, Icons.check_circle_outline),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _statisticCard(String label, String value, Color color, IconData icon) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withOpacity(0.1)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 12),
            Text(
              value,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.w500),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMyReportsSection() {
    // FIX: Removing orderBy temporarily to avoid index issues.
    return StreamBuilder<QuerySnapshot>(
      stream: _firestore
          .collection('reports')
          .where('userId', isEqualTo: _auth.currentUser?.uid)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
           return Text("Error loading reports: ${snapshot.error}");
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final reports = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Recent Reports',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: (){}, // Could navigate to a full list page
                  child: const Text("View All", style: TextStyle(color: Color(0xFF5A6F4A))),
                )
              ],
            ),
            const SizedBox(height: 10),
            if (reports.isEmpty)
              _buildEmptyReportState()
            else
              Column(
                children: reports.take(3).map((doc) { // Show only recent 3 for brevity in profile
                  final data = doc.data() as Map<String, dynamic>;
                  return _buildReportCard(doc.id, data);
                }).toList(),
              ),
          ],
        );
      },
    );
  }
  
  Widget _buildEmptyReportState() {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Column(
          children: [
            Icon(Icons.assignment_outlined, size: 48, color: Colors.grey[300]),
            const SizedBox(height: 16),
            Text(
              "No reports submitted yet",
              style: TextStyle(color: Colors.grey[600], fontSize: 16),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ReportIssuePage(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A6F4A),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 0,
              ),
              child: const Text('Report an Issue', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
      );
  }

  Widget _buildReportCard(String reportId, Map<String, dynamic> data) {
    Color statusColor;
    switch (data['status']) {
      case 'Pending':
        statusColor = Colors.orange;
        break;
      case 'In Progress':
      case 'Assigned':
        statusColor = Colors.blue;
        break;
      case 'Resolved':
      case 'Completed':
        statusColor = Colors.green;
        break;
      default:
        statusColor = Colors.grey;
    }
    
    bool canReportAgain = data['status'] == 'Pending';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    data['problemType'] ?? 'Unknown',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF333333),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    data['status'] ?? 'Unknown',
                    style: TextStyle(
                      color: statusColor,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.location_on, size: 14, color: Colors.grey),
                const SizedBox(width: 4),
                Text(
                  data['location'] ?? 'Unknown location',
                  style: TextStyle(color: Colors.grey[600], fontSize: 13),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                if (canReportAgain)
                  InkWell(
                    onTap: () => _reportAgain(data),
                     child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("Report Again", style: TextStyle(color: Colors.orange, fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                const SizedBox(width: 8),
                if (data['status'] != 'Completed' && data['status'] != 'Resolved') ...[
                  InkWell(
                    onTap: () => _editReport(reportId, data),
                    child: const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Text("Edit", style: TextStyle(color: Color(0xFF5A6F4A), fontSize: 13, fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                InkWell(
                  onTap: () => _deleteReport(reportId),
                  child: const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text("Delete", style: TextStyle(color: Colors.red, fontSize: 13, fontWeight: FontWeight.w600)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class EditReportPage extends StatefulWidget {
  final String reportId;
  final Map<String, dynamic> reportData;

  const EditReportPage({
    super.key,
    required this.reportId,
    required this.reportData,
  });

  @override
  State<EditReportPage> createState() => _EditReportPageState();
}

class _EditReportPageState extends State<EditReportPage> {
  late TextEditingController _problemTypeController;
  late TextEditingController _descriptionController;
  late TextEditingController _locationController;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    _problemTypeController = TextEditingController(
      text: widget.reportData['problemType'] ?? '',
    );
    _descriptionController = TextEditingController(
      text: widget.reportData['description'] ?? '',
    );
    _locationController = TextEditingController(
      text: widget.reportData['location'] ?? '',
    );
  }

  @override
  void dispose() {
    _problemTypeController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    super.dispose();
  }

  Future<void> _updateReport() async {
    if (_problemTypeController.text.isEmpty ||
        _descriptionController.text.isEmpty ||
        _locationController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    try {
      await _firestore.collection('reports').doc(widget.reportId).update({
        'problemType': _problemTypeController.text,
        'description': _descriptionController.text,
        'location': _locationController.text,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Report updated successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A6F4A),
        title: const Text('Edit Report', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Problem Type',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _problemTypeController,
              decoration: InputDecoration(
                hintText: 'e.g., Pothole, Street Light',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Location',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _locationController,
              decoration: InputDecoration(
                hintText: 'Enter location',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Description',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 5,
              decoration: InputDecoration(
                hintText: 'Describe the issue in detail',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _updateReport,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A6F4A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Save Changes',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  late TextEditingController _stateController;
  late TextEditingController _districtController;
  late TextEditingController _panchayatController;
  late TextEditingController _wardController;

  @override
  void initState() {
    super.initState();
    _stateController = TextEditingController();
    _districtController = TextEditingController();
    _panchayatController = TextEditingController();
    _wardController = TextEditingController();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      final doc = await _firestore.collection('users').doc(user.uid).get();
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        setState(() {
          _stateController.text = data['state'] ?? '';
          _districtController.text = data['district'] ?? '';
          _panchayatController.text = data['panchayat'] ?? '';
          _wardController.text = data['ward'] ?? '';
        });
      }
    } catch (e) {
      debugPrint('Error loading user data: $e');
    }
  }

  Future<void> _saveSettings() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return;

      await _firestore.collection('users').doc(user.uid).set(
        {
          'state': _stateController.text,
          'district': _districtController.text,
          'panchayat': _panchayatController.text,
          'ward': _wardController.text,
        },
        SetOptions(merge: true),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Settings saved successfully')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error saving settings: $e')),
      );
    }
  }

  @override
  void dispose() {
    _stateController.dispose();
    _districtController.dispose();
    _panchayatController.dispose();
    _wardController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A6F4A),
        title: const Text('Settings', style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Location Information',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A6F4A),
              ),
            ),
            const SizedBox(height: 16),
            _buildTextField("State", _stateController),
            const SizedBox(height: 12),
            _buildTextField("District", _districtController),
            const SizedBox(height: 12),
            _buildTextField("Panchayat", _panchayatController),
            const SizedBox(height: 12),
            _buildTextField("Ward", _wardController),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _saveSettings,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF5A6F4A),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                child: const Text(
                  'Save Settings',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
            const Divider(height: 40),
             const Text(
              'About',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFF5A6F4A),
              ),
            ),
            ListTile(
              title: const Text("Terms and Conditions"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const PolicyDetailPage(title: "Terms and Conditions", content: kTermsAndConditions)));
              },
            ),
            ListTile(
              title: const Text("Community Policy"),
              trailing: const Icon(Icons.arrow_forward_ios, size: 16),
              onTap: () {
                 Navigator.push(context, MaterialPageRoute(builder: (context) => const PolicyDetailPage(title: "Community Policy", content: kCommunityPolicy)));
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }
}
