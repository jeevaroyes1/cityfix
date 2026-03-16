import 'package:flutter/material.dart';
import 'login_page.dart';
import 'signup_page.dart';

// --- Color Palette for Professional Olive Green Theme (Matching Auth Pages) ---
// Primary/Background: A muted, professional olive green.
const Color kPrimaryColor = Color(0xFF5A6F4A);
// Accent/Button: A soft, contrasting tone for buttons.
const Color kAccentColor = Color(0xFFC0C7B2); // Light Grayish Green
// Text and Icon Color on Dark Background
const Color kOnPrimaryColor = Colors.white;

class LandingPage extends StatelessWidget {
  const LandingPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kPrimaryColor, // Olive Green Background
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // App Logo / Icon (Styled)
                const Icon(
                  Icons.location_city_rounded,
                  color: kAccentColor, // Use accent color for contrast
                  size: 100,
                ),
                const SizedBox(height: 20),

                // App Name (Styled)
                const Text(
                  "CityFix",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 38,
                    fontWeight: FontWeight.w900, // Extra bold
                    color: kOnPrimaryColor,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 15),

                // Tagline (Styled)
                const Text(
                  "Report city problems easily.\nTogether, let’s build a better community.",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 17,
                    color: kOnPrimaryColor,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 60),

                // --- Buttons Section ---

                // Login Button (Primary Action)
                SizedBox(
                  height: 55,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: kAccentColor, // Light accent color
                      foregroundColor: kPrimaryColor, // Dark text on light button
                      elevation: 5,
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const LoginPage(),
                        ),
                      );
                    },
                    child: const Text("Log In"),
                  ),
                ),
                const SizedBox(height: 20),

                // Sign Up Button (Secondary Action)
                SizedBox(
                  height: 55,
                  child: OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: kOnPrimaryColor, // White text
                      side: const BorderSide(
                          color: kAccentColor, width: 2.0), // Accent border
                      textStyle: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const SignUpPage(),
                        ),
                      );
                    },
                    child: const Text("Create Account"),
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