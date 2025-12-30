import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Secure storage wrapper for sensitive data
/// Uses platform-specific secure storage (Keychain on iOS, Keystore on Android)
class SecureStorage {
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(
      encryptedSharedPreferences: true,
      resetOnError: true,
    ),
    iOptions: IOSOptions(
      accessibility: KeychainAccessibility.first_unlock,
    ),
  );

  // Keys for stored data
  static const _keyAccessToken = 'access_token';
  static const _keyRefreshToken = 'refresh_token';
  static const _keyUserId = 'user_id';
  static const _keyUserType = 'user_type';
  static const _keyUserData = 'user_data';
  static const _keySessionExpiry = 'session_expiry';
  static const _keyDeviceId = 'device_id';
  static const _keyEncryptionKey = 'encryption_key';

  /// Generate a unique device identifier
  static Future<String> _getDeviceId() async {
    String? deviceId = await _storage.read(key: _keyDeviceId);
    return deviceId;
  }

  /// Generate random string for IDs
  static String _generateRandomString(int length) {
    final random = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode(random);
    return sha256.convert(bytes).toString().substring(0, length);
  }

  /// Save authentication tokens
  static Future<void> saveAuthTokens({
    required String accessToken,
    String? refreshToken,
    required int expiresIn, // seconds
  }) async {
    try {
      final expiry = DateTime.now().add(Duration(seconds: expiresIn));

      await Future.wait([
        _storage.write(key: _keyAccessToken, value: accessToken),
        if (refreshToken != null)
          _storage.write(key: _keyRefreshToken, value: refreshToken),
        _storage.write(key: _keySessionExpiry, value: expiry.toIso8601String()),
      ]);

      debugPrint('✅ Auth tokens saved securely');
    } catch (e) {
      debugPrint('❌ Error saving auth tokens: $e');
      rethrow;
    }
  }

  /// Get access token
  static Future<String?> getAccessToken() async {
    try {
      // Check if token is expired
      if (await isSessionExpired()) {
        debugPrint('⚠️ Session expired');
        return null;
      }
      return await _storage.read(key: _keyAccessToken);
    } catch (e) {
      debugPrint('❌ Error reading access token: $e');
      return null;
    }
  }

  /// Get refresh token
  static Future<String?> getRefreshToken() async {
    try {
      return await _storage.read(key: _keyRefreshToken);
    } catch (e) {
      debugPrint('❌ Error reading refresh token: $e');
      return null;
    }
  }

  /// Check if session is expired
  static Future<bool> isSessionExpired() async {
    try {
      final expiryStr = await _storage.read(key: _keySessionExpiry);
      if (expiryStr == null) return true;

      final expiry = DateTime.parse(expiryStr);
      // Add 5 minute buffer
      return DateTime.now()
          .isAfter(expiry.subtract(const Duration(minutes: 5)));
    } catch (e) {
      debugPrint('❌ Error checking session expiry: $e');
      return true;
    }
  }

  /// Save user session data
  static Future<void> saveUserSession({
    required String userId,
    required String userType,
    required Map<String, dynamic> userData,
  }) async {
    try {
      await Future.wait([
        _storage.write(key: _keyUserId, value: userId),
        _storage.write(key: _keyUserType, value: userType),
        _storage.write(key: _keyUserData, value: jsonEncode(userData)),
      ]);

      debugPrint('✅ User session saved securely');
    } catch (e) {
      debugPrint('❌ Error saving user session: $e');
      rethrow;
    }
  }

  /// Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    try {
      final data = await _storage.read(key: _keyUserData);
      if (data == null) return null;
      return jsonDecode(data) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('❌ Error reading user data: $e');
      return null;
    }
  }

  /// Get user ID
  static Future<String?> getUserId() async {
    return await _storage.read(key: _keyUserId);
  }

  /// Get user type
  static Future<String?> getUserType() async {
    return await _storage.read(key: _keyUserType);
  }

  /// Check if user is logged in
  static Future<bool> isLoggedIn() async {
    final accessToken = await getAccessToken();
    final userId = await getUserId();
    return accessToken != null && userId != null && !await isSessionExpired();
  }

  /// Clear all session data (logout)
  static Future<void> clearSession() async {
    try {
      await Future.wait([
        _storage.delete(key: _keyAccessToken),
        _storage.delete(key: _keyRefreshToken),
        _storage.delete(key: _keyUserId),
        _storage.delete(key: _keyUserType),
        _storage.delete(key: _keyUserData),
        _storage.delete(key: _keySessionExpiry),
      ]);

      debugPrint('✅ Session cleared');
    } catch (e) {
      debugPrint('❌ Error clearing session: $e');
      rethrow;
    }
  }

  /// Clear ALL data (including device ID)
  static Future<void> clearAll() async {
    try {
      await _storage.deleteAll();
      debugPrint('✅ All secure storage cleared');
    } catch (e) {
      debugPrint('❌ Error clearing all data: $e');
      rethrow;
    }
  }

  /// Store encrypted sensitive data
  static Future<void> writeEncrypted(String key, String value) async {
    try {
      await _storage.write(key: key, value: value);
    } catch (e) {
      debugPrint('❌ Error writing encrypted data: $e');
      rethrow;
    }
  }

  /// Read encrypted sensitive data
  static Future<String?> readEncrypted(String key) async {
    try {
      return await _storage.read(key: key);
    } catch (e) {
      debugPrint('❌ Error reading encrypted data: $e');
      return null;
    }
  }

  /// Delete specific key
  static Future<void> delete(String key) async {
    try {
      await _storage.delete(key: key);
    } catch (e) {
      debugPrint('❌ Error deleting key: $e');
      rethrow;
    }
  }

  /// Check if contains key
  static Future<bool> containsKey(String key) async {
    try {
      final value = await _storage.read(key: key);
      return value != null;
    } catch (e) {
      debugPrint('❌ Error checking key: $e');
      return false;
    }
  }

  /// Get all keys (for debugging only, not for production)
  static Future<Map<String, String>> getAllData() async {
    if (kReleaseMode) {
      throw Exception('getAllData() is not allowed in release mode');
    }
    try {
      return await _storage.readAll();
    } catch (e) {
      debugPrint('❌ Error reading all data: $e');
      return {};
    }
  }
}
