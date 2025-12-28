import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:crypto/crypto.dart';

class SessionManager {
  static const String _keyUserId = 'user_id';
  static const String _keyUserType = 'user_type';
  static const String _keyUserData = 'user_data';
  static const String _keyLoginTime = 'login_time';
  static const String _keySessionToken = 'session_token';

  // Session timeout: 7 days
  static const int _sessionTimeout = 7 * 24 * 60 * 60 * 1000; // milliseconds

  // Simple encryption key (dalam production, gunakan key management yang proper)
  static const String _encryptionSalt = 'mentorly_salt_2024';

  /// Enkripsi data sederhana menggunakan Base64 dan hash
  static String _encryptData(String data) {
    var bytes = utf8.encode(data + _encryptionSalt);
    var digest = sha256.convert(bytes);
    return '${base64Encode(utf8.encode(data))}:$digest';
  }

  /// Dekripsi data
  static String? _decryptData(String encryptedData) {
    try {
      var parts = encryptedData.split(':');
      if (parts.length != 2) return null;

      var data = utf8.decode(base64Decode(parts[0]));
      var expectedHash = parts[1];

      var bytes = utf8.encode(data + _encryptionSalt);
      var actualHash = sha256.convert(bytes).toString();

      if (expectedHash == actualHash) {
        return data;
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Generate session token
  static String _generateSessionToken(String userId, String userType) {
    var timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    var data = '$userId:$userType:$timestamp:$_encryptionSalt';
    return sha256.convert(utf8.encode(data)).toString();
  }

  /// Simpan session dengan enkripsi
  static Future<void> saveSession({
    String? userId,
    required String userType,
    required Map<String, dynamic> userData,
  }) async {
    // Ambil userId dari userData jika tidak disediakan
    userId ??= userData['id']?.toString();

    if (userId == null) {
      throw Exception('User ID is required');
    }
    final prefs = await SharedPreferences.getInstance();

    var sessionToken = _generateSessionToken(userId, userType);
    var loginTime = DateTime.now().millisecondsSinceEpoch;

    await prefs.setString(_keyUserId, _encryptData(userId));
    await prefs.setString(_keyUserType, _encryptData(userType));
    await prefs.setString(_keyUserData, _encryptData(jsonEncode(userData)));
    await prefs.setInt(_keyLoginTime, loginTime);
    await prefs.setString(_keySessionToken, sessionToken);
  }

  /// Validasi session
  static Future<bool> validateSession() async {
    final prefs = await SharedPreferences.getInstance();

    var loginTime = prefs.getInt(_keyLoginTime);
    if (loginTime == null) return false;

    // Check timeout
    var currentTime = DateTime.now().millisecondsSinceEpoch;
    if (currentTime - loginTime > _sessionTimeout) {
      await logout();
      return false;
    }

    // Validate data exists
    var userId = prefs.getString(_keyUserId);
    var userType = prefs.getString(_keyUserType);
    var sessionToken = prefs.getString(_keySessionToken);

    if (userId == null || userType == null || sessionToken == null) {
      return false;
    }

    // Decrypt and validate
    var decryptedUserId = _decryptData(userId);
    var decryptedUserType = _decryptData(userType);

    if (decryptedUserId == null || decryptedUserType == null) {
      await logout();
      return false;
    }

    return true;
  }

  /// Get user data
  static Future<Map<String, dynamic>?> getUserData() async {
    final prefs = await SharedPreferences.getInstance();

    var encryptedData = prefs.getString(_keyUserData);
    if (encryptedData == null) return null;

    var decrypted = _decryptData(encryptedData);
    if (decrypted == null) return null;

    try {
      return jsonDecode(decrypted);
    } catch (e) {
      return null;
    }
  }

  /// Get user ID
  static Future<String?> getUserId() async {
    final prefs = await SharedPreferences.getInstance();
    var encrypted = prefs.getString(_keyUserId);
    return encrypted != null ? _decryptData(encrypted) : null;
  }

  /// Get user type
  static Future<String?> getUserType() async {
    final prefs = await SharedPreferences.getInstance();
    var encrypted = prefs.getString(_keyUserType);
    return encrypted != null ? _decryptData(encrypted) : null;
  }

  /// Check if logged in
  static Future<bool> isLoggedIn() async {
    return await validateSession();
  }

  /// Logout
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyUserId);
    await prefs.remove(_keyUserType);
    await prefs.remove(_keyUserData);
    await prefs.remove(_keyLoginTime);
    await prefs.remove(_keySessionToken);
  }

  /// Update login time (refresh session)
  static Future<void> refreshSession() async {
    if (await validateSession()) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLoginTime, DateTime.now().millisecondsSinceEpoch);
    }
  }
}
