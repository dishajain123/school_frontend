/// Spacing, border radius, elevation, icon size, and layout constants.
/// All measurements in logical pixels. Never hardcode values outside this file.
abstract final class AppDimensions {
  // ── Spacing Scale ─────────────────────────────────────────────────────────
  /// 2px — extreme micro gaps (e.g. badge dot offset)
  static const double space2 = 2.0;

  /// 4px — icon-to-text gaps, internal chip padding
  static const double space4 = 4.0;

  /// 8px — between related elements, icon margins
  static const double space8 = 8.0;

  /// 12px — compact spacing, between label and value
  static const double space12 = 12.0;

  /// 16px — default card padding, standard gap
  static const double space16 = 16.0;

  /// 20px — between cards, page horizontal padding
  static const double space20 = 20.0;

  /// 24px — section spacing, modal top padding
  static const double space24 = 24.0;

  /// 32px — between major page sections
  static const double space32 = 32.0;

  /// 40px — bottom padding for scroll screens (clears FAB + nav)
  static const double space40 = 40.0;

  /// 48px — jumbo / hero area padding, splash
  static const double space48 = 48.0;

  /// 64px — extra jumbo (empty state top offset)
  static const double space64 = 64.0;

  // ── Aliases for readability ───────────────────────────────────────────────
  static const double spacingXs = space4;
  static const double spacingSm = space8;
  static const double spacingMd = space16;
  static const double spacingLg = space24;
  static const double spacingXl = space32;

  // ── Screen Padding ────────────────────────────────────────────────────────
  /// Standard horizontal page padding on all screens.
  static const double pageHorizontal = space16;

  /// Standard vertical page padding on scroll screens.
  static const double pageVertical = space16;

  /// Bottom padding for scroll screens (clears FAB + bottom nav).
  static const double pageBottomScroll = space40;

  /// Card grid: 2-column gap.
  static const double gridGap2col = space12;

  /// Card grid: 3-column gap.
  static const double gridGap3col = space8;

  // ── Border Radius ─────────────────────────────────────────────────────────
  /// 8px — input fields, small chips, dense chips
  static const double radiusSmall = 8.0;

  /// 12px — default cards, buttons, list tiles
  static const double radiusMedium = 12.0;

  /// 16px — bottom sheet tops, prominent/dashboard cards
  static const double radiusLarge = 16.0;

  /// 24px — hero dashboard sections, profile photo backgrounds
  static const double radiusXL = 24.0;

  /// 999px — circular elements, pill chips, avatar, FAB
  static const double radiusFull = 999.0;

  // ── Component Heights ─────────────────────────────────────────────────────
  static const double buttonHeight = 52.0;
  static const double buttonHeightSm = 40.0;
  static const double buttonHeightXs = 32.0;
  static const double inputHeight = 52.0;
  static const double appBarHeight = 56.0;
  static const double bottomNavHeight = 64.0;
  static const double filterBarHeight = 52.0;
  static const double chipHeight = 28.0;
  static const double dragHandleHeight = 4.0;
  static const double dragHandleWidth = 32.0;

  // ── List Tile ─────────────────────────────────────────────────────────────
  static const double listTileHeight = 64.0;
  static const double listTileHeightWithSubtitle = 72.0;
  static const double listTileDenseHeight = 56.0;
  static const double listTileLeadingSize = 40.0;
  static const double listTileDividerIndent = 56.0;

  // ── Avatar Sizes ──────────────────────────────────────────────────────────
  static const double avatarSm = 32.0;   // compact lists
  static const double avatarMd = 40.0;   // standard list tile
  static const double avatarLg = 56.0;   // detail header
  static const double avatarXl = 80.0;   // profile screen

  // ── Icon Sizes ────────────────────────────────────────────────────────────
  /// 16px — inside chips, small badges
  static const double iconXS = 16.0;

  /// 20px — trailing icons in tiles, input field icons
  static const double iconSM = 20.0;

  /// 24px — standard: AppBar, nav bar, card icons
  static const double iconMD = 24.0;

  /// 32px — dashboard quick action icons
  static const double iconLG = 32.0;

  /// 48px — empty state illustrations
  static const double iconXL = 48.0;

  /// 64px — full-page empty states, splash
  static const double iconJumbo = 64.0;

  // ── Borders ───────────────────────────────────────────────────────────────
  static const double borderThin = 1.0;
  static const double borderMedium = 1.5;
  static const double borderThick = 2.0;

  // ── Quick Action Container ────────────────────────────────────────────────
  static const double quickActionIconContainer = 40.0;

  // ── Bottom Sheet ─────────────────────────────────────────────────────────
  static const double bottomSheetMaxHeight = 0.9; // 90% of screen height

  // ── Tab Bar ──────────────────────────────────────────────────────────────
  static const double tabBarHeight = 46.0;
  static const double tabIndicatorWeight = 2.0;

  // ── Minimum tap target ────────────────────────────────────────────────────
  static const double tapTargetMin = 48.0;
}