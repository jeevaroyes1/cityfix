import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class StaffProfileScreen extends StatefulWidget {
  const StaffProfileScreen({super.key});

  @override
  State<StaffProfileScreen> createState() => _StaffProfileScreenState();
}

class _StaffProfileScreenState extends State<StaffProfileScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _timeRange = 'Week'; // 'Week' or 'Month'

  // Profile controllers
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _districtController;
  late TextEditingController _panchayatController;
  late TextEditingController _wardController;
  late TextEditingController _departmentController;

  File? _selectedImage;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _districtController = TextEditingController();
    _panchayatController = TextEditingController();
    _wardController = TextEditingController();
    _departmentController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _districtController.dispose();
    _panchayatController.dispose();
    _wardController.dispose();
    _departmentController.dispose();
    super.dispose();
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'duau9rsfh';
    const uploadPreset = 'cityfix';
    final uploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

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
  }

  Future<void> _pickImage() async {
    final pickedFile = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
      });
    }
  }

  Future<void> _updateProfile(String docId, Map<String, dynamic> currentData) async {
    setState(() => _isUploading = true);
    
    try {
      // 1. Handle Direct Updates (Name, Phone, Image)
      String? imageUrl = currentData['profilePic'];
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToCloudinary(_selectedImage!);
      }

      await _firestore.collection('users').doc(docId).update({
        'name': _nameController.text.trim(),
        'phone': _phoneController.text.trim(),
        'profilePic': imageUrl,
      });

      // 2. Handle Email Update (if changed)
      if (_emailController.text.trim() != currentData['email']) {
        final user = _auth.currentUser;
        if (user != null) {
          try {
            await user.verifyBeforeUpdateEmail(_emailController.text.trim());
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Verification email sent to new address. Please verify to update.')),
            );
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error updating email: $e')),
            );
          }
        }
      }

      // 3. Handle Restricted Fields (District, Panchayat, Ward, Dept)
      final newDistrict = _districtController.text.trim();
      final newPanchayat = _panchayatController.text.trim();
      final newWard = _wardController.text.trim();
      final newDept = _departmentController.text.trim();

      if (newDistrict != (currentData['district'] ?? '') ||
          newPanchayat != (currentData['panchayat'] ?? '') ||
          newWard != (currentData['ward'] ?? '') ||
          newDept != (currentData['department'] ?? '')) {
        
        await _firestore.collection('staff_change_requests').add({
          'userId': docId,
          'staffName': _nameController.text.trim(),
          'staffEmail': _auth.currentUser?.email,
          'requestedChanges': {
            'district': newDistrict,
            'panchayat': newPanchayat,
            'ward': newWard,
            'department': newDept,
          },
          'status': 'pending',
          'createdAt': FieldValue.serverTimestamp(),
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Request sent to Admin for restricted fields update.')),
        );
      } else {
         ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile updated successfully')),
        );
      }
      
      if (mounted) Navigator.pop(context);

    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  void _showEditProfileDialog(Map<String, dynamic> userData, String docId) {
    _nameController.text = userData['name'] ?? '';
    _phoneController.text = userData['phone'] ?? '';
    _emailController.text = userData['email'] ?? '';
    _districtController.text = userData['district'] ?? '';
    _panchayatController.text = userData['panchayat'] ?? '';
    _wardController.text = userData['ward'] ?? '';
    _departmentController.text = userData['department'] ?? '';
    _selectedImage = null;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Edit Profile'),
          content: SizedBox(
            width: double.maxFinite,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                   GestureDetector(
                    onTap: () async {
                       await _pickImage();
                       setState(() {});
                    },
                    child: CircleAvatar(
                      radius: 40,
                      backgroundColor: Colors.grey[200],
                      backgroundImage: _selectedImage != null 
                        ? FileImage(_selectedImage!) 
                        : (userData['profilePic'] != null && userData['profilePic'].isNotEmpty 
                            ? NetworkImage(userData['profilePic']) 
                            : null) as ImageProvider?,
                      child: (_selectedImage == null && (userData['profilePic'] == null || userData['profilePic'].isEmpty))
                          ? const Icon(Icons.camera_alt, color: Colors.grey)
                          : null,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text("Tap to change picture", style: TextStyle(fontSize: 12, color: Colors.grey)),
                  const SizedBox(height: 16),
                  
                  TextField(controller: _nameController, decoration: const InputDecoration(labelText: 'Full Name')),
                  TextField(controller: _phoneController, decoration: const InputDecoration(labelText: 'Phone'), keyboardType: TextInputType.phone),
                  TextField(controller: _emailController, decoration: const InputDecoration(labelText: 'Email')),
                  const Divider(height: 30),
                  const Text("Restricted Fields (Requires Approval)", style: TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                  TextField(controller: _districtController, decoration: const InputDecoration(labelText: 'District')),
                  TextField(controller: _panchayatController, decoration: const InputDecoration(labelText: 'Panchayat')),
                  TextField(controller: _wardController, decoration: const InputDecoration(labelText: 'Ward')),
                  TextField(controller: _departmentController, decoration: const InputDecoration(labelText: 'Department')),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: _isUploading ? null : () => _updateProfile(docId, userData),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF5A6F4A),
                foregroundColor: Colors.white,
              ),
              child: _isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) 
                  : const Text('Save Changes'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildProfileHeader(user),
                  const SizedBox(height: 24),
                  
                  // Evaluation Section
                  StreamBuilder<QuerySnapshot>(
                    stream: _firestore.collection('reports').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return const Center(child: Text('No reports data available'));
                      }

                      final allReports = snapshot.data!.docs;
                      final myReports = allReports.where((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return (data['assignedTo'] == user.email) && 
                               (data['status'] == 'Completed' || data['status'] == 'Resolved');
                      }).toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSummaryCards(myReports),
                          const SizedBox(height: 24),
                          _buildChartSection(myReports),
                          const SizedBox(height: 24),
                          _buildComparisonSection(allReports, user.email ?? ''),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildProfileHeader(User user) {
    return StreamBuilder<DocumentSnapshot>(
      stream: _firestore.collection('users').where('email', isEqualTo: user.email).limit(1).snapshots().map((event) => event.docs.first),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final userData = snapshot.data!.data() as Map<String, dynamic>;
        final docId = snapshot.data!.id;

        return Card(
          elevation: 2,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    CircleAvatar(
                      radius: 35,
                      backgroundColor: const Color(0xFF5A6F4A),
                      backgroundImage: (userData['profilePic'] != null && userData['profilePic'].isNotEmpty)
                          ? NetworkImage(userData['profilePic'])
                          : null,
                      child: (userData['profilePic'] == null || userData['profilePic'].isEmpty)
                          ? Text(
                              (userData['name'] ?? 'S').substring(0, 1).toUpperCase(),
                              style: const TextStyle(fontSize: 24, color: Colors.white, fontWeight: FontWeight.bold),
                            )
                          : null,
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            userData['name'] ?? 'Staff Member',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            user.email ?? '',
                            style: const TextStyle(color: Colors.grey, fontSize: 13),
                          ),
                          if (userData['phone'] != null)
                             Text(
                              userData['phone'],
                              style: const TextStyle(color: Colors.grey, fontSize: 13),
                            ),
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              if (userData['department'] != null)
                                _buildTag(userData['department'], Colors.blue),
                              if (userData['district'] != null)
                                _buildTag(userData['district'], Colors.orange),
                              if (userData['panchayat'] != null)
                                _buildTag(userData['panchayat'], Colors.purple),
                             if (userData['ward'] != null)
                                _buildTag("Ward: ${userData['ward']}", Colors.teal),
                            ],
                          )
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => _showEditProfileDialog(userData, docId),
                      icon: const Icon(Icons.edit, color: Color(0xFF5A6F4A)),
                    ),
                  ],
                ),
                // Show Pending Status if any
                 StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('staff_change_requests')
                      .where('userId', isEqualTo: docId)
                      .where('status', isEqualTo: 'pending')
                      .snapshots(),
                  builder: (context, reqSnapshot) {
                    if (reqSnapshot.hasData && reqSnapshot.data!.docs.isNotEmpty) {
                      return Container(
                        margin: const EdgeInsets.only(top: 12),
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.orange.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.orange),
                        ),
                        child: const Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.orange, size: 16),
                            SizedBox(width: 8),
                            Expanded(child: Text("Change request pending approval.", style: TextStyle(color: Colors.orange, fontSize: 12))),
                          ],
                        ),
                      );
                    }
                    return const SizedBox();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(color: color, fontSize: 10, fontWeight: FontWeight.w500),
      ),
    );
  }

  Widget _buildSummaryCards(List<QueryDocumentSnapshot> myReports) {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);

    int countPastWeek = 0;
    int countPastMonth = 0;
    int countPrevWeek = 0;

    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    for (var doc in myReports) {
      final data = doc.data() as Map<String, dynamic>;
      final completedAt = (data['completedAt'] as Timestamp?)?.toDate() ?? 
                         (data['createdAt'] as Timestamp?)?.toDate() ?? 
                         DateTime.now();

      if (completedAt.isAfter(oneWeekAgo)) {
        countPastWeek++;
      }
      if (completedAt.isAfter(oneMonthAgo)) {
        countPastMonth++;
      }
      if (completedAt.isAfter(twoWeeksAgo) && completedAt.isBefore(oneWeekAgo)) {
        countPrevWeek++;
      }
    }

    double growthRate = 0;
    if (countPrevWeek > 0) {
      growthRate = ((countPastWeek - countPrevWeek) / countPrevWeek) * 100;
    } else if (countPastWeek > 0) {
      growthRate = 100;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Performance Overview",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5A6F4A)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard("Past Week", countPastWeek.toString(), Icons.calendar_view_week, Colors.blue),
            const SizedBox(width: 12),
            _buildStatCard("Past Month", countPastMonth.toString(), Icons.calendar_month, Colors.orange),
          ],
        ),
        const SizedBox(height: 12),
        _buildGrowthCard(growthRate),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthCard(double growthRate) {
    final isPositive = growthRate >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Work Completion Rate",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  "${isPositive ? '+' : ''}${growthRate.toStringAsFixed(1)}% compared to last week",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(List<QueryDocumentSnapshot> myReports) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Activity Chart",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Week', label: Text('Week')),
                  ButtonSegment(value: 'Month', label: Text('Month')),
                ],
                selected: {_timeRange},
                onSelectionChanged: (value) => setState(() => _timeRange = value.first),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  selectedBackgroundColor: const Color(0xFF5A6F4A),
                  selectedForegroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              _getMainChartData(myReports),
            ),
          ),
        ],
      ),
    );
  }

  BarChartData _getMainChartData(List<QueryDocumentSnapshot> myReports) {
    final now = DateTime.now();
    final days = _timeRange == 'Week' ? 7 : 30;
    final Map<String, int> dataMap = {};

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      dataMap[dateStr] = 0;
    }

    for (var doc in myReports) {
      final data = doc.data() as Map<String, dynamic>;
      final completedAt = (data['completedAt'] as Timestamp?)?.toDate() ?? 
                         (data['createdAt'] as Timestamp?)?.toDate() ?? 
                         DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(completedAt);
      if (dataMap.containsKey(dateStr)) {
        dataMap[dateStr] = dataMap[dateStr]! + 1;
      }
    }

    final sortedKeys = dataMap.keys.toList()..sort();
    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < sortedKeys.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: dataMap[sortedKeys[i]]!.toDouble(),
              color: const Color(0xFF5A6F4A),
              width: _timeRange == 'Week' ? 16 : 4,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (_timeRange == 'Month' && value.toInt() % 5 != 0) return const SizedBox();
              final index = value.toInt();
              if (index < 0 || index >= sortedKeys.length) return const SizedBox();
              final date = DateFormat('yyyy-MM-dd').parse(sortedKeys[index]);
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _timeRange == 'Week' ? DateFormat('E').format(date) : DateFormat('d').format(date),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
    );
  }

  Widget _buildComparisonSection(List<QueryDocumentSnapshot> allReports, String myEmail) {
    final staffStats = <String, int>{};

    for (var doc in allReports) {
      final data = doc.data() as Map<String, dynamic>;
      final assignedTo = data['assignedTo'] as String?;
      if (assignedTo != null && (data['status'] == 'Completed' || data['status'] == 'Resolved')) {
        staffStats[assignedTo] = (staffStats[assignedTo] ?? 0) + 1;
      }
    }

    final sortedStaff = staffStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get top 5 or some reasonable number for comparison
    final displayStats = sortedStaff.take(5).toList();
    if (!displayStats.any((e) => e.key == myEmail) && staffStats.containsKey(myEmail)) {
      displayStats.add(MapEntry(myEmail, staffStats[myEmail]!));
    }
    displayStats.sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Comparison with Others",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...displayStats.map((entry) {
            final isMe = entry.key == myEmail;
            final maxVal = displayStats.first.value;
            final percentage = maxVal > 0 ? entry.value / maxVal : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMe ? "You" : entry.key.split('@')[0],
                        style: TextStyle(
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          color: isMe ? const Color(0xFF5A6F4A) : Colors.black87,
                        ),
                      ),
                      Text(
                        "${entry.value} reports",
                        style: TextStyle(
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isMe ? const Color(0xFF5A6F4A) : Colors.grey[400]!,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
