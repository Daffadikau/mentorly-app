import 'package:firebase_auth/firebase_auth.dart';
import 'package:mentorly/security/secure_storage.dart';
import 'package:flutter/foundation.dart';

/// Enhanced session manager using Firebase Auth + Secure Storage
class SecureSessionManager {
  static const String _keyUserType = 'user_type';
  static const String _keyUserData = 'user_data';
  static const int _sessionTimeoutDays = 7;

  /// Save session after Firebase Auth login
  static Future<void> saveSession({
    required String userType,
    required Map<String, dynamic> userData,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('No authenticated user');
      }

      // Get ID token for API calls
      final idToken = await user.getIdToken();

      if (idToken != null) {
        // Save auth token to secure storage
        await SecureStorage.saveAuthTokens(
          accessToken: idToken,
          expiresIn: 3600, // Firebase tokens expire in 1 hour
        );
      }

      // Save user session data
      await SecureStorage.saveUserSession(
        userId: user.uid,
        userType: userType,
        userData: {
          ...userData,
          'email': user.email,
          'emailVerified': user.emailVerified,
          'lastLogin': DateTime.now().toIso8601String(),
        },
      );

      debugPrint('✅ Session saved for user: ${user.uid}');
    } catch (e) {
      debugPrint('❌ Error saving session: $e');
      rethrow;
    }
  }

  /// Validate session (check Firebase Auth state + token expiry)
  static Future<bool> validateSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        await logout();
        return false;
      }

      // Check if token is expired
      if (await SecureStorage.isSessionExpired()) {
        // Refresh token
        final idToken = await user.getIdToken(true); // Force refresh
        if (idToken != null) {
          await SecureStorage.saveAuthTokens(
            accessToken: idToken,
            expiresIn: 3600,
          );
        }
      }

      // Verify local cache matches Firebase Auth state
      final userType = await SecureStorage.getUserType();
      return userType != null;
    } catch (e) {
      debugPrint('❌ Session validation failed: $e');
      return false;
    }
  }

  /// Get user data from secure storage
  static Future<Map<String, dynamic>?> getUserData() async {
    return await SecureStorage.getUserData();
  }

  /// Get Firebase Auth user ID
  static String? getUserId() {
    return FirebaseAuth.instance.currentUser?.uid;
  }

  /// Get user type
  static Future<String?> getUserType() async {
    return await SecureStorage.getUserType();
  }

  /// Check if logged in
  static Future<bool> isLoggedIn() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    return await validateSession();
  }

  /// Logout (Firebase Auth + secure storage)
  static Future<void> logout() async {
    try {
      // Sign out from Firebase
      await FirebaseAuth.instance.signOut();

      // Clear secure storage
      await SecureStorage.clearSession();

      debugPrint('✅ User logged out successfully');
    } catch (e) {
      debugPrint('❌ Error during logout: $e');
      rethrow;
    }
  }

  /// Refresh session and get fresh token
  static Future<String?> refreshSession() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) return null;

      // Force refresh Firebase token
      final idToken = await user.getIdToken(true);

      if (idToken != null) {
        await SecureStorage.saveAuthTokens(
          accessToken: idToken,
          expiresIn: 3600,
        );
      }

      // Reload user data
      await user.reload();

      debugPrint('✅ Session refreshed');
      return idToken;
    } catch (e) {
      debugPrint('❌ Error refreshing session: $e');
      return null;
    }
  }

  /// Get current auth token for API calls
  static Future<String?> getAuthToken() async {
    try {
      // Check if token is expired
      if (await SecureStorage.isSessionExpired()) {
        return await refreshSession();
      }

      return await SecureStorage.getAccessToken();
    } catch (e) {
      debugPrint('❌ Error getting auth token: $e');
      return null;
    }
  }

  /// Re-authenticate user before sensitive operations
  static Future<bool> reauthenticate(String password) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null || user.email == null) return false;

      final credential = EmailAuthProvider.credential(
        email: user.email!,
        password: password,
      );

      await user.reauthenticateWithCredential(credential);
      debugPrint('✅ User reauthenticated');
      return true;
    } catch (e) {
      debugPrint('❌ Reauthentication failed: $e');
      return false;
    }
  }

  /// Check if email is verified
  static Future<bool> isEmailVerified() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    await user.reload();
    return user.emailVerified;
  }

  /// Send email verification
  static Future<void> sendEmailVerification() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user != null && !user.emailVerified) {
        await user.sendEmailVerification();
        debugPrint('✅ Verification email sent');
      }
    } catch (e) {
      debugPrint('❌ Error sending verification email: $e');
      rethrow;
    }
  }

  /// Update user profile
  static Future<void> updateProfile({
    String? displayName,
    String? photoURL,
  }) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      await user.updateDisplayName(displayName);
      if (photoURL != null) {
        await user.updatePhotoURL(photoURL);
      }

      debugPrint('✅ Profile updated');
    } catch (e) {
      debugPrint('❌ Error updating profile: $e');
      rethrow;
    }
  }

  /// Delete account
  static Future<void> deleteAccount(String password) async {
    try {
      // Re-authenticate before deletion
      if (!await reauthenticate(password)) {
        throw Exception('Authentication required');
      }

      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('No authenticated user');

      // Delete user from Firebase Auth
      await user.delete();

      // Clear local data
      await SecureStorage.clearAll();

      debugPrint('✅ Account deleted');
    } catch (e) {
      debugPrint('❌ Error deleting account: $e');
      rethrow;
    }
  }

  /// Check password strength
  static bool isPasswordStrong(String password) {
    // At least 8 characters, 1 uppercase, 1 lowercase, 1 number, 1 special char
    final regex = RegExp(
      r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
    );
    return regex.hasMatch(password);
  }

  /// Monitor auth state changes
  static Stream<User?> get authStateChanges {
    return FirebaseAuth.instance.authStateChanges();
  }

  /// Get time until token expires
  static Future<Duration?> getTimeUntilExpiry() async {
    try {
      final expiryStr = await SecureStorage.readEncrypted('session_expiry');
      if (expiryStr == null) return null;

      final expiry = DateTime.parse(expiryStr);
      final now = DateTime.now();

      return expiry.isAfter(now) ? expiry.difference(now) : Duration.zero;
    } catch (e) {
      return null;
    }
  }
}
