import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

import 'add_staff_page.dart'; // <-- NEW IMPORT

class CreateStaffPage extends StatefulWidget {
  const CreateStaffPage({super.key});

  @override
  State<CreateStaffPage> createState() => _CreateStaffPageState();
}

class _CreateStaffPageState extends State<CreateStaffPage> {
  String selectedCategory = "All";
  final _firestore = FirebaseFirestore.instance;

  final TextEditingController _searchController = TextEditingController();

  final List<String> categories = [
    "All",
    "Infrastructure & Roads",
    "Utilities (Water & Electricity)",
    "Sanitation & Environment",
    "Traffic & Public Safety",
    "Parks & Recreation",
  ];

  void _openAddStaffModal() {
    showDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.4),
      builder: (context) {
        return AddStaffPage(); // <-- separate modal widget
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      floatingActionButton: SizedBox(
        height: 55,
        child: ElevatedButton.icon(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF5A6F4A),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
          ),
          onPressed: _openAddStaffModal,
          icon: const Icon(Icons.add, color: Colors.white),
          label: const Text(
            "Add Staff",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Search",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            _buildSearchBar(),
            const SizedBox(height: 24),
            const Text("Filter by Category",
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            _buildCategoryChips(),
            const SizedBox(height: 20),

            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: _firestore
                    .collection('users')
                    .where('role', isEqualTo: 'staff')
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No staff found"));
                  }

                  final staffDocs = snapshot.data!.docs.map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    final createdAt = data['createdAt'] != null
                        ? DateFormat('dd MMM yyyy, hh:mm a')
                        .format((data['createdAt'] as Timestamp).toDate())
                        : '';
                    return {
                      'name': data['name'] ?? '',
                      'email': data['email'] ?? '',
                      'department': data['department'] ?? '',
                      'createdAt': createdAt,
                    };
                  }).toList();

                  final query = _searchController.text.toLowerCase();
                  final searched = staffDocs.where((s) {
                    return s['name'].toLowerCase().contains(query) ||
                        s['email'].toLowerCase().contains(query);
                  }).toList();

                  final filtered = selectedCategory == "All"
                      ? searched
                      : searched
                      .where((s) => s['department'] == selectedCategory)
                      .toList();

                  if (filtered.isEmpty) {
                    return const Center(child: Text("No staff match found"));
                  }

                  return ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final staff = filtered[index];
                      return Card(
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 6),
                        child: ListTile(
                          title: Text(staff["name"]),
                          subtitle: Text(
                            "${staff["department"]} • ${staff["email"]}\nAdded: ${staff["createdAt"]}",
                            style: const TextStyle(
                                fontSize: 13, color: Colors.grey),
                          ),
                          trailing: const Icon(
                            Icons.chevron_right,
                            color: Color(0xFF5A6F4A),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade300),
      ),
      child: Row(
        children: [
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 12),
            child: Icon(Icons.search, color: Colors.grey),
          ),
          Expanded(
            child: TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                hintText: "Search staff by name or email…",
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryChips() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: categories.map((category) {
          final isSelected = category == selectedCategory;
          return Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: FilterChip(
              label: Text(category),
              selected: isSelected,
              selectedColor: const Color(0xFF5A6F4A),
              backgroundColor: Colors.grey.shade200,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.black87,
                fontWeight: FontWeight.w500,
              ),
              onSelected: (_) => setState(() => selectedCategory = category),
            ),
          );
        }).toList(),
      ),
    );
  }
}
