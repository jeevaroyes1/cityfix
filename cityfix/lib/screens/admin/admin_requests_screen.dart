import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AdminRequestsScreen extends StatelessWidget {
  const AdminRequestsScreen({super.key});

  Future<void> _handleRequest(BuildContext context, String requestId, String userId, Map<String, dynamic> changes, bool isApproved) async {
    try {
      if (isApproved) {
        // 1. Update User Profile
        await FirebaseFirestore.instance.collection('users').doc(userId).update(changes);
      }

      // 2. Update Request Status
      await FirebaseFirestore.instance.collection('staff_change_requests').doc(requestId).update({
        'status': isApproved ? 'approved' : 'rejected',
        'processedAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(isApproved ? "Request Approved & Profile Updated" : "Request Rejected")),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Staff Change Requests", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5A6F4A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('staff_change_requests')
            .where('status', isEqualTo: 'pending')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(child: Text("No pending requests."));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final doc = snapshot.data!.docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final changes = data['requestedChanges'] as Map<String, dynamic>;
              final createdAt = (data['createdAt'] as Timestamp?)?.toDate();

              return Card(
                elevation: 3,
                margin: const EdgeInsets.only(bottom: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.person_outline, size: 28, color: Color(0xFF5A6F4A)),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  data['staffName'] ?? 'Unknown Staff',
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                                ),
                                Text(
                                  data['staffEmail'] ?? '',
                                  style: const TextStyle(color: Colors.grey, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          if (createdAt != null)
                            Text(
                              DateFormat('MMM d, h:mm a').format(createdAt),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                        ],
                      ),
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 12),
                        child: Divider(),
                      ),
                      const Text("Requested Changes:", style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      ...changes.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.only(bottom: 4.0),
                          child: Row(
                            children: [
                              Text(
                                "${e.key.substring(0, 1).toUpperCase()}${e.key.substring(1)}: ",
                                style: TextStyle(color: Colors.grey[700], fontWeight: FontWeight.w500),
                              ),
                              Expanded(
                                child: Text(
                                  e.value.toString(),
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                        );
                      }),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => _handleRequest(context, doc.id, data['userId'], changes, false),
                            style: TextButton.styleFrom(foregroundColor: Colors.red),
                            child: const Text("Reject"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () => _handleRequest(context, doc.id, data['userId'], changes, true),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF5A6F4A),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Approve"),
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
