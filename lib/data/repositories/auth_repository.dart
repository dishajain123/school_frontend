import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/api_constants.dart';
import '../../core/network/dio_client.dart';
import '../models/auth/current_user.dart';
import '../models/auth/login_request.dart';
import '../models/auth/token_response.dart';

class AuthRepository {
  const AuthRepository(this._dio);

  final Dio _dio;

  /// POST /auth/login
  Future<TokenResponse> login({
    String? email,
    String? phone,
    required String password,
  }) async {
    final response = await _dio.post(
      ApiConstants.login,
      data: LoginRequest(email: email, phone: phone, password: password)
          .toJson(),
    );
    return TokenResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /auth/refresh
  Future<AccessTokenResponse> refresh(String refreshToken) async {
    final response = await _dio.post(
      ApiConstants.refresh,
      data: {'refresh_token': refreshToken},
    );
    return AccessTokenResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /auth/logout  — fire-and-forget; 204 on success.
  Future<void> logout({String? refreshToken}) async {
    await _dio.post(
      ApiConstants.logout,
      data: {'refresh_token': refreshToken},
    );
  }

  /// POST /auth/forgot-password
  Future<ForgotPasswordResponse> forgotPassword({
    String? email,
    String? phone,
  }) async {
    final body = <String, dynamic>{};
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    final response = await _dio.post(ApiConstants.forgotPassword, data: body);
    return ForgotPasswordResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// POST /auth/verify-otp
  Future<VerifyOtpResponse> verifyOtp({
    String? email,
    String? phone,
    required String otpCode,
  }) async {
    final body = <String, dynamic>{'otp_code': otpCode};
    if (email != null && email.isNotEmpty) body['email'] = email;
    if (phone != null && phone.isNotEmpty) body['phone'] = phone;
    final response = await _dio.post(ApiConstants.verifyOtp, data: body);
    return VerifyOtpResponse.fromJson(response.data as Map<String, dynamic>);
  }

  /// POST /auth/reset-password
  Future<ResetPasswordResponse> resetPassword({
    required String resetToken,
    required String newPassword,
  }) async {
    final response = await _dio.post(
      ApiConstants.resetPassword,
      data: {'reset_token': resetToken, 'new_password': newPassword},
    );
    return ResetPasswordResponse.fromJson(
        response.data as Map<String, dynamic>);
  }

  /// GET /auth/me
  Future<CurrentUser> getMe() async {
    final response = await _dio.get(ApiConstants.authMe);
    return CurrentUser.fromJson(response.data as Map<String, dynamic>);
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(dioClientProvider));
});