/// Response model for POST /auth/login
class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final String tokenType;
  final int expiresIn;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory TokenResponse.fromJson(Map<String, dynamic> json) {
    return TokenResponse(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int,
    );
  }
}

/// Response model for POST /auth/refresh
class AccessTokenResponse {
  final String accessToken;
  final String tokenType;
  final int expiresIn;

  const AccessTokenResponse({
    required this.accessToken,
    required this.tokenType,
    required this.expiresIn,
  });

  factory AccessTokenResponse.fromJson(Map<String, dynamic> json) {
    return AccessTokenResponse(
      accessToken: json['access_token'] as String,
      tokenType: json['token_type'] as String? ?? 'bearer',
      expiresIn: json['expires_in'] as int,
    );
  }
}

/// Response model for POST /auth/forgot-password
class ForgotPasswordResponse {
  final String message;

  /// Only present in DEBUG mode – the plain OTP for dev testing.
  final String? hint;

  const ForgotPasswordResponse({required this.message, this.hint});

  factory ForgotPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ForgotPasswordResponse(
      message: json['message'] as String,
      hint: json['hint'] as String?,
    );
  }
}

/// Response model for POST /auth/verify-otp
class VerifyOtpResponse {
  final String resetToken;
  final int expiresIn;
  final String message;

  const VerifyOtpResponse({
    required this.resetToken,
    required this.expiresIn,
    required this.message,
  });

  factory VerifyOtpResponse.fromJson(Map<String, dynamic> json) {
    return VerifyOtpResponse(
      resetToken: json['reset_token'] as String,
      expiresIn: json['expires_in'] as int,
      message: json['message'] as String,
    );
  }
}

/// Response model for POST /auth/reset-password
class ResetPasswordResponse {
  final String message;

  const ResetPasswordResponse({required this.message});

  factory ResetPasswordResponse.fromJson(Map<String, dynamic> json) {
    return ResetPasswordResponse(message: json['message'] as String);
  }
}