# 🔄 Migration Guide: Updating Existing Code

This guide helps you migrate your existing Mentorly code to use the new security infrastructure.

---

## 📋 Overview

You need to update:
1. Session management imports and calls
2. API calls to use SecureApiClient
3. Form validation to use InputValidator
4. Backend to include SecurityMiddleware

---

## 1️⃣ Session Management Migration

### Find & Replace in All Files

**Import Statement:**
```dart
// FIND
import '../utils/session_manager.dart';
import 'package:mentorly/utils/session_manager.dart';

// REPLACE WITH
import 'package:mentorly/security/secure_session_manager.dart';
```

**Save Session:**
```dart
// OLD
await SessionManager.saveSession(
  userType: userType,
  userData: userData,
);

// NEW
await SecureSessionManager.saveSession(
  userType: userType,
  userData: userData,
);
```

**Get User Data:**
```dart
// OLD
final data = await SessionManager.getUserData();

// NEW
final data = await SecureSessionManager.getUserData();
```

**Check Login Status:**
```dart
// OLD
final isLoggedIn = await SessionManager.isLoggedIn();

// NEW
final isLoggedIn = await SecureSessionManager.isLoggedIn();
```

**Logout:**
```dart
// OLD
await SessionManager.logout();

// NEW
await SecureSessionManager.logout();
```

---

## 2️⃣ Update Login Pages

### Files to Update:
- `lib/mentor/login_mentor.dart`
- `lib/pelajar/login_pelajar.dart`
- `lib/admin/login_admin.dart`

### Changes Needed:

**1. Add input validation import:**
```dart
import 'package:mentorly/security/input_validator.dart';
```

**2. Add validation to login method:**
```dart
// Replace existing validasi() method
bool validasi() {
  bool isValid = true;

  setState(() {
    // Email validation
    final emailResult = InputValidator.validateEmail(_email.text);
    if (!emailResult.isValid) {
      errorEmail = emailResult.error;
      isValid = false;
    } else {
      errorEmail = null;
    }

    // Password validation
    final passResult = InputValidator.validatePassword(
      _password.text,
      minLength: 6,
    );
    if (!passResult.isValid) {
      errorPassword = passResult.error;
      isValid = false;
    } else {
      errorPassword = null;
    }
  });

  return isValid;
}
```

**3. Update login success handler:**
```dart
// After successful Firebase authentication
await SecureSessionManager.saveSession(
  userType: 'mentor', // or 'pelajar', 'admin'
  userData: {
    'uid': uid,
    'email': user.email,
    'nama': nama,
    // ... other fields
  },
);
```

---

## 3️⃣ Update API Calls

### For New API Endpoints

**Create a service class:**
```dart
import 'package:mentorly/security/api_client.dart';

class MentorService {
  final _client = SecureApiClient();

  Future<List<dynamic>> getMentors() async {
    try {
      final response = await _client.get('/api/mentors');
      if (response.statusCode == 200) {
        return response.data as List<dynamic>;
      }
      return [];
    } on ApiException catch (e) {
      print('Error: ${e.message}');
      return [];
    }
  }

  Future<bool> bookSession(String mentorId, DateTime date) async {
    try {
      final response = await _client.post(
        '/api/sessions/book',
        data: {
          'mentor_id': mentorId,
          'date': date.toIso8601String(),
        },
      );
      return response.statusCode == 200;
    } on ApiException catch (e) {
      print('Error: ${e.message}');
      return false;
    }
  }
}
```

### For Existing HTTP Calls

If you have existing `http` package calls, replace them:

**OLD:**
```dart
import 'package:http/http.dart' as http;

final response = await http.post(
  Uri.parse('${ApiConfig.baseUrl}/api/endpoint'),
  headers: {'Content-Type': 'application/json'},
  body: jsonEncode(data),
);

if (response.statusCode == 200) {
  final result = jsonDecode(response.body);
  // handle result
}
```

**NEW:**
```dart
import 'package:mentorly/security/api_client.dart';

final client = SecureApiClient();

try {
  final response = await client.post('/api/endpoint', data: data);
  
  if (response.statusCode == 200) {
    final result = response.data;
    // handle result
  }
} on ApiException catch (e) {
  if (e.isUnauthorized) {
    // Handle auth error - redirect to login
  } else {
    // Handle other errors
    showError(e.message);
  }
}
```

---

## 4️⃣ Update Profile/Registration Forms

### Files to Update:
- `lib/mentor/register_mentor.dart`
- `lib/pelajar/register_pelajar.dart`
- `lib/mentor/profile_mentor.dart`
- `lib/pelajar/profile_pelajar.dart`

### Add Validation:

**1. Import validator:**
```dart
import 'package:mentorly/security/input_validator.dart';
```

**2. Update form validation:**
```dart
Future<void> _submitForm() async {
  // Email validation
  final emailResult = InputValidator.validateEmail(_emailController.text);
  if (!emailResult.isValid) {
    _showError(emailResult.error!);
    return;
  }

  // Password validation
  final passResult = InputValidator.validatePassword(
    _passwordController.text,
    requireStrong: true, // Require strong password
  );
  if (!passResult.isValid) {
    _showError(passResult.error!);
    return;
  }

  // Name validation
  final nameResult = InputValidator.validateName(_nameController.text);
  if (!nameResult.isValid) {
    _showError(nameResult.error!);
    return;
  }

  // Phone validation
  final phoneResult = InputValidator.validatePhoneNumber(_phoneController.text);
  if (!phoneResult.isValid) {
    _showError(phoneResult.error!);
    return;
  }

  // Proceed with registration/update
  final userData = {
    'email': emailResult.value!,
    'nama': nameResult.value!,
    'phone': phoneResult.value!,
  };
  
  // Save or send to API...
}
```

---

## 5️⃣ Update Chat & Messages

### Sanitize User Input

**For text messages:**
```dart
import 'package:mentorly/security/input_validator.dart';

Future<void> _sendMessage(String message) async {
  // Validate and sanitize
  final textResult = InputValidator.validateText(
    message,
    maxLength: 500,
    fieldName: 'Message',
  );
  
  if (!textResult.isValid) {
    _showError(textResult.error!);
    return;
  }

  // Send sanitized message
  final sanitizedMessage = textResult.value!;
  
  // Send to Firebase or API
  await sendMessageToFirebase(sanitizedMessage);
}
```

---

## 6️⃣ Update File Uploads

### Add File Validation

```dart
import 'package:mentorly/security/input_validator.dart';
import 'package:file_picker/file_picker.dart';

Future<void> _pickFile() async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: ['jpg', 'jpeg', 'png', 'pdf'],
  );

  if (result != null) {
    final file = result.files.first;
    
    // Validate file extension
    final extResult = InputValidator.validateFileExtension(
      file.name,
      ['jpg', 'jpeg', 'png', 'pdf'],
    );
    
    if (!extResult.isValid) {
      _showError(extResult.error!);
      return;
    }

    // Validate file size (5MB max)
    final sizeResult = InputValidator.validateFileSize(
      file.size,
      maxMB: 5,
    );
    
    if (!sizeResult.isValid) {
      _showError(sizeResult.error!);
      return;
    }

    // Upload file
    await _uploadFile(file);
  }
}
```

---

## 7️⃣ PHP Backend Integration

### Update Your PHP Entry Point

**Create or update `api/index.php`:**
```php
<?php
// Load environment variables
require_once __DIR__ . '/../vendor/autoload.php';
$dotenv = Dotenv\Dotenv::createImmutable(__DIR__ . '/..');
$dotenv->load();

// Include security middleware
require_once __DIR__ . '/../PHPMailer/SecurityMiddleware.php';

// Initialize security
$security = new SecurityMiddleware([
    'jwt_secret' => $_ENV['JWT_SECRET'],
    'redis_host' => $_ENV['REDIS_HOST'] ?? '127.0.0.1',
]);

// Apply security middleware
$security->handle();

// Your routing logic here
$endpoint = $_GET['endpoint'] ?? '';

switch ($endpoint) {
    case 'login':
        require_once __DIR__ . '/auth/login.php';
        break;
    
    case 'mentors':
        require_once __DIR__ . '/mentors/list.php';
        break;
    
    // ... other endpoints
    
    default:
        http_response_code(404);
        echo json_encode(['error' => 'Endpoint not found']);
}
```

### Update Login Endpoint

**In `api/auth/login.php`:**
```php
<?php
// Validate input
if (!SecurityMiddleware::validateEmail($_POST['email'])) {
    http_response_code(400);
    echo json_encode(['error' => 'Invalid email']);
    exit;
}

$email = filter_var($_POST['email'], FILTER_SANITIZE_EMAIL);
$password = $_POST['password'];

// Get user from database (use prepared statements!)
$stmt = $pdo->prepare("SELECT * FROM users WHERE email = ?");
$stmt->execute([$email]);
$user = $stmt->fetch();

// Verify password
if ($user && SecurityMiddleware::verifyPassword($password, $user['password'])) {
    // Generate JWT token
    $token = generateJWT($user['id'], $user['type']);
    
    // Log successful login
    SecurityMiddleware::logSecurityEvent('login_success', [
        'user_id' => $user['id'],
        'user_type' => $user['type'],
    ]);
    
    echo json_encode([
        'success' => true,
        'access_token' => $token,
        'user' => [
            'id' => $user['id'],
            'email' => $user['email'],
            'type' => $user['type'],
        ],
    ]);
} else {
    // Log failed login
    SecurityMiddleware::logSecurityEvent('login_failed', [
        'email' => $email,
    ]);
    
    http_response_code(401);
    echo json_encode(['error' => 'Invalid credentials']);
}
```

---

## 8️⃣ Testing Your Migration

### 1. Run Security Audit
```bash
./security_audit.sh
```

### 2. Test Login Flow
```bash
flutter run
```

Test:
- [ ] Login as mentor
- [ ] Login as pelajar
- [ ] Login as admin
- [ ] Logout
- [ ] Session persistence after app restart

### 3. Test API Calls
- [ ] Fetch data from API
- [ ] Post data to API
- [ ] Verify token is sent automatically
- [ ] Test error handling

### 4. Test Validation
- [ ] Try invalid email
- [ ] Try weak password
- [ ] Try oversized file upload
- [ ] Verify error messages display correctly

---

## 🔍 Common Issues & Solutions

### Issue: "Unresolved reference to SecureSessionManager"
**Solution:** Run `flutter pub get` to install dependencies

### Issue: "flutter_secure_storage not found"
**Solution:** Ensure `pubspec.yaml` has been updated and run `flutter pub get`

### Issue: "Certificate verification failed"
**Solution:** In development, certificate pinning is disabled. For production, add your certificate fingerprints.

### Issue: "Rate limit exceeded"
**Solution:** Default is 30 req/min. Either reduce API calls or increase limit in `api_client.dart`

### Issue: PHP SecurityMiddleware not found
**Solution:** Ensure the file path is correct in your require_once statement

---

## 📊 Migration Checklist

Track your progress:

### Flutter App
- [ ] Updated all SessionManager imports
- [ ] Updated all login pages
- [ ] Updated all registration forms
- [ ] Updated all profile pages
- [ ] Added input validation to forms
- [ ] Updated API calls to use SecureApiClient
- [ ] Added file upload validation
- [ ] Tested all flows

### PHP Backend
- [ ] Included SecurityMiddleware in entry point
- [ ] Created .env file with secrets
- [ ] Updated login endpoint
- [ ] Updated all API endpoints to use prepared statements
- [ ] Added password hashing for new users
- [ ] Tested API authentication
- [ ] Tested rate limiting

### Configuration
- [ ] Ran `flutter pub get`
- [ ] Created .env from .env.example
- [ ] Generated JWT secret
- [ ] Configured Firebase
- [ ] Ran security audit
- [ ] Fixed all audit warnings/errors

### Documentation
- [ ] Read SECURITY_GUIDE.md
- [ ] Reviewed code examples
- [ ] Understood certificate pinning setup
- [ ] Planned production deployment

---

## 🎯 Priority Order

Migrate in this order for best results:

1. **High Priority (Do First):**
   - Install dependencies (`flutter pub get`)
   - Update SessionManager to SecureSessionManager
   - Add input validation to login forms
   - Include PHP SecurityMiddleware

2. **Medium Priority:**
   - Update all API calls to SecureApiClient
   - Add validation to registration/profile forms
   - Configure .env file

3. **Before Production:**
   - Configure certificate pinning
   - Run security audit
   - Test thoroughly
   - Build with obfuscation

---

## 📞 Need Help?

1. Run security audit: `./security_audit.sh`
2. Check SECURITY_GUIDE.md for detailed instructions
3. Review example code in `lib/security/auth_example.dart`
4. Test incrementally - migrate one page at a time

---

**Good luck with your migration! 🚀**
