import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'user_alerts_screen.dart';

class UserLeaderboardScreen extends StatefulWidget {
  const UserLeaderboardScreen({super.key});

  @override
  State<UserLeaderboardScreen> createState() => _UserLeaderboardScreenState();
}

class _UserLeaderboardScreenState extends State<UserLeaderboardScreen> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A6F4A),
        title: const Text("Leaderboard", style: TextStyle(color: Colors.white)),
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
        stream: _firestore.collection('users').snapshots(),
        builder: (context, userSnapshot) {
          if (userSnapshot.connectionState == ConnectionState.waiting) {
             return const Center(child: CircularProgressIndicator());
          }
          
          final userDocs = userSnapshot.data?.docs ?? [];
          final Map<String, String> userNames = {};
          
          for (var doc in userDocs) {
            final data = doc.data() as Map<String, dynamic>;
            final name = data['fullName'] as String?; // Assuming 'fullName' is the field
            if (name != null && name.isNotEmpty) {
               userNames[doc.id] = name;
            }
          }

          return StreamBuilder<QuerySnapshot>(
            stream: _firestore.collection('reports').snapshots(),
            builder: (context, reportSnapshot) {
              if (reportSnapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              if (!reportSnapshot.hasData || reportSnapshot.data!.docs.isEmpty) {
                return const Center(
                  child: Text(
                    'No reports yet',
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                );
              }

              final reports = reportSnapshot.data!.docs;
              final userStats = <String, Map<String, dynamic>>{};

              for (var doc in reports) {
                final data = doc.data() as Map<String, dynamic>;
                final userId = data['userId'] as String?;
                final userEmail = data['userEmail'] as String?;

                if (userId != null) {
                  if (!userStats.containsKey(userId)) {
                    // Try to get name from our map, fallback to email name, then 'Citizen'
                    String displayName = userNames[userId] ?? 
                        (userEmail?.split('@')[0] ?? 'Citizen');
                        
                    userStats[userId] = {
                      'userId': userId,
                      'displayName': displayName,
                      'reportCount': 0,
                    };
                  }

                  userStats[userId]!['reportCount']++;
                }
              }

              final leaderboard = userStats.values.toList();
              // Always sort by reports now
              leaderboard.sort((a, b) => (b['reportCount'] as int).compareTo(a['reportCount'] as int));

              return ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: leaderboard.length,
                itemBuilder: (context, index) {
                  final user = leaderboard[index];
                  final rank = index + 1;
                  final isTopThree = rank <= 3;

                  return _buildLeaderboardCard(
                    rank: rank,
                    name: user['displayName'] as String,
                    reportCount: user['reportCount'] as int,
                    isTopThree: isTopThree,
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  Widget _buildLeaderboardCard({
    required int rank,
    required String name,
    required int reportCount,
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
        child: Row(
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
                    name,
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
                        icon: Icons.assignment_turned_in,
                        color: Colors.blueAccent,
                        label: '$reportCount Reports',
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
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
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
