// lib/screens/admin/staff_details_page.dart
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class StaffDetailsPage extends StatelessWidget {
  final String staffUid;
  final String staffName;
  final String email;
  final String department;

  const StaffDetailsPage({
    super.key,
    required this.staffUid,
    required this.staffName,
    required this.email,
    required this.department,
  });

  @override
  Widget build(BuildContext context) {
    final firestore = FirebaseFirestore.instance;

    return Scaffold(
      backgroundColor: Colors.white.withOpacity(0.98),
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A6F4A),
        elevation: 0,
        title: const Text("Staff Details"),
        actions: [
          IconButton(
            icon: const Icon(Icons.close, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          )
        ],
      ),
      body: FutureBuilder<DocumentSnapshot>(
        future: firestore.collection('users').doc(staffUid).get(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final staffData = snapshot.data?.data() as Map<String, dynamic>? ?? {};
          final joinedDate = staffData['createdAt'] != null
              ? DateFormat('dd/MM/yyyy')
              .format((staffData['createdAt'] as Timestamp).toDate())
              : 'N/A';

          return Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // 👤 Staff Info Section
                  Row(
                    children: [
                      CircleAvatar(
                        radius: 30,
                        backgroundColor: const Color(0xFF5A6F4A),
                        child: Text(
                          staffName.isNotEmpty
                              ? staffName[0].toUpperCase()
                              : "?",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              staffName,
                              style: const TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.brown.shade100,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                department,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w600),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // 📩 Email
                  Row(
                    children: [
                      const Icon(Icons.email, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(email),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 📞 Phone
                  Row(
                    children: [
                      const Icon(Icons.phone, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text(staffData['phone'] ?? 'No phone'),
                    ],
                  ),
                  const SizedBox(height: 8),

                  // 📅 Joined date
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, color: Colors.grey),
                      const SizedBox(width: 8),
                      Text("Joined $joinedDate"),
                    ],
                  ),
                  const SizedBox(height: 16),

                  const Divider(thickness: 1),

                  // 📊 Performance Section
                  const SizedBox(height: 16),
                  const Text(
                    "Performance",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),

                  StreamBuilder<QuerySnapshot>(
                    stream: firestore
                        .collection('reports')
                        .where('assignedTo', isEqualTo: email)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData) {
                        return const Center(
                            child: CircularProgressIndicator());
                      }

                      final allReports = snapshot.data!.docs;

                      final completedReports = allReports.where((doc) {
                        final status = (doc['status'] ?? '').toLowerCase();
                        return status == "completed";
                      }).toList();

                      // Average completion time
                      double avgDays = 0;
                      for (var doc in completedReports) {
                        final created =
                        (doc['createdAt'] as Timestamp).toDate();
                        final completedAt =
                        (doc['completedAt'] as Timestamp?)?.toDate();

                        if (completedAt != null) {
                          avgDays +=
                              completedAt.difference(created).inHours / 24.0;
                        }
                      }
                      avgDays = completedReports.isNotEmpty
                          ? avgDays / completedReports.length
                          : 0;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildMetricCard("Assigned", allReports.length),
                              _buildMetricCard("Completed",
                                  completedReports.length),
                              _buildMetricCard(
                                  "Avg. Time",
                                  "${avgDays.toStringAsFixed(1)} days"),
                            ],
                          ),
                          const SizedBox(height: 16),
                          const Divider(thickness: 1),

                          // List of completed issues
                          Text(
                            "Completed (${completedReports.length})",
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),

                          ...completedReports.map((doc) {
                            final data = doc.data() as Map<String, dynamic>;
                            final date = (data['completedAt'] as Timestamp?)
                                ?.toDate() ??
                                (data['createdAt'] as Timestamp).toDate();

                            return Card(
                              color: Colors.grey.shade100,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Column(
                                  crossAxisAlignment:
                                  CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          data['title'] ?? 'No title',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 8, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: Colors.black,
                                            borderRadius:
                                            BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            "completed",
                                            style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    Text(data['description'] ??
                                        'No description'),
                                    const SizedBox(height: 6),
                                    Row(
                                      children: [
                                        const Icon(Icons.location_on,
                                            color: Colors.grey, size: 16),
                                        const SizedBox(width: 4),
                                        Expanded(
                                          child: Text(
                                            data['location'] ??
                                                'No location',
                                            style: const TextStyle(
                                              color: Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    Row(
                                      children: [
                                        const Icon(Icons.calendar_today,
                                            color: Colors.grey, size: 16),
                                        const SizedBox(width: 4),
                                        Text(DateFormat('dd/MM/yyyy')
                                            .format(date)),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }).toList(),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0xFF5A6F4A),
        child: const Icon(Icons.help_outline, color: Colors.white),
        onPressed: () {},
      ),
    );
  }

  Widget _buildMetricCard(String label, dynamic value) {
    return Card(
      elevation: 2,
      color: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Container(
        width: 95,
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            Text(
              label,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              value.toString(),
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
