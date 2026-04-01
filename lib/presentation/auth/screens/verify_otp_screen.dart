import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../common/widgets/app_button.dart';
import '../widgets/otp_input.dart';

/// OTP verification screen stub for FM04.
/// FM05 will wire the actual API call via [AuthProvider].
class VerifyOtpScreen extends ConsumerStatefulWidget {
  const VerifyOtpScreen({
    super.key,
    this.email,
    this.phone,
  });

  final String? email;
  final String? phone;

  @override
  ConsumerState<VerifyOtpScreen> createState() => _VerifyOtpScreenState();
}

class _VerifyOtpScreenState extends ConsumerState<VerifyOtpScreen>
    with SingleTickerProviderStateMixin {
  String _otp = '';
  bool _isVerifying = false;
  bool _isResending = false;
  int _secondsRemaining = 60;
  late AnimationController _timerController;

  @override
  void initState() {
    super.initState();
    _timerController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 60),
    )..addListener(() {
        setState(() {
          _secondsRemaining = (60 * (1 - _timerController.value)).ceil();
        });
      });
    _timerController.forward();
  }

  @override
  void dispose() {
    _timerController.dispose();
    super.dispose();
  }

  String get _maskedIdentifier {
    if (widget.email != null) {
      final parts = widget.email!.split('@');
      if (parts.length == 2) {
        final local = parts[0];
        final masked = local.length > 2
            ? '${local[0]}***${local[local.length - 1]}'
            : local;
        return '$masked@${parts[1]}';
      }
      return widget.email!;
    }
    if (widget.phone != null) {
      final phone = widget.phone!;
      return phone.length > 4
          ? '****${phone.substring(phone.length - 4)}'
          : phone;
    }
    return '';
  }

  Future<void> _verify() async {
    if (_otp.length < 6) return;
    setState(() => _isVerifying = true);

    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isVerifying = false);

    // Navigate to reset password with a mock token.
    context.push(RouteNames.resetPassword, extra: {
      'resetToken': 'mock_reset_token',
    });
  }

  Future<void> _resend() async {
    if (_secondsRemaining > 0) return;
    setState(() => _isResending = true);
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;
    setState(() => _isResending = false);
    _timerController
      ..reset()
      ..forward();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppBar(
        backgroundColor: AppColors.navyDeep,
        foregroundColor: AppColors.white,
        elevation: 0,
        title: Text(
          'Verify OTP',
          style: AppTypography.titleLargeOnDark,
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppDimensions.space32),

              // Icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.infoLight,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.mark_email_read_outlined,
                    size: 40,
                    color: AppColors.infoBlue,
                  ),
                ),
              ),

              const SizedBox(height: AppDimensions.space24),

              Text(
                'Enter verification code',
                style: AppTypography.headlineSmall,
              ),
              const SizedBox(height: AppDimensions.space8),
              RichText(
                text: TextSpan(
                  style: AppTypography.bodyMedium,
                  children: [
                    const TextSpan(text: 'We sent a 6-digit code to '),
                    TextSpan(
                      text: _maskedIdentifier,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: AppColors.navyDeep,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: AppDimensions.space40),

              // OTP Input
              OtpInput(
                onCompleted: (otp) {
                  setState(() => _otp = otp);
                  _verify();
                },
                onChanged: (otp) => setState(() => _otp = otp),
              ),

              const SizedBox(height: AppDimensions.space32),

              // Verify button
              AppButton.primary(
                label: 'Verify',
                onTap: _otp.length == 6 && !_isVerifying ? _verify : null,
                isLoading: _isVerifying,
                isDisabled: _otp.length < 6,
              ),

              const SizedBox(height: AppDimensions.space24),

              // Resend timer
              Center(
                child: _secondsRemaining > 0
                    ? RichText(
                        text: TextSpan(
                          style: AppTypography.bodySmall,
                          children: [
                            const TextSpan(text: 'Resend code in '),
                            TextSpan(
                              text: '${_secondsRemaining}s',
                              style: AppTypography.bodySmall.copyWith(
                                color: AppColors.navyMedium,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      )
                    : GestureDetector(
                        onTap: _resend,
                        child: _isResending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: AppColors.navyMedium,
                                ),
                              )
                            : Text(
                                'Resend code',
                                style: AppTypography.bodyMediumLink,
                              ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}