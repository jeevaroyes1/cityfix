import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'screens/auth/landing_page.dart';
import 'utils/notification_service.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final notificationService = NotificationService();
  await notificationService.init();
  FirebaseMessaging.onBackgroundMessage(NotificationService.onBackgroundMessage);

  runApp(const CityFixApp());
}

class CityFixApp extends StatelessWidget {
  const CityFixApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CityFix',
      theme: ThemeData(
        primaryColor: const Color(0xFF6B8E23), // Olive Drab
        scaffoldBackgroundColor: const Color(0xFF583224), // chocolate milk
        useMaterial3: true,
      ),
      home: const AppInitializer(),
    );
  }
}

class AppInitializer extends StatelessWidget {
  const AppInitializer({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<FirebaseApp>(
      future: Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      ),
      builder: (context, snapshot) {
        // Show loading spinner while initializing
        if (snapshot.connectionState != ConnectionState.done) {
          return const Scaffold(
            backgroundColor: Color(0xFF583224), // chocolate milk
            body: Center(
              child: CircularProgressIndicator(
                color: Color(0xFF6B8E23),
              ),
            ),
          );
        }

        // Show error if initialization fails
        if (snapshot.hasError) {
          debugPrint('Firebase init error: ${snapshot.error}');
          return Scaffold(
            backgroundColor: const Color(0xFF583224), // chocolate milk
            body: Center(
              child: Text(
                "Firebase initialization failed!\n${snapshot.error}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.red.shade300,
                  fontSize: 18,
                ),
              ),
            ),
          );
        }

        // Firebase initialized successfully → show LandingPage
        return const LandingPage();
      },
    );
  }
}
