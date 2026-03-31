class StorageKeys {
  StorageKeys._();

  // ── SecureStorage keys ────────────────────────────────────────────────────
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';

  // ── SharedPreferences keys ────────────────────────────────────────────────
  static const String currentUser = 'current_user';
  static const String schoolId = 'school_id';
  static const String userRole = 'user_role';
  static const String userPermissions = 'user_permissions';

  // Parent-specific
  static const String selectedChildId = 'selected_child_id';
  static const String parentId = 'parent_id';

  // App preferences
  static const String onboardingComplete = 'onboarding_complete';
  static const String lastSeenNotificationId = 'last_seen_notification_id';
  static const String themeMode = 'theme_mode';
}