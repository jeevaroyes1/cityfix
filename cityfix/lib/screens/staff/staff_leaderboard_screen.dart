import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class StaffLeaderboardScreen extends StatefulWidget {
  const StaffLeaderboardScreen({super.key});

  @override
  State<StaffLeaderboardScreen> createState() => _StaffLeaderboardScreenState();
}

class _StaffLeaderboardScreenState extends State<StaffLeaderboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _sortBy = 'completed';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                const Text(
                  'Sort by:',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: SegmentedButton<String>(
                    segments: const [
                      ButtonSegment(
                        value: 'completed',
                        label: Text('Completed'),
                      ),
                      ButtonSegment(
                        value: 'rating',
                        label: Text('Rating'),
                      ),
                    ],
                    selected: {_sortBy},
                    onSelectionChanged: (Set<String> newSelection) {
                      setState(() {
                        _sortBy = newSelection.first;
                      });
                    },
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('reports').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(
                    child: Text(
                      'No reports yet',
                      style: TextStyle(fontSize: 16, color: Colors.grey),
                    ),
                  );
                }

                final reports = snapshot.data!.docs;
                final staffStats = <String, Map<String, dynamic>>{};

                for (var doc in reports) {
                  final data = doc.data() as Map<String, dynamic>;
                  final assignedTo = data['assignedTo'] as String?;

                  if (assignedTo != null && assignedTo.isNotEmpty) {
                    if (!staffStats.containsKey(assignedTo)) {
                      staffStats[assignedTo] = {
                        'staffEmail': assignedTo,
                        'assignedCount': 0,
                        'completedCount': 0,
                        'totalRating': 0.0,
                        'ratingCount': 0,
                      };
                    }

                    staffStats[assignedTo]!['assignedCount']++;

                    if (data['status'] == 'Completed' || data['status'] == 'Resolved') {
                      staffStats[assignedTo]!['completedCount']++;
                    }

                    final rating = (data['staffRating'] as num?) ?? 0;
                    if (rating > 0) {
                      staffStats[assignedTo]!['totalRating'] += rating;
                      staffStats[assignedTo]!['ratingCount']++;
                    }
                  }
                }

                final leaderboard = staffStats.values.toList();
                leaderboard.sort((a, b) {
                  if (_sortBy == 'completed') {
                    return (b['completedCount'] as int).compareTo(a['completedCount'] as int);
                  } else {
                    final ratingA = (a['ratingCount'] as int) == 0
                        ? 0.0
                        : (a['totalRating'] as double) / (a['ratingCount'] as int);
                    final ratingB = (b['ratingCount'] as int) == 0
                        ? 0.0
                        : (b['totalRating'] as double) / (b['ratingCount'] as int);
                    return ratingB.compareTo(ratingA);
                  }
                });

                return ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: leaderboard.length,
                  itemBuilder: (context, index) {
                    final staff = leaderboard[index];
                    final rank = index + 1;
                    final isTopThree = rank <= 3;
                    final avgRating = (staff['ratingCount'] as int) == 0
                        ? 0.0
                        : (staff['totalRating'] as double) / (staff['ratingCount'] as int);

                    return _buildStaffCard(
                      rank: rank,
                      email: staff['staffEmail'] as String,
                      completedCount: staff['completedCount'] as int,
                      assignedCount: staff['assignedCount'] as int,
                      avgRating: avgRating,
                      isTopThree: isTopThree,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStaffCard({
    required int rank,
    required String email,
    required int completedCount,
    required int assignedCount,
    required double avgRating,
    required bool isTopThree,
  }) {
    Color? rankColor;
    Color? accentColor;
    Widget rankWidget;

    if (rank == 1) {
      rankColor = const Color(0xFFFFD700); // Gold
      accentColor = const Color(0xFFFFF7CC);
      rankWidget = const Icon(Icons.emoji_events, color: Colors.white, size: 28);
    } else if (rank == 2) {
      rankColor = const Color(0xFFC0C0C0); // Silver
      accentColor = const Color(0xFFEEEEEE);
      rankWidget = const Icon(Icons.emoji_events, color: Colors.white, size: 28);
    } else if (rank == 3) {
      rankColor = const Color(0xFFCD7F32); // Bronze
      accentColor = const Color(0xFFF5E6DA);
      rankWidget = const Icon(Icons.emoji_events, color: Colors.white, size: 28);
    } else {
      rankColor = Colors.grey.shade700;
      accentColor = Colors.white;
      rankWidget = Text(
        '#$rank',
        style: const TextStyle(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      );
    }

    final completionRate = assignedCount == 0
        ? 0
        : ((completedCount / assignedCount) * 100).toInt();

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      elevation: isTopThree ? 4 : 1,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: isTopThree
            ? BorderSide(color: rankColor!.withOpacity(0.5), width: 1.5)
            : BorderSide.none,
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: isTopThree
              ? LinearGradient(
                  colors: [accentColor!.withOpacity(0.3), Colors.white],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: rankColor,
                    boxShadow: [
                      BoxShadow(
                        color: rankColor!.withOpacity(0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  alignment: Alignment.center,
                  child: rankWidget,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        email.split('@')[0],
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildStatBadge(
                            icon: Icons.check_circle_outline,
                            color: Colors.green,
                            label: '$completedCount/$assignedCount Done',
                          ),
                          const SizedBox(width: 10),
                          _buildStatBadge(
                            icon: Icons.star_rounded,
                            color: Colors.amber,
                            label: '${avgRating.toStringAsFixed(1)} Rating',
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Completion Rate',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    Text(
                      '$completionRate%',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.black54,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: completionRate / 100,
                    minHeight: 8,
                    backgroundColor: Colors.grey.shade200,
                    valueColor:
                        const AlwaysStoppedAnimation<Color>(Color(0xFF5A6F4A)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge({
    required IconData icon,
    required Color color,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
