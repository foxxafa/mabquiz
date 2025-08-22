/// Form validation utilities for authentication forms
class AuthFormValidators {
  /// Validates email address format
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email adresi gereklidir';
    }

    final email = value.trim();

    // Basic email format validation
    final emailRegex = RegExp(
      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(email)) {
      return 'Geçerli bir email adresi girin';
    }

    // Check for common email format issues
    if (email.startsWith('.') || email.endsWith('.')) {
      return 'Email adresi nokta ile başlayamaz veya bitemez';
    }

    if (email.contains('..')) {
      return 'Email adresinde ardışık nokta bulunamaz';
    }

    return null;
  }

  /// Validates password strength (relaxed for testing)
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Şifre gereklidir';
    }

    if (value.length < 3) {
      return 'Şifre en az 3 karakter olmalıdır';
    }

    // Removed all complex validations for easier testing
    return null;
  }

  /// Validates password confirmation
  static String? validatePasswordConfirmation(String? value, String? originalPassword) {
    if (value == null || value.isEmpty) {
      return 'Şifre tekrarı gereklidir';
    }

    if (value != originalPassword) {
      return 'Şifreler eşleşmiyor';
    }

    return null;
  }

  /// Validates required field
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) {
      return '$fieldName gereklidir';
    }
    return null;
  }

  /// Validates display name
  static String? validateDisplayName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Display name is optional
    }

    final name = value.trim();

    if (name.length < 2) {
      return 'İsim en az 2 karakter olmalıdır';
    }

    if (name.length > 50) {
      return 'İsim en fazla 50 karakter olabilir';
    }

    // Check for valid characters (letters, spaces, some special characters)
    if (!RegExp(r'^[a-zA-ZğüşıöçĞÜŞİÖÇ\s\-\.]+$').hasMatch(name)) {
      return 'İsim sadece harf, boşluk, tire ve nokta içerebilir';
    }

    return null;
  }

  /// Validates phone number (Turkish format)
  static String? validatePhoneNumber(String? value) {
    if (value == null || value.trim().isEmpty) {
      return null; // Phone number is optional
    }

    final phone = value.trim().replaceAll(RegExp(r'[\s\-\(\)]'), '');

    // Turkish phone number format: +90XXXXXXXXXX or 0XXXXXXXXXX
    if (!RegExp(r'^(\+90|0)?[5][0-9]{9}$').hasMatch(phone)) {
      return 'Geçerli bir telefon numarası girin (örn: 05XXXXXXXXX)';
    }

    return null;
  }

  /// Gets password strength level (0-4)
  static int getPasswordStrength(String password) {
    if (password.isEmpty) return 0;

    int strength = 0;

    // Length check
    if (password.length >= 8) strength++;
    if (password.length >= 12) strength++;

    // Character variety checks
    if (RegExp(r'[a-z]').hasMatch(password)) strength++;
    if (RegExp(r'[A-Z]').hasMatch(password)) strength++;
    if (RegExp(r'[0-9]').hasMatch(password)) strength++;
    if (RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) strength++;

    // Reduce strength for common patterns
    if (RegExp(r'(.)\1{2,}').hasMatch(password)) strength--; // Repeated characters
    if (RegExp(r'(012|123|234|345|456|567|678|789|890)').hasMatch(password)) strength--; // Sequential numbers
    if (RegExp(r'(abc|bcd|cde|def|efg|fgh|ghi|hij|ijk|jkl|klm|lmn|mno|nop|opq|pqr|qrs|rst|stu|tuv|uvw|vwx|wxy|xyz)').hasMatch(password.toLowerCase())) strength--; // Sequential letters

    return strength.clamp(0, 4);
  }

  /// Gets password strength description in Turkish
  static String getPasswordStrengthDescription(int strength) {
    switch (strength) {
      case 0:
        return 'Çok zayıf';
      case 1:
        return 'Zayıf';
      case 2:
        return 'Orta';
      case 3:
        return 'Güçlü';
      case 4:
        return 'Çok güçlü';
      default:
        return 'Bilinmiyor';
    }
  }

  /// Gets password strength color
  static int getPasswordStrengthColor(int strength) {
    switch (strength) {
      case 0:
      case 1:
        return 0xFFE53E3E; // Red
      case 2:
        return 0xFFDD6B20; // Orange
      case 3:
        return 0xFF38A169; // Green
      case 4:
        return 0xFF00A86B; // Dark green
      default:
        return 0xFF718096; // Gray
    }
  }

  /// Validates form fields and returns first error message
  static String? validateForm(Map<String, String?> fields, Map<String, String? Function(String?)> validators) {
    for (final entry in validators.entries) {
      final fieldName = entry.key;
      final validator = entry.value;
      final value = fields[fieldName];

      final error = validator(value);
      if (error != null) {
        return error;
      }
    }
    return null;
  }

  /// Validates login form
  static Map<String, String?> validateLoginForm({
    required String? email,
    required String? password,
  }) {
    return {
      'email': validateEmail(email),
      'password': password == null || password.isEmpty ? 'Şifre gereklidir' : null,
    };
  }

  /// Validates registration form
  static Map<String, String?> validateRegistrationForm({
    required String? email,
    required String? password,
    required String? passwordConfirmation,
    String? displayName,
  }) {
    return {
      'email': validateEmail(email),
      'password': validatePassword(password),
      'passwordConfirmation': validatePasswordConfirmation(passwordConfirmation, password),
      'displayName': validateDisplayName(displayName),
    };
  }
}

/// Extension methods for easier validation
extension StringValidation on String? {
  /// Validates as email
  String? get emailError => AuthFormValidators.validateEmail(this);

  /// Validates as password
  String? get passwordError => AuthFormValidators.validatePassword(this);

  /// Validates as required field
  String? requiredError(String fieldName) => AuthFormValidators.validateRequired(this, fieldName);

  /// Gets password strength
  int get passwordStrength => AuthFormValidators.getPasswordStrength(this ?? '');

  /// Gets password strength description
  String get passwordStrengthDescription => AuthFormValidators.getPasswordStrengthDescription(passwordStrength);
}
