# Mentorly Security Implementation Guide

## 🔒 Security Features Implemented

This guide covers all the security features that have been added to your Mentorly app.

---

## Table of Contents
1. [Secure Storage](#1-secure-storage)
2. [API Security](#2-api-security)
3. [Certificate Pinning](#3-certificate-pinning)
4. [Input Validation](#4-input-validation)
5. [PHP Backend Security](#5-php-backend-security)
6. [Configuration](#6-configuration)
7. [Testing](#7-testing)
8. [Deployment Checklist](#8-deployment-checklist)

---

## 1. Secure Storage

### Implementation
We've replaced `SharedPreferences` with `flutter_secure_storage` for sensitive data:

**Old (Insecure):**
```dart
SharedPreferences.setString('token', token); // ❌ INSECURE
```

**New (Secure):**
```dart
import 'package:mentorly/security/secure_storage.dart';

await SecureStorage.saveAuthTokens(
  accessToken: token,
  expiresIn: 3600,
); // ✅ SECURE
```

### Usage Examples

```dart
// Save user session
await SecureStorage.saveUserSession(
  userId: userId,
  userType: 'mentor',
  userData: userData,
);

// Get access token
final token = await SecureStorage.getAccessToken();

// Check if session expired
if (await SecureStorage.isSessionExpired()) {
  // Refresh token or logout
}

// Logout
await SecureStorage.clearSession();
```

---

## 2. API Security

### Secure API Client

The new `SecureApiClient` provides:
- ✅ Automatic JWT token injection
- ✅ Token refresh on 401 errors
- ✅ Rate limiting
- ✅ Certificate pinning
- ✅ Error handling
- ✅ Device info headers

### Usage

```dart
import 'package:mentorly/security/api_client.dart';

final client = SecureApiClient();

// GET request
try {
  final response = await client.get('/api/mentors');
  if (response.statusCode == 200) {
    final data = response.data;
    // Process data
  }
} on ApiException catch (e) {
  print('API Error: ${e.message}');
  if (e.isUnauthorized) {
    // Handle auth error
  }
}

// POST request
try {
  final response = await client.post(
    '/api/sessions/book',
    data: {
      'mentor_id': mentorId,
      'date': date,
    },
  );
} on ApiException catch (e) {
  // Handle error
}
```

---

## 3. Certificate Pinning

### Setup Instructions

1. **Get your certificate fingerprint:**

```bash
# For your production domain
openssl s_client -connect your-domain.com:443 < /dev/null 2>/dev/null | \
  openssl x509 -pubkey -noout | \
  openssl pkey -pubin -outform der | \
  openssl dgst -sha256 -binary | \
  openssl enc -base64
```

2. **Add to certificate_pinning.dart:**

```dart
static const List<String> _productionFingerprints = [
  'YOUR_CERTIFICATE_FINGERPRINT_HERE',
  'BACKUP_CERTIFICATE_FINGERPRINT_HERE', // Always pin 2+ certs
];
```

3. **Test in release mode:**

```bash
flutter build apk --release
# Test on device
```

⚠️ **Important:** Always pin at least 2 certificates (primary + backup) to avoid app breakage when renewing certificates.

---

## 4. Input Validation

### Usage

```dart
import 'package:mentorly/security/input_validator.dart';

// Validate email
final emailResult = InputValidator.validateEmail(email);
if (!emailResult.isValid) {
  showError(emailResult.error!);
  return;
}
final sanitizedEmail = emailResult.value!;

// Validate password
final passResult = InputValidator.validatePassword(
  password,
  requireStrong: true,
);
if (!passResult.isValid) {
  showError(passResult.error!);
  return;
}

// Validate name
final nameResult = InputValidator.validateName(name);

// Validate phone
final phoneResult = InputValidator.validatePhoneNumber(phone);

// Validate text (checks for XSS/SQL injection)
final textResult = InputValidator.validateText(
  userInput,
  maxLength: 500,
  fieldName: 'Description',
);
```

---

## 5. PHP Backend Security

### Implementation

Add this to your PHP entry point (e.g., `index.php`):

```php
<?php
require_once __DIR__ . '/PHPMailer/SecurityMiddleware.php';

// Initialize security middleware
$security = new SecurityMiddleware([
    'jwt_secret' => $_ENV['JWT_SECRET'],
    'redis_host' => $_ENV['REDIS_HOST'] ?? '127.0.0.1',
]);

// Apply security checks
$security->handle();

// Your API routes below...
```

### Features Enabled

✅ **Rate Limiting** - 100 requests/minute per user/IP
✅ **CSRF Protection** - For cookie-based sessions
✅ **Security Headers** - CSP, X-Frame-Options, etc.
✅ **Input Sanitization** - Automatic sanitization of $_GET, $_POST
✅ **JWT Verification** - Automatic token validation
✅ **SQL Injection Protection** - Via prepared statements
✅ **XSS Protection** - Via output encoding

### Password Hashing

```php
// Hash password (Argon2id or bcrypt)
$hash = SecurityMiddleware::hashPassword($password);

// Verify password
if (SecurityMiddleware::verifyPassword($password, $hash)) {
    // Login success
}
```

### Security Logging

```php
SecurityMiddleware::logSecurityEvent('login_attempt', [
    'user_id' => $userId,
    'success' => true,
]);
```

---

## 6. Configuration

### Step 1: Copy Environment Template

```bash
cp .env.example .env
```

### Step 2: Configure Critical Values

Edit `.env` and set:

```bash
# CRITICAL: Change these!
JWT_SECRET=your-random-256-bit-secret-key
DB_PASSWORD=your-database-password
ENCRYPTION_KEY=your-encryption-key

# Generate secrets with:
openssl rand -base64 32
```

### Step 3: Set Firebase Configuration

Update `.env` with your Firebase credentials:

```bash
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_API_KEY=your-api-key
# ... etc
```

### Step 4: Configure CORS

```bash
ALLOWED_ORIGINS=https://your-production-domain.com,https://your-staging-domain.com
```

---

## 7. Testing

### Run Security Audit

```bash
chmod +x security_audit.sh
./security_audit.sh
```

This will check for:
- ✅ Exposed secrets
- ✅ Outdated dependencies
- ✅ Insecure storage patterns
- ✅ HTTP vs HTTPS
- ✅ SQL injection patterns
- ✅ Debug mode flags
- ✅ File permissions
- ✅ Certificate pinning
- ✅ Sensitive data logging

### Flutter Analyze

```bash
flutter analyze
```

### Run Tests

```bash
flutter test
```

---

## 8. Deployment Checklist

### Before Deploying to Production:

- [ ] Copy `.env.example` to `.env` and configure all values
- [ ] Generate strong JWT secret: `openssl rand -base64 32`
- [ ] Set up HTTPS with valid SSL certificate
- [ ] Configure certificate pinning with production fingerprints
- [ ] Set `APP_ENV=production` in `.env`
- [ ] Set `APP_DEBUG=false` in `.env`
- [ ] Enable HSTS header (uncomment in SecurityMiddleware.php)
- [ ] Configure CORS with actual production domains
- [ ] Set up Redis for production rate limiting
- [ ] Run security audit: `./security_audit.sh`
- [ ] Build release APK/IPA with obfuscation:
  ```bash
  flutter build apk --release --obfuscate --split-debug-info=./debug-info
  flutter build ios --release --obfuscate --split-debug-info=./debug-info
  ```
- [ ] Test all API endpoints with production credentials
- [ ] Set up monitoring and alerting
- [ ] Configure backup strategy
- [ ] Document emergency procedures
- [ ] Set up security log monitoring

---

## Security Best Practices

### DO ✅
- Always use HTTPS in production
- Store sensitive data in `flutter_secure_storage`
- Validate all user inputs
- Use prepared statements for database queries
- Hash passwords with Argon2id or bcrypt
- Implement rate limiting
- Log security events
- Keep dependencies updated
- Use strong, unique passwords
- Enable MFA for admin accounts

### DON'T ❌
- Store tokens in SharedPreferences
- Commit `.env` to git
- Log passwords or tokens
- Use HTTP in production
- Trust user input
- Hardcode secrets
- Ignore security warnings
- Use weak passwords
- Disable SSL verification

---

## Migration Guide

### Updating Existing Login Flows

Replace your current session manager with the secure one:

**Old:**
```dart
import '../utils/session_manager.dart';

await SessionManager.saveSession(
  userType: 'mentor',
  userData: userData,
);
```

**New:**
```dart
import 'package:mentorly/security/secure_session_manager.dart';

await SecureSessionManager.saveSession(
  userType: 'mentor',
  userData: userData,
);
```

### Updating API Calls

**Old:**
```dart
final response = await http.post(
  Uri.parse(ApiConfig.getUrl('api/login')),
  body: jsonEncode(data),
);
```

**New:**
```dart
final client = SecureApiClient();
final response = await client.post('/api/login', data: data);
```

---

## Support & Questions

For security concerns or questions:
1. Run `./security_audit.sh` to check for common issues
2. Review the implementation files in `lib/security/`
3. Check certificate pinning setup: Run the app and check logs

---

## License & Security Disclosure

If you discover a security vulnerability, please email: security@mentorly.com

---

**Last Updated:** 2025-12-30
**Version:** 1.0.0
