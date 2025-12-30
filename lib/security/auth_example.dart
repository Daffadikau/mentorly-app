import 'package:flutter/material.dart';
import 'package:mentorly/security/api_client.dart';
import 'package:mentorly/security/secure_session_manager.dart';

/// Example usage of secure authentication
class SecureAuthExample {
  final SecureApiClient _client = SecureApiClient();

  /// Login example
  Future<bool> login(String email, String password) async {
    try {
      final response = await _client.post(
        '/api/auth/login',
        data: {
          'email': email,
          'password': password,
        },
      );

      if (response.statusCode == 200) {
        final data = response.data;

        // Save session
        await SecureSessionManager.saveSession(
          userType: data['user_type'],
          userData: data['user'],
        );

        debugPrint('✅ Login successful');
        return true;
      }

      return false;
    } on ApiException catch (e) {
      debugPrint('❌ Login failed: ${e.message}');
      return false;
    }
  }

  /// Fetch protected data example
  Future<Map<String, dynamic>?> fetchUserProfile() async {
    try {
      final response = await _client.get('/api/user/profile');

      if (response.statusCode == 200) {
        return response.data as Map<String, dynamic>;
      }

      return null;
    } on ApiException catch (e) {
      debugPrint('❌ Error fetching profile: ${e.message}');

      if (e.isUnauthorized) {
        // Handle unauthorized - redirect to login
        await SecureSessionManager.logout();
      }

      return null;
    }
  }

  /// Update profile example
  Future<bool> updateProfile(Map<String, dynamic> data) async {
    try {
      final response = await _client.put(
        '/api/user/profile',
        data: data,
      );

      return response.statusCode == 200;
    } on ApiException catch (e) {
      debugPrint('❌ Error updating profile: ${e.message}');
      return false;
    }
  }

  /// Logout example
  Future<void> logout() async {
    try {
      // Call logout API
      await _client.post('/api/auth/logout');
    } catch (e) {
      debugPrint('⚠️ Logout API call failed: $e');
    } finally {
      // Always clear local session
      await SecureSessionManager.logout();
    }
  }

  /// Check authentication status
  Future<bool> isAuthenticated() async {
    return await SecureSessionManager.isLoggedIn();
  }

  /// Get current user data
  Future<Map<String, dynamic>?> getCurrentUser() async {
    return await SecureSessionManager.getUserData();
  }
}
