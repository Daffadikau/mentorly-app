import 'package:flutter/foundation.dart';

// PHP backend removed - App now uses Firebase only
// This class is kept for backward compatibility but returns empty strings
class ApiConfig {
  static String get baseUrl {
    // No longer using PHP backend
    return "";
  }

  static String getUrl(String endpoint) {
    // PHP backend disabled - all features now use Firebase
    print("⚠️ Warning: Attempted to call PHP endpoint: $endpoint (PHP backend removed)");
    return "";
  }
}
