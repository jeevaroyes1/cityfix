import 'package:flutter/material.dart';

class PoliciesPage extends StatelessWidget {
  const PoliciesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text("Policies", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5A6F4A),
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildPolicyItem(context, "Terms & Conditions", kTermsAndConditions),
          const SizedBox(height: 12),
          _buildPolicyItem(context, "Community Policy", kCommunityPolicy),
        ],
      ),
    );
  }

  Widget _buildPolicyItem(BuildContext context, String title, String content) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey),
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => PolicyDetailPage(title: title, content: content),
            ),
          );
        },
      ),
    );
  }
}

class PolicyDetailPage extends StatelessWidget {
  final String title;
  final String content;

  const PolicyDetailPage({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(title, style: const TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF5A6F4A),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Text(
          content,
          style: const TextStyle(fontSize: 16, height: 1.6, color: Colors.black87),
        ),
      ),
    );
  }
}

const String kTermsAndConditions = """
**Terms and Conditions**

1. **User Responsibility**: Users are responsible for the accuracy of the information they report. False reporting may lead to account suspension.
2. **Privacy**: Your personal data will be handled in accordance with our Privacy Policy.
3. **Content**: Offensive or inappropriate content in reports will be removed.
4. **Usage**: This application is for reporting city infrastructure issues only.
5. **Liability**: The city administration is not liable for damages resulting from the use of this app.

(This is a sample text for demonstration purposes.)
""";

const String kCommunityPolicy = """
**Community Policy**

1. **Respect**: Treat all community members and staff with respect.
2. **Honesty**: Report issues truthfully and provide accurate locations and descriptions.
3. **Safety**: Do not endanger yourself or others while reporting issues.
4. **Collaboration**: Work together to keep our city clean and safe.

(This is a sample text for demonstration purposes.)
""";
