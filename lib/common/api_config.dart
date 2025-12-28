import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Use 10.0.2.2 for Android Emulator to access host machine's localhost
  // Use your machine's LAN IP (e.g., 192.168.1.x) for physical devices
  static String get baseUrl {
    if (kReleaseMode) {
      return "https://your-production-server.com/mentorly";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:8080/mentorly";
    } else {
      return "http://localhost:8080/mentorly";
    }
  }

  static String getUrl(String endpoint) => "$baseUrl/$endpoint";
}
