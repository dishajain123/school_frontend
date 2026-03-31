extension StringExtensions on String {
  /// Capitalizes the first letter of each word.
  String get capitalize {
    if (isEmpty) return this;
    return split(' ')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1)}')
        .join(' ');
  }

  /// Returns initials from up to the first two words.
  String get initials {
    final words = trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    if (words.isEmpty) return '';
    if (words.length == 1) return words[0][0].toUpperCase();
    return '${words[0][0]}${words[1][0]}'.toUpperCase();
  }

  /// Returns true if null or empty after trim.
  bool get isNullOrEmpty => trim().isEmpty;

  /// Returns null if empty, otherwise returns the string.
  String? get nullIfEmpty => trim().isEmpty ? null : this;

  /// Truncates with ellipsis if longer than [maxLength].
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}…';
  }

  /// Converts snake_case or SCREAMING_SNAKE to Title Case.
  String get snakeToTitle {
    return split('_')
        .map((w) => w.isEmpty ? '' : '${w[0].toUpperCase()}${w.substring(1).toLowerCase()}')
        .join(' ');
  }
}

extension NullableStringExtensions on String? {
  bool get isNullOrEmpty => this == null || this!.trim().isEmpty;

  String get orEmpty => this ?? '';
}