import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Color _statusColor(String status) {
    switch (status) {
      case 'Pending':
        return Colors.amber;
      case 'Assigned':
        return Colors.blueAccent;
      case 'Completed':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  Widget _buildSummaryCard({
    required String label,
    required IconData icon,
    required String value,
    required Color iconColor,
    Color? valueColor,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 5,
            offset: const Offset(0, 2),
          )
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: const TextStyle(
                      fontSize: 14,
                      color: Colors.black87,
                      fontWeight: FontWeight.w500)),
              const SizedBox(height: 6),
              Text(value,
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: valueColor ?? Colors.black)),
            ],
          ),
          Icon(icon, size: 28, color: iconColor),
        ],
      ),
    );
  }

  Widget _buildStatusSummaryCard({
    required String label,
    required int count,
    required IconData icon,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 5,
              offset: const Offset(0, 2),
            )
          ],
        ),
        padding: const EdgeInsets.symmetric(vertical: 20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 32),
            const SizedBox(height: 8),
            Text("$count",
                style: TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold, color: color)),
            const SizedBox(height: 4),
            Text(label,
                style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }

  // 🟫 Issue Card — KNN removed
  Widget _buildIssueCard(Map<String, dynamic> issue) {
    return Card(
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(issue['problemType'] ?? 'No Title',
                style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF5A6F4A))),
            const SizedBox(height: 8),
            Row(children: [
              const Icon(Icons.location_on,
                  color: Color(0xFF6B8E23), size: 18),
              const SizedBox(width: 6),
              Expanded(
                  child: Text(issue['location'] ?? 'Unknown',
                      style: const TextStyle(fontSize: 14))),
            ]),
            const SizedBox(height: 6),
            Row(children: [
              const Icon(Icons.calendar_today,
                  color: Colors.grey, size: 16),
              const SizedBox(width: 6),
              Text(
                issue['createdAt'] != null
                    ? (issue['createdAt'] as Timestamp)
                    .toDate()
                    .toString()
                    .split('.')[0]
                    : 'No Date',
                style: const TextStyle(fontSize: 14, color: Colors.grey),
              ),
            ]),
            const SizedBox(height: 10),
            Container(
              padding:
              const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                  color: _statusColor(issue['status'] ?? '').withOpacity(0.2),
                  borderRadius: BorderRadius.circular(20)),
              child: Text(
                (issue['status'] ?? 'Unknown').toUpperCase(),
                style: TextStyle(
                    color: _statusColor(issue['status'] ?? ''),
                    fontWeight: FontWeight.bold,
                    fontSize: 13),
              ),
            ),

            const SizedBox(height: 8),

            // ❌ Removed KNN Priority section
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No issues found',
                style: TextStyle(fontSize: 16, color: Colors.grey)),
          );
        }

        final docs = snapshot.data!.docs;
        final total = docs.length;
        final pendingCount =
            docs.where((d) => d['status'] == 'Pending').length;
        final assignedCount =
            docs.where((d) => d['status'] == 'Assigned').length;
        final completedCount =
            docs.where((d) => d['status'] == 'Completed').length;
        final resolutionRate =
        total == 0 ? 0 : ((completedCount / total) * 100).toInt();

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                GridView.count(
                  crossAxisCount: 2,
                  crossAxisSpacing: 14,
                  mainAxisSpacing: 14,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  childAspectRatio: 1.9,
                  children: [
                    _buildSummaryCard(
                      label: "Total Issues",
                      icon: Icons.warning_amber_rounded,
                      value: "$total",
                      iconColor: Colors.grey,
                    ),
                    _buildSummaryCard(
                      label: "Resolution Rate",
                      icon: Icons.trending_up,
                      value: "$resolutionRate%",
                      iconColor: Colors.green,
                      valueColor: Colors.green,
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                const Text("Status Summary",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A6F4A))),
                const SizedBox(height: 12),
                Row(children: [
                  _buildStatusSummaryCard(
                      label: "Pending",
                      count: pendingCount,
                      icon: Icons.access_time,
                      color: Colors.amber),
                  const SizedBox(width: 10),
                  _buildStatusSummaryCard(
                      label: "Assigned",
                      count: assignedCount,
                      icon: Icons.work_outline,
                      color: Colors.blueAccent),
                  const SizedBox(width: 10),
                  _buildStatusSummaryCard(
                      label: "Completed",
                      count: completedCount,
                      icon: Icons.check_circle,
                      color: Colors.green),
                ]),
                const SizedBox(height: 24),

                const Text("Recent Issues",
                    style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF5A6F4A))),
                const SizedBox(height: 12),
                Column(
                  children: docs
                      .map((d) =>
                      _buildIssueCard(d.data() as Map<String, dynamic>))
                      .toList(),
                ),
              ]),
        );
      },
    );
  }
}
