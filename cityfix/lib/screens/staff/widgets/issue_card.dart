import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../common/issue_details_screen.dart';

class IssueCard extends StatelessWidget {
  final Map<String, dynamic> issue;
  final String id;

  const IssueCard({super.key, required this.issue, required this.id});

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return Colors.amber;
      case 'assigned':
        return Colors.blueAccent;
      case 'completed':
      case 'resolved':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Future<void> _updateReportStatus(String reportId, String currentStatus, String? assignedTo) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    String newStatus;
    String? newAssignedTo;

    if (currentStatus == 'Pending') {
      newStatus = 'Assigned';
      newAssignedTo = user.email;
    } else if (currentStatus == 'Assigned' && assignedTo == user.email) {
      newStatus = 'Completed';
      newAssignedTo = user.email;
    } else {
      return;
    }

    await FirebaseFirestore.instance.collection('reports').doc(reportId).update({
      'status': newStatus,
      'assignedTo': newAssignedTo,
      if (newStatus == 'Completed') 'completedAt': FieldValue.serverTimestamp(),
    });

    if (newStatus == 'Completed') {
      final issueData = await FirebaseFirestore.instance.collection('reports').doc(reportId).get();
      final userId = issueData.data()?['userId'];
      final problemType = issueData.data()?['problemType'] ?? 'Issue';

      if (userId != null) {
        // Create an in-app notification record
        await FirebaseFirestore.instance.collection('notifications').add({
          'userId': userId,
          'title': 'Issue Completed',
          'body': 'Your reported issue "$problemType" has been marked as completed.',
          'createdAt': FieldValue.serverTimestamp(),
          'read': false,
          'reportId': reportId,
        });

        // The user also wants real-time notifications. 
        // In a full production app, you would use a Cloud Function to send FCM messages.
        // For this local implementation, we have set up the foundation in NotificationService.
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final status = (issue['status'] ?? 'Pending').toString();
    final assignedTo = issue['assignedTo'];
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;
    final imageUrl = issue['imageUrl'];

    return Card(
      color: Colors.white,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 2,
      clipBehavior: Clip.antiAlias, // Enable clipping for InkWell and Image
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => IssueDetailsScreen(issue: issue, reportId: id),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Display Image if available
            if (imageUrl != null && imageUrl.toString().isNotEmpty)
              Image.network(
                imageUrl,
                height: 150,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
              ),
            
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        issue['problemType'] ?? 'Unknown',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF583224),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      const Icon(Icons.location_on, size: 18, color: Color(0xFF583224)),
                      const SizedBox(width: 6),
                      Text(issue['location'] ?? 'Unknown location'),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    issue['description'] ?? '',
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 14, color: Colors.black87),
                  ),
                  const SizedBox(height: 8),
                  if (issue['userId'] != null)
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: Colors.grey),
                        const SizedBox(width: 6),
                        Text("User ID: ${issue['userId']}", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  const SizedBox(height: 10),
                  Align(
                    alignment: Alignment.centerRight,
                    child: ElevatedButton.icon(
                      onPressed: () => _updateReportStatus(id, status, assignedTo),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: (status.toLowerCase() == 'completed') ? Colors.grey : const Color(0xFF583224),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      icon: const Icon(Icons.assignment_ind, size: 18, color: Colors.white),
                      label: Text(
                        status == 'Pending'
                            ? "Assign to Me"
                            : (status == 'Assigned' && assignedTo == currentUserEmail)
                            ? "Mark Completed"
                            : (status == 'Completed')
                            ? "Completed"
                            : "Assigned to ${assignedTo ?? 'Other'}",
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
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
