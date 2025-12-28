import 'package:flutter/material.dart';
import 'dart:async';
import 'onboarding_page.dart';
import 'dashboard_pelajar.dart';
import 'dashboard_mentor.dart';
import 'dashboard_admin.dart';
import 'session_manager.dart';

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

  Future<void> _checkLoginStatus() async {
    await Future.delayed(const Duration(seconds: 3));

    bool isLoggedIn = await SessionManager.isLoggedIn();

    if (isLoggedIn) {
      String? userType = await SessionManager.getUserType();
      Map<String, dynamic>? userData = await SessionManager.getUserData();

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
      } else if (userType == 'admin') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardAdmin()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => OnboardingPage()),
        );
      }
    } else {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => OnboardingPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(30),
              child: Image.asset(
                'assets/images/logot.png',
                width: 500,
                height: 500,
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
            const SizedBox(height: 5),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Colors.blue[700]!),
            ),
          ],
        ),
      ),
    );
  }
}
