import 'dart:math';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:geolocator/geolocator.dart';
import 'report_issue_page.dart';
import 'user_alerts_screen.dart';
import '../common/issue_details_screen.dart';

import 'lost_and_found_page.dart';
import 'community_hub_page.dart';
import 'volunteering_page.dart';
import 'news_updates_page.dart';
import 'helpline_page.dart';
import 'donation_page.dart';
import 'chat_screen.dart';

class UserHomeScreen extends StatefulWidget {
  const UserHomeScreen({super.key});

  @override
  State<UserHomeScreen> createState() => _UserHomeScreenState();
}

class _UserHomeScreenState extends State<UserHomeScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  Position? _currentPosition;
  double _selectedRadius = 5;
  Stream<QuerySnapshot>? _reportsStream;

  @override
  void initState() {
    super.initState();
    _getCurrentLocation();
    _reportsStream = FirebaseFirestore.instance
        .collection('reports')
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Future<void> _getCurrentLocation() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) return;

    LocationPermission permission = await Geolocator.requestPermission();
    if (permission == LocationPermission.denied) return;

    final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.high);
    setState(() => _currentPosition = position);
  }

  double _calculateDistance(lat1, lon1, lat2, lon2) {
    const p = 0.017453292519943295;
    final a = 0.5 -
        cos((lat2 - lat1) * p) / 2 +
        cos(lat1 * p) * cos(lat2 * p) *
            (1 - cos((lon2 - lon1) * p)) / 2;
    return 12742 * asin(sqrt(a));
  }

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    return Scaffold(
      backgroundColor: Colors.white,
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            UserAccountsDrawerHeader(
              decoration: const BoxDecoration(
                color: Color(0xFF5A6F4A),
              ),
              accountName: Text(user?.displayName ?? "User"),
              accountEmail: Text(user?.email ?? ""),
              currentAccountPicture: const CircleAvatar(
                backgroundColor: Colors.white,
                child: Icon(Icons.person, color: Color(0xFF5A6F4A), size: 40),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.search),
              title: const Text('Lost and Found'),
              onTap: () {
                Navigator.pop(context); // Close drawer
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const LostAndFoundPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.people),
              title: const Text('Community Hub'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const CommunityHubPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.volunteer_activism),
              title: const Text('Volunteering'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const VolunteeringPage()),
                );
              },
            ),
             ListTile(
              leading: const Icon(Icons.newspaper),
              title: const Text('News Updates'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const NewsUpdatesPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.favorite, color: Colors.pink),
              title: const Text('Donate to Welfare'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const DonationPage()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.emergency, color: Colors.red),
              title: const Text('Helpline'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HelplinePage()),
                );
              },
            ),
          ],
        ),
      ),
      appBar: AppBar(
        iconTheme: const IconThemeData(color: Colors.white),
        backgroundColor: const Color(0xFF5A6F4A),
        title: const Text("CityFix", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const UserAlertsScreen()),
              );
            },
            icon: const Icon(Icons.notifications, color: Colors.white),
            tooltip: "Alerts",
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _reportsStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No reports found."));
          }

          final allReports = snapshot.data!.docs;
          List<QueryDocumentSnapshot> nearbyReports = [];
          
          // Filter out issues completed more than 1 month ago
          final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
          
          final filteredReports = allReports.where((doc) {
            final data = doc.data() as Map<String, dynamic>?;
            if (data == null) return true;
            
            final status = data['status'] ?? '';
            
            // Only filter if status is Completed or Resolved
            if (status == 'Completed' || status == 'Resolved') {
              // Safely check if completedAt field exists
              if (data.containsKey('completedAt')) {
                final completedAt = data['completedAt'];
                if (completedAt != null && completedAt is Timestamp) {
                  try {
                    final completedDate = completedAt.toDate();
                    if (completedDate.isBefore(oneMonthAgo)) {
                      return false; // Exclude this report (completed more than 1 month ago)
                    }
                  } catch (e) {
                    // If there's an error parsing the date, include the report
                    return true;
                  }
                }
              }
            }
            return true; // Include this report
          }).toList();

          if (_currentPosition != null) {
            for (var doc in filteredReports) {
              final lat = doc['latitude'];
              final lng = doc['longitude'];
              if (lat != null && lng != null) {
                final distance = _calculateDistance(
                  _currentPosition!.latitude,
                  _currentPosition!.longitude,
                  lat,
                  lng,
                );
                if (distance <= _selectedRadius) nearbyReports.add(doc);
              }
            }
          } else {
            nearbyReports = filteredReports;
          }

          int pendingCount = 0, inProgressCount = 0, resolvedCount = 0;
          for (var doc in nearbyReports) {
            final status = doc['status'] ?? '';
            if (status == 'Pending') {
              pendingCount++;
            } else if (status == 'In Progress' || status == 'Assigned') {
              inProgressCount++;
            } else if (status == 'Resolved' || status == 'Completed') {
              resolvedCount++;
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Hello, ${user?.email?.split('@')[0] ?? 'citizen'}",
                  style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5A6F4A)),
                ),
                const SizedBox(height: 4),
                const Text("What needs fixing today?", style: TextStyle(fontSize: 16, color: Colors.black54)),
                const SizedBox(height: 20),
                // 🟩 Report an Issue Card
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            GestureDetector(
                              onTap: () {
                                Navigator.push(context, MaterialPageRoute(builder: (context) => const ReportIssuePage()));
                              },
                              child: const CircleAvatar(
                                backgroundColor: Color(0xFF5A6F4A),
                                child: Icon(Icons.add, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text("Report an Issue", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                          ],
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          "Spotted a problem? Help make your city better by reporting it.",
                          style: TextStyle(fontSize: 14, color: Colors.black87),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                // 📊 Status Summary
                const Text("Your Reports", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5A6F4A))),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _statusCard("Pending", Colors.orange, "$pendingCount"),
                    _statusCard("In Progress", Colors.blue, "$inProgressCount"),
                    _statusCard("Resolved", Colors.green, "$resolvedCount"),
                  ],
                ),
                const SizedBox(height: 24),
                // 📍 Nearby Issues Filter
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text("Nearby Issues", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Color(0xFF5A6F4A))),
                    DropdownButton<double>(
                      value: _selectedRadius,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text("1 km")),
                        DropdownMenuItem(value: 5, child: Text("5 km")),
                        DropdownMenuItem(value: 10, child: Text("10 km")),
                        DropdownMenuItem(value: 30, child: Text("30 km")),
                        DropdownMenuItem(value: 50, child: Text("50 km")),
                      ],
                      onChanged: (value) => setState(() => _selectedRadius = value!),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // 🗂 Display Reports
                ...nearbyReports.map((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return _issueCard(data, doc.id);
                }).toList(),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const ChatScreen()),
          );
        },
        backgroundColor: const Color(0xFF5A6F4A),
        child: const Icon(Icons.chat_bubble_outline, color: Colors.white),
      ),
    );
  }

  Widget _statusCard(String title, Color color, String count) {
    return Expanded(
      child: Card(
        color: color.withOpacity(0.1),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            children: [
              Text(count, style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              const SizedBox(height: 4),
              Text(title, style: TextStyle(color: color)),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _toggleUpvote(String reportId, List<dynamic> currentUpvotes) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final upvotesList = List<String>.from(currentUpvotes);
    final userEmail = user.email!;

    if (upvotesList.contains(userEmail)) {
      upvotesList.remove(userEmail);
    } else {
      upvotesList.add(userEmail);
    }

    await FirebaseFirestore.instance
        .collection('reports')
        .doc(reportId)
        .update({'upvotes': upvotesList});
  }

  Widget _issueCard(Map<String, dynamic> issue, String reportId) {
    final type = issue['problemType'] ?? 'Unknown';
    final location = issue['location'] ?? 'Unknown';
    final status = issue['status'] ?? 'Pending';
    final description = issue['description'] ?? '';
    final date = (issue['createdAt'] != null) ? (issue['createdAt'] as Timestamp).toDate().toString().split(' ').first : '';
    final upvotes = (issue['upvotes'] as List<dynamic>?) ?? [];
    final imageUrl = issue['imageUrl'];

    Color badgeColor;
    if (status == "Pending") {
      badgeColor = Colors.orange;
    } else if (status == "In Progress" || status == "Assigned") {
      badgeColor = Colors.blue;
    } else if (status == "Resolved" || status == "Completed") {
      badgeColor = Colors.green;
    } else {
      badgeColor = Colors.grey;
    }

    final currentUserEmail = _auth.currentUser?.email;
    final hasUpvoted = currentUserEmail != null && upvotes.contains(currentUserEmail);

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 3,
      margin: const EdgeInsets.symmetric(vertical: 8),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IssueDetailsScreen(issue: issue, reportId: reportId),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
             if (imageUrl != null && imageUrl.toString().isNotEmpty)
              Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                    Text(type, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(color: badgeColor.withOpacity(0.15), borderRadius: BorderRadius.circular(20)),
                      child: Text(status, style: TextStyle(color: badgeColor, fontWeight: FontWeight.bold)),
                    ),
                  ]),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 16, color: Colors.grey),
                      const SizedBox(width: 4),
                      Expanded(child: Text(location, style: const TextStyle(color: Colors.black87), maxLines: 1, overflow: TextOverflow.ellipsis)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(description, maxLines: 2, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  Text("Reported: $date", style: const TextStyle(color: Colors.black54, fontSize: 12)),
                  // Only show upvote button if issue is not completed/resolved
                  if (status.toLowerCase() != 'completed' && status.toLowerCase() != 'resolved')
                    const SizedBox(height: 12),
                  if (status.toLowerCase() != 'completed' && status.toLowerCase() != 'resolved')
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => _toggleUpvote(reportId, upvotes),
                          child: Row(
                            children: [
                              Icon(
                                hasUpvoted ? Icons.thumb_up : Icons.thumb_up_outlined,
                                size: 20,
                                color: hasUpvoted ? const Color(0xFF5A6F4A) : Colors.grey,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                upvotes.length.toString(),
                                style: TextStyle(
                                  color: hasUpvoted ? const Color(0xFF5A6F4A) : Colors.grey,
                                  fontWeight: hasUpvoted ? FontWeight.bold : FontWeight.normal,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
