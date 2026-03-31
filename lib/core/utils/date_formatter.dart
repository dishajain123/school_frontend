import 'package:intl/intl.dart';

class DateFormatter {
  DateFormatter._();

  // "12 Mar 2025"
  static String formatDate(DateTime dt) =>
      DateFormat('dd MMM yyyy').format(dt);

  // "3:45 PM"
  static String formatTime(DateTime dt) =>
      DateFormat('h:mm a').format(dt);

  // "12 Mar 2025, 3:45 PM"
  static String formatDateTime(DateTime dt) =>
      DateFormat('dd MMM yyyy, h:mm a').format(dt);

  // "March 2025"
  static String formatMonthYear(DateTime dt) =>
      DateFormat('MMMM yyyy').format(dt);

  // "Mar 2025"
  static String formatShortMonthYear(DateTime dt) =>
      DateFormat('MMM yyyy').format(dt);

  // "Mon" (day of week short)
  static String formatDayOfWeek(DateTime dt) =>
      DateFormat('EEE').format(dt);

  // "Monday"
  static String formatFullDayOfWeek(DateTime dt) =>
      DateFormat('EEEE').format(dt);

  // "2025-03-12" (ISO for API)
  static String formatDateForApi(DateTime dt) =>
      DateFormat('yyyy-MM-dd').format(dt);

  /// Relative time: "Just now", "5 min ago", "Yesterday", "12 Mar 2025"
  static String formatRelative(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);

    if (diff.inSeconds < 60) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) {
      return diff.inHours == 1 ? '1 hour ago' : '${diff.inHours} hours ago';
    }
    if (diff.inDays == 1) return 'Yesterday';
    if (diff.inDays < 7) return '${diff.inDays} days ago';
    return formatDate(dt);
  }

  /// Parse ISO date string to DateTime.
  static DateTime? parseApiDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    try {
      return DateTime.parse(raw);
    } catch (_) {
      return null;
    }
  }
}