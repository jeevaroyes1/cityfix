import 'package:flutter/material.dart';

class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Text(
        "No new alerts at the moment.",
        style: TextStyle(
          fontSize: 18,
          color: Color(0xFF5A6F4A),
        ),
      ),
    );
  }
}
