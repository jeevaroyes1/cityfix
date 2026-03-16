import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'create_event_page.dart';

class VolunteeringPage extends StatelessWidget {
  const VolunteeringPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Volunteering Opportunities", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5A6F4A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(
            child: FutureBuilder<DocumentSnapshot>(
              future: FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser?.uid).get(),
              builder: (context, userSnapshot) {
                if (userSnapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: Color(0xFF5A6F4A)));
                }
                
                if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
                   return const Center(child: Text("User data not found"));
                }

                final userPanchayat = (userSnapshot.data!.data() as Map<String, dynamic>)['panchayat'];

                return StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('volunteering_events')
                      .where('panchayat', isEqualTo: userPanchayat)
                      .orderBy('createdAt', descending: true)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator(color: Color(0xFF5A6F4A)));
                    }

                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return _buildEmptyState();
                    }

                    return ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: snapshot.data!.docs.length,
                      itemBuilder: (context, index) {
                        final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                        return _buildEventCard(data);
                      },
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateEventPage()),
          );
        },
        backgroundColor: const Color(0xFF5A6F4A),
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text("Organize Event", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      color: Colors.grey[50],
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Give Back to Community",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF5A6F4A)),
          ),
          const SizedBox(height: 8),
          Text(
            "Find events to participate in or organize your own drive to make a difference.",
            style: TextStyle(fontSize: 14, color: Colors.grey[600], height: 1.5),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.volunteer_activism_outlined, size: 80, color: Colors.grey[300]),
          const SizedBox(height: 16),
          Text("No upcoming events", style: TextStyle(fontSize: 18, color: Colors.grey[600], fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text("Be the first to organize a drive!", style: TextStyle(color: Colors.grey[500])),
        ],
      ),
    );
  }

  Widget _buildEventCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Untitled Event';
    final category = data['category'] ?? 'General';
    final description = data['description'] ?? '';
    final location = data['location'] ?? 'Unknown Location';
    final contact = data['contactInfo'] ?? 'No contact info';
    final dateTimestamp = data['eventDate'] as Timestamp?;
    
    String dateStr = 'Date TBD';
    String timeStr = '';
    
    if (dateTimestamp != null) {
      final dateTime = dateTimestamp.toDate();
      dateStr = DateFormat('MMM d, yyyy').format(dateTime);
      timeStr = DateFormat('h:mm a').format(dateTime);
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 3,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF5A6F4A).withOpacity(0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    category.toUpperCase(),
                    style: const TextStyle(color: Color(0xFF5A6F4A), fontWeight: FontWeight.bold, fontSize: 11),
                  ),
                ),
                Text(dateStr, style: TextStyle(color: Colors.grey[600], fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.black87),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey[500]),
                const SizedBox(width: 4),
                Text(location, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                const SizedBox(width: 16),
                 if (timeStr.isNotEmpty) ...[
                  Icon(Icons.access_time, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Text(timeStr, style: TextStyle(color: Colors.grey[700], fontSize: 14)),
                ],
              ],
            ),
            const SizedBox(height: 12),
            Text(
              description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: Colors.grey[600], height: 1.4),
            ),
             const SizedBox(height: 16),
            const Divider(),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.person_outline, size: 18, color: Colors.grey),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Contact: $contact",
                    style: TextStyle(color: Colors.grey[700], fontSize: 14),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
