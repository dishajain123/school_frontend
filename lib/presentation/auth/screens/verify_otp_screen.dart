import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../common/widgets/app_button.dart';
import '../widgets/otp_input.dart';

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

  late AnimationController _contentAnim;
  late Animation<double> _contentFade;
  late Animation<Offset> _contentSlide;

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

    _contentAnim = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );
    _contentFade =
        CurvedAnimation(parent: _contentAnim, curve: Curves.easeOut);
    _contentSlide = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _contentAnim, curve: Curves.easeOut));
    _contentAnim.forward();
  }

  @override
  void dispose() {
    _timerController.dispose();
    _contentAnim.dispose();
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
      body: Column(
        children: [
          _OtpHeader(onBack: () => context.pop()),
          Expanded(
            child: FadeTransition(
              opacity: _contentFade,
              child: SlideTransition(
                position: _contentSlide,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          color: AppColors.infoBlue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: const Icon(
                          Icons.mark_email_read_outlined,
                          size: 28,
                          color: AppColors.infoBlue,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'Enter verification code',
                        style: AppTypography.headlineSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          fontSize: 20,
                          letterSpacing: -0.3,
                          color: AppColors.grey800,
                        ),
                      ),
                      const SizedBox(height: 8),
                      RichText(
                        text: TextSpan(
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.grey500,
                            height: 1.5,
                          ),
                          children: [
                            const TextSpan(
                                text: 'We sent a 6-digit code to '),
                            TextSpan(
                              text: _maskedIdentifier,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w700,
                                color: AppColors.navyDeep,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 36),
                      OtpInput(
                        onCompleted: (otp) {
                          setState(() => _otp = otp);
                          _verify();
                        },
                        onChanged: (otp) => setState(() => _otp = otp),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: _secondsRemaining > 0
                            ? _TimerText(seconds: _secondsRemaining)
                            : _ResendButton(
                                isResending: _isResending,
                                onResend: _resend,
                              ),
                      ),
                      const SizedBox(height: 32),
                      AppButton.primary(
                        label: 'Verify Code',
                        onTap: _otp.length == 6 && !_isVerifying
                            ? _verify
                            : null,
                        isLoading: _isVerifying,
                        isDisabled: _otp.length < 6,
                        icon: Icons.verified_outlined,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _OtpHeader extends StatelessWidget {
  const _OtpHeader({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final top = MediaQuery.of(context).padding.top;
    return Container(
      padding: EdgeInsets.fromLTRB(8, top + 8, 16, 16),
      decoration: const BoxDecoration(
        color: AppColors.navyDeep,
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(24),
          bottomRight: Radius.circular(24),
        ),
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.arrow_back_ios_new_rounded,
                  color: AppColors.white, size: 16),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            'Verify OTP',
            style: AppTypography.titleLargeOnDark.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 17,
            ),
          ),
        ],
      ),
    );
  }
}

class _TimerText extends StatelessWidget {
  const _TimerText({required this.seconds});
  final int seconds;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surface100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 13, color: AppColors.grey400),
          const SizedBox(width: 5),
          RichText(
            text: TextSpan(
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.grey500,
              ),
              children: [
                const TextSpan(text: 'Resend in '),
                TextSpan(
                  text: '${seconds}s',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.navyMedium,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ResendButton extends StatelessWidget {
  const _ResendButton({required this.isResending, required this.onResend});
  final bool isResending;
  final VoidCallback onResend;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onResend,
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.navyDeep.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(20),
        ),
        child: isResending
            ? const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                  strokeWidth: 1.5,
                  color: AppColors.navyMedium,
                ),
              )
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.refresh_rounded,
                      size: 14, color: AppColors.navyMedium),
                  const SizedBox(width: 5),
                  Text(
                    'Resend code',
                    style: AppTypography.labelMedium.copyWith(
                      color: AppColors.navyMedium,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}