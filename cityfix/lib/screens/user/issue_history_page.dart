import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

class IssueHistoryPage extends StatelessWidget {
  const IssueHistoryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A6F4A),
        title: const Text("Issue History", style: TextStyle(color: Colors.white)),
        centerTitle: true,
      ),
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('reports')
                  .where('status', whereIn: ['Completed', 'Resolved'])
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No completed issues found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                // Filter: Only show issues completed more than 1 month ago
                final oneMonthAgo = DateTime.now().subtract(const Duration(days: 30));
                final oldCompletedIssues = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>?;
                  if (data == null) return false;
                  
                  // Safely check if completedAt field exists
                  if (data.containsKey('completedAt')) {
                    final completedAt = data['completedAt'];
                    if (completedAt != null && completedAt is Timestamp) {
                      try {
                        final completedDate = completedAt.toDate();
                        return completedDate.isBefore(oneMonthAgo);
                      } catch (e) {
                        return false;
                      }
                    }
                  }
                  return false;
                }).toList()
                  ..sort((a, b) {
                    final aData = a.data() as Map<String, dynamic>?;
                    final bData = b.data() as Map<String, dynamic>?;
                    final aDate = (aData != null && aData.containsKey('completedAt') && aData['completedAt'] is Timestamp)
                        ? (aData['completedAt'] as Timestamp).toDate()
                        : DateTime(1970);
                    final bDate = (bData != null && bData.containsKey('completedAt') && bData['completedAt'] is Timestamp)
                        ? (bData['completedAt'] as Timestamp).toDate()
                        : DateTime(1970);
                    return bDate.compareTo(aDate); // Descending order
                  });

                if (oldCompletedIssues.isEmpty) {
                  return const Center(
                    child: Text(
                      'No historical issues found',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: oldCompletedIssues.length,
                  itemBuilder: (context, index) {
                    final doc = oldCompletedIssues[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final completedAt = data['completedAt'] as Timestamp?;
                    final createdAt = data['createdAt'] as Timestamp?;
                    
                    return Card(
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 3,
                      margin: const EdgeInsets.symmetric(vertical: 8),
                      child: Padding(
                        padding: const EdgeInsets.all(12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    data['problemType'] ?? 'Unknown Issue',
                                    style: const TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                    vertical: 6,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.green.withOpacity(0.15),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    data['status'] ?? 'Completed',
                                    style: const TextStyle(
                                      color: Colors.green,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                                const SizedBox(width: 4),
                                Expanded(
                                  child: Text(
                                    data['location'] ?? 'Unknown location',
                                    style: const TextStyle(color: Colors.black87),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              data['description'] ?? 'No description',
                              style: const TextStyle(color: Colors.black87),
                            ),
                            const SizedBox(height: 8),
                            if (createdAt != null)
                              Text(
                                "Reported: ${DateFormat('MMM dd, yyyy').format(createdAt.toDate())}",
                                style: const TextStyle(
                                  color: Colors.black54,
                                  fontSize: 12,
                                ),
                              ),
                            if (completedAt != null) ...[
                              const SizedBox(height: 4),
                              Text(
                                "Completed: ${DateFormat('MMM dd, yyyy').format(completedAt.toDate())}",
                                style: const TextStyle(
                                  color: Colors.green,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ],
                            const SizedBox(height: 8),
                            // Show upvote count (read-only, no interaction)
                            Row(
                              children: [
                                const Icon(
                                  Icons.thumb_up_outlined,
                                  size: 16,
                                  color: Colors.grey,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  "${(data['upvotes'] as List<dynamic>? ?? []).length} upvotes",
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 12,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
    );
  }
}
