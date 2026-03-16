import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

// --- Color Palette for Professional Olive Green Theme (Matching Login/SignUp) ---
// Primary/Background: A muted, professional olive green.
const Color kPrimaryColor = Color(0xFF5A6F4A);
// Accent/Button: A soft, contrasting tone for buttons.
const Color kAccentColor = Color(0xFFC0C7B2); // Light Grayish Green
// Text and Icon Color on Dark Background
const Color kOnPrimaryColor = Colors.white;
// Light Background: For cards and text fields.
const Color kCardColor = Color(0xFFF3F4F6); // Light Gray

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final TextEditingController _emailController = TextEditingController();
  bool _loading = false;

  // --- Logic remains completely unchanged ---

  Future<void> _resetPassword() async {
    if (_emailController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter your email")),
      );
      return;
    }

    setState(() => _loading = true);

    try {
      await FirebaseAuth.instance
          .sendPasswordResetEmail(email: _emailController.text.trim());

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Password reset link sent! Check your email."),
        ),
      );

      Navigator.pop(context); // Go back to login
    } on FirebaseAuthException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? "Failed to send reset email")),
      );
    } finally {
      setState(() => _loading = false);
    }
  }

  // Helper method for input decoration (Consistent with Login/SignUp)
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

  // --- ATTRACTIVE UI CODE ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor, // Olive Green Background
      appBar: AppBar(
        backgroundColor: kPrimaryColor,
        title: const Text(
          "Forgot Password",
          style: TextStyle(
            color: kOnPrimaryColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        iconTheme: const IconThemeData(color: kOnPrimaryColor),
        elevation: 0,
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Icon for visual appeal
              const Icon(
                Icons.lock_reset,
                size: 80,
                color: kOnPrimaryColor,
              ),
              const SizedBox(height: 20),

              const Text(
                "Enter your registered email to receive the password reset link.",
                style: TextStyle(color: kOnPrimaryColor, fontSize: 16),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // Email Field (Styled)
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                // Using the consistent input decoration helper
                decoration: _inputDecoration("Email Address", Icons.email_outlined),
              ),
              const SizedBox(height: 30),

              // Reset Button (Styled)
              SizedBox(
                height: 55,
                child: ElevatedButton(
                  onPressed: _loading ? null : _resetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kAccentColor, // Use accent color
                    foregroundColor: kPrimaryColor, // Dark text on light button
                    elevation: 5,
                    textStyle: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: _loading
                      ? const CircularProgressIndicator(color: kPrimaryColor)
                      : const Text("Send Reset Link"),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}