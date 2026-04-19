import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// All TextStyle constants using Inter via Google Fonts.
/// Never use literal font sizes or weights outside this file.
abstract final class AppTypography {
  // ── Internal builder ──────────────────────────────────────────────────────
  static _inter({
    required double fontSize,
    required FontWeight fontWeight,
    double letterSpacing = 0,
    double? height,
    Color color = AppColors.grey800,
    TextDecoration? decoration,
  }) =>
      GoogleFonts.inter(
        fontSize: fontSize,
        fontWeight: fontWeight,
        letterSpacing: letterSpacing,
        height: height,
        color: color,
        decoration: decoration,
      );

  // ── Display ───────────────────────────────────────────────────────────────
  /// 32px / w700 — Large hero text, splash, onboarding.
  static final displayLarge = _inter(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.5,
    color: AppColors.black,
  );

  // ── Headline ──────────────────────────────────────────────────────────────
  /// 24px / w700 — Page titles in AppBar, major section headings.
  static final headlineLarge = _inter(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.3,
    color: AppColors.black,
  );

  /// 20px / w600 — Section major headings, dialog titles.
  static final headlineMedium = _inter(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.2,
    color: AppColors.black,
  );

  /// 18px / w600 — Sub-section headings, card prominent titles.
  static final headlineSmall = _inter(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    letterSpacing: -0.1,
    color: AppColors.grey800,
  );

  // ── Title ─────────────────────────────────────────────────────────────────
  /// 16px / w600 — Card titles, list item primary labels.
  static final titleLarge = _inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.grey800,
  );

  /// 15px / w500 — Secondary card titles, modal section labels.
  static final titleMedium = _inter(
    fontSize: 15,
    fontWeight: FontWeight.w500,
    color: AppColors.grey800,
  );

  /// 14px / w500 — Tertiary labels, dense list primary text.
  static final titleSmall = _inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.grey800,
  );

  // ── Body ──────────────────────────────────────────────────────────────────
  /// 16px / w400 — Main descriptive text, paragraphs, form field values.
  static final bodyLarge = _inter(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.grey800,
  );

  /// 14px / w400 — Supporting text, subtitles, descriptions.
  static final bodyMedium = _inter(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    height: 1.4,
    color: AppColors.grey600,
  );

  /// 13px / w400 — Supplementary text, card metadata.
  static final bodySmall = _inter(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    height: 1.35,
    color: AppColors.grey600,
  );

  // ── Label ─────────────────────────────────────────────────────────────────
  /// 14px / w500 — Chips, form labels, section headers, button text.
  static final labelLarge = _inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.grey800,
  );

  /// 12px / w500 — Badge text, small chips, input field labels.
  static final labelMedium = _inter(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.3,
    color: AppColors.grey600,
  );

  /// 11px / w500 — Status chip text, micro labels.
  static final labelSmall = _inter(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.4,
    color: AppColors.grey400,
  );

  // ── Caption ───────────────────────────────────────────────────────────────
  /// 11px / w400 — Timestamps, metadata, fine print.
  static final caption = _inter(
    fontSize: 11,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.2,
    height: 1.3,
    color: AppColors.grey400,
  );

  // ── Button ────────────────────────────────────────────────────────────────
  /// Used inside ElevatedButton and OutlinedButton — same as labelLarge on white.
  static final buttonPrimary = _inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.white,
  );

  static final buttonSecondary = _inter(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.navyDeep,
  );

  static final buttonText = _inter(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.navyMedium,
  );

  // ── Convenience copies with color overrides ───────────────────────────────

  /// [labelLarge] on a white/navy dark background.
  static final labelLargeOnDark = _inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.white,
  );

  /// [bodyMedium] with primary color for links/tappable text.
  static final bodyMediumLink = _inter(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0,
    height: 1.5,
    color: AppColors.navyMedium,
    decoration: TextDecoration.underline,
  );

  /// [titleLarge] on dark (AppBar title, dark card header).
  static final titleLargeOnDark = _inter(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    color: AppColors.white,
  );

  // ── Derive Google Fonts TextTheme for ThemeData ───────────────────────────
  static TextTheme toTextTheme() {
    final base = GoogleFonts.interTextTheme();
    return base.copyWith(
      displayLarge: displayLarge,
      headlineLarge: headlineLarge,
      headlineMedium: headlineMedium,
      headlineSmall: headlineSmall,
      titleLarge: titleLarge,
      titleMedium: titleMedium,
      titleSmall: titleSmall,
      bodyLarge: bodyLarge,
      bodyMedium: bodyMedium,
      bodySmall: bodySmall,
      labelLarge: labelLarge,
      labelMedium: labelMedium,
      labelSmall: labelSmall,
    );
  }
}
