import 'dart:io';
import 'package:flutter/foundation.dart';

class ApiConfig {
  // Use 10.0.2.2 for Android Emulator to access host machine's localhost
  // Use your machine's LAN IP (e.g., 192.168.1.x) for physical devices
  static String get baseUrl {
    if (kReleaseMode) {
      return "https://your-production-server.com/mentorly";
    } else if (Platform.isAndroid) {
      return "http://10.0.2.2:8888/mentorly";
    } else {
      // Physical iOS devices cannot reach your Mac via "localhost".
      // Use the Mac's LAN IP for device testing.
      return "http://192.168.1.6:8888/mentorly";
    }
  }

  static String getUrl(String endpoint) => "$baseUrl/$endpoint";
}
