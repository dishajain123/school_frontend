class AppConstants {
  AppConstants._();

  static const String appName = 'Gurukul';
  static const String appVersion = '1.0.0';

  // Pagination
  static const int defaultPageSize = 20;
  static const int maxPageSize = 100;

  // File upload
  static const int maxFileSizeMb = 10;
  static const int maxFileSizeBytes = maxFileSizeMb * 1024 * 1024;

  // Presigned URL cache
  static const int presignedUrlCacheDurationMinutes = 55; // < 1h expiry

  // Token
  static const int tokenRefreshMarginSeconds = 60;

  // Animation durations
  static const int animShortMs = 150;
  static const int animMediumMs = 300;
  static const int animLongMs = 500;

  // Snackbar durations
  static const int snackbarSuccessDurationMs = 3000;
  static const int snackbarErrorDurationMs = 4000;
  static const int snackbarInfoDurationMs = 3000;

  // Attendance
  static const double defaultAttendanceThreshold = 75.0;
}
