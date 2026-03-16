import 'package:flutter/material.dart';
import 'user_home_screen.dart';
import 'user_alerts_screen.dart';
import 'user_analytics_screen.dart';
import 'user_leaderboard_screen.dart';
import 'user_profile_screen.dart';

class UserHomePage extends StatefulWidget {
  final int initialIndex;
  const UserHomePage({super.key, this.initialIndex = 0});

  @override
  State<UserHomePage> createState() => _UserHomePageState();
}

class _UserHomePageState extends State<UserHomePage> {
  late int _selectedIndex;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
  }

  final List<Widget> screens = const [
    UserHomeScreen(),
    UserAnalyticsScreen(),
    UserLeaderboardScreen(),
    UserProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed, // 🔴 REQUIRED for 5 items
        backgroundColor: const Color(0xFF5A6F4A), // ✅ Olive green
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        currentIndex: _selectedIndex,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.bar_chart), label: "Analytics"),
          BottomNavigationBarItem(icon: Icon(Icons.military_tech), label: "Leaderboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
