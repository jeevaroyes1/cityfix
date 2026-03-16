import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

import 'package:profanity_filter/profanity_filter.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ReportFoundItemPage extends StatefulWidget {
  const ReportFoundItemPage({super.key});

  @override
  State<ReportFoundItemPage> createState() => _ReportFoundItemPageState();
}


class _ReportFoundItemPageState extends State<ReportFoundItemPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _dateController = TextEditingController();

  File? _selectedImage;
  DateTime? _selectedDate;
  bool _isLoading = false;

  final ImagePicker _picker = ImagePicker();

  Future<void> _pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      setState(() {
        _selectedImage = File(image.path);
      });
    }
  }

  Future<String?> _uploadImageToCloudinary(File imageFile) async {
    const cloudName = 'duau9rsfh';
    const uploadPreset = 'cityfix'; // Reusing existing preset
    final uploadUrl = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    try {
      final request = http.MultipartRequest('POST', uploadUrl)
        ..fields['upload_preset'] = uploadPreset
        ..fields['folder'] = 'report' // Requested folder
        ..files.add(await http.MultipartFile.fromPath('file', imageFile.path));

      final response = await request.send();
      if (response.statusCode == 200) {
        final resBody = await response.stream.bytesToString();
        final data = jsonDecode(resBody);
        return data['secure_url'];
      } else {
        debugPrint('Cloudinary Upload Failed: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      debugPrint('Cloudinary Upload Error: $e');
      return null;
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFF5A6F4A),
              onPrimary: Colors.white,
              onSurface: Colors.black,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xFF5A6F4A),
              ),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = DateFormat('yyyy-MM-dd').format(picked);
      });
    }
  }

  Future<void> _submitReport() async {
    if (_formKey.currentState!.validate()) {
      if (_selectedImage == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select an image of the item')),
        );
        return;
      }
      if (_selectedDate == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please select the date found')),
        );
        return;
      }

      // Check for inappropriate content
      final filter = ProfanityFilter();
      if (filter.hasProfanity(_descriptionController.text)) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please remove inappropriate content from description'),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      setState(() {
        _isLoading = true;
      });

      try {
        // Fetch user's panchayat
        final userDoc = await FirebaseFirestore.instance.collection('users').doc(FirebaseAuth.instance.currentUser!.uid).get();
        final userPanchayat = userDoc.data()?['panchayat'] as String?;

        if (userPanchayat == null) {
          throw Exception("User panchayat not found");
        }

        // Upload to Cloudinary
        final imageUrl = await _uploadImageToCloudinary(_selectedImage!);
        
        if (imageUrl == null) {
          throw Exception("Failed to upload image to Cloudinary");
        }

        await FirebaseFirestore.instance.collection('lost_and_found_items').add({
          'description': _descriptionController.text.trim(),
          'dateFound': _selectedDate,
          'contactEmail': _emailController.text.trim(),
          'imageUrl': imageUrl,
          'createdAt': FieldValue.serverTimestamp(),
          'status': 'Open',
          'userId': FirebaseAuth.instance.currentUser?.uid,
          'panchayat': userPanchayat,
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lost Item Reported Successfully!')),
        );

        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error reporting item: $e')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text("Report Found Item", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        backgroundColor: const Color(0xFF5A6F4A),
        iconTheme: const IconThemeData(color: Colors.white),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Detail the Item",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF5A6F4A)),
              ),
              const SizedBox(height: 8),
              const Text(
                "Provide clear details to help the owner find their item.",
                style: TextStyle(fontSize: 14, color: Colors.grey),
              ),
              const SizedBox(height: 24),
              
              // Image Picker
              GestureDetector(
                onTap: _pickImage,
                child: Container(
                  height: 220,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.grey[300]!, width: 1.5),
                    image: _selectedImage != null
                        ? DecorationImage(
                            image: FileImage(_selectedImage!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: _selectedImage == null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.add_a_photo_outlined, size: 48, color: Colors.grey[500]),
                            const SizedBox(height: 12),
                            Text("Tap to upload photo", style: TextStyle(color: Colors.grey[600], fontSize: 16)),
                          ],
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 24),

              _buildLabel("Description"),
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: _inputDecoration("Describe the item found..."),
                validator: (value) => value == null || value.isEmpty ? 'Please enter a description' : null,
              ),
              const SizedBox(height: 20),

              _buildLabel("Date Found"),
              TextFormField(
                controller: _dateController,
                readOnly: true,
                onTap: () => _selectDate(context),
                decoration: _inputDecoration("Select Date").copyWith(
                  suffixIcon: const Icon(Icons.calendar_today, color: Color(0xFF5A6F4A)),
                ),
                validator: (value) => value == null || value.isEmpty ? 'Please select a date' : null,
              ),
              const SizedBox(height: 20),

              _buildLabel("Contact Email"),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: _inputDecoration("Your email for contact"),
                validator: (value) {
                  if (value == null || value.isEmpty) return 'Please enter your email';
                  if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) return 'Please enter a valid email';
                  return null;
                },
              ),
              const SizedBox(height: 40),

              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _submitReport,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF5A6F4A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 2,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text("Submit Report", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0, left: 4),
      child: Text(label, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.black87)),
    );
  }

  InputDecoration _inputDecoration(String hint) {
    return InputDecoration(
      hintText: hint,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF5A6F4A), width: 2)),
      filled: true,
      fillColor: Colors.grey[50],
    );
  }
}
