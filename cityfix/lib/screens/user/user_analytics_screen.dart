import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'issue_history_page.dart';
import 'user_alerts_screen.dart';

class UserAnalyticsScreen extends StatefulWidget {
  const UserAnalyticsScreen({super.key});

  @override
  State<UserAnalyticsScreen> createState() => _UserAnalyticsScreenState();
}

class _UserAnalyticsScreenState extends State<UserAnalyticsScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A6F4A),
        title: const Text("Analytics", style: TextStyle(color: Colors.white)),
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
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore
                  .collection('reports')
                  .where('userId', isEqualTo: user.uid)
                  .snapshots(),
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
                final data = reports.map((doc) => doc.data() as Map<String, dynamic>).toList();

                int totalReports = reports.length;
                int pendingReports = data.where((r) => r['status'] == 'Pending').length;
                int inProgressReports = data.where((r) => r['status'] == 'Assigned' || r['status'] == 'In Progress').length;
                int resolvedReports = data.where((r) => r['status'] == 'Completed' || r['status'] == 'Resolved').length;
                int totalUpvotes = 0;

                for (var report in data) {
                  final upvotes = report['upvotes'] as List<dynamic>? ?? [];
                  totalUpvotes += upvotes.length;
                }

                final resolutionRate = totalReports == 0 ? 0 : ((resolvedReports / totalReports) * 100).toInt();

                // Calculate issue types breakdown
                final Map<String, int> issueTypeCount = {};
                for (var report in data) {
                  final type = report['problemType'] ?? 'Unknown';
                  issueTypeCount[type] = (issueTypeCount[type] ?? 0) + 1;
                }

                // Calculate reports by month (last 6 months)
                final Map<String, int> monthlyReports = {};
                final now = DateTime.now();
                for (int i = 5; i >= 0; i--) {
                  final month = DateTime(now.year, now.month - i, 1);
                  final monthKey = DateFormat('MMM yyyy').format(month);
                  monthlyReports[monthKey] = 0;
                }
                
                for (var report in data) {
                  final createdAt = report['createdAt'] as Timestamp?;
                  if (createdAt != null) {
                    final date = createdAt.toDate();
                    final monthKey = DateFormat('MMM yyyy').format(date);
                    if (monthlyReports.containsKey(monthKey)) {
                      monthlyReports[monthKey] = (monthlyReports[monthKey] ?? 0) + 1;
                    }
                  }
                }

                // Calculate average resolution time
                double avgResolutionDays = 0;
                int resolvedWithDates = 0;
                for (var report in data) {
                  final status = report['status'] ?? '';
                  if ((status == 'Completed' || status == 'Resolved')) {
                    final createdAt = report['createdAt'] as Timestamp?;
                    final completedAt = report['completedAt'] as Timestamp?;
                    if (createdAt != null && completedAt != null) {
                      final days = completedAt.toDate().difference(createdAt.toDate()).inDays;
                      if (days >= 0) {
                        avgResolutionDays += days;
                        resolvedWithDates++;
                      }
                    }
                  }
                }
                if (resolvedWithDates > 0) {
                  avgResolutionDays = avgResolutionDays / resolvedWithDates;
                }

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Your Analytics',
                        style: TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A6F4A),
                        ),
                      ),
                      const SizedBox(height: 20),
                      GridView.count(
                        crossAxisCount: 2,
                        crossAxisSpacing: 14,
                        mainAxisSpacing: 14,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: 1.2,
                        children: [
                          _buildAnalyticsCard(
                            label: 'Total Reports',
                            value: totalReports.toString(),
                            icon: Icons.assignment,
                            color: Colors.blue,
                          ),
                          _buildAnalyticsCard(
                            label: 'Pending',
                            value: pendingReports.toString(),
                            icon: Icons.schedule,
                            color: Colors.orange,
                          ),
                          _buildAnalyticsCard(
                            label: 'In Progress',
                            value: inProgressReports.toString(),
                            icon: Icons.engineering,
                            color: Colors.lightBlue,
                          ),
                          _buildAnalyticsCard(
                            label: 'Resolved',
                            value: resolvedReports.toString(),
                            icon: Icons.check_circle,
                            color: Colors.green,
                          ),
                          _buildAnalyticsCard(
                            label: 'Total Upvotes',
                            value: totalUpvotes.toString(),
                            icon: Icons.thumb_up,
                            color: const Color(0xFF5A6F4A),
                          ),
                          _buildAnalyticsCard(
                            label: 'Resolution Rate',
                            value: '$resolutionRate%',
                            icon: Icons.trending_up,
                            color: Colors.purple,
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      // Status Distribution Pie Chart
                      const Text(
                        'Status Distribution',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A6F4A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusPieChart(
                        pending: pendingReports,
                        inProgress: inProgressReports,
                        resolved: resolvedReports,
                        total: totalReports,
                      ),
                      const SizedBox(height: 28),
                      // Issue Types Bar Chart
                      if (issueTypeCount.isNotEmpty) ...[
                        const Text(
                          'Issue Types Breakdown',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF5A6F4A),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _buildIssueTypesChart(issueTypeCount),
                        const SizedBox(height: 28),
                      ],
                      // Reports Over Time
                      const Text(
                        'Reports Over Time (Last 6 Months)',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A6F4A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildMonthlyReportsChart(monthlyReports),
                      const SizedBox(height: 28),
                      const Text(
                        'Status Breakdown',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A6F4A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildStatusBreakdown(
                        pending: pendingReports,
                        inProgress: inProgressReports,
                        resolved: resolvedReports,
                        total: totalReports,
                      ),
                      const SizedBox(height: 28),
                      const Text(
                        'Detailed Statistics',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFF5A6F4A),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildDetailedStats(
                        resolutionRate: resolutionRate,
                        avgUpvotes: totalReports == 0 ? '0' : (totalUpvotes / totalReports).toStringAsFixed(1),
                        avgResolutionDays: avgResolutionDays.toStringAsFixed(1),
                        mostCommonType: issueTypeCount.isEmpty 
                            ? 'N/A' 
                            : issueTypeCount.entries.reduce((a, b) => a.value > b.value ? a : b).key,
                      ),
                      const SizedBox(height: 28),
                      // Issue History Button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const IssueHistoryPage(),
                              ),
                            );
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF5A6F4A),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: const Icon(Icons.history),
                          label: const Text(
                            'View Issue History',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildAnalyticsCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBreakdown({
    required int pending,
    required int inProgress,
    required int resolved,
    required int total,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatusRow(
              label: 'Pending',
              count: pending,
              percentage: total == 0 ? 0 : ((pending / total) * 100).toInt(),
              color: Colors.orange,
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              label: 'In Progress',
              count: inProgress,
              percentage: total == 0 ? 0 : ((inProgress / total) * 100).toInt(),
              color: Colors.lightBlue,
            ),
            const SizedBox(height: 12),
            _buildStatusRow(
              label: 'Resolved',
              count: resolved,
              percentage: total == 0 ? 0 : ((resolved / total) * 100).toInt(),
              color: Colors.green,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusRow({
    required String label,
    required int count,
    required int percentage,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
            Text('$count ($percentage%)', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: LinearProgressIndicator(
            value: percentage / 100,
            minHeight: 8,
            backgroundColor: color.withOpacity(0.2),
            valueColor: AlwaysStoppedAnimation<Color>(color),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusPieChart({
    required int pending,
    required int inProgress,
    required int resolved,
    required int total,
  }) {
    if (total == 0) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(child: Text('No data available')),
        ),
      );
    }

    final pendingPercent = (pending / total) * 100;
    final inProgressPercent = (inProgress / total) * 100;
    final resolvedPercent = (resolved / total) * 100;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: PieChart(
            PieChartData(
              sectionsSpace: 2,
              centerSpaceRadius: 50,
              sections: [
                if (pending > 0)
                  PieChartSectionData(
                    color: Colors.orange,
                    value: pendingPercent,
                    title: 'Pending\n$pending',
                    radius: 70,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (inProgress > 0)
                  PieChartSectionData(
                    color: Colors.blue,
                    value: inProgressPercent,
                    title: 'In Progress\n$inProgress',
                    radius: 70,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                if (resolved > 0)
                  PieChartSectionData(
                    color: Colors.green,
                    value: resolvedPercent,
                    title: 'Resolved\n$resolved',
                    radius: 70,
                    titleStyle: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIssueTypesChart(Map<String, int> issueTypeCount) {
    final sortedTypes = issueTypeCount.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final topTypes = sortedTypes.take(5).toList();
    
    if (topTypes.isEmpty) {
      return const Card(
        child: Padding(
          padding: EdgeInsets.all(40.0),
          child: Center(child: Text('No issue types found')),
        ),
      );
    }

    final maxY = topTypes.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 250,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY + 1,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= topTypes.length) {
                        return const Text('');
                      }
                      final type = topTypes[value.toInt()].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          type.length > 10 ? '${type.substring(0, 10)}...' : type,
                          style: const TextStyle(fontSize: 10),
                          textAlign: TextAlign.center,
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: List.generate(topTypes.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: topTypes[i].value.toDouble(),
                      color: const Color(0xFF5A6F4A),
                      width: 20,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMonthlyReportsChart(Map<String, int> monthlyReports) {
    final entries = monthlyReports.entries.toList();
    final maxY = entries.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble();

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: SizedBox(
          height: 200,
          child: BarChart(
            BarChartData(
              alignment: BarChartAlignment.spaceAround,
              maxY: maxY + 1,
              barTouchData: BarTouchData(enabled: false),
              titlesData: FlTitlesData(
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 30,
                    getTitlesWidget: (value, meta) {
                      return Text(
                        value.toInt().toString(),
                        style: const TextStyle(fontSize: 10),
                      );
                    },
                  ),
                ),
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (double value, TitleMeta meta) {
                      if (value.toInt() >= entries.length) {
                        return const Text('');
                      }
                      final month = entries[value.toInt()].key;
                      return Padding(
                        padding: const EdgeInsets.only(top: 8.0),
                        child: Text(
                          month.split(' ')[0], // Just show month abbreviation
                          style: const TextStyle(fontSize: 10),
                        ),
                      );
                    },
                  ),
                ),
                topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
                rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false),
                ),
              ),
              borderData: FlBorderData(show: false),
              gridData: const FlGridData(show: false),
              barGroups: List.generate(entries.length, (i) {
                return BarChartGroupData(
                  x: i,
                  barRods: [
                    BarChartRodData(
                      toY: entries[i].value.toDouble(),
                      color: Colors.blue,
                      width: 15,
                      borderRadius: BorderRadius.circular(4),
                    )
                  ],
                );
              }),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDetailedStats({
    required int resolutionRate,
    required String avgUpvotes,
    required String avgResolutionDays,
    required String mostCommonType,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            _buildStatRow(
              label: 'Resolution Rate',
              value: '$resolutionRate%',
              icon: Icons.trending_up,
            ),
            const Divider(),
            _buildStatRow(
              label: 'Avg Upvotes per Report',
              value: avgUpvotes,
              icon: Icons.thumb_up,
            ),
            const Divider(),
            _buildStatRow(
              label: 'Avg Resolution Time',
              value: '$avgResolutionDays days',
              icon: Icons.access_time,
            ),
            const Divider(),
            _buildStatRow(
              label: 'Most Common Issue Type',
              value: mostCommonType,
              icon: Icons.category,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatRow({
    required String label,
    required String value,
    required IconData icon,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Icon(icon, size: 20, color: const Color(0xFF5A6F4A)),
              const SizedBox(width: 8),
              Text(
                label,
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Color(0xFF5A6F4A),
            ),
          ),
        ],
      ),
    );
  }
}
