import 'package:flutter/foundation.dart';

/// Input validation utilities for secure data handling
class InputValidator {
  // Email validation regex
  static final _emailRegex = RegExp(
    r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
  );

  // Phone number regex (Indonesian format)
  static final _phoneRegex = RegExp(
    r'^(\+62|62|0)[0-9]{9,12}$',
  );

  // Password strength regex
  static final _passwordStrengthRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{8,}$',
  );

  // Alphanumeric only
  static final _alphanumericRegex = RegExp(r'^[a-zA-Z0-9]+$');

  // No special characters (for names)
  static final _nameRegex = RegExp(r'^[a-zA-Z\s]+$');

  // SQL injection patterns
  static final _sqlInjectionPattern = RegExp(
    r"(\b(SELECT|INSERT|UPDATE|DELETE|DROP|CREATE|ALTER|EXEC|UNION|SCRIPT)\b|--|;|'|\")",
    caseSensitive: false,
  );

  // XSS patterns
  static final _xssPattern = RegExp(
    r'(<script|<iframe|javascript:|onerror=|onclick=|onload=)',
    caseSensitive: false,
  );

  /// Validate email address
  static ValidationResult validateEmail(String email) {
    if (email.isEmpty) {
      return ValidationResult.error('Email tidak boleh kosong');
    }

    final trimmed = email.trim().toLowerCase();
    
    if (trimmed.length > 255) {
      return ValidationResult.error('Email terlalu panjang');
    }

    if (!_emailRegex.hasMatch(trimmed)) {
      return ValidationResult.error('Format email tidak valid');
    }

    // Check for suspicious patterns
    if (_containsSqlInjection(trimmed) || _containsXss(trimmed)) {
      return ValidationResult.error('Email mengandung karakter tidak valid');
    }

    return ValidationResult.success(trimmed);
  }

  /// Validate password
  static ValidationResult validatePassword(String password, {
    int minLength = 8,
    int maxLength = 128,
    bool requireStrong = false,
  }) {
    if (password.isEmpty) {
      return ValidationResult.error('Password tidak boleh kosong');
    }

    if (password.length < minLength) {
      return ValidationResult.error('Password minimal $minLength karakter');
    }

    if (password.length > maxLength) {
      return ValidationResult.error('Password maksimal $maxLength karakter');
    }

    if (requireStrong && !_passwordStrengthRegex.hasMatch(password)) {
      return ValidationResult.error(
        'Password harus mengandung huruf besar, huruf kecil, angka, dan simbol',
      );
    }

    // Check for common weak passwords
    if (_isCommonPassword(password)) {
      return ValidationResult.error('Password terlalu umum, gunakan yang lebih kuat');
    }

    return ValidationResult.success(password);
  }

  /// Validate phone number
  static ValidationResult validatePhoneNumber(String phone) {
    if (phone.isEmpty) {
      return ValidationResult.error('Nomor telepon tidak boleh kosong');
    }

    final cleaned = phone.replaceAll(RegExp(r'[\s-]'), '');
    
    if (!_phoneRegex.hasMatch(cleaned)) {
      return ValidationResult.error('Format nomor telepon tidak valid');
    }

    return ValidationResult.success(cleaned);
  }

  /// Validate name (no special characters)
  static ValidationResult validateName(String name, {
    int minLength = 2,
    int maxLength = 100,
  }) {
    if (name.isEmpty) {
      return ValidationResult.error('Nama tidak boleh kosong');
    }

    final trimmed = name.trim();

    if (trimmed.length < minLength) {
      return ValidationResult.error('Nama minimal $minLength karakter');
    }

    if (trimmed.length > maxLength) {
      return ValidationResult.error('Nama maksimal $maxLength karakter');
    }

    if (!_nameRegex.hasMatch(trimmed)) {
      return ValidationResult.error('Nama hanya boleh berisi huruf dan spasi');
    }

    return ValidationResult.success(trimmed);
  }

  /// Validate alphanumeric string
  static ValidationResult validateAlphanumeric(String value, String fieldName) {
    if (value.isEmpty) {
      return ValidationResult.error('$fieldName tidak boleh kosong');
    }

    if (!_alphanumericRegex.hasMatch(value)) {
      return ValidationResult.error('$fieldName hanya boleh berisi huruf dan angka');
    }

    return ValidationResult.success(value);
  }

  /// Validate text (check for SQL injection and XSS)
  static ValidationResult validateText(String text, {
    int maxLength = 1000,
    String fieldName = 'Input',
  }) {
    if (text.isEmpty) {
      return ValidationResult.error('$fieldName tidak boleh kosong');
    }

    if (text.length > maxLength) {
      return ValidationResult.error('$fieldName maksimal $maxLength karakter');
    }

    if (_containsSqlInjection(text)) {
      debugPrint('⚠️ SQL injection attempt detected in $fieldName');
      return ValidationResult.error('Input mengandung karakter tidak diizinkan');
    }

    if (_containsXss(text)) {
      debugPrint('⚠️ XSS attempt detected in $fieldName');
      return ValidationResult.error('Input mengandung karakter tidak diizinkan');
    }

    return ValidationResult.success(text.trim());
  }

  /// Validate URL
  static ValidationResult validateUrl(String url) {
    if (url.isEmpty) {
      return ValidationResult.error('URL tidak boleh kosong');
    }

    try {
      final uri = Uri.parse(url);
      
      if (!uri.hasScheme || !uri.hasAuthority) {
        return ValidationResult.error('Format URL tidak valid');
      }

      if (!['http', 'https'].contains(uri.scheme)) {
        return ValidationResult.error('URL harus menggunakan HTTP atau HTTPS');
      }

      return ValidationResult.success(url);
    } catch (e) {
      return ValidationResult.error('Format URL tidak valid');
    }
  }

  /// Validate numeric string
  static ValidationResult validateNumeric(String value, String fieldName) {
    if (value.isEmpty) {
      return ValidationResult.error('$fieldName tidak boleh kosong');
    }

    if (int.tryParse(value) == null && double.tryParse(value) == null) {
      return ValidationResult.error('$fieldName harus berupa angka');
    }

    return ValidationResult.success(value);
  }

  /// Validate age
  static ValidationResult validateAge(int age, {
    int minAge = 13,
    int maxAge = 150,
  }) {
    if (age < minAge) {
      return ValidationResult.error('Umur minimal $minAge tahun');
    }

    if (age > maxAge) {
      return ValidationResult.error('Umur tidak valid');
    }

    return ValidationResult.success(age.toString());
  }

  /// Sanitize input (remove dangerous characters)
  static String sanitize(String input) {
    return input
        .replaceAll(_sqlInjectionPattern, '')
        .replaceAll(_xssPattern, '')
        .replaceAll(RegExp(r'[<>]'), '')
        .trim();
  }

  /// Check for SQL injection patterns
  static bool _containsSqlInjection(String input) {
    return _sqlInjectionPattern.hasMatch(input);
  }

  /// Check for XSS patterns
  static bool _containsXss(String input) {
    return _xssPattern.hasMatch(input);
  }

  /// Check if password is commonly used
  static bool _isCommonPassword(String password) {
    final common = [
      'password', '12345678', 'qwerty', 'abc123', 'password123',
      'admin123', 'letmein', 'welcome', '123456789', 'password1',
    ];
    
    return common.contains(password.toLowerCase());
  }

  /// Validate file extension
  static ValidationResult validateFileExtension(
    String filename,
    List<String> allowedExtensions,
  ) {
    final extension = filename.split('.').last.toLowerCase();
    
    if (!allowedExtensions.contains(extension)) {
      return ValidationResult.error(
        'File harus berformat: ${allowedExtensions.join(", ")}',
      );
    }

    return ValidationResult.success(filename);
  }

  /// Validate file size
  static ValidationResult validateFileSize(
    int bytes, {
    int maxMB = 5,
  }) {
    final maxBytes = maxMB * 1024 * 1024;
    
    if (bytes > maxBytes) {
      return ValidationResult.error('Ukuran file maksimal $maxMB MB');
    }

    return ValidationResult.success(bytes.toString());
  }
}

/// Validation result class
class ValidationResult {
  final bool isValid;
  final String? error;
  final String? value;

  ValidationResult._({
    required this.isValid,
    this.error,
    this.value,
  });

  factory ValidationResult.success(String value) {
    return ValidationResult._(
      isValid: true,
      value: value,
    );
  }

  factory ValidationResult.error(String message) {
    return ValidationResult._(
      isValid: false,
      error: message,
    );
  }

  @override
  String toString() => isValid ? 'Valid: $value' : 'Error: $error';
}
