import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:profanity_filter/profanity_filter.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class CreateNotePage extends StatefulWidget {
  final String? noteId;
  final Map<String, dynamic>? initialData;

  const CreateNotePage({super.key, this.noteId, this.initialData});

  @override
  State<CreateNotePage> createState() => _CreateNotePageState();
}

class _CreateNotePageState extends State<CreateNotePage> {
  late TextEditingController _textController;
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isUploading = false;
  final ImagePicker _picker = ImagePicker();
  final User? _currentUser = FirebaseAuth.instance.currentUser;

  @override
  void initState() {
    super.initState();
    _textController = TextEditingController(text: widget.initialData?['content'] ?? '');
    _existingImageUrl = widget.initialData?['imageUrl'];
  }

  @override
  void dispose() {
    _textController.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'duau9rsfh';
    const uploadPreset = 'cityfix';
    final uploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    try {
      final request = http.MultipartRequest('POST', uploadUrl)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'report'
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final data = jsonDecode(resBody);
        return data['secure_url'];
      }
      return null;
    } catch (e) {
      debugPrint("Error uploading image: $e");
      return null;
    }
  }

  Future<void> _postNote() async {
    if (_textController.text.trim().isEmpty && _selectedImage == null) return;

    // Check for inappropriate content
    final filter = ProfanityFilter();
    if (filter.hasProfanity(_textController.text)) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please remove inappropriate content from your note'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    setState(() => _isUploading = true);

    try {
      String? imageUrl = _existingImageUrl;
      if (_selectedImage != null) {
        imageUrl = await _uploadImageToCloudinary(_selectedImage!);
      }

      if (widget.noteId != null) {
        // Update existing note
        await FirebaseFirestore.instance.collection('community_notes').doc(widget.noteId).update({
          'content': _textController.text.trim(),
          'imageUrl': imageUrl,
          'updatedAt': FieldValue.serverTimestamp(),
        });
        
        if (mounted) {
           Navigator.pop(context);
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Note updated successfully!")),
          );
        }
      } else {
        // Create new note
        // Fetch user's panchayat
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(_currentUser!.uid).get();
        final userPanchayat = userDoc.data()?['panchayat'] as String?;

        if (userPanchayat == null) {
          throw Exception("User panchayat not found");
        }

        await FirebaseFirestore.instance.collection('community_notes').add({
          'content': _textController.text.trim(),
          'imageUrl': imageUrl,
          'authorId': _currentUser?.uid,
          'authorEmail': _currentUser?.email,
          'createdAt': FieldValue.serverTimestamp(),
          'likes': [],
          'panchayat': userPanchayat,
        });

        if (mounted) {
          Navigator.pop(context);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Note posted to Community Hub!")),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error posting note: $e")),
        );
      }
    } finally {
      if (mounted) setState(() => _isUploading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Minimalist Design - Full Screen White with Green Accents
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.black, size: 28),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          widget.noteId != null ? "Edit note" : "New note",
          style: const TextStyle(
            color: Colors.black,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: TextButton(
              onPressed: _isUploading || (_textController.text.isEmpty && _selectedImage == null && _existingImageUrl == null) 
                  ? null 
                  : _postNote,
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5A6F4A),
                disabledForegroundColor: Colors.grey[300],
              ),
              child: _isUploading 
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) 
                  : Text(widget.noteId != null ? "Update" : "Post", style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // User Avatar Placeholder or Actual
                      CircleAvatar(
                        radius: 20,
                        backgroundColor: const Color(0xFF5A6F4A),
                        child: Text(
                          (_currentUser?.email ?? "U").substring(0, 1).toUpperCase(),
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                        ),
                      ),
                      const SizedBox(width: 12),
                      
                      // Input Field
                      Expanded(
                        child: TextField(
                          controller: _textController,
                          onChanged: (val) => setState(() {}),
                          autofocus: true,
                          maxLines: null,
                          style: const TextStyle(fontSize: 18, color: Colors.black87),
                          decoration: const InputDecoration(
                            hintText: "Write something...",
                            hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Image Preview
                  if (_selectedImage != null || _existingImageUrl != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 20, left: 52), // Align with text
                      child: Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: _selectedImage != null 
                              ? Image.file(
                                  _selectedImage!,
                                  height: 200,
                                  fit: BoxFit.cover,
                                )
                              : Image.network(
                                  _existingImageUrl!,
                                  height: 200,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    height: 200,
                                    width: 200,
                                    color: Colors.grey[200],
                                    child: const Icon(Icons.broken_image),
                                  ),
                                ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: InkWell(
                              onTap: () {
                                setState(() {
                                  _selectedImage = null;
                                  _existingImageUrl = null;
                                });
                              },
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.black54,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close, color: Colors.white, size: 16),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),
          
          // Bottom Actions Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border(top: BorderSide(color: Colors.grey[100]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildActionButton(Icons.photo_library_outlined, "Library", () => _pickImage(ImageSource.gallery)),
                _buildActionButton(Icons.camera_alt_outlined, "Camera", () => _pickImage(ImageSource.camera)),
                // _buildActionButton(Icons.location_on_outlined, "Location", () {}), // Optional
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton(IconData icon, String label, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: Colors.black87, size: 24),
            const SizedBox(height: 4),
            Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: Colors.black87)),
          ],
        ),
      ),
    );
  }
}
