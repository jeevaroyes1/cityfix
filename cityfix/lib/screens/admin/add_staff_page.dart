import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class AddStaffPage extends StatefulWidget {
  const AddStaffPage({super.key});

  @override
  State<AddStaffPage> createState() => _AddStaffPageState();
}

class _AddStaffPageState extends State<AddStaffPage> {
  final _firestore = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _districtController = TextEditingController();
  final TextEditingController _panchayatController = TextEditingController();

  String? _selectedDepartment;

  // Real-time error messages (null = no error)
  String? _nameError;
  String? _emailError;
  String? _phoneError;
  String? _passwordError;
  String? _districtError;
  String? _panchayatError;
  String? _departmentError;

  final List<String> categories = [
    "Infrastructure & Roads",
    "Utilities (Water & Electricity)",
    "Sanitation & Environment",
    "Traffic & Public Safety",
    "Parks & Recreation",
  ];

  @override
  void initState() {
    super.initState();
    _nameController.addListener(_validateName);
    _emailController.addListener(_validateEmail);
    _phoneController.addListener(_validatePhone);
    _passwordController.addListener(_validatePassword);
    _districtController.addListener(_validateDistrict);
    _panchayatController.addListener(_validatePanchayat);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _districtController.dispose();
    _panchayatController.dispose();
    super.dispose();
  }

  // --- Validation Methods (called on every keystroke) ---

  void _validateName() {
    final name = _nameController.text.trim();
    setState(() {
      if (name.isEmpty) {
        _nameError = 'Full name is required';
      } else if (name.length < 2) {
        _nameError = 'Name must be at least 2 characters';
      } else if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(name)) {
        _nameError = 'Name can only contain letters and spaces';
      } else {
        _nameError = null;
      }
    });
  }

  void _validateEmail() {
    final email = _emailController.text.trim();
    setState(() {
      if (email.isEmpty) {
        _emailError = 'Email is required';
      } else if (!RegExp(
              r"^[a-zA-Z0-9.!#$%&'*+/=?^_`{|}~-]+@[a-zA-Z0-9]+\.[a-zA-Z]+")
          .hasMatch(email)) {
        _emailError = 'Please enter a valid email address';
      } else {
        _emailError = null;
      }
    });
  }

  void _validatePhone() {
    final phone = _phoneController.text.trim();
    setState(() {
      if (phone.isEmpty) {
        _phoneError = 'Phone number is required';
      } else if (int.tryParse(phone) == null) {
        _phoneError = 'Phone number must contain only digits';
      } else if (phone.length != 10) {
        _phoneError = 'Phone number must be exactly 10 digits';
      } else {
        _phoneError = null;
      }
    });
  }

  void _validatePassword() {
    final password = _passwordController.text.trim();
    setState(() {
      if (password.isEmpty) {
        _passwordError = 'Password is required';
      } else if (password.length < 5) {
        _passwordError = 'Password must be at least 5 characters';
      } else {
        _passwordError = null;
      }
    });
  }

  void _validateDistrict() {
    final district = _districtController.text.trim();
    setState(() {
      if (district.isEmpty) {
        _districtError = 'District is required';
      } else {
        _districtError = null;
      }
    });
  }

  void _validatePanchayat() {
    final panchayat = _panchayatController.text.trim();
    setState(() {
      if (panchayat.isEmpty) {
        _panchayatError = 'Panchayat is required';
      } else {
        _panchayatError = null;
      }
    });
  }

  /// Returns true if all fields are valid
  bool _validateAll() {
    _validateName();
    _validateEmail();
    _validatePhone();
    _validatePassword();
    _validateDistrict();
    _validatePanchayat();

    // Department dropdown validation
    setState(() {
      _departmentError =
          _selectedDepartment == null ? 'Please select a department' : null;
    });

    return _nameError == null &&
        _emailError == null &&
        _phoneError == null &&
        _passwordError == null &&
        _districtError == null &&
        _panchayatError == null &&
        _departmentError == null;
  }

  Future<void> _addStaffToFirebase() async {
    if (!_validateAll()) return;

    try {
      final userCredential = await _auth.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
      final uid = userCredential.user!.uid;

      await _firestore.collection('users').doc(uid).set({
        'uid': uid,
        'name': _nameController.text.trim(),
        'email': _emailController.text.trim(),
        'phone': _phoneController.text.trim(),
        'department': _selectedDepartment,
        'district': _districtController.text.trim(),
        'panchayat': _panchayatController.text.trim(),
        'role': 'staff',
        'createdAt': FieldValue.serverTimestamp(),
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Staff account created successfully!")),
      );

      Navigator.pop(context);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    }
  }

  Widget _buildTextField(
    String label,
    TextEditingController controller, {
    bool isPassword = false,
    String? errorText,
    TextInputType? keyboardType,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        TextField(
          controller: controller,
          obscureText: isPassword,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : Colors.grey,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(
                color: errorText != null ? Colors.red : const Color(0xFF5A6F4A),
                width: 2,
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 4),
          Text(
            errorText,
            style: const TextStyle(
              color: Colors.red,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        borderRadius: BorderRadius.circular(16),
        color: Colors.white,
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.95,
          height: MediaQuery.of(context).size.height * 0.85,
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  right: 0,
                  child: IconButton(
                    icon: const Icon(Icons.close, color: Colors.grey),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),

                SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      const Text("Add New Staff Member",
                          style: TextStyle(
                              fontSize: 22, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      const Text(
                        "Enter the details of the new staff member",
                        style: TextStyle(color: Colors.grey, fontSize: 14),
                      ),
                      const SizedBox(height: 24),

                      _buildTextField("Full Name", _nameController,
                          errorText: _nameError),
                      const SizedBox(height: 16),

                      _buildTextField("Email", _emailController,
                          errorText: _emailError,
                          keyboardType: TextInputType.emailAddress),
                      const SizedBox(height: 16),

                      _buildTextField("Phone Number", _phoneController,
                          errorText: _phoneError,
                          keyboardType: TextInputType.phone),
                      const SizedBox(height: 16),

                      _buildTextField("District", _districtController,
                          errorText: _districtError),
                      const SizedBox(height: 16),

                      _buildTextField("Panchayat", _panchayatController,
                          errorText: _panchayatError),
                      const SizedBox(height: 16),

                      _buildTextField("Password", _passwordController,
                          isPassword: true, errorText: _passwordError),
                      const SizedBox(height: 16),

                      const Text("Department/Role",
                          style: TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(height: 6),

                      DropdownButtonFormField<String>(
                        decoration: InputDecoration(
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _departmentError != null
                                  ? Colors.red
                                  : Colors.grey,
                            ),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(10),
                            borderSide: BorderSide(
                              color: _departmentError != null
                                  ? Colors.red
                                  : const Color(0xFF5A6F4A),
                              width: 2,
                            ),
                          ),
                        ),
                        value: _selectedDepartment,
                        items: categories
                            .map((dept) => DropdownMenuItem(
                                  value: dept,
                                  child: Text(dept),
                                ))
                            .toList(),
                        onChanged: (value) {
                          setState(() {
                            _selectedDepartment = value;
                            _departmentError = null;
                          });
                        },
                      ),
                      if (_departmentError != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          _departmentError!,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],

                      const SizedBox(height: 24),

                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          OutlinedButton(
                            onPressed: () => Navigator.pop(context),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: const Color(0xFF5A6F4A),
                            ),
                            child: const Text("Cancel"),
                          ),
                          ElevatedButton(
                            onPressed: () async {
                              await _addStaffToFirebase();
                            },
                            style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF5A6F4A)),
                            child: const Text(
                              "Save Staff",
                              style: TextStyle(color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
