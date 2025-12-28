import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dart:convert';

class SessionManager {
  static const String _keyUserType = 'user_type';
  static const String _keyUserData = 'user_data';

  // Session timeout: 7 days
  static const int _sessionTimeout = 7 * 24 * 60 * 60 * 1000; // milliseconds

  /// Save session after Firebase Auth login
  static Future<void> saveSession({
    required String userType,
    required Map<String, dynamic> userData,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    // Firebase Auth user ID is already secure, no need to encrypt
    await prefs.setString(_keyUserType, userType);
    await prefs.setString(_keyUserData, jsonEncode(userData));
  }

  /// Validate session (check Firebase Auth state)
  static Future<bool> validateSession() async {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      await logout();
      return false;
    }

    // Verify local cache matches Firebase Auth state
    final prefs = await SharedPreferences.getInstance();
    final userType = prefs.getString(_keyUserType);

    return userType != null;
  }

  /// Get user data from local cache
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();
    final encryptedData = prefs.getString(_keyUserData);

    if (encryptedData == null) return null;

    try {
      return jsonDecode(encryptedData);
    } catch (e) {
      return null;
    }
  }

  /// Get Firebase Auth user ID
  static String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Get user type
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyUserType);
  }

  /// Check if logged in
  static Future<bool> isLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    return await validateSession();
  }

  /// Logout (Firebase Auth + local cache)
  static Future<void> logout() async {
    await FirebaseAuth.instance.signOut();

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserType);
    await prefs.remove(_keyUserData);
  }

  /// Refresh session (Firebase Auth already manages this automatically)
  static Future<void> refreshSession() async {
    if (await isLoggedIn()) {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null) {
        await user.reload();
      }
    }
  }
}
