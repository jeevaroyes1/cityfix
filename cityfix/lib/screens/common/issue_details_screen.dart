import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class IssueDetailsScreen extends StatelessWidget {
  final Map<String, dynamic> issue;
  final String reportId;

  const IssueDetailsScreen({
    super.key,
    required this.issue,
    required this.reportId,
  });

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

  @override
  Widget build(BuildContext context) {
    final status = (issue['status'] ?? 'Pending').toString();
    final imageUrl = issue['imageUrl'];
    final timestamp = issue['createdAt'];
    String dateStr = 'No Date';
    if (timestamp != null && timestamp is Timestamp) {
      dateStr = timestamp.toDate().toString().split('.')[0];
    }

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Issue Details", style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5A6F4A),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (imageUrl != null && imageUrl.toString().isNotEmpty)
              Image.network(
                imageUrl,
                width: double.infinity,
                height: 300,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 300,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image, size: 50, color: Colors.grey)),
                ),
              )
            else
              Container(
                height: 200,
                color: Colors.grey[200],
                child: const Center(child: Icon(Icons.image_not_supported, size: 50, color: Colors.grey)),
              ),
            
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          issue['problemType'] ?? 'Report',
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF583224),
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: _statusColor(status).withOpacity(0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          status.toUpperCase(),
                          style: TextStyle(
                            color: _statusColor(status),
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  _buildDetailRow(Icons.location_on, "Location", issue['location'] ?? 'Unknown'),
                  const SizedBox(height: 12),
                  
                  _buildDetailRow(Icons.calendar_today, "Reported On", dateStr),
                  const SizedBox(height: 12),

                  if (issue['description'] != null && issue['description'].toString().isNotEmpty) ... [
                     const Text("Description", style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                     const SizedBox(height: 4),
                     Text(
                       issue['description'],
                       style: const TextStyle(fontSize: 16, color: Colors.black87),
                     ),
                     const SizedBox(height: 12),
                  ],

                  if (issue['userId'] != null)
                   _buildDetailRow(Icons.person, "Reported By (ID)", issue['userId']),

                  const SizedBox(height: 12),
                  _buildDetailRow(Icons.thumb_up, "Upvotes", "${(issue['upvotes'] as List<dynamic>? ?? []).length}"),

                    const SizedBox(height: 20),
                   if (status == 'Completed' && issue['completedAt'] != null)
                      _buildDetailRow(Icons.check_circle_outline, "Completed On", (issue['completedAt'] as Timestamp).toDate().toString().split('.')[0]),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: const TextStyle(fontSize: 12, color: Colors.grey)),
              Text(value, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500)),
            ],
          ),
        ),
      ],
    );
  }
}
