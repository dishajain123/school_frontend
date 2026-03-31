import 'package:flutter/material.dart';
import 'app_colors.dart';
import 'app_dimensions.dart';

/// Reusable [BoxDecoration] presets and shadow definitions.
/// Reference these instead of constructing inline decorations.
abstract final class AppDecorations {
  // =========================================================================
  // SHADOWS
  // Exact values from the design system spec (section 5).
  // =========================================================================

  /// Level 0 — Flat, no shadow (surface tiles, section backgrounds).
  static const List<BoxShadow> shadow0 = [];

  /// Level 1 — Subtle lift (default cards, input fields on focus).
  /// navyDeep at 5% opacity
  static const List<BoxShadow> shadow1 = [
    BoxShadow(
      color: Color(0x0D0B1F3A),
      blurRadius: 8,
      offset: Offset(0, 2),
      spreadRadius: 0,
    ),
  ];

  /// Level 2 — Medium lift (hovered/active cards, bottom sheet handle area).
  /// navyDeep at 8% opacity
  static const List<BoxShadow> shadow2 = [
    BoxShadow(
      color: Color(0x140B1F3A),
      blurRadius: 16,
      offset: Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  /// Level 3 — Prominent lift (FABs, dialogs, modals).
  /// navyDeep at 12% opacity
  static const List<BoxShadow> shadow3 = [
    BoxShadow(
      color: Color(0x1F0B1F3A),
      blurRadius: 32,
      offset: Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  /// Bottom navigation bar top shadow (reversed Level 1).
  static const List<BoxShadow> shadowBottomNav = [
    BoxShadow(
      color: Color(0x0D0B1F3A),
      blurRadius: 8,
      offset: Offset(0, -2),
      spreadRadius: 0,
    ),
  ];

  // =========================================================================
  // CARD DECORATIONS
  // =========================================================================

  /// Standard list card — white, radiusMedium, shadow1, subtle border.
  static BoxDecoration get card => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200, width: AppDimensions.borderThin),
        boxShadow: shadow1,
      );

  /// Hero / Dashboard card — white, radiusLarge, shadow2.
  static BoxDecoration get cardHero => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: shadow2,
      );

  /// Flat card — no shadow, only border (for dense/inline displays).
  static BoxDecoration get cardFlat => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200, width: AppDimensions.borderThin),
      );

  /// Surface card — off-white background, no shadow (section backgrounds).
  static BoxDecoration get cardSurface => BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface100, width: AppDimensions.borderThin),
      );

  /// Navy gradient card — primary brand colored card (dashboard hero, headers).
  static BoxDecoration get cardNavy => BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navyMedium],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        boxShadow: shadow2,
      );

  /// Navy gradient — no radius (for full-bleed backgrounds like AppBar area).
  static const BoxDecoration navyGradientFlat = BoxDecoration(
    gradient: LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [AppColors.navyDeep, AppColors.navyMedium],
    ),
  );

  /// Gold accent card (fee due, premium emphasis).
  static BoxDecoration get cardGold => BoxDecoration(
        color: AppColors.goldLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: AppColors.goldPrimary.withValues(alpha: 0.3),
          width: AppDimensions.borderThin,
        ),
      );

  // =========================================================================
  // INPUT FIELD DECORATIONS
  // =========================================================================

  /// Input field — unfocused state (surface50 fill, surface200 border).
  static BoxDecoration get inputField => BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.surface200,
          width: AppDimensions.borderMedium,
        ),
      );

  /// Input field — focused state (white fill, navyMedium border).
  static BoxDecoration get inputFieldFocused => BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.navyMedium,
          width: AppDimensions.borderMedium,
        ),
      );

  /// Input field — error state.
  static BoxDecoration get inputFieldError => BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.errorRed,
          width: AppDimensions.borderMedium,
        ),
      );

  // =========================================================================
  // STATUS / BADGE DECORATIONS
  // =========================================================================

  static BoxDecoration statusSuccess = BoxDecoration(
    color: AppColors.successLight,
    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
  );

  static BoxDecoration statusError = BoxDecoration(
    color: AppColors.errorLight,
    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
  );

  static BoxDecoration statusWarning = BoxDecoration(
    color: AppColors.warningLight,
    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
  );

  static BoxDecoration statusInfo = BoxDecoration(
    color: AppColors.infoLight,
    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
  );

  static BoxDecoration statusNeutral = BoxDecoration(
    color: AppColors.surface100,
    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
  );

  static BoxDecoration statusNavy = BoxDecoration(
    color: AppColors.navyLight.withValues(alpha: 0.12),
    borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
  );

  // =========================================================================
  // BOTTOM SHEET
  // =========================================================================

  static const BoxDecoration bottomSheet = BoxDecoration(
    color: AppColors.white,
    borderRadius: BorderRadius.only(
      topLeft: Radius.circular(AppDimensions.radiusXL),
      topRight: Radius.circular(AppDimensions.radiusXL),
    ),
  );

  // =========================================================================
  // QUICK ACTION ICON CONTAINER
  // Container for domain icons on dashboard quick actions.
  // 40×40px square, radiusSmall, background = color at 12% opacity.
  // =========================================================================

  static BoxDecoration quickActionContainer(Color color) => BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
      );

  // =========================================================================
  // AVATAR BACKGROUND
  // =========================================================================

  static BoxDecoration avatarBackground(Color color) => BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      );

  // =========================================================================
  // SECTION HEADER UNDERLINE
  // =========================================================================

  static BoxDecoration get sectionAccent => BoxDecoration(
        border: Border(
          left: BorderSide(
            color: AppColors.goldPrimary,
            width: 3,
          ),
        ),
      );
}