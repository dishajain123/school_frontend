import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_decorations.dart';
import 'app_dimensions.dart';
import 'app_typography.dart';

/// Builds and exports the complete [ThemeData] for the SMS app.
///
/// Usage in [MaterialApp.router]:
/// ```dart
/// theme: AppTheme.light(),
/// ```
abstract final class AppTheme {
  static ThemeData light() {
    // ── Base color scheme ─────────────────────────────────────────────────
    const colorScheme = ColorScheme(
      brightness: Brightness.light,
      primary: AppColors.navyDeep,
      onPrimary: AppColors.white,
      primaryContainer: AppColors.navyLight,
      onPrimaryContainer: AppColors.white,
      secondary: AppColors.goldPrimary,
      onSecondary: AppColors.navyDeep,
      secondaryContainer: AppColors.goldLight,
      onSecondaryContainer: AppColors.navyDeep,
      tertiary: AppColors.navyMedium,
      onTertiary: AppColors.white,
      tertiaryContainer: AppColors.surface100,
      onTertiaryContainer: AppColors.navyDeep,
      error: AppColors.errorRed,
      onError: AppColors.white,
      errorContainer: AppColors.errorLight,
      onErrorContainer: AppColors.errorDark,
      surface: AppColors.white,
      onSurface: AppColors.grey800,
      surfaceContainerHighest: AppColors.surface100,
      onSurfaceVariant: AppColors.grey600,
      outline: AppColors.surface200,
      outlineVariant: AppColors.surface100,
      shadow: AppColors.black,
      scrim: AppColors.black,
      inverseSurface: AppColors.navyDeep,
      onInverseSurface: AppColors.white,
      inversePrimary: AppColors.navyLight,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,

      // ── Scaffold ─────────────────────────────────────────────────────────
      scaffoldBackgroundColor: AppColors.surface50,

      // ── Text Theme ────────────────────────────────────────────────────────
      textTheme: AppTypography.toTextTheme(),
      primaryTextTheme: AppTypography.toTextTheme(),

      // ── AppBar ────────────────────────────────────────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.navyDeep,
        foregroundColor: AppColors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleTextStyle: AppTypography.titleLargeOnDark.copyWith(fontSize: 18),
        iconTheme: const IconThemeData(
          color: AppColors.white,
          size: AppDimensions.iconMD,
        ),
        actionsIconTheme: const IconThemeData(
          color: AppColors.white,
          size: AppDimensions.iconMD,
        ),
        systemOverlayStyle: SystemUiOverlayStyle.light.copyWith(
          statusBarColor: Colors.transparent,
        ),
        toolbarHeight: AppDimensions.appBarHeight,
      ),

      // ── Tab Bar ───────────────────────────────────────────────────────────
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.white,
        unselectedLabelColor: AppColors.white.withValues(alpha: 0.6),
        labelStyle: AppTypography.labelLarge.copyWith(
          color: AppColors.white,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: AppTypography.labelLarge.copyWith(
          color: AppColors.white.withValues(alpha: 0.6),
          fontWeight: FontWeight.w500,
        ),
        indicator: const UnderlineTabIndicator(
          borderSide: BorderSide(
            color: AppColors.goldPrimary,
            width: AppDimensions.tabIndicatorWeight + 1,
          ),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        overlayColor: WidgetStateProperty.all(
          AppColors.white.withValues(alpha: 0.08),
        ),
        dividerColor: Colors.transparent,
      ),

      // ── Bottom Navigation Bar ──────────────────────────────────────────────
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: AppColors.white,
        selectedItemColor: AppColors.navyDeep,
        unselectedItemColor: AppColors.grey400,
        elevation: 0, // shadow applied via decoration in shell widget
        type: BottomNavigationBarType.fixed,
        showSelectedLabels: true,
        showUnselectedLabels: true,
        selectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w400,
        ),
        selectedIconTheme: IconThemeData(
          size: AppDimensions.iconMD,
          color: AppColors.navyDeep,
        ),
        unselectedIconTheme: IconThemeData(
          size: AppDimensions.iconMD,
          color: AppColors.grey400,
        ),
      ),

      // ── Card ──────────────────────────────────────────────────────────────
      cardTheme: CardThemeData(
        color: AppColors.white,
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          side: const BorderSide(color: AppColors.surface200, width: AppDimensions.borderThin),
        ),
        margin: EdgeInsets.zero,
        clipBehavior: Clip.antiAlias,
      ),

      // ── Elevated Button ───────────────────────────────────────────────────
      // Spec: navyDeep fill, white text, 52px height, radiusMedium.
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.surface200;
            }
            if (states.contains(WidgetState.pressed)) {
              return AppColors.navyMedium;
            }
            return AppColors.navyDeep;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.grey400;
            }
            return AppColors.white;
          }),
          elevation: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) return 0;
            return AppDecorations.shadow1.isNotEmpty ? 2 : 0;
          }),
          shadowColor: WidgetStateProperty.all(
            const Color(0x0D0B1F3A), // shadow1 color
          ),
          minimumSize: WidgetStateProperty.all(
            const Size(double.infinity, AppDimensions.buttonHeight),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
          textStyle: WidgetStateProperty.all(AppTypography.buttonPrimary),
          overlayColor: WidgetStateProperty.all(
            AppColors.white.withValues(alpha: 0.08),
          ),
          animationDuration: const Duration(milliseconds: 80),
        ),
      ),

      // ── Outlined Button ───────────────────────────────────────────────────
      // Spec: transparent fill, 1.5px navyDeep border, 52px height.
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.navyLight.withValues(alpha: 0.08);
            }
            return Colors.transparent;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.grey400;
            }
            return AppColors.navyDeep;
          }),
          side: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return const BorderSide(color: AppColors.surface200, width: AppDimensions.borderMedium);
            }
            return const BorderSide(color: AppColors.navyDeep, width: AppDimensions.borderMedium);
          }),
          elevation: WidgetStateProperty.all(0),
          minimumSize: WidgetStateProperty.all(
            const Size(double.infinity, AppDimensions.buttonHeight),
          ),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(horizontal: AppDimensions.space24),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
          textStyle: WidgetStateProperty.all(AppTypography.buttonSecondary),
          overlayColor: WidgetStateProperty.all(
            AppColors.navyLight.withValues(alpha: 0.06),
          ),
          animationDuration: const Duration(milliseconds: 80),
        ),
      ),

      // ── Text Button ───────────────────────────────────────────────────────
      textButtonTheme: TextButtonThemeData(
        style: ButtonStyle(
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.disabled)) {
              return AppColors.grey400;
            }
            return AppColors.navyMedium;
          }),
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.pressed)) {
              return AppColors.navyLight.withValues(alpha: 0.06);
            }
            return Colors.transparent;
          }),
          elevation: WidgetStateProperty.all(0),
          padding: WidgetStateProperty.all(
            const EdgeInsets.symmetric(
              horizontal: AppDimensions.space12,
              vertical: AppDimensions.space8,
            ),
          ),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
          ),
          textStyle: WidgetStateProperty.all(AppTypography.buttonText),
          overlayColor: WidgetStateProperty.all(
            AppColors.navyLight.withValues(alpha: 0.06),
          ),
        ),
      ),

      // ── FAB ───────────────────────────────────────────────────────────────
      // Spec: goldPrimary background, navyDeep icon, shadow3, circular.
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.goldPrimary,
        foregroundColor: AppColors.navyDeep,
        elevation: 8,
        focusElevation: 8,
        hoverElevation: 10,
        highlightElevation: 6,
        shape: const CircleBorder(),
        iconSize: AppDimensions.iconMD,
        extendedTextStyle: AppTypography.labelLarge.copyWith(
          color: AppColors.navyDeep,
        ),
      ),

      // ── Input Decoration ──────────────────────────────────────────────────
      // Spec: surface50 fill, radiusSmall (8px), 1.5px borders.
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.surface50,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: 14,
        ),
        // Unfocused
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(
            color: AppColors.surface200,
            width: AppDimensions.borderMedium,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(
            color: AppColors.surface200,
            width: AppDimensions.borderMedium,
          ),
        ),
        // Focused
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(
            color: AppColors.navyMedium,
            width: AppDimensions.borderMedium,
          ),
        ),
        // Error
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(
            color: AppColors.errorRed,
            width: AppDimensions.borderMedium,
          ),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(
            color: AppColors.errorRed,
            width: AppDimensions.borderThick,
          ),
        ),
        // Disabled
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(
            color: AppColors.surface100,
            width: AppDimensions.borderThin,
          ),
        ),
        hintStyle: AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
        labelStyle: AppTypography.labelMedium.copyWith(color: AppColors.grey600),
        floatingLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.navyMedium,
        ),
        errorStyle: AppTypography.labelSmall.copyWith(color: AppColors.errorRed),
        helperStyle: AppTypography.caption,
        prefixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return AppColors.navyMedium;
          return AppColors.grey400;
        }),
        suffixIconColor: WidgetStateColor.resolveWith((states) {
          if (states.contains(WidgetState.focused)) return AppColors.navyMedium;
          return AppColors.grey400;
        }),
        isDense: false,
        constraints: const BoxConstraints(minHeight: AppDimensions.inputHeight),
      ),

      // ── Chip ─────────────────────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.surface100,
        selectedColor: AppColors.navyDeep,
        disabledColor: AppColors.surface200,
        deleteIconColor: AppColors.grey600,
        labelStyle: AppTypography.labelMedium,
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.white,
        ),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space4,
        ),
        labelPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.space4),
        shape: StadiumBorder(
          side: BorderSide.none,
          // ignore: unused_element
        ),
        side: BorderSide.none,
        showCheckmark: false,
        elevation: 0,
        pressElevation: 0,
        brightness: Brightness.light,
      ),

      // ── Divider ───────────────────────────────────────────────────────────
      dividerTheme: const DividerThemeData(
        color: AppColors.surface100,
        thickness: 1,
        space: 1,
      ),

      // ── List Tile ─────────────────────────────────────────────────────────
      listTileTheme: ListTileThemeData(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space8,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        minLeadingWidth: 0,
        minVerticalPadding: 0,
        iconColor: AppColors.grey600,
        textColor: AppColors.grey800,
        titleTextStyle: AppTypography.titleMedium,
        subtitleTextStyle: AppTypography.bodySmall,
        leadingAndTrailingTextStyle: AppTypography.labelMedium,
      ),

      // ── Bottom Sheet ──────────────────────────────────────────────────────
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: AppColors.white,
        modalBackgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(AppDimensions.radiusXL),
            topRight: Radius.circular(AppDimensions.radiusXL),
          ),
        ),
        elevation: 0,
        modalElevation: 0,
        dragHandleColor: AppColors.surface200,
        dragHandleSize: Size(
          AppDimensions.dragHandleWidth,
          AppDimensions.dragHandleHeight,
        ),
        showDragHandle: false, // shown manually per sheet for control
      ),

      // ── Dialog ────────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: AppColors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        titleTextStyle: AppTypography.headlineSmall.copyWith(
          color: AppColors.navyDeep,
        ),
        contentTextStyle: AppTypography.bodyMedium,
        actionsPadding: const EdgeInsets.fromLTRB(
          AppDimensions.space16,
          0,
          AppDimensions.space16,
          AppDimensions.space16,
        ),
      ),

      // ── Snack Bar ─────────────────────────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: AppColors.white,
        ),
        elevation: 0,
      ),

      // ── Progress Indicator ────────────────────────────────────────────────
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: AppColors.navyDeep,
        linearTrackColor: AppColors.surface100,
        circularTrackColor: Colors.transparent,
        refreshBackgroundColor: AppColors.surface50,
      ),

      // ── Switch ────────────────────────────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return AppColors.grey400;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.surface200;
          if (states.contains(WidgetState.selected)) return AppColors.navyDeep;
          return AppColors.surface200;
        }),
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        overlayColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return AppColors.navyDeep.withValues(alpha: 0.12);
          }
          return AppColors.grey400.withValues(alpha: 0.12);
        }),
      ),

      // ── Checkbox ──────────────────────────────────────────────────────────
      checkboxTheme: CheckboxThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.surface200;
          if (states.contains(WidgetState.selected)) return AppColors.navyDeep;
          return Colors.transparent;
        }),
        checkColor: WidgetStateProperty.all(AppColors.white),
        side: const BorderSide(color: AppColors.grey400, width: AppDimensions.borderMedium),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.space4),
        ),
        overlayColor: WidgetStateProperty.all(
          AppColors.navyDeep.withValues(alpha: 0.08),
        ),
      ),

      // ── Radio ─────────────────────────────────────────────────────────────
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.disabled)) return AppColors.surface200;
          if (states.contains(WidgetState.selected)) return AppColors.navyDeep;
          return AppColors.grey400;
        }),
        overlayColor: WidgetStateProperty.all(
          AppColors.navyDeep.withValues(alpha: 0.08),
        ),
      ),

      // ── Tooltip ───────────────────────────────────────────────────────────
      tooltipTheme: TooltipThemeData(
        decoration: BoxDecoration(
          color: AppColors.navyDeep.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
        ),
        textStyle: AppTypography.labelSmall.copyWith(color: AppColors.white),
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: AppDimensions.space8,
        ),
        waitDuration: const Duration(milliseconds: 600),
        showDuration: const Duration(seconds: 2),
      ),

      // ── Popup Menu ────────────────────────────────────────────────────────
      popupMenuTheme: PopupMenuThemeData(
        color: AppColors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        textStyle: AppTypography.bodyMedium,
        labelTextStyle: WidgetStateProperty.all(AppTypography.bodyMedium),
        shadowColor: const Color(0x1F0B1F3A),
        surfaceTintColor: Colors.transparent,
      ),

      // ── Date Picker ───────────────────────────────────────────────────────
      datePickerTheme: DatePickerThemeData(
        backgroundColor: AppColors.white,
        headerBackgroundColor: AppColors.navyDeep,
        headerForegroundColor: AppColors.white,
        headerHeadlineStyle: AppTypography.headlineMedium.copyWith(
          color: AppColors.white,
        ),
        headerHelpStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.white.withValues(alpha: 0.7),
        ),
        dayStyle: AppTypography.bodyMedium,
        dayForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return AppColors.grey800;
        }),
        dayBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.navyDeep;
          return Colors.transparent;
        }),
        todayForegroundColor: WidgetStateProperty.all(AppColors.navyDeep),
        todayBorder: const BorderSide(
          color: AppColors.navyDeep,
          width: AppDimensions.borderMedium,
        ),
        yearStyle: AppTypography.bodyMedium,
        yearForegroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.white;
          return AppColors.grey800;
        }),
        yearBackgroundColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return AppColors.navyDeep;
          return Colors.transparent;
        }),
        rangeSelectionBackgroundColor: AppColors.navyLight.withValues(alpha: 0.12),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        surfaceTintColor: Colors.transparent,
        dividerColor: AppColors.surface100,
      ),

      // ── Time Picker ───────────────────────────────────────────────────────
      timePickerTheme: TimePickerThemeData(
        backgroundColor: AppColors.white,
        dialBackgroundColor: AppColors.surface50,
        dialHandColor: AppColors.navyDeep,
        dialTextStyle: AppTypography.bodyLarge,
        hourMinuteColor: AppColors.surface50,
        hourMinuteTextStyle: AppTypography.headlineMedium,
        hourMinuteShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          side: const BorderSide(color: AppColors.surface200),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
        ),
        entryModeIconColor: AppColors.grey600,
      ),

      // ── Expansion Tile ────────────────────────────────────────────────────
      expansionTileTheme: ExpansionTileThemeData(
        backgroundColor: AppColors.white,
        collapsedBackgroundColor: AppColors.white,
        iconColor: AppColors.grey600,
        collapsedIconColor: AppColors.grey400,
        textColor: AppColors.grey800,
        collapsedTextColor: AppColors.grey800,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space4,
        ),
        childrenPadding: const EdgeInsets.only(
          left: AppDimensions.space16,
          right: AppDimensions.space16,
          bottom: AppDimensions.space12,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
        collapsedShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        ),
      ),

      // ── Drawer ────────────────────────────────────────────────────────────
      drawerTheme: const DrawerThemeData(
        backgroundColor: AppColors.white,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.only(
            topRight: Radius.circular(AppDimensions.radiusXL),
            bottomRight: Radius.circular(AppDimensions.radiusXL),
          ),
        ),
      ),

      // ── Search Bar ────────────────────────────────────────────────────────
      searchBarTheme: SearchBarThemeData(
        backgroundColor: WidgetStateProperty.all(AppColors.surface50),
        elevation: WidgetStateProperty.all(0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            side: const BorderSide(color: AppColors.surface200),
          ),
        ),
        textStyle: WidgetStateProperty.all(AppTypography.bodyMedium),
        hintStyle: WidgetStateProperty.all(
          AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
        ),
        padding: WidgetStateProperty.all(
          const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
        ),
        constraints: const BoxConstraints(
          minHeight: AppDimensions.buttonHeightSm,
          maxHeight: AppDimensions.inputHeight,
        ),
      ),

      // ── Slider ────────────────────────────────────────────────────────────
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.navyDeep,
        inactiveTrackColor: AppColors.surface200,
        thumbColor: AppColors.navyDeep,
        overlayColor: AppColors.navyDeep.withValues(alpha: 0.12),
        valueIndicatorColor: AppColors.navyDeep,
        valueIndicatorTextStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.white,
        ),
        trackHeight: 4,
        thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
        overlayShape: const RoundSliderOverlayShape(overlayRadius: 20),
      ),

      // ── Segmented Button ──────────────────────────────────────────────────
      segmentedButtonTheme: SegmentedButtonThemeData(
        style: ButtonStyle(
          backgroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.navyDeep;
            return AppColors.surface50;
          }),
          foregroundColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) return AppColors.white;
            return AppColors.grey600;
          }),
          side: WidgetStateProperty.all(
            const BorderSide(color: AppColors.surface200),
          ),
          textStyle: WidgetStateProperty.all(AppTypography.labelMedium),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
          ),
        ),
      ),
    );
  }

  // ── Animation durations ───────────────────────────────────────────────────
  // Exposed here as statics for use in AnimationController throughout the app.

  /// 80ms — button press feedback
  static const Duration durationPress = Duration(milliseconds: 80);

  /// 150ms — fast micro-interaction (icon switch, chip select)
  static const Duration durationFast = Duration(milliseconds: 150);

  /// 200ms — dialog appear / fade
  static const Duration durationDialog = Duration(milliseconds: 200);

  /// 280ms — bottom sheet slide up
  static const Duration durationSheet = Duration(milliseconds: 280);

  /// 300ms — screen push transition
  static const Duration durationPage = Duration(milliseconds: 300);

  /// 500ms — number counter, stat animation
  static const Duration durationStat = Duration(milliseconds: 500);

  /// 600ms — progress bar fill animation
  static const Duration durationProgress = Duration(milliseconds: 600);

  /// 800ms — attendance ring sweep
  static const Duration durationRing = Duration(milliseconds: 800);

  // ── Animation curves ──────────────────────────────────────────────────────
  static const Curve curvePress = Curves.easeOut;
  static const Curve curveSheet = Curves.easeOutCubic;
  static const Curve curveProgress = Curves.easeOutCubic;
  static const Curve curveRing = Curves.easeOutBack;
  static const Curve curvePage = Curves.easeInOut;
}
