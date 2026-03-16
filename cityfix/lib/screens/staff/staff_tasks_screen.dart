import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/issue_card.dart';

class StaffTasksScreen extends StatelessWidget {
  final String staffEmail;
  final String staffName;

  const StaffTasksScreen({
    super.key,
    required this.staffEmail,
    required this.staffName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .where('assignedTo', isEqualTo: staffEmail)
            .snapshots(),

        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(
              child: CircularProgressIndicator(
                color: Color(0xFF5A6F4A),
              ),
            );
          }

          if (snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No tasks assigned to $staffName.",
                style: const TextStyle(
                  fontSize: 16,
                  color: Color(0xFF5A6F4A),
                ),
              ),
            );
          }

          final tasks = snapshot.data!.docs;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: tasks
                .map(
                  (doc) => IssueCard(
                issue: doc.data() as Map<String, dynamic>,
                id: doc.id,
              ),
            )
                .toList(),
          );
        },
      ),
    );
  }
}
