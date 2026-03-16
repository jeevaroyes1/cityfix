import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'widgets/issue_card.dart';

class StaffHomeScreen extends StatefulWidget {
  const StaffHomeScreen({super.key});

  @override
  State<StaffHomeScreen> createState() => _StaffHomeScreenState();
}

class _StaffHomeScreenState extends State<StaffHomeScreen> {
  String _selectedFilter = 'All Issues';
  String _selectedCategory = 'All Categories';

  bool _matchesFilter(Map<String, dynamic> issue, String statusFilter, String categoryFilter) {
    final rawStatus = (issue['status'] ?? '').toString().toLowerCase();
    final rawCategory = (issue['category'] ?? '').toString();

    bool statusMatch = true;
    if (statusFilter == 'Pending') statusMatch = rawStatus == 'pending';
    else if (statusFilter == 'In Progress') statusMatch = rawStatus == 'assigned' || rawStatus == 'in progress';
    else if (statusFilter == 'Resolved') statusMatch = rawStatus == 'completed' || rawStatus == 'resolved';

    bool categoryMatch = true;
    if (categoryFilter != 'All Categories') {
      categoryMatch = rawCategory == categoryFilter;
    }

    return statusMatch && categoryMatch;
  }

  @override
  Widget build(BuildContext context) {
    final currentUserEmail = FirebaseAuth.instance.currentUser?.email;

    Widget summaryBox(String label, int count, Color countColor) {
      return Expanded(
        child: Container(
          margin: const EdgeInsets.symmetric(horizontal: 6),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFE6E6E6)),
            boxShadow: const [
              BoxShadow(color: Color(0x0A000000), offset: Offset(0, 2), blurRadius: 6)
            ],
          ),
          child: Column(
            children: [
              Text(count.toString(),
                  style: TextStyle(
                      fontSize: 20, fontWeight: FontWeight.w600, color: countColor)),
              const SizedBox(height: 8),
              Text(label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 13, color: Colors.black54, height: 1.1)),
            ],
          ),
        ),
      );
    }

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('reports')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data?.docs ?? [];
        int unassigned = 0, myTasks = 0, pending = 0, resolved = 0;
        final List<Map<String, dynamic>> allIssues = [];

        for (var d in docs) {
          final data = Map<String, dynamic>.from(d.data() as Map);
          final statusRaw = (data['status'] ?? '').toString().toLowerCase();
          final assignedTo = (data['assignedTo'] ?? '').toString();

          if (assignedTo.isEmpty) unassigned++;
          if (currentUserEmail != null &&
              assignedTo.toLowerCase() == currentUserEmail.toLowerCase() &&
              !(statusRaw == 'completed' || statusRaw == 'resolved')) myTasks++;
          if (statusRaw == 'pending') pending++;
          if (statusRaw == 'completed' || statusRaw == 'resolved') resolved++;

          final issueMap = Map<String, dynamic>.from(data);
          issueMap['_id'] = d.id;
          allIssues.add(issueMap);
        }

        // Sort by upvotes (descending) then by createdAt (descending)
        allIssues.sort((a, b) {
          final aVotes = (a['upvotes'] as List<dynamic>? ?? []).length;
          final bVotes = (b['upvotes'] as List<dynamic>? ?? []).length;
          if (bVotes != aVotes) return bVotes.compareTo(aVotes);
          
          final aTime = (a['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          final bTime = (b['createdAt'] as Timestamp?)?.toDate() ?? DateTime(0);
          return bTime.compareTo(aTime);
        });

        final filteredIssues = allIssues.where((issue) => _matchesFilter(issue, _selectedFilter, _selectedCategory)).toList();

        return Container(
          color: Colors.white,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    summaryBox('Unassigned', unassigned, Colors.red),
                    summaryBox('My Tasks', myTasks, const Color(0xFF2E59FF)),
                    summaryBox('Pending', pending, Colors.orange),
                    summaryBox('Resolved', resolved, Colors.green),
                  ],
                ),
                const SizedBox(height: 12),
                
                // Filters Row
                Column(
                  children: [
                    // Status Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE6E6E6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.filter_list, color: Colors.black54),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedFilter,
                                isExpanded: true,
                                items: const [
                                  DropdownMenuItem(value: 'All Issues', child: Text('All Statuses')),
                                  DropdownMenuItem(value: 'Pending', child: Text('Pending')),
                                  DropdownMenuItem(value: 'In Progress', child: Text('In Progress')),
                                  DropdownMenuItem(value: 'Resolved', child: Text('Resolved')),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    _selectedFilter = v;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    // Category Filter
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: const Color(0xFFE6E6E6)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.category, color: Colors.black54),
                          const SizedBox(width: 10),
                          Expanded(
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                value: _selectedCategory,
                                isExpanded: true,
                                isDense: true,
                                items: const [
                                  DropdownMenuItem(value: 'All Categories', child: Text('All Categories')),
                                  DropdownMenuItem(value: 'Infrastructure & Roads', child: Text('Infrastructure & Roads')),
                                  DropdownMenuItem(value: 'Utilities (Water & Electricity)', child: Text('Utilities')),
                                  DropdownMenuItem(value: 'Sanitation & Environment', child: Text('Sanitation & Environment')),
                                  DropdownMenuItem(value: 'Traffic & Public Safety', child: Text('Traffic & Public Safety')),
                                  DropdownMenuItem(value: 'Parks & Recreation', child: Text('Parks & Recreation')),
                                ],
                                onChanged: (v) {
                                  if (v == null) return;
                                  setState(() {
                                    _selectedCategory = v;
                                  });
                                },
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  "Manage City Issues",
                  style: TextStyle(
                    color: Color(0xFF5A6F4A),
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 12),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: filteredIssues.isEmpty
                      ? [
                    const SizedBox(height: 12),
                    const Center(
                        child: Text("No reports found.",
                            style: TextStyle(color: Color(0xFF5A6F4A)))),
                  ]
                      : filteredIssues
                      .map((issue) => IssueCard(issue: issue, id: issue['_id'] as String))
                      .toList(),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
