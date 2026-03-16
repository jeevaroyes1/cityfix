import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'create_note_page.dart';

class CommunityHubPage extends StatefulWidget {
  const CommunityHubPage({super.key});

  @override
  State<CommunityHubPage> createState() => _CommunityHubPageState();
}

class _CommunityHubPageState extends State<CommunityHubPage> {
  final User? _currentUser = FirebaseAuth.instance.currentUser;
  late Future<DocumentSnapshot> _userFuture;

  @override
  void initState() {
    super.initState();
    _userFuture = FirebaseFirestore.instance
        .collection('users')
        .doc(FirebaseAuth.instance.currentUser?.uid)
        .get();
  }
  


  void _navigateToCreateNote() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const CreateNotePage()),
    );
  }

  Future<void> _toggleLike(String docId, List<dynamic> likes) async {
    if (_currentUser == null) return;
    
    final uid = _currentUser!.uid;
    final isLiked = likes.contains(uid);

    if (isLiked) {
      await FirebaseFirestore.instance.collection('community_notes').doc(docId).update({
        'likes': FieldValue.arrayRemove([uid]),
      });
    } else {
      await FirebaseFirestore.instance.collection('community_notes').doc(docId).update({
        'likes': FieldValue.arrayUnion([uid]),
      });
    }
  }

  Future<void> _deletePost(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Delete Post"),
        content: const Text("Are you sure you want to delete this post?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await FirebaseFirestore.instance.collection('community_notes').doc(docId).delete();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Post deleted")),
        );
      }
    }
  }
  
  void _showCommentsSheet(BuildContext context, String docId) {
     showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => _CommentsSheet(docId: docId),
    ); 
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Community Hub", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5A6F4A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _navigateToCreateNote,
        backgroundColor: const Color(0xFF5A6F4A),
        child: const Icon(Icons.add, color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [


            // 🗣️ Community Voice Section (Notes)
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.forum_outlined, color: Color(0xFF5A6F4A), size: 28),
                      const SizedBox(width: 8),
                      const Text(
                        "Posts",
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5A6F4A)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    "Share your thoughts, photos, and updates with neighbors.",
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                  const SizedBox(height: 20),

                  FutureBuilder<DocumentSnapshot>(
                    future: _userFuture,
                    builder: (context, userSnapshot) {
                      if (userSnapshot.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator(color: Color(0xFF5A6F4A)));
                      }

                      if (userSnapshot.hasError) {
                         return Center(child: Text("Error loading user: ${userSnapshot.error}"));
                      }
                      
                      if (!userSnapshot.hasData || userSnapshot.data?.data() == null) {
                         return const Center(child: Text("User data not found"));
                      }

                      final userPanchayat = (userSnapshot.data!.data() as Map<String, dynamic>)['panchayat'];

                      return StreamBuilder<QuerySnapshot>(
                        stream: FirebaseFirestore.instance
                            .collection('community_notes')
                            .where('panchayat', isEqualTo: userPanchayat)
                            .orderBy('createdAt', descending: true)
                            .snapshots(),
                        builder: (context, snapshot) {
                          if (snapshot.hasError) {
                            return Center(
                              child: Padding(
                                padding: const EdgeInsets.all(16.0),
                                child: SelectableText(
                                  "Error: ${snapshot.error}",
                                  style: const TextStyle(color: Colors.red),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            );
                          }

                          if (snapshot.connectionState == ConnectionState.waiting) {
                            return const Center(child: CircularProgressIndicator(color: Color(0xFF5A6F4A)));
                          }

                          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                            return Center(
                              child: Column(
                                children: [
                                  const SizedBox(height: 40),
                                  Icon(Icons.chat_bubble_outline, size: 60, color: Colors.grey[300]),
                                  const SizedBox(height: 12),
                                  const Text("No notes yet. Be the first to post!", style: TextStyle(color: Colors.grey)),
                                ],
                              ),
                            );
                          }

                          return ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: snapshot.data!.docs.length,
                            separatorBuilder: (context, index) => const SizedBox(height: 16),
                            itemBuilder: (context, index) {
                              final doc = snapshot.data!.docs[index];
                              final data = doc.data() as Map<String, dynamic>;
                              return _buildNoteCard(doc.id, data);
                            },
                          );
                        },
                      );
                    },
                  ),
                  const SizedBox(height: 80), // Space for FAB
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }



  Widget _buildNoteCard(String docId, Map<String, dynamic> data) {
    final content = data['content'] ?? '';
    final imageUrl = data['imageUrl'] as String?;
    final authorEmail = data['authorEmail'] as String? ?? 'Anonymous';
    final timestamp = data['createdAt'] as Timestamp?;
    final likes = List<String>.from(data['likes'] ?? []);
    final isLiked = _currentUser != null && likes.contains(_currentUser!.uid);

    final timeStr = timestamp != null 
        ? DateFormat('MMM d, h:mm a').format(timestamp.toDate()) 
        : 'Just now';

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.withOpacity(0.2)),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: const Color(0xFF5A6F4A).withOpacity(0.1),
                  radius: 18,
                  child: Text(
                    authorEmail.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Color(0xFF5A6F4A), fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        authorEmail.split('@')[0],
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        timeStr,
                        style: TextStyle(color: Colors.grey[500], fontSize: 12),
                      ),
                    ],
                  ),
                ),
                if (_currentUser?.uid == data['authorId'])
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'edit') {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => CreateNotePage(
                              noteId: docId,
                              initialData: data,
                            ),
                          ),
                        );
                      } else if (value == 'delete') {
                        _deletePost(docId);
                      }
                    },
                    itemBuilder: (context) => [
                      const PopupMenuItem(
                        value: 'edit',
                        child: Text("Edit"),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text("Delete", style: TextStyle(color: Colors.red)),
                      ),
                    ],
                    child: const Icon(Icons.more_vert, color: Colors.grey),
                  ),
              ],
            ),
          ),
          
          // Content
          if (content.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              child: Text(
                content,
                style: const TextStyle(fontSize: 15, height: 1.4, color: Colors.black87),
              ),
            ),
          
          if (imageUrl != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Image.network(
                imageUrl,
                width: double.infinity,
                height: 200,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) => Container(
                  height: 200,
                  color: Colors.grey[200],
                  child: const Center(child: Icon(Icons.broken_image, color: Colors.grey)),
                ),
              ),
            ),
            
          const Divider(height: 24),

          // Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
            child: Row(
              children: [
                _buildInteractionButton(
                  icon: isLiked ? Icons.favorite : Icons.favorite_border,
                  label: likes.length.toString(),
                  color: isLiked ? Colors.red : Colors.grey[600]!,
                  onTap: () => _toggleLike(docId, likes),
                ),
                const SizedBox(width: 20),
                _buildInteractionButton(
                  icon: Icons.chat_bubble_outline,
                  label: "Comment",
                  color: Colors.grey[600]!,
                  onTap: () => _showCommentsSheet(context, docId),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInteractionButton({
    required IconData icon, 
    required String label, 
    required Color color, 
    required VoidCallback onTap
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

class _CommentsSheet extends StatefulWidget {
  final String docId;
  const _CommentsSheet({required this.docId});

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentController = TextEditingController();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  Future<void> _postComment() async {
    final text = _commentController.text.trim();
    if (text.isEmpty || _currentUser == null) return;

    _commentController.clear();
    FocusScope.of(context).unfocus();

    await FirebaseFirestore.instance
        .collection('community_notes')
        .doc(widget.docId)
        .collection('comments')
        .add({
      'text': text,
      'authorName': _currentUser!.email?.split('@')[0] ?? 'User',
      'createdAt': FieldValue.serverTimestamp(),
    });
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        height: 500,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(color: Colors.grey[300], borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Text("Comments", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('community_notes')
                    .doc(widget.docId)
                    .collection('comments')
                    .orderBy('createdAt', descending: true)
                    .snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                    return const Center(child: Text("No comments yet.", style: TextStyle(color: Colors.grey)));
                  }
                  return ListView.builder(
                    itemCount: snapshot.data!.docs.length,
                    itemBuilder: (context, index) {
                      final data = snapshot.data!.docs[index].data() as Map<String, dynamic>;
                      return ListTile(
                        leading: CircleAvatar(
                          radius: 16,
                          backgroundColor: Colors.grey[200],
                          child: Text(
                            (data['authorName'] ?? 'U')[0].toUpperCase(),
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                        ),
                        title: Text(data['authorName'] ?? 'User', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        subtitle: Text(data['text'] ?? ''),
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                      );
                    },
                  );
                },
              ),
            ),
            
            const Divider(),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _commentController,
                    decoration: InputDecoration(
                      hintText: "Add a comment...",
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(24), borderSide: BorderSide.none),
                      filled: true,
                      fillColor: Colors.grey[100],
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _postComment,
                  icon: const Icon(Icons.send, color: Color(0xFF5A6F4A)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
