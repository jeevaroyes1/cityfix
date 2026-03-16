import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'login_page.dart';
import 'email_verification_screen.dart';
import '../../utils/notification_service.dart';

// --- Color Palette for Professional Olive Green Theme ---
// Primary/Background: A muted, professional olive green.
const Color kPrimaryColor = Color(0xFF5A6F4A);
// Accent/Button: A soft, contrasting tone for buttons.
const Color kAccentColor = Color(0xFFC0C7B2); // Light Grayish Green
// Text and Icon Color on Dark Background
const Color kOnPrimaryColor = Colors.white;
// Light Background: For cards and text fields.
const Color kCardColor = Color(0xFFF3F4F6); // Light Gray

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _phoneController = TextEditingController();
  final _otpController = TextEditingController();
  
  bool _isLoading = false;
  bool _isOtpSent = false;
  bool _isPhoneVerified = false;
  String? _verificationId;

  // New dropdown selections
  String? _selectedState;
  String? _selectedDistrict;
  String? _selectedPanchayat;
  String? _selectedWard;

  final List<String> _states = ['Kerala'];
  final List<String> _districts = ['Kottayam', 'Kollam', 'Pathanamthitta'];
  final List<String> _panchayats = ['Erumeli', 'Parathodu'];
  final List<String> _wards = ['Ward 1', 'Ward 2'];

  // ✅ Email/Password signup (FUNCTIONALITY REMAINS UNCHANGED)
  Future<void> _signUpWithEmail() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final confirmPassword = _confirmPasswordController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty || 
        _selectedState == null || _selectedDistrict == null || 
        _selectedPanchayat == null || _selectedWard == null) {
      _showSnackBar("Please fill all fields");
      return;
    }
    if (!_isPhoneVerified) {
      _showSnackBar("Please verify your phone number first");
      return;
    }
    if (password != confirmPassword) {
      _showSnackBar("Passwords do not match");
      return;
    }

    setState(() => _isLoading = true);
    try {
      final userCredential = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(email: email, password: password);

      final user = userCredential.user;

      // ✅ Add user details to Firestore
      if (user != null) {
        await FirebaseFirestore.instance.collection('users').doc(user.uid).set({
          'fullName': fullName,
          'email': user.email,
          'role': 'user', // default role
          'state': _selectedState,
          'district': _selectedDistrict,
          'panchayat': _selectedPanchayat,
          'ward': _selectedWard,
          'phoneNumber': _phoneController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
        });
        await NotificationService().updateTokenInFirestore();
      }

      _showSnackBar("Signup successful! Please verify your email.");
      await user?.sendEmailVerification();
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const EmailVerificationScreen()),
      );
    } on FirebaseAuthException catch (e) {
      _showSnackBar(e.message ?? "Signup failed");
    } catch (e) {
      _showSnackBar("An error occurred");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Google Sign-In (FUNCTIONALITY REMAINS UNCHANGED)
  Future<void> _signInWithGoogle() async {
    setState(() => _isLoading = true);
    try {
      final googleSignIn = GoogleSignIn();
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return; // user canceled

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
        accessToken: googleAuth.accessToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      // ✅ Ensure Google user has Firestore document
      if (user != null) {
        final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          await userDoc.set({
            'fullName': googleUser.displayName ?? '',
            'email': user.email,
            'role': 'user',
            'state': _selectedState,
            'district': _selectedDistrict,
            'panchayat': _selectedPanchayat,
            'ward': _selectedWard,
            'createdAt': FieldValue.serverTimestamp(),
          });
          await NotificationService().updateTokenInFirestore();
        }
      }

      _showSnackBar("Signed in with Google!");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    } catch (e) {
      _showSnackBar("Google sign-in failed");
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // ✅ Send OTP Logic
  Future<void> _sendOtp() async {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty || phone.length < 10) {
      _showSnackBar("Please enter a valid phone number");
      return;
    }

    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.verifyPhoneNumber(
        phoneNumber: "+91$phone", // Assuming Indian numbers for now, can be generalized
        verificationCompleted: (PhoneAuthCredential credential) async {
          // Auto-resolution (on Android)
          await FirebaseAuth.instance.signInWithCredential(credential);
          setState(() {
            _isPhoneVerified = true;
            _isLoading = false;
          });
          _showSnackBar("Phone verified automatically!");
        },
        verificationFailed: (FirebaseAuthException e) {
          setState(() => _isLoading = false);
          _showSnackBar("Verification failed: ${e.message}");
        },
        codeSent: (String verificationId, int? resendToken) {
          setState(() {
            _verificationId = verificationId;
            _isOtpSent = true;
            _isLoading = false;
          });
          _showSnackBar("OTP sent to $phone");
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          _verificationId = verificationId;
        },
      );
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Error sending OTP: $e");
    }
  }

  // ✅ Verify OTP Logic
  Future<void> _verifyOtp() async {
    final otp = _otpController.text.trim();
    if (otp.isEmpty || otp.length < 6) {
      _showSnackBar("Please enter a valid 6-digit OTP");
      return;
    }

    setState(() => _isLoading = true);
    try {
      PhoneAuthCredential credential = PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: otp,
      );
      
      // We don't necessarily want to sign in yet, just verify.
      // But Firebase Phone Auth usually links to a user.
      // For verification during signup, we can just check if the credential is valid.
      // Alternatively, we can sign in and then proceed with email signup linking.
      // However, the simplest way for "verification" is to try signing in.
      
      await FirebaseAuth.instance.signInWithCredential(credential);
      
      setState(() {
        _isPhoneVerified = true;
        _isLoading = false;
      });
      _showSnackBar("Phone verified successfully!");
    } catch (e) {
      setState(() => _isLoading = false);
      _showSnackBar("Invalid OTP: $e");
    }
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _phoneController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  // --- ATTRACTIVE UI CODE ---

  @override
  Widget build(BuildContext context) {
    // Using the muted olive green background
    return Scaffold(
      backgroundColor: kPrimaryColor,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo/Icon
                const Icon(
                  Icons.lock_open_rounded,
                  size: 80,
                  color: kOnPrimaryColor,
                ),
                const SizedBox(height: 10),
                const Text(
                  "Create Your Account",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: kOnPrimaryColor,
                  ),
                ),
                const SizedBox(height: 30),

                // Full Name
                TextField(
                  controller: _fullNameController,
                  decoration: _inputDecoration(
                      "Full Name", Icons.person_outline),
                ),
                const SizedBox(height: 16),

                // Email
                TextField(
                  controller: _emailController,
                  decoration: _inputDecoration(
                      "Email", Icons.email_outlined),
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),

                // Phone Verification Section
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        controller: _phoneController,
                        enabled: !_isPhoneVerified,
                        decoration: _inputDecoration("Phone Number", Icons.phone_android_outlined),
                        keyboardType: TextInputType.phone,
                      ),
                    ),
                    const SizedBox(width: 10),
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _isPhoneVerified ? Colors.green : kAccentColor,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                      onPressed: (_isLoading || _isPhoneVerified) ? null : _sendOtp,
                      child: Text(
                        _isPhoneVerified ? "Verified" : (_isOtpSent ? "Resend" : "Send"),
                        style: TextStyle(color: _isPhoneVerified ? Colors.white : kPrimaryColor),
                      ),
                    ),
                  ],
                ),
                if (_isOtpSent && !_isPhoneVerified) ...[
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _otpController,
                          decoration: _inputDecoration("Enter OTP", Icons.security_outlined),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 10),
                      ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: kAccentColor,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                        onPressed: _isLoading ? null : _verifyOtp,
                        child: const Text("Verify", style: TextStyle(color: kPrimaryColor)),
                      ),
                    ],
                  ),
                ],
                const SizedBox(height: 16),

                // Password
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  decoration: _inputDecoration(
                      "Password", Icons.lock_outline),
                ),
                const SizedBox(height: 16),

                // Confirm Password
                TextField(
                  controller: _confirmPasswordController,
                  obscureText: true,
                  decoration: _inputDecoration(
                      "Confirm Password", Icons.check_circle_outline),
                ),
                const SizedBox(height: 20),

                // Dropdowns Section
                _buildDropdown(
                  label: "State",
                  value: _selectedState,
                  items: _states,
                  icon: Icons.location_city_outlined,
                  onChanged: (value) {
                    setState(() => _selectedState = value!);
                  },
                ),
                const SizedBox(height: 16),

                _buildDropdown(
                  label: "District",
                  value: _selectedDistrict,
                  items: _districts,
                  icon: Icons.apartment_outlined,
                  onChanged: (value) {
                    setState(() => _selectedDistrict = value!);
                  },
                ),
                const SizedBox(height: 16),

                _buildDropdown(
                  label: "Panchayat",
                  value: _selectedPanchayat,
                  items: _panchayats,
                  icon: Icons.holiday_village_outlined,
                  onChanged: (value) {
                    setState(() => _selectedPanchayat = value!);
                  },
                ),
                const SizedBox(height: 16),

                _buildDropdown(
                  label: "Ward",
                  value: _selectedWard,
                  items: _wards,
                  icon: Icons.home_outlined,
                  onChanged: (value) {
                    setState(() => _selectedWard = value!);
                  },
                ),
                const SizedBox(height: 30),

                // Sign Up button
                _isLoading
                    ? const Center(
                    child: CircularProgressIndicator(color: kAccentColor))
                    : SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor,
                      foregroundColor: kPrimaryColor, // Dark text on light button
                      elevation: 5,
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: _signUpWithEmail,
                    child: const Text("Create Account"),
                  ),
                ),
                const SizedBox(height: 25),

                // OR Divider
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20.0),
                  child: Row(
                    children: [
                      Expanded(
                          child: Divider(
                              thickness: 1, color: kOnPrimaryColor)),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 10.0),
                        child: Text("OR",
                            style: TextStyle(color: kOnPrimaryColor)),
                      ),
                      Expanded(
                          child: Divider(
                              thickness: 1, color: kOnPrimaryColor)),
                    ],
                  ),
                ),
                const SizedBox(height: 25),

                // ✅ CORRECTED: Google Sign-In Button (Image only)
                _buildGoogleSignInButton(),
                const SizedBox(height: 40),

                // Go to Login
                TextButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    );
                  },
                  child: const Text(
                    "Already have an account? Log In",
                    style: TextStyle(
                      color: kOnPrimaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      decoration: TextDecoration.underline,
                      decorationColor: kOnPrimaryColor,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Reusable dropdown builder with improved styling and Icon
  Widget _buildDropdown({
    required String label,
    required String? value, // Changed to nullable
    required List<String> items,
    required IconData icon,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: kCardColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: DropdownButtonFormField<String>(
        decoration: InputDecoration(
          prefixIcon: Icon(icon, color: kPrimaryColor),
          labelText: label,
          hintText: "Select $label", // Add hint text
          labelStyle: const TextStyle(color: kPrimaryColor),
          contentPadding:
          const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          border: InputBorder.none,
        ),
        value: value,
        isExpanded: true,
        validator: (value) => value == null ? 'Please select $label' : null, // Add validation
        style: const TextStyle(color: Colors.black, fontSize: 16),
        dropdownColor: Colors.white,
        icon: const Icon(Icons.arrow_drop_down, color: kPrimaryColor),
        onChanged: onChanged,
        items: items
            .map((item) => DropdownMenuItem(value: item, child: Text(item)))
            .toList(),
      ),
    );
  }

  // Improved Input Decoration with border radius and icons
  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: kCardColor,
      hintText: hint,
      prefixIcon: Icon(icon, color: kPrimaryColor),
      contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 15),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: kAccentColor, width: 2),
      ),
    );
  }

  // ✅ CORRECTED: Custom Google Sign-In widget using only GestureDetector and Image.asset
  Widget _buildGoogleSignInButton() {
    return GestureDetector(
      onTap: _signInWithGoogle,
      child: Center( // Center the image horizontally
        child: Image.asset(
          'assets/google_logo2.png', // Your asset path
          height: 55, // Set a height for visibility and consistency
          fit: BoxFit.fitHeight,
        ),
      ),
    );
  }
}