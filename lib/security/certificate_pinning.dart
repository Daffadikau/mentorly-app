import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:crypto/crypto.dart';

/// Certificate pinning for secure HTTPS communication
/// Prevents man-in-the-middle attacks by validating server certificates
class CertificatePinning {
  // Production certificate fingerprints (SHA-256)
  // TODO: Replace with your actual production server certificate fingerprints
  static const List<String> _productionFingerprints = [
    // Example: '5F:3A:6B:7C:8D:9E:0F:1A:2B:3C:4D:5E:6F:7A:8B:9C...',
    // Get your fingerprint by running:
    // openssl s_client -connect your-domain.com:443 | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64
  ];

  // Staging certificate fingerprints (if you have a staging environment)
  static const List<String> _stagingFingerprints = [
    // Add staging fingerprints here
  ];

  /// Verify SSL certificate against pinned fingerprints
  static bool verifyCertificate(X509Certificate cert, String host, int port) {
    if (!kReleaseMode) {
      // In debug mode, allow all certificates for easier development
      debugPrint('⚠️ Certificate pinning disabled in debug mode');
      return true;
    }

    try {
      // Get certificate fingerprint
      final fingerprint = _getCertificateFingerprint(cert);

      // Check against pinned fingerprints
      final isValid = _productionFingerprints.contains(fingerprint) ||
          _stagingFingerprints.contains(fingerprint);

      if (!isValid) {
        debugPrint('❌ Certificate pinning failed!');
        debugPrint('❌ Host: $host:$port');
        debugPrint('❌ Received fingerprint: $fingerprint');
        debugPrint('❌ This could indicate a man-in-the-middle attack!');
      } else {
        debugPrint('✅ Certificate pinning verified for $host');
      }

      return isValid;
    } catch (e) {
      debugPrint('❌ Certificate verification error: $e');
      return false;
    }
  }

  /// Get SHA-256 fingerprint of certificate
  static String _getCertificateFingerprint(X509Certificate cert) {
    try {
      final der = cert.der;
      final digest = sha256.convert(der);

      // Convert to uppercase hex with colons
      final fingerprint = digest.bytes
          .map((b) => b.toRadixString(16).toUpperCase().padLeft(2, '0'))
          .join(':');

      return fingerprint;
    } catch (e) {
      debugPrint('❌ Error getting certificate fingerprint: $e');
      rethrow;
    }
  }

  /// Validate certificate chain
  static bool validateCertificateChain(
      List<X509Certificate> chain, String host) {
    if (chain.isEmpty) {
      debugPrint('❌ Empty certificate chain');
      return false;
    }

    // Verify each certificate in the chain
    for (var i = 0; i < chain.length; i++) {
      final cert = chain[i];

      // Check certificate validity period
      final now = DateTime.now();
      if (now.isBefore(cert.startValidity) || now.isAfter(cert.endValidity)) {
        debugPrint('❌ Certificate expired or not yet valid');
        return false;
      }

      // Verify subject matches host (for leaf certificate)
      if (i == 0 && !_verifyHostname(cert, host)) {
        debugPrint('❌ Hostname verification failed');
        return false;
      }
    }

    return true;
  }

  /// Verify certificate hostname matches expected host
  static bool _verifyHostname(X509Certificate cert, String host) {
    final subject = cert.subject;

    // Simple hostname check (you might want to implement wildcard matching)
    return subject.contains('CN=$host') || subject.contains('CN=*.');
  }

  /// Get certificate info for debugging
  static Map<String, dynamic> getCertificateInfo(X509Certificate cert) {
    return {
      'issuer': cert.issuer,
      'subject': cert.subject,
      'startValidity': cert.startValidity.toIso8601String(),
      'endValidity': cert.endValidity.toIso8601String(),
      'fingerprint': _getCertificateFingerprint(cert),
    };
  }

  /// Instructions for getting certificate fingerprints
  static String get setupInstructions => '''
Certificate Pinning Setup Instructions:
=========================================

1. Get your server's certificate fingerprint:

   For your domain (e.g., your-production-server.com):
   
   openssl s_client -connect your-production-server.com:443 < /dev/null 2>/dev/null | openssl x509 -fingerprint -sha256 -noout
   
   Or for public key pinning (recommended):
   
   openssl s_client -connect your-production-server.com:443 < /dev/null 2>/dev/null | openssl x509 -pubkey -noout | openssl pkey -pubin -outform der | openssl dgst -sha256 -binary | openssl enc -base64

2. Add the fingerprint to _productionFingerprints list in certificate_pinning.dart

3. Test in production mode:
   flutter build apk --release
   
4. Monitor certificate expiry and update pins before renewal

5. Always pin at least 2 certificates (current + backup) to avoid app breakage

⚠️ Important: Certificate pinning is currently DISABLED in debug mode for easier development.
It will be ENABLED in release builds.

Current fingerprints configured: ${_productionFingerprints.length}
''';
}

/// Extension for certificate validation
extension X509CertificateExtension on X509Certificate {
  /// Check if certificate is valid now
  bool get isValid {
    final now = DateTime.now();
    return now.isAfter(startValidity) && now.isBefore(endValidity);
  }

  /// Days until certificate expires
  int get daysUntilExpiry {
    return endValidity.difference(DateTime.now()).inDays;
  }

  /// Check if certificate expires soon (within 30 days)
  bool get expiresSoon {
    return daysUntilExpiry < 30;
  }
}
