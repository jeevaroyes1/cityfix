import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'admin_home_page.dart';
import 'create_staff_page.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  int _selectedIndex = 1; // Analytics index

  Widget _buildHomeScreen() => const AdminHomePage();
  Widget _buildStaffScreen() => const CreateStaffPage();
  Widget _buildAlertsScreen() => const Center(
    child: Text(
      "No new alerts at the moment.",
      style: TextStyle(fontSize: 18, color: Color(0xFF5A6F4A)),
    ),
  );

  // 🟫 Build Analytics body with Firestore data
  Widget _buildAnalyticsBody() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('reports').snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text(
              'No reports data available',
              style: TextStyle(fontSize: 16, color: Colors.grey),
            ),
          );
        }

        final reports = snapshot.data!.docs.map((doc) => doc.data() as Map<String, dynamic>).toList();

        // 🟤 Count issue types (problemType)
        final Map<String, int> issueTypeCount = {};
        for (var report in reports) {
          final type = report['problemType'] ?? 'Unknown';
          issueTypeCount[type] = (issueTypeCount[type] ?? 0) + 1;
        }

        // 🟤 Count status distribution
        int pending = 0, assigned = 0, completed = 0;
        for (var report in reports) {
          switch (report['status']) {
            case 'Pending':
              pending++;
              break;
            case 'Assigned':
              assigned++;
              break;
            case 'Completed':
              completed++;
              break;
          }
        }

        // 🟤 Prepare bar chart data
        final barData = issueTypeCount.entries.toList();
        final maxY = (barData.isNotEmpty)
            ? barData.map((e) => e.value).reduce((a, b) => a > b ? a : b).toDouble()
            : 1;

        // 🟤 Prepare pie chart data
        final total = pending + assigned + completed;
        final pendingPercent = total == 0 ? 0.0 : pending / total * 100;
        final assignedPercent = total == 0 ? 0.0 : assigned / total * 100;
        final completedPercent = total == 0 ? 0.0 : completed / total * 100;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Chart 1 – Top Issue Types
              const Text(
                "Top Issue Types",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A6F4A),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 300,
                child: barData.isEmpty
                    ? const Center(
                  child: Text(
                    'No issue types found',
                    style: TextStyle(color: Colors.grey),
                  ),
                )
                    : BarChart(
                  BarChartData(
                    alignment: BarChartAlignment.spaceAround,
                    maxY: maxY + 1,
                    barTouchData: BarTouchData(enabled: false),
                    titlesData: FlTitlesData(
                      leftTitles: AxisTitles(
                        sideTitles: SideTitles(showTitles: true),
                      ),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 60,
                          getTitlesWidget: (double value, TitleMeta meta) {
                            if (value.toInt() >= barData.length) {
                              return const SizedBox.shrink();
                            }
                            return SideTitleWidget(
                              meta: meta,
                              angle: -0.5,
                              child: SizedBox(
                                width: 70,
                                child: Text(
                                  barData[value.toInt()].key,
                                  style: const TextStyle(fontSize: 10),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      rightTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                      topTitles: const AxisTitles(
                        sideTitles: SideTitles(showTitles: false),
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    gridData: const FlGridData(show: false),
                    barGroups: List.generate(barData.length, (i) {
                      return BarChartGroupData(
                        x: i,
                        barRods: [
                          BarChartRodData(
                            toY: barData[i].value.toDouble(),
                            color: const Color(0xFF5A6F4A),
                            width: 18,
                            borderRadius: BorderRadius.circular(4),
                          )
                        ],
                      );
                    }),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Chart 2 – Status Distribution
              const Text(
                "Status Distribution",
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF5A6F4A),
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                height: 250,
                child: PieChart(
                  PieChartData(
                    sectionsSpace: 2,
                    centerSpaceRadius: 40,
                    sections: [
                      PieChartSectionData(
                        color: Colors.amber,
                        value: pendingPercent,
                        title: 'Pending\n${pending.toString()}',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.black,
                        ),
                      ),
                      PieChartSectionData(
                        color: Colors.blueAccent,
                        value: assignedPercent,
                        title: 'Assigned\n${assigned.toString()}',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                      PieChartSectionData(
                        color: Colors.green,
                        value: completedPercent,
                        title: 'Completed\n${completed.toString()}',
                        radius: 60,
                        titleStyle: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  List<Widget> get _screens => [
    _buildHomeScreen(),
    _buildAnalyticsBody(),
    _buildStaffScreen(),
    _buildAlertsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: _screens[_selectedIndex],
    );
  }
}
