import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import 'app_button.dart';

class AppErrorState extends StatefulWidget {
  const AppErrorState({
    super.key,
    this.message,
    this.onRetry,
    this.compact = false,
  });

  final String? message;
  final VoidCallback? onRetry;
  final bool compact;

  @override
  State<AppErrorState> createState() => _AppErrorStateState();
}

class _AppErrorStateState extends State<AppErrorState>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _ctrl, curve: Curves.easeOut));
    _ctrl.forward();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.compact ? 52.0 : 72.0;
    final effectiveMessage = widget.message?.isNotEmpty == true
        ? widget.message!
        : 'Something went wrong. Please try again.';

    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.space32,
                      vertical: widget.compact
                          ? AppDimensions.space16
                          : AppDimensions.space48,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: iconSize,
                          height: iconSize,
                          decoration: BoxDecoration(
                            color:
                                AppColors.errorRed.withValues(alpha: 0.08),
                            shape: BoxShape.circle,
                          ),
                          child: Icon(
                            Icons.error_outline_rounded,
                            size: iconSize * 0.48,
                            color:
                                AppColors.errorRed.withValues(alpha: 0.7),
                          ),
                        ),
                        SizedBox(
                          height: widget.compact
                              ? AppDimensions.space12
                              : AppDimensions.space20,
                        ),
                        Text(
                          'Something went wrong',
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.grey800,
                            fontWeight: FontWeight.w600,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: AppDimensions.space8),
                        Text(
                          effectiveMessage,
                          style: AppTypography.bodyMedium.copyWith(
                            color: AppColors.grey600,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.center,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (widget.onRetry != null) ...[
                          const SizedBox(height: AppDimensions.space24),
                          AppButton.secondary(
                            label: 'Try Again',
                            onTap: widget.onRetry,
                            fullWidth: false,
                            icon: Icons.refresh_rounded,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}