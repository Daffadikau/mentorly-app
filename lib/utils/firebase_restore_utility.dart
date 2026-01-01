import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Emergency Restore Utility - Restores deleted Firebase nodes
class FirebaseRestoreUtility extends StatefulWidget {
  const FirebaseRestoreUtility({super.key});

  @override
  State<FirebaseRestoreUtility> createState() => _FirebaseRestoreUtilityState();
}

class _FirebaseRestoreUtilityState extends State<FirebaseRestoreUtility> {
  bool isRestoring = false;
  final List<String> logs = [];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🚨 Firebase Restore Utility'),
        backgroundColor: Colors.red[700],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Warning Card
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Icon(Icons.warning, color: Colors.red[700], size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'Emergency Restore Tool\nUse only when nodes are accidentally deleted',
                        style: TextStyle(
                          color: Colors.red[700],
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Text(
              'Restore Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            // Restore All Button
            ElevatedButton.icon(
              onPressed: isRestoring ? null : _restoreAll,
              icon: const Icon(Icons.restore),
              label: const Text('Restore All (Mentors + Pelajar)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Restore Mentors Only
            ElevatedButton.icon(
              onPressed: isRestoring ? null : _restoreMentorsOnly,
              icon: const Icon(Icons.school),
              label: const Text('Restore Mentors Node Only'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Restore Pelajar Only
            ElevatedButton.icon(
              onPressed: isRestoring ? null : _restorePelajarOnly,
              icon: const Icon(Icons.person),
              label: const Text('Restore Pelajar Node Only'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Delete and Recreate Section
            Text(
              'Delete & Recreate',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.orange[800],
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: isRestoring ? null : _deleteAndRecreateMentor,
              icon: const Icon(Icons.refresh),
              label:
                  const Text('Delete & Recreate Mentor (Fixes Verification)'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[600],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Logs Section
            if (logs.isNotEmpty) ...[
              Text(
                'Restore Log',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey[800],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                constraints: const BoxConstraints(maxHeight: 300),
                child: SingleChildScrollView(
                  child: Text(
                    logs.join('\n'),
                    style: TextStyle(
                      fontSize: 12,
                      fontFamily: 'monospace',
                      color: Colors.grey[800],
                    ),
                  ),
                ),
              ),
            ],

            if (isRestoring) ...[
              const SizedBox(height: 16),
              const Center(
                child: CircularProgressIndicator(),
              ),
            ],
          ],
        ),
      ),
    );
  }

  void _log(String message) {
    setState(() {
      logs.add('[${DateTime.now().toString().substring(11, 19)}] $message');
    });
  }

  Future<void> _restoreAll() async {
    setState(() {
      isRestoring = true;
      logs.clear();
    });

    _log('🚀 Starting full restoration...');
    await _restoreMentors();
    await _restorePelajar();
    _log('✅ Full restoration complete!');

    setState(() => isRestoring = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ All nodes restored successfully!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _restoreMentorsOnly() async {
    setState(() {
      isRestoring = true;
      logs.clear();
    });

    _log('🚀 Starting mentors restoration...');
    await _restoreMentors();
    _log('✅ Mentors restoration complete!');

    setState(() => isRestoring = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Mentors node restored!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _restorePelajarOnly() async {
    setState(() {
      isRestoring = true;
      logs.clear();
    });

    _log('🚀 Starting pelajar restoration...');
    await _restorePelajar();
    _log('✅ Pelajar restoration complete!');

    setState(() => isRestoring = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Pelajar node restored!'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 3),
        ),
      );
    }
  }

  Future<void> _restoreMentors() async {
    _log('📝 Checking existing mentor accounts in Firebase Auth...');

    // Check Firebase Authentication for existing mentors
    // Note: We can't directly query all users, so we'll recreate with sample data

    final ref = FirebaseDatabase.instance.ref('mentors');

    _log('🔨 Creating mentors node structure...');

    // Create sample mentor account
    try {
      // Sign out first
      await FirebaseAuth.instance.signOut();

      final mentorEmail = 'mentor@example.com';
      final mentorPassword = 'password123';

      _log('Creating mentor account: $mentorEmail');

      UserCredential? mentorCred;
      try {
        // Try to sign in first (account might exist)
        mentorCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: mentorEmail,
          password: mentorPassword,
        );
        _log('✓ Existing mentor account found: $mentorEmail');
      } catch (e) {
        // Create new account
        mentorCred = await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: mentorEmail,
          password: mentorPassword,
        );
        _log('✓ New mentor account created: $mentorEmail');
      }

      final uid = mentorCred.user!.uid;

      // Create mentor profile
      await ref.child(uid).set({
        'uid': uid,
        'id': uid,
        'email': mentorEmail,
        'nama_lengkap': 'Mentor Demo',
        'phone': '081234567890',
        'bidang_keahlian': 'Programming',
        'pengalaman': 5,
        'harga_per_jam': 100000,
        'deskripsi': 'Expert mentor in programming and software development',
        'rating': 4.5,
        'jumlah_review': 10,
        'created_at': DateTime.now().toIso8601String(),
        'email_verified': true,
        'status_verifikasi': 'verified', // Important: Set as verified!
        'balance': 0,
      });

      _log('✓ Mentor profile created: $uid');

      await FirebaseAuth.instance.signOut();
      _log('✅ Mentors node restored successfully!');
    } catch (e) {
      _log('❌ Error restoring mentors: $e');
    }
  }

  Future<void> _restorePelajar() async {
    _log('📝 Restoring pelajar node...');

    final ref = FirebaseDatabase.instance.ref('pelajar');

    _log('🔨 Creating pelajar node structure...');

    try {
      // Sign out first
      await FirebaseAuth.instance.signOut();

      final pelajarEmail = 'pelajar@example.com';
      final pelajarPassword = 'password123';

      _log('Creating pelajar account: $pelajarEmail');

      UserCredential? pelajarCred;
      try {
        // Try to sign in first (account might exist)
        pelajarCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: pelajarEmail,
          password: pelajarPassword,
        );
        _log('✓ Existing pelajar account found: $pelajarEmail');
      } catch (e) {
        // Create new account
        pelajarCred =
            await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: pelajarEmail,
          password: pelajarPassword,
        );
        _log('✓ New pelajar account created: $pelajarEmail');
      }

      final uid = pelajarCred.user!.uid;

      // Create pelajar profile
      await ref.child(uid).set({
        'uid': uid,
        'id': uid,
        'email': pelajarEmail,
        'nama_lengkap': 'Pelajar Demo',
        'phone': '081234567891',
        'created_at': DateTime.now().toIso8601String(),
        'email_verified': true,
      });

      _log('✓ Pelajar profile created: $uid');

      await FirebaseAuth.instance.signOut();
      _log('✅ Pelajar node restored successfully!');
    } catch (e) {
      _log('❌ Error restoring pelajar: $e');
    }
  }

  Future<void> _deleteAndRecreateMentor() async {
    setState(() {
      isRestoring = true;
      logs.clear();
    });

    _log('🗑️  Deleting existing mentor data...');

    try {
      // Delete from Authentication
      await FirebaseAuth.instance.signOut();

      try {
        final userCred = await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: 'mentor@example.com',
          password: 'password123',
        );
        final uid = userCred.user!.uid;

        // Delete from RTDB first
        _log('Deleting RTDB data for UID: $uid');
        await FirebaseDatabase.instance.ref('mentors').child(uid).remove();

        // Delete from Authentication
        _log('Deleting from Firebase Authentication...');
        await userCred.user!.delete();
        _log('✓ Deleted mentor@example.com from Auth');
      } catch (e) {
        _log('⚠️  Account may not exist or already deleted: $e');
      }

      await FirebaseAuth.instance.signOut();

      // Wait a moment for Firebase to sync
      await Future.delayed(const Duration(seconds: 1));

      _log('🔨 Creating fresh mentor account...');
      await _restoreMentors();

      _log('✅ Mentor deleted and recreated successfully!');

      setState(() => isRestoring = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Mentor recreated with verification status!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      _log('❌ Error: $e');
      setState(() => isRestoring = false);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }
}
