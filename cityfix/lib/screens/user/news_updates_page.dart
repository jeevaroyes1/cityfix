import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'add_news_page.dart';

class NewsUpdatesPage extends StatelessWidget {
  const NewsUpdatesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("News Updates", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5A6F4A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (context) => const AddNewsPage()));
        },
        backgroundColor: const Color(0xFF5A6F4A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              "Official updates on maintenance, policies, and more.",
              style: TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('city_news')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator(color: Color(0xFF5A6F4A)));
                  }

                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.check_circle_outline, size: 40, color: Colors.grey[300]),
                          const SizedBox(height: 8),
                          const Text("No news alerts.", style: TextStyle(color: Colors.grey)),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      return _buildNewsCard(data);
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

  Widget _buildNewsCard(Map<String, dynamic> data) {
    final title = data['title'] ?? 'Important Update';
    final description = data['description'] ?? '';
    final importance = data['importance'] ?? 'Normal'; // High, Medium, Normal
    final dateTimestamp = data['createdAt'] as Timestamp?;
    final imageUrl = data['imageUrl'];
    
    final dateStr = dateTimestamp != null 
        ? DateFormat('MMM d, h:mm a').format(dateTimestamp.toDate()) 
        : 'Result Update';

    Color cardColor;
    Color iconColor;
    IconData icon;

    switch (importance) {
      case 'High':
        cardColor = Colors.red[50]!;
        iconColor = Colors.red;
        icon = Icons.warning_amber_rounded;
        break;
      case 'Medium':
        cardColor = Colors.orange[50]!;
        iconColor = Colors.orange[800]!;
        icon = Icons.info_outline;
        break;
      default:
        cardColor = Colors.blue[50]!;
        iconColor = Colors.blue[700]!;
        icon = Icons.article_outlined;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 5,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Image if available
          if (imageUrl != null && imageUrl.toString().isNotEmpty)
             ClipRRect(
               borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
               child: Image.network(
                 imageUrl,
                 height: 180,
                 width: double.infinity,
                 fit: BoxFit.cover,
                 errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
               ),
             ),
             
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Left color strip - smaller because now integrated in card content flow differently
                Container(
                  width: 4,
                  height: 40,
                  margin: const EdgeInsets.only(right: 12, top: 4),
                  decoration: BoxDecoration(
                    color: iconColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(icon, size: 18, color: iconColor),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black87),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        dateStr,
                        style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        description,
                        style: TextStyle(fontSize: 14, color: Colors.grey[700], height: 1.4),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
