import 'package:flutter/material.dart';

extension ContextExtensions on BuildContext {
  ThemeData get theme => Theme.of(this);

  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  TextTheme get textTheme => Theme.of(this).textTheme;

  double get screenWidth => MediaQuery.sizeOf(this).width;

  double get screenHeight => MediaQuery.sizeOf(this).height;

  EdgeInsets get viewPadding => MediaQuery.viewPaddingOf(this);

  EdgeInsets get viewInsets => MediaQuery.viewInsetsOf(this);

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  bool get isLight => Theme.of(this).brightness == Brightness.light;

  /// True if device is a tablet (width ≥ 600dp).
  bool get isTablet => MediaQuery.sizeOf(this).width >= 600;

  /// Keyboard visible.
  bool get isKeyboardVisible => MediaQuery.viewInsetsOf(this).bottom > 0;

  /// Dismiss keyboard.
  void dismissKeyboard() => FocusScope.of(this).unfocus();

  /// Push a named route.
  void push(String location) {
    // Delegate to GoRouter — avoids direct import in extension.
    Navigator.of(this).pushNamed(location);
  }

  /// Pop current route.
  void pop([Object? result]) => Navigator.of(this).pop(result);

  bool get canPop => Navigator.of(this).canPop();
}