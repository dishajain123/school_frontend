import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// Draggable modal bottom sheet with design system styling.
///
/// Use the static [AppBottomSheet.show] method to present:
/// ```dart
/// await AppBottomSheet.show(
///   context,
///   title: 'Filter',
///   child: FilterWidget(),
/// );
/// ```
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

  // ── Static show helpers ───────────────────────────────────────────────────

  /// Shows a modal bottom sheet.
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
      barrierColor: AppColors.black.withValues(alpha: 0.5),
      builder: (_) => AppBottomSheet(
        title: title,
        titleWidget: titleWidget,
        subtitle: subtitle,
        child: child,
        actions: actions,
        showDragHandle: showDragHandle,
        maxHeightFraction: maxHeightFraction,
        padding: padding,
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
            topLeft: Radius.circular(AppDimensions.radiusXL),
            topRight: Radius.circular(AppDimensions.radiusXL),
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Drag handle
            if (showDragHandle)
              Padding(
                padding: const EdgeInsets.only(top: AppDimensions.space12),
                child: Center(
                  child: Container(
                    width: AppDimensions.dragHandleWidth,
                    height: AppDimensions.dragHandleHeight,
                    decoration: BoxDecoration(
                      color: AppColors.surface200,
                      borderRadius: BorderRadius.circular(
                          AppDimensions.radiusFull),
                    ),
                  ),
                ),
              ),

            // Header
            if (title != null ||
                titleWidget != null ||
                subtitle != null) ...[
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppDimensions.space16,
                  AppDimensions.space16,
                  AppDimensions.space16,
                  0,
                ),
                child: titleWidget ??
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (title != null)
                          Text(
                            title!,
                            style: AppTypography.headlineSmall,
                          ),
                        if (subtitle != null) ...[
                          const SizedBox(height: AppDimensions.space4),
                          Text(
                            subtitle!,
                            style: AppTypography.bodyMedium,
                          ),
                        ],
                      ],
                    ),
              ),
            ],

            // Content
            Flexible(
              child: SingleChildScrollView(
                padding: padding ??
                    EdgeInsets.fromLTRB(
                      AppDimensions.space16,
                      AppDimensions.space16,
                      AppDimensions.space16,
                      AppDimensions.space32 + bottomPadding,
                    ),
                child: child,
              ),
            ),

            // Action buttons
            if (actions != null && actions!.isNotEmpty)
              Padding(
                padding: EdgeInsets.fromLTRB(
                  AppDimensions.space16,
                  AppDimensions.space8,
                  AppDimensions.space16,
                  AppDimensions.space16 + bottomPadding,
                ),
                child: Row(
                  children: actions!
                      .map(
                        (a) => Expanded(
                          child: Padding(
                            padding: EdgeInsets.only(
                              left: actions!.indexOf(a) > 0
                                  ? AppDimensions.space8
                                  : 0,
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