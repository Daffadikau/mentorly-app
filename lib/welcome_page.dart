import 'package:flutter/material.dart';
import 'login_pelajar.dart';
import 'login_mentor.dart';
import 'login_admin.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.blue[700],
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(30),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(40),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: Image.asset(
                    'assets/images/logodoang.png',
                    width: 100,
                    height: 100,
                  ),
                ),
                const SizedBox(height: 40),
                const Text(
                  "Selamat Datang di Mentorly",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  "Siapa untuk naik level?\nDaftar Mentorly sekarang!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 16, color: Colors.white70),
                ),
                const SizedBox(height: 50),
                _buildRoleButton(
                  context,
                  "Pelajar",
                  Icons.person,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginPage()),
                  ),
                ),
                const SizedBox(height: 15),
                _buildRoleButton(
                  context,
                  "Mentor",
                  Icons.school,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginMentor()),
                  ),
                ),
                const SizedBox(height: 15),
                _buildRoleButton(
                  context,
                  "Admin",
                  Icons.admin_panel_settings,
                  () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => LoginAdmin()),
                  ),
                ),
              ],
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
