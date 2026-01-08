import 'package:flutter/material.dart';
import 'dart:async';
import 'onboarding_page.dart';
import '../pelajar/dashboard_pelajar.dart';
import '../mentor/dashboard_mentor.dart';
import '../utils/session_manager.dart';
import '../services/notification_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLoginStatus();
  }

  Future<void> _initializeNotifications() async {
    try {
      // Wait for context to be ready
      await Future.delayed(const Duration(milliseconds: 100));
      if (mounted) {
        await NotificationService.initialize(context);
        print('✅ Notification service initialized');
      }
    } catch (e) {
      print('⚠️ Error initializing notifications: $e');
      // Continue without notifications
    }
  }

  Future<void> _checkLoginStatus() async {
    try {
      print('🔍 Checking login status...');

      // Initialize notifications in background
      _initializeNotifications();

      await Future.delayed(const Duration(seconds: 3));

      bool isLoggedIn = await SessionManager.isLoggedIn();
      print('📱 Is logged in: $isLoggedIn');

      if (isLoggedIn) {
        String? userType = await SessionManager.getUserType();
        Map<String, dynamic>? userData = await SessionManager.getUserData();
        print('👤 User type: $userType');

        if (userType == 'pelajar' && userData != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardPelajar(userData: userData),
            ),
          );
        } else if (userType == 'mentor' && userData != null) {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
              builder: (context) => DashboardMentor(mentorData: userData),
            ),
          );
        } else {
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => const OnboardingPage()),
          );
        }
      } else {
        print('➡️  Navigating to onboarding...');
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const OnboardingPage()),
        );
      }
    } catch (e, stackTrace) {
      print('❌ Error in splash screen: $e');
      print('❌ Stack trace: $stackTrace');

      // Show error and navigate to onboarding
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );

      await Future.delayed(const Duration(seconds: 2));
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final logoSize = constraints.maxHeight < 500
                ? (constraints.maxHeight * 0.55).clamp(180.0, 320.0)
                : 320.0;

            return Center(
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Image.asset(
                        'assets/images/logot.png',
                        width: logoSize,
                        height: logoSize,
                        fit: BoxFit.contain,
                      ),
                    ),
                    Text(
                      "Learn from the Best",
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 12),
                    CircularProgressIndicator(
                      valueColor:
                          AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
