import 'package:flutter/material.dart';

/// Single source of truth for all colors in the SMS design system.
/// No hex values may be used anywhere in the app outside this file.
abstract final class AppColors {
  // ── Primary — Deep Navy ───────────────────────────────────────────────────
  /// Primary brand color. Headers, active states, primary buttons.
  static const Color navyDeep = Color(0xFF0B1F3A);

  /// AppBar backgrounds, bottom nav active, prominent cards.
  static const Color navyMedium = Color(0xFF1A3558);

  /// Subtle backgrounds, unselected tab tints, light badges.
  static const Color navyLight = Color(0xFF2E5481);

  // ── Gold Accent ───────────────────────────────────────────────────────────
  /// Primary accent. Use sparingly: FABs, active indicators, premium emphasis.
  static const Color goldPrimary = Color(0xFFF0A500);

  /// Soft gold for backgrounds behind gold elements, banners.
  static const Color goldLight = Color(0xFFFFF3D6);

  /// Pressed state for gold buttons, text on light gold backgrounds.
  static const Color goldDark = Color(0xFFBF8000);

  // ── Neutrals ──────────────────────────────────────────────────────────────
  /// Primary background for all screens.
  static const Color white = Color(0xFFFFFFFF);

  /// Card backgrounds, input fields, list backgrounds.
  static const Color surface50 = Color(0xFFF8F9FB);

  /// Dividers, inactive states, subtle separators.
  static const Color surface100 = Color(0xFFEEF1F5);

  /// Borders on cards and inputs.
  static const Color surface200 = Color(0xFFDDE2EA);

  /// Placeholder text, disabled labels, secondary metadata.
  static const Color grey400 = Color(0xFF9BA5B4);

  /// Secondary text — subtitles, descriptions, captions.
  static const Color grey600 = Color(0xFF637082);

  /// Primary text on white backgrounds.
  static const Color grey800 = Color(0xFF2D3748);

  /// Maximum contrast headings only.
  static const Color black = Color(0xFF0D1117);

  // ── Semantic — Success ────────────────────────────────────────────────────
  static const Color successGreen = Color(0xFF10B981);
  static const Color successLight = Color(0xFFD1FAE5);
  static const Color successDark = Color(0xFF065F46);

  // ── Semantic — Warning ────────────────────────────────────────────────────
  static const Color warningAmber = Color(0xFFF59E0B);
  static const Color warningLight = Color(0xFFFEF3C7);
  static const Color warningDark = Color(0xFF92400E);

  // ── Semantic — Error ──────────────────────────────────────────────────────
  static const Color errorRed = Color(0xFFEF4444);
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color errorDark = Color(0xFF991B1B);

  // ── Semantic — Info ───────────────────────────────────────────────────────
  static const Color infoBlue = Color(0xFF3B82F6);
  static const Color infoLight = Color(0xFFDBEAFE);
  static const Color infoDark = Color(0xFF1E40AF);

  // ── Subject / Category Colors ─────────────────────────────────────────────
  static const Color subjectMath = Color(0xFF6366F1);    // Indigo
  static const Color subjectScience = Color(0xFF10B981); // Emerald
  static const Color subjectEnglish = Color(0xFF3B82F6); // Blue
  static const Color subjectHindi = Color(0xFFEC4899);   // Pink
  static const Color subjectHistory = Color(0xFFF97316); // Orange
  static const Color subjectPhysics = Color(0xFF8B5CF6); // Violet
  static const Color subjectChem = Color(0xFF14B8A6);    // Teal
  static const Color subjectBio = Color(0xFF22C55E);     // Green
  static const Color subjectDefault = Color(0xFF64748B); // Slate

  // ── Transparency helpers ──────────────────────────────────────────────────
  static const Color transparent = Color(0x00000000);

  // ── Avatar fallback palette (seeded from name hash) ───────────────────────
  static const List<Color> avatarPalette = [
    Color(0xFF2E5481), // navyLight
    Color(0xFF0D9668), // successGreen 70%
    Color(0xFF1D6FED), // infoBlue 70%
    Color(0xFFD48E00), // goldPrimary 70%
    Color(0xFF7C3AED), // violet
    Color(0xFFDB2777), // pink
    Color(0xFF0891B2), // cyan
    Color(0xFFD97706), // amber
  ];

  /// Returns a subject color by cycling through the palette.
  static Color subjectByIndex(int index) {
    const palette = [
      subjectMath,
      subjectScience,
      subjectEnglish,
      subjectHindi,
      subjectHistory,
      subjectPhysics,
      subjectChem,
      subjectBio,
    ];
    return palette[index % palette.length];
  }

  /// Returns an avatar background color deterministically from a string hash.
  static Color avatarBackground(String seed) {
    final hash = seed.codeUnits.fold(0, (a, b) => a + b);
    return avatarPalette[hash % avatarPalette.length];
  }

  // ── Status chip helpers ───────────────────────────────────────────────────

  /// Background color for a status value.
  static Color statusBackground(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'DRAFT':
      case 'PROCESSING':
        return warningLight;
      case 'APPROVED':
      case 'PAID':
      case 'PRESENT':
      case 'ACTIVE':
      case 'PUBLISHED':
      case 'READY':
        return successLight;
      case 'REJECTED':
      case 'OVERDUE':
      case 'ABSENT':
      case 'FAILED':
        return errorLight;
      case 'IN_PROGRESS':
      case 'PARTIAL':
        return infoLight;
      case 'CLOSED':
      case 'INACTIVE':
      case 'LATE':
        return surface100;
      case 'RESOLVED':
        return successLight;
      default:
        return surface100;
    }
  }

  /// Foreground color for a status value.
  static Color statusForeground(String status) {
    switch (status.toUpperCase()) {
      case 'PENDING':
      case 'DRAFT':
      case 'PROCESSING':
        return warningDark;
      case 'APPROVED':
      case 'PAID':
      case 'PRESENT':
      case 'ACTIVE':
      case 'PUBLISHED':
      case 'READY':
        return successDark;
      case 'REJECTED':
      case 'OVERDUE':
      case 'ABSENT':
      case 'FAILED':
        return errorDark;
      case 'IN_PROGRESS':
      case 'PARTIAL':
        return infoDark;
      case 'CLOSED':
      case 'INACTIVE':
      case 'LATE':
        return grey600;
      case 'RESOLVED':
        return successDark;
      default:
        return grey600;
    }
  }
}