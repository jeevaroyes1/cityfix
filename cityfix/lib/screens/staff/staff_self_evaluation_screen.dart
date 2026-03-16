import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

class StaffSelfEvaluationScreen extends StatefulWidget {
  const StaffSelfEvaluationScreen({super.key});

  @override
  State<StaffSelfEvaluationScreen> createState() => _StaffSelfEvaluationScreenState();
}

class _StaffSelfEvaluationScreenState extends State<StaffSelfEvaluationScreen> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  String _timeRange = 'Week'; // 'Week' or 'Month'

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: user == null
          ? const Center(child: Text('Not logged in'))
          : StreamBuilder<QuerySnapshot>(
              stream: _firestore.collection('reports').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text('No data available'));
                }

                final allReports = snapshot.data!.docs;
                final myReports = allReports.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['assignedTo'] == user.email && 
                         (data['status'] == 'Completed' || data['status'] == 'Resolved');
                }).toList();

                return SingleChildScrollView(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSummaryCards(myReports),
                      const SizedBox(height: 24),
                      _buildChartSection(myReports),
                      const SizedBox(height: 24),
                      _buildComparisonSection(allReports, user.email ?? ''),
                    ],
                  ),
                );
              },
            ),
    );
  }

  Widget _buildSummaryCards(List<QueryDocumentSnapshot> myReports) {
    final now = DateTime.now();
    final oneWeekAgo = now.subtract(const Duration(days: 7));
    final oneMonthAgo = DateTime(now.year, now.month - 1, now.day);

    int countPastWeek = 0;
    int countPastMonth = 0;
    int countPrevWeek = 0;

    final twoWeeksAgo = now.subtract(const Duration(days: 14));

    for (var doc in myReports) {
      final data = doc.data() as Map<String, dynamic>;
      final completedAt = (data['completedAt'] as Timestamp?)?.toDate() ?? 
                         (data['createdAt'] as Timestamp?)?.toDate() ?? 
                         DateTime.now();

      if (completedAt.isAfter(oneWeekAgo)) {
        countPastWeek++;
      }
      if (completedAt.isAfter(oneMonthAgo)) {
        countPastMonth++;
      }
      if (completedAt.isAfter(twoWeeksAgo) && completedAt.isBefore(oneWeekAgo)) {
        countPrevWeek++;
      }
    }

    double growthRate = 0;
    if (countPrevWeek > 0) {
      growthRate = ((countPastWeek - countPrevWeek) / countPrevWeek) * 100;
    } else if (countPastWeek > 0) {
      growthRate = 100;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Performance Overview",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF5A6F4A)),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _buildStatCard("Past Week", countPastWeek.toString(), Icons.calendar_view_week, Colors.blue),
            const SizedBox(width: 12),
            _buildStatCard("Past Month", countPastMonth.toString(), Icons.calendar_month, Colors.orange),
          ],
        ),
        const SizedBox(height: 12),
        _buildGrowthCard(growthRate),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            Text(value, style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            Text(title, style: TextStyle(fontSize: 12, color: Colors.grey[600])),
          ],
        ),
      ),
    );
  }

  Widget _buildGrowthCard(double growthRate) {
    final isPositive = growthRate >= 0;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isPositive ? Colors.green : Colors.red).withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isPositive ? Icons.trending_up : Icons.trending_down,
              color: isPositive ? Colors.green : Colors.red,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Work Completion Rate",
                  style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                ),
                Text(
                  "${isPositive ? '+' : ''}${growthRate.toStringAsFixed(1)}% compared to last week",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isPositive ? Colors.green : Colors.red,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChartSection(List<QueryDocumentSnapshot> myReports) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "Activity Chart",
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Week', label: Text('Week')),
                  ButtonSegment(value: 'Month', label: Text('Month')),
                ],
                selected: {_timeRange},
                onSelectionChanged: (value) => setState(() => _timeRange = value.first),
                style: SegmentedButton.styleFrom(
                  visualDensity: VisualDensity.compact,
                  selectedBackgroundColor: const Color(0xFF5A6F4A),
                  selectedForegroundColor: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 200,
            child: BarChart(
              _getMainChartData(myReports),
            ),
          ),
        ],
      ),
    );
  }

  BarChartData _getMainChartData(List<QueryDocumentSnapshot> myReports) {
    final now = DateTime.now();
    final days = _timeRange == 'Week' ? 7 : 30;
    final Map<String, int> dataMap = {};

    for (int i = 0; i < days; i++) {
      final date = now.subtract(Duration(days: i));
      final dateStr = DateFormat('yyyy-MM-dd').format(date);
      dataMap[dateStr] = 0;
    }

    for (var doc in myReports) {
      final data = doc.data() as Map<String, dynamic>;
      final completedAt = (data['completedAt'] as Timestamp?)?.toDate() ?? 
                         (data['createdAt'] as Timestamp?)?.toDate() ?? 
                         DateTime.now();
      final dateStr = DateFormat('yyyy-MM-dd').format(completedAt);
      if (dataMap.containsKey(dateStr)) {
        dataMap[dateStr] = dataMap[dateStr]! + 1;
      }
    }

    final sortedKeys = dataMap.keys.toList()..sort();
    final List<BarChartGroupData> barGroups = [];

    for (int i = 0; i < sortedKeys.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: dataMap[sortedKeys[i]]!.toDouble(),
              color: const Color(0xFF5A6F4A),
              width: _timeRange == 'Week' ? 16 : 4,
              borderRadius: BorderRadius.circular(4),
            ),
          ],
        ),
      );
    }

    return BarChartData(
      gridData: const FlGridData(show: false),
      titlesData: FlTitlesData(
        leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            getTitlesWidget: (value, meta) {
              if (_timeRange == 'Month' && value.toInt() % 5 != 0) return const SizedBox();
              final index = value.toInt();
              if (index < 0 || index >= sortedKeys.length) return const SizedBox();
              final date = DateFormat('yyyy-MM-dd').parse(sortedKeys[index]);
              return Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: Text(
                  _timeRange == 'Week' ? DateFormat('E').format(date) : DateFormat('d').format(date),
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
              );
            },
          ),
        ),
      ),
      borderData: FlBorderData(show: false),
      barGroups: barGroups,
    );
  }

  Widget _buildComparisonSection(List<QueryDocumentSnapshot> allReports, String myEmail) {
    final staffStats = <String, int>{};

    for (var doc in allReports) {
      final data = doc.data() as Map<String, dynamic>;
      final assignedTo = data['assignedTo'] as String?;
      if (assignedTo != null && (data['status'] == 'Completed' || data['status'] == 'Resolved')) {
        staffStats[assignedTo] = (staffStats[assignedTo] ?? 0) + 1;
      }
    }

    final sortedStaff = staffStats.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // Get top 5 or some reasonable number for comparison
    final displayStats = sortedStaff.take(5).toList();
    if (!displayStats.any((e) => e.key == myEmail) && staffStats.containsKey(myEmail)) {
      displayStats.add(MapEntry(myEmail, staffStats[myEmail]!));
    }
    displayStats.sort((a, b) => b.value.compareTo(a.value));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Comparison with Others",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          ...displayStats.map((entry) {
            final isMe = entry.key == myEmail;
            final maxVal = displayStats.first.value;
            final percentage = maxVal > 0 ? entry.value / maxVal : 0.0;

            return Padding(
              padding: const EdgeInsets.only(bottom: 12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        isMe ? "You" : entry.key.split('@')[0],
                        style: TextStyle(
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          color: isMe ? const Color(0xFF5A6F4A) : Colors.black87,
                        ),
                      ),
                      Text(
                        "${entry.value} reports",
                        style: TextStyle(
                          fontWeight: isMe ? FontWeight.bold : FontWeight.normal,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: percentage,
                      backgroundColor: Colors.grey[200],
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isMe ? const Color(0xFF5A6F4A) : Colors.grey[400]!,
                      ),
                      minHeight: 8,
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
