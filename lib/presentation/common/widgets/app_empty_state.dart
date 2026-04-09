import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import 'app_button.dart';

/// Displayed when a list or page has no content.
///
/// Provides a centered icon, contextual heading, subtitle, and optional action.
/// Always use this instead of leaving screens blank.
class AppEmptyState extends StatefulWidget {
  const AppEmptyState({
    super.key,
    required this.title,
    this.subtitle,
    this.icon,
    this.actionLabel,
    this.onAction,
    this.iconColor,
    this.compact = false,
  });

  final String title;
  final String? subtitle;
  final IconData? icon;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  /// Compact mode — smaller icon and spacing for inline use.
  final bool compact;

  @override
  State<AppEmptyState> createState() => _AppEmptyStateState();
}

class _AppEmptyStateState extends State<AppEmptyState>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOut,
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.05),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOut));

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.compact
        ? AppDimensions.iconXL
        : AppDimensions.iconJumbo;

    return FadeTransition(
      opacity: _fadeAnimation,
      child: SlideTransition(
        position: _slideAnimation,
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppDimensions.space32,
                      vertical: widget.compact
                          ? AppDimensions.space24
                          : AppDimensions.space48,
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          widget.icon ?? Icons.inbox_outlined,
                          size: iconSize,
                          color: widget.iconColor ?? AppColors.grey400,
                        ),
                        SizedBox(
                          height: widget.compact
                              ? AppDimensions.space16
                              : AppDimensions.space24,
                        ),
                        Text(
                          widget.title,
                          style: AppTypography.headlineSmall.copyWith(
                            color: AppColors.grey800,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        if (widget.subtitle != null) ...[
                          const SizedBox(height: AppDimensions.space8),
                          Text(
                            widget.subtitle!,
                            style: AppTypography.bodyMedium,
                            textAlign: TextAlign.center,
                            maxLines: 4,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                        if (widget.actionLabel != null &&
                            widget.onAction != null) ...[
                          const SizedBox(height: AppDimensions.space24),
                          AppButton.primary(
                            label: widget.actionLabel!,
                            onTap: widget.onAction,
                            fullWidth: false,
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
