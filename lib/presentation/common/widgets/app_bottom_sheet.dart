import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

class AppBottomSheet extends StatelessWidget {
  const AppBottomSheet({
    super.key,
    this.title,
    required this.child,
    this.actions,
    this.showDragHandle = true,
    this.maxHeightFraction = AppDimensions.bottomSheetMaxHeight,
    this.padding,
    this.titleWidget,
    this.subtitle,
  });

  final String? title;
  final Widget? titleWidget;
  final String? subtitle;
  final Widget child;
  final List<Widget>? actions;
  final bool showDragHandle;
  final double maxHeightFraction;
  final EdgeInsetsGeometry? padding;

  static Future<T?> show<T>(
    BuildContext context, {
    String? title,
    Widget? titleWidget,
    String? subtitle,
    required Widget child,
    List<Widget>? actions,
    bool showDragHandle = true,
    double maxHeightFraction = AppDimensions.bottomSheetMaxHeight,
    bool isScrollControlled = true,
    bool isDismissible = true,
    bool enableDrag = true,
    EdgeInsetsGeometry? padding,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      isDismissible: isDismissible,
      enableDrag: enableDrag,
      backgroundColor: Colors.transparent,
      barrierColor: AppColors.black.withValues(alpha: 0.45),
      builder: (_) => AppBottomSheet(
        title: title,
        titleWidget: titleWidget,
        subtitle: subtitle,
        actions: actions,
        showDragHandle: showDragHandle,
        maxHeightFraction: maxHeightFraction,
        padding: padding,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.sizeOf(context).height;
    final bottomPadding = MediaQuery.viewInsetsOf(context).bottom;

    return ConstrainedBox(
      constraints: BoxConstraints(
        maxHeight: screenHeight * maxHeightFraction + bottomPadding,
      ),
      child: Container(
        decoration: const BoxDecoration(
          color: AppColors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (showDragHandle)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppColors.surface200,
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull),
                    ),
                  ),
                ),
              ),
            if (title != null ||
                titleWidget != null ||
                subtitle != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
                child: titleWidget ??
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: AppTypography.headlineSmall.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 17,
                              letterSpacing: -0.3,
                            ),
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            subtitle!,
                            style: AppTypography.bodyMedium.copyWith(
                              color: AppColors.grey600,
                            ),
                          ),
                        ],
                      ],
                    ),
              ),
            ],
            Flexible(
              child: SingleChildScrollView(
                padding: padding ??
                    EdgeInsets.fromLTRB(
                      20,
                      16,
                      20,
                      AppDimensions.space32 + bottomPadding,
                    ),
                child: child,
              ),
            ),
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  20,
                  AppDimensions.space8,
                  20,
                  AppDimensions.space16 + bottomPadding,
                ),
                child: Row(
                  children: actions!
                      .map(
                        (a) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: actions!.indexOf(a) > 0 ? 10 : 0,
                            ),
                            child: a,
                          ),
                        ),
                      )
                      .toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}