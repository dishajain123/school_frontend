class Validators {
  Validators._();

  /// Required field — returns error if blank.
  static String? validateRequired(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required.';
    }
    return null;
  }

  /// Email format validation.
  static String? validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required.';
    }
    final pattern = RegExp(r'^[a-zA-Z0-9._%+\-]+@[a-zA-Z0-9.\-]+\.[a-zA-Z]{2,}$');
    if (!pattern.hasMatch(value.trim())) {
      return 'Please enter a valid email address.';
    }
    return null;
  }

  /// Phone number validation (10–15 digits, optional leading +).
  static String? validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Phone number is required.';
    }
    final cleaned = value.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    if (!RegExp(r'^\+?[0-9]{10,15}$').hasMatch(cleaned)) {
      return 'Enter a valid phone number (10–15 digits).';
    }
    return null;
  }

  /// Password strength: min 8 chars, one uppercase, one digit.
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) return 'Password is required.';
    if (value.length < 8) return 'Password must be at least 8 characters.';
    if (!RegExp(r'[A-Z]').hasMatch(value)) {
      return 'Password must include at least one uppercase letter.';
    }
    if (!RegExp(r'\d').hasMatch(value)) {
      return 'Password must include at least one number.';
    }
    return null;
  }

  /// Confirm password match.
  static String? validateConfirmPassword(String? value, String original) {
    if (value == null || value.isEmpty) return 'Please confirm your password.';
    if (value != original) return 'Passwords do not match.';
    return null;
  }

  /// Minimum length.
  static String? validateMinLength(String? value, int min, [String? fieldName]) {
    if (value == null || value.length < min) {
      return '${fieldName ?? 'This field'} must be at least $min characters.';
    }
    return null;
  }

  /// Numeric value (positive).
  static String? validatePositiveNumber(String? value, [String? fieldName]) {
    if (value == null || value.trim().isEmpty) {
      return '${fieldName ?? 'This field'} is required.';
    }
    final n = num.tryParse(value.trim());
    if (n == null || n <= 0) {
      return '${fieldName ?? 'This field'} must be a positive number.';
    }
    return null;
  }

  /// OTP — exactly 6 digits.
  static String? validateOtp(String? value) {
    if (value == null || !RegExp(r'^\d{6}$').hasMatch(value)) {
      return 'OTP must be exactly 6 digits.';
    }
    return null;
  }
}