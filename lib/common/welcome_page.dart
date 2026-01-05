import 'package:flutter/material.dart';
import '../pelajar/login_pelajar.dart';
import '../mentor/login_mentor.dart';
import '../utils/debug_account_manager.dart';
import '../utils/firebase_restore_utility.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    // Precache logo to prevent freeze
    precacheImage(const AssetImage('assets/images/logodoang.png'), context);

    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(30),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Image.asset(
                    'assets/images/logodoang.png',
                    width: 320,
                    height: 320,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 30),
                  const Text(
                    "Selamat Datang di Mentorly",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    "Siapa untuk naik level?\nDaftar Mentorly sekarang!",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey[700]),
                  ),
                  const SizedBox(height: 40),
                  _buildRoleButton(
                    context,
                    "Pelajar",
                    Icons.person,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginPage()),
                    ),
                  ),
                  const SizedBox(height: 15),
                  _buildRoleButton(
                    context,
                    "Mentor",
                    Icons.school,
                    () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const LoginMentor()),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Debug button - Remove before production
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const DebugAccountManager()),
                    ),
                    icon: Icon(Icons.bug_report, color: Colors.grey[600]),
                    label: Text(
                      '🔧 Test Account Manager',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  // Restore button - Emergency use only
                  TextButton.icon(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (context) => const FirebaseRestoreUtility()),
                    ),
                    icon: Icon(Icons.restore, color: Colors.red[400]),
                    label: Text(
                      '🚨 Firebase Restore',
                      style: TextStyle(color: Colors.grey[600], fontSize: 12),
                    ),
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleButton(
    BuildContext context,
    String title,
    IconData icon,
    VoidCallback onTap,
  ) {
    return SizedBox(
      width: double.infinity,
      height: 60,
      child: ElevatedButton(
        onPressed: onTap,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: Colors.blue[700], size: 28),
            const SizedBox(width: 15),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                color: Colors.blue[700],
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
