import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'news_updates_page.dart';
import 'helpline_page.dart';

class UserHomePage extends StatelessWidget {
  const UserHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("CityFix - User Home"),
        backgroundColor: const Color(0xFF583224), // chocolate milk brown
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Welcome to CityFix 👋",
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Color(0xFF556B2F), // olive drab
              ),
            ),
            const SizedBox(height: 20),

            // Example quick actions
            Expanded(
              child: GridView.count(
                crossAxisCount: 2,
                crossAxisSpacing: 16,
                mainAxisSpacing: 16,
                children: [
                  _buildHomeCard(
                    icon: Icons.report_problem,
                    title: "Report Issue",
                    onTap: () {
                      // TODO: Navigate to Report Issue screen
                    },
                  ),
                  _buildHomeCard(
                    icon: Icons.history,
                    title: "My Reports",
                    onTap: () {
                      // TODO: Navigate to My Reports screen
                    },
                  ),
                  _buildHomeCard(
                    icon: Icons.notifications,
                    title: "Notifications",
                    onTap: () {
                      // TODO: Navigate to Notifications screen
                    },
                  ),
                  _buildHomeCard(
                    icon: Icons.settings,
                    title: "Settings",
                    onTap: () {
                      // TODO: Navigate to Settings screen
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHomeCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 5,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        color: const Color(0xFFF5F5F5),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 48, color: Color(0xFF583224)), // chocolate milk brown
              const SizedBox(height: 10),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
