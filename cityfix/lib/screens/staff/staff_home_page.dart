import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../auth/login_page.dart';
import 'staff_home_screen.dart';
import 'staff_tasks_screen.dart';
import 'staff_alerts_screen.dart';
import 'staff_leaderboard_screen.dart';
import 'staff_profile.dart';

class StaffHomePage extends StatefulWidget {
  const StaffHomePage({super.key});

  @override
  State<StaffHomePage> createState() => _StaffHomePageState();
}

class _StaffHomePageState extends State<StaffHomePage> {
  int _selectedIndex = 0;

  @override
  Widget build(BuildContext context) {
    // ✅ Added: staff email + staff name
    final staffEmail = FirebaseAuth.instance.currentUser?.email ?? "";
    final staffName = FirebaseAuth.instance.currentUser?.displayName ?? "Staff";

    // ✅ StaffTasksScreen now requires TWO params
    final screens = [
      const StaffHomeScreen(),
      StaffTasksScreen(staffEmail: staffEmail, staffName: staffName),
      const StaffLeaderboardScreen(),
      const StaffProfileScreen(),
    ];

    final titles = [
      "Staff Dashboard",
      "$staffName's Tasks",
      "Staff Leaderboard",
      "My Profile",
    ];

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: const Color(0xFF5A6F4A),
        title: Text(titles[_selectedIndex], style: const TextStyle(color: Colors.white)),
        actions: [
          IconButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const StaffAlertsScreen()),
              );
            },
            icon: const Icon(Icons.notifications, color: Colors.white),
            tooltip: "Alerts",
          ),
        ],
      ),
      body: screens[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF5A6F4A),
        currentIndex: _selectedIndex,
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        onTap: (index) => setState(() => _selectedIndex = index),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(icon: Icon(Icons.task), label: "Tasks"),
          BottomNavigationBarItem(icon: Icon(Icons.military_tech), label: "Leaderboard"),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }
}
