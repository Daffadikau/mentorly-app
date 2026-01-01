import 'package:flutter/material.dart';
import '../utils/manual_verify_mentor.dart';

/// Debug page for manually verifying mentors
/// Add this to your app temporarily for debugging
///
/// To use: Navigate to this page from anywhere in your app
class DebugVerifyMentorPage extends StatefulWidget {
  const DebugVerifyMentorPage({super.key});

  @override
  State<DebugVerifyMentorPage> createState() => _DebugVerifyMentorPageState();
}

class _DebugVerifyMentorPageState extends State<DebugVerifyMentorPage> {
  final TextEditingController _uidController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  String _output = '';
  bool _isLoading = false;

  void _updateOutput(String message) {
    setState(() {
      _output += '$message\n';
    });
  }

  Future<void> _verifyByUid() async {
    if (_uidController.text.isEmpty) {
      _updateOutput('❌ Please enter a UID');
      return;
    }

    setState(() {
      _isLoading = true;
      _output = '';
    });

    await ManualVerifyMentor.verifyMentorByUid(_uidController.text.trim());

    setState(() {
      _isLoading = false;
    });

    _updateOutput('✅ Operation completed - check console for details');
  }

  Future<void> _verifyByEmail() async {
    if (_emailController.text.isEmpty) {
      _updateOutput('❌ Please enter an email');
      return;
    }

    setState(() {
      _isLoading = true;
      _output = '';
    });

    await ManualVerifyMentor.verifyMentorByEmail(_emailController.text.trim());

    setState(() {
      _isLoading = false;
    });

    _updateOutput('✅ Operation completed - check console for details');
  }

  Future<void> _listAllMentors() async {
    setState(() {
      _isLoading = true;
      _output = 'Loading mentors...\n';
    });

    await ManualVerifyMentor.listAllMentors();

    setState(() {
      _isLoading = false;
    });

    _updateOutput('✅ Check console for full mentor list');
  }

  Future<void> _verifyCurrentUser() async {
    setState(() {
      _isLoading = true;
      _output = '';
    });

    await ManualVerifyMentor.verifyCurrentUser();

    setState(() {
      _isLoading = false;
    });

    _updateOutput('✅ Operation completed - check console for details');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Debug: Verify Mentor'),
        backgroundColor: Colors.orange,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const Card(
              color: Colors.orange,
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    Icon(Icons.warning, color: Colors.white, size: 40),
                    SizedBox(height: 8),
                    Text(
                      '⚠️ DEBUG TOOL ONLY',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'This page is for debugging only. Remove before production.',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Verify by UID
            const Text(
              'Verify by UID',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _uidController,
              decoration: const InputDecoration(
                labelText: 'Mentor UID',
                hintText: 'Enter Firebase Auth UID',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _verifyByUid,
              icon: const Icon(Icons.check_circle),
              label: const Text('Verify by UID'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const Divider(height: 40),

            // Verify by Email
            const Text(
              'Verify by Email',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                labelText: 'Mentor Email',
                hintText: 'Enter mentor email',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _verifyByEmail,
              icon: const Icon(Icons.email),
              label: const Text('Verify by Email'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const Divider(height: 40),

            // Other actions
            const Text(
              'Other Actions',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _listAllMentors,
              icon: const Icon(Icons.list),
              label: const Text('List All Mentors'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(
              onPressed: _isLoading ? null : _verifyCurrentUser,
              icon: const Icon(Icons.person_add),
              label: const Text('Verify Currently Logged In User'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.teal,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.all(16),
              ),
            ),

            const Divider(height: 40),

            // Output area
            if (_output.isNotEmpty) ...[
              const Text(
                'Output',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[200],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _output,
                  style: const TextStyle(fontFamily: 'monospace'),
                ),
              ),
            ],

            if (_isLoading)
              const Padding(
                padding: EdgeInsets.all(16),
                child: Center(child: CircularProgressIndicator()),
              ),

            const SizedBox(height: 24),
            Card(
              color: Colors.blue[50],
              child: const Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '💡 Tips:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 8),
                    Text('• Check Flutter console for detailed output'),
                    Text('• UID is the Firebase Auth user ID'),
                    Text('• Email must match exactly (case-insensitive)'),
                    Text('• This directly updates Firebase Realtime Database'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _uidController.dispose();
    _emailController.dispose();
    super.dispose();
  }
}
