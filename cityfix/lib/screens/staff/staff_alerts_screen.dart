import 'package:flutter/material.dart';

class StaffAlertsScreen extends StatelessWidget {
  const StaffAlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: Colors.white,
      child: const Center(
        child: Text("No new alerts",
            style: TextStyle(color: Color(0xFF5A6F4A))),
      ),
    );
  }
}
