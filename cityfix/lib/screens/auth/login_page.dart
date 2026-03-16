import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import 'signup_page.dart';
import 'forgot_password.dart';
import 'email_verification_screen.dart';
import 'terms_and_conditions_dialog.dart';
import '../user/user_home_page.dart';
import '../admin/admin_home_page.dart';
import '../staff/staff_home_page.dart';
import '../../utils/notification_service.dart';

// --- Color Palette for Professional Olive Green Theme (Matching SignUpPage) ---
// Primary/Background: A muted, professional olive green.
const Color kPrimaryColor = Color(0xFF5A6F4A);
// Accent/Button: A soft, contrasting tone for buttons.
const Color kAccentColor = Color(0xFFC0C7B2); // Light Grayish Green
// Text and Icon Color on Dark Background
const Color kOnPrimaryColor = Colors.white;
// Light Background: For cards and text fields.
const Color kCardColor = Color(0xFFF3F4F6); // Light Gray

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  bool _loading = false;

  // --- Logic remains completely unchanged ---

  Future<void> _checkUserRole(User user) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();


      if (doc.exists) {
        final role = doc.data()?['role'] ?? 'user';
        if (role == 'admin') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const AdminHomePage()),
          );
        } else if (role == 'staff') {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const StaffHomePage()),
          );
        } else {
          // For regular users, check if they've agreed to terms
          final termsAgreed = doc.data()?['termsAgreed'] ?? false;
          if (!termsAgreed) {
            // Show terms dialog before navigating
            await _showTermsDialog(user);
          } else {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const UserHomePage()),
            );
          }
        }
      } else {
        // New user - show terms dialog
        await _showTermsDialog(user);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error fetching role: $e")),
      );
    }
  }

  Future<void> _showTermsDialog(User user) async {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return TermsAndConditionsDialog(
          onAgree: (agreed) async {
            if (agreed) {
              // Store agreement in Firestore
              try {
                await FirebaseFirestore.instance
                    .collection('users')
                    .doc(user.uid)
                    .set({
                  'termsAgreed': true,
                  'termsAgreedAt': FieldValue.serverTimestamp(),
                }, SetOptions(merge: true));
                
                // Navigate to home page
                if (mounted) {
                  Navigator.pushReplacement(
                    context,
                    MaterialPageRoute(builder: (context) => const UserHomePage()),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Error saving agreement: $e")),
                  );
                }
              }
            }
          },
        );
      },
    );
  }

  Future<void> _loginWithEmailPassword() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _loading = true);

    try {
      final userCredential = await FirebaseAuth.instance
          .signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );

      final user = userCredential.user;
      if (user != null) {
        await NotificationService().updateTokenInFirestore();
        await _checkUserRole(user);
      }
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Login failed")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) return;

      final googleAuth = await googleUser.authentication;

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final userCredential =
      await FirebaseAuth.instance.signInWithCredential(credential);
      final user = userCredential.user;

      if (user != null) {
        final userDoc =
        FirebaseFirestore.instance.collection('users').doc(user.uid);

        final docSnapshot = await userDoc.get();
        if (!docSnapshot.exists) {
          await userDoc.set({
            'email': user.email,
            'role': 'user',
          });
        }

        await NotificationService().updateTokenInFirestore();
        await _checkUserRole(user);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Google sign-in failed: $e")),
      );
    }
  }

  // Helper method for input decoration (copied from SignUpPage)
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
      onTap: _loginWithGoogle,
      child: Center( // Center the image horizontally
        child: Image.asset(
          'assets/google_logo.png', // Assuming this is the path to your button image
          height: 55, // Set a height for visibility and consistency
          fit: BoxFit.fitHeight,
        ),
      ),
    );
  }

  // --- ATTRACTIVE UI CODE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor, // Olive Green Background
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 32.0, vertical: 40.0),
            child: Form(
              key: _formKey,
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
                    "Welcome Back",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: kOnPrimaryColor,
                    ),
                  ),
                  const SizedBox(height: 30),

                  // Email Field
                  TextFormField(
                    controller: _emailController,
                    validator: (value) =>
                    value == null || value.isEmpty ? "Enter email" : null,
                    decoration: _inputDecoration("Email", Icons.email_outlined),
                  ),
                  const SizedBox(height: 16),

                  // Password Field
                  TextFormField(
                    controller: _passwordController,
                    obscureText: true,
                    validator: (value) =>
                    value == null || value.isEmpty ? "Enter password" : null,
                    decoration: _inputDecoration("Password", Icons.lock_outline),
                  ),
                  const SizedBox(height: 8),

                  // Forgot Password Link
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => const ForgotPasswordPage()),
                        );
                      },
                      child: const Text(
                        "Forgot Password?",
                        style: TextStyle(
                          color: kOnPrimaryColor,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 20),

                  // Login Button
                  SizedBox(
                    height: 55,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: kAccentColor,
                        foregroundColor: kPrimaryColor,
                        elevation: 5,
                        textStyle: const TextStyle(
                            fontSize: 18, fontWeight: FontWeight.bold),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: _loading ? null : _loginWithEmailPassword,
                      child: _loading
                          ? const CircularProgressIndicator(color: kPrimaryColor)
                          : const Text("Log In"),
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

                  // Google Sign-In Button (Image only)
                  _buildGoogleSignInButton(),
                  const SizedBox(height: 40),

                  // Go to SignUp
                  TextButton(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const SignUpPage()),
                      );
                    },
                    child: const Text(
                      "Don't have an account? Sign Up",
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
      ),
    );
  }
}