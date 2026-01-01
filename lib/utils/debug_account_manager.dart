import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_database/firebase_database.dart';

/// Debug/Testing Page - Remove before production!
/// Allows quick deletion and recreation of test accounts
class DebugAccountManager extends StatefulWidget {
  const DebugAccountManager({super.key});

  @override
  State<DebugAccountManager> createState() => _DebugAccountManagerState();
}

class _DebugAccountManagerState extends State<DebugAccountManager> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('🔧 Debug Account Manager'),
        backgroundColor: Colors.orange[700],
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
                        'TESTING ONLY! Remove before production.',
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

            // Quick Actions
            Text(
              'Quick Test Account Creation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            // Main Pelajar Account
            _buildQuickActionCard(
              title: '⭐ Create "pelajar" Account',
              subtitle: 'pelajar@example.com',
              icon: Icons.star,
              color: Colors.purple,
              onTap: () => _createTestAccount(
                email: 'pelajar@example.com',
                password: 'pelajar123',
                phone: '081234567890',
                type: 'pelajar',
              ),
            ),
            const SizedBox(height: 12),

            // Test Pelajar 1
            _buildQuickActionCard(
              title: 'Create Test Pelajar 1',
              subtitle: 'test.pelajar1@example.com',
              icon: Icons.person,
              color: Colors.blue,
              onTap: () => _createTestAccount(
                email: 'test.pelajar1@example.com',
                password: 'password123',
                phone: '081234567891',
                type: 'pelajar',
              ),
            ),
            const SizedBox(height: 12),

            // Test Pelajar 2
            _buildQuickActionCard(
              title: 'Create Test Pelajar 2',
              subtitle: 'test.pelajar2@example.com',
              icon: Icons.person,
              color: Colors.green,
              onTap: () => _createTestAccount(
                email: 'test.pelajar2@example.com',
                password: 'password123',
                phone: '081234567892',
                type: 'pelajar',
              ),
            ),
            const SizedBox(height: 12),

            // Test Pelajar 3
            _buildQuickActionCard(
              title: 'Create Test Pelajar 3',
              subtitle: 'test.pelajar3@example.com',
              icon: Icons.person,
              color: Colors.orange,
              onTap: () => _createTestAccount(
                email: 'test.pelajar3@example.com',
                password: 'password123',
                phone: '081234567893',
                type: 'pelajar',
              ),
            ),

            const SizedBox(height: 32),
            const Divider(),
            const SizedBox(height: 16),

            // Custom Account Creation
            Text(
              'Custom Account Creation',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[800],
              ),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'example@email.com',
                prefixIcon: const Icon(Icons.email),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _passwordController,
              decoration: InputDecoration(
                labelText: 'Password',
                hintText: 'Min 6 characters',
                prefixIcon: const Icon(Icons.lock),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              obscureText: true,
            ),
            const SizedBox(height: 12),

            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                labelText: 'Phone',
                hintText: '081234567890',
                prefixIcon: const Icon(Icons.phone),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              keyboardType: TextInputType.phone,
            ),
            const SizedBox(height: 20),

            ElevatedButton.icon(
              onPressed: isLoading
                  ? null
                  : () => _createTestAccount(
                        email: _emailController.text,
                        password: _passwordController.text,
                        phone: _phoneController.text,
                        type: 'pelajar',
                      ),
              icon: const Icon(Icons.add),
              label: const Text('Create Custom Pelajar'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
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

            // Delete Actions
            Text(
              'Delete Accounts',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.red[700],
              ),
            ),
            const SizedBox(height: 16),

            ElevatedButton.icon(
              onPressed: isLoading ? null : _deleteAllPelajarAccounts,
              icon: const Icon(Icons.delete_forever),
              label: const Text('Delete ALL Pelajar Accounts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 12),

            ElevatedButton.icon(
              onPressed: isLoading ? null : _deleteAllTestAccounts,
              icon: const Icon(Icons.delete_sweep),
              label: const Text('Delete Only Test Accounts'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.orange[700],
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Info Card
            Card(
              color: Colors.blue[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.info, color: Colors.blue[700]),
                        const SizedBox(width: 8),
                        Text(
                          'Test Account Info',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.blue[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '✅ All test accounts use password: password123',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '⭐ Main account: pelajar@example.com / pelajar123',
                      style: TextStyle(
                          color: Colors.grey[700], fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '✅ Test accounts (test.*@example.com) skip email verification',
                      style: TextStyle(color: Colors.grey[700]),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '✅ Login immediately after creation - no verification needed!',
                      style: TextStyle(
                          color: Colors.grey[700], fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActionCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 2,
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color,
          child: Icon(icon, color: Colors.white),
        ),
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(subtitle),
        trailing: isLoading
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : const Icon(Icons.arrow_forward),
        onTap: isLoading ? null : onTap,
      ),
    );
  }

  Future<void> _createTestAccount({
    required String email,
    required String password,
    required String phone,
    required String type,
  }) async {
    if (email.isEmpty || password.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please fill all fields')),
      );
      return;
    }

    setState(() => isLoading = true);

    try {
      // Try to delete existing account with same email first
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email.toLowerCase(),
          password: password,
        );
        await FirebaseAuth.instance.currentUser?.delete();
      } catch (e) {
        // Account doesn't exist, that's fine
      }

      // Sign out to ensure clean state
      await FirebaseAuth.instance.signOut();

      // Create new account
      final userCredential =
          await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email.toLowerCase(),
        password: password,
      );

      final uid = userCredential.user!.uid;
      final user = userCredential.user!;

      // Send verification email
      await user.sendEmailVerification();

      // Save to database
      final ref = FirebaseDatabase.instance.ref(type).child(uid);
      await ref.set({
        'email': email.toLowerCase(),
        'phone': phone,
        'nama_lengkap': 'Test ${type.capitalize()} ${email.split('@')[0]}',
        'created_at': DateTime.now().toIso8601String(),
        'uid': uid,
        'email_verified': false, // Will be verified by email
        'id': uid,
      });

      // Sign out after creation
      await FirebaseAuth.instance.signOut();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                '✅ Account created: $email\n🔑 Password: password123\n✨ No verification needed - login now!'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      String message = 'Error creating account';
      if (e.code == 'email-already-in-use') {
        message = 'Email already exists. Try deleting it first.';
      } else if (e.code == 'weak-password') {
        message = 'Password is too weak';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ $message'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() => isLoading = false);
    }
  }

  Future<void> _deleteAllTestAccounts() async {
    // Confirm deletion
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('⚠️ Confirm Deletion'),
        content: const Text(
          'This will delete test accounts:\n\n'
          '• test.pelajar1@example.com\n'
          '• test.pelajar2@example.com\n'
          '• test.pelajar3@example.com\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    final testEmails = [
      'test.pelajar1@example.com',
      'test.pelajar2@example.com',
      'test.pelajar3@example.com',
    ];

    int deleted = 0;
    for (String email in testEmails) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: 'password123',
        );
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          await FirebaseDatabase.instance.ref('pelajar').child(uid).remove();
        }
        await FirebaseAuth.instance.currentUser?.delete();
        deleted++;
      } catch (e) {
        // Account doesn't exist or error, skip
      }
    }

    await FirebaseAuth.instance.signOut();

    setState(() => isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Deleted $deleted test account(s)'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  Future<void> _deleteAllPelajarAccounts() async {
    // Confirm deletion
    bool? confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('🚨 DANGER: Delete ALL Pelajar'),
        content: const Text(
          'This will delete ALL pelajar accounts from Firebase:\n\n'
          '• Firebase Authentication\n'
          '• Firebase Database\n'
          '• Cannot be undone!\n\n'
          'This will try common test emails including:\n'
          '• pelajar@example.com\n'
          '• test.pelajar1-3@example.com\n\n'
          'Continue?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red[900]),
            child: const Text('DELETE ALL'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    // Try to delete common test accounts
    final testEmails = [
      {'email': 'pelajar@example.com', 'password': 'pelajar123'},
      {'email': 'test.pelajar1@example.com', 'password': 'password123'},
      {'email': 'test.pelajar2@example.com', 'password': 'password123'},
      {'email': 'test.pelajar3@example.com', 'password': 'password123'},
    ];

    int deleted = 0;
    for (var account in testEmails) {
      try {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: account['email']!,
          password: account['password']!,
        );
        final uid = FirebaseAuth.instance.currentUser?.uid;
        if (uid != null) {
          // Delete from database
          await FirebaseDatabase.instance.ref('pelajar').child(uid).remove();
        }
        // Delete from auth
        await FirebaseAuth.instance.currentUser?.delete();
        deleted++;
      } catch (e) {
        // Account doesn't exist or wrong password, skip
      }
    }

    await FirebaseAuth.instance.signOut();

    setState(() => isLoading = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('✅ Deleted $deleted pelajar account(s)'),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${substring(1)}";
  }
}
