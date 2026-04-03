import 'package:flutter/foundation.dart';
import 'exam_series_model.dart';

@immutable
class ExamEntryModel {
  const ExamEntryModel({
    required this.id,
    required this.seriesId,
    required this.subjectId,
    required this.examDate,
    required this.startTime,
    required this.durationMinutes,
    required this.isCancelled,
    required this.createdAt,
    required this.updatedAt,
    this.venue,
  });

  final String id;
  final String seriesId;
  final String subjectId;
  final DateTime examDate;
  final String startTime; // "HH:MM:SS" string from backend
  final int durationMinutes;
  final bool isCancelled;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String? venue;

  /// Formatted start time like "9:00 AM"
  String get formattedStartTime {
    final parts = startTime.split(':');
    if (parts.length < 2) return startTime;
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
    return '$displayHour:${minute.toString().padLeft(2, '0')} $period';
  }

  /// End time computed from start + duration
  String get formattedEndTime {
    final parts = startTime.split(':');
    if (parts.length < 2) return '';
    final hour = int.tryParse(parts[0]) ?? 0;
    final minute = int.tryParse(parts[1]) ?? 0;
    final totalMinutes = hour * 60 + minute + durationMinutes;
    final endHour = (totalMinutes ~/ 60) % 24;
    final endMinute = totalMinutes % 60;
    final period = endHour >= 12 ? 'PM' : 'AM';
    final displayHour = endHour == 0 ? 12 : (endHour > 12 ? endHour - 12 : endHour);
    return '$displayHour:${endMinute.toString().padLeft(2, '0')} $period';
  }

  /// Duration label like "2h 30m"
  String get durationLabel {
    final hours = durationMinutes ~/ 60;
    final mins = durationMinutes % 60;
    if (hours == 0) return '${mins}m';
    if (mins == 0) return '${hours}h';
    return '${hours}h ${mins}m';
  }

  factory ExamEntryModel.fromJson(Map<String, dynamic> json) {
    return ExamEntryModel(
      id: json['id'] as String,
      seriesId: json['series_id'] as String,
      subjectId: json['subject_id'] as String,
      examDate: DateTime.parse(json['exam_date'] as String),
      startTime: json['start_time'] as String,
      durationMinutes: json['duration_minutes'] as int,
      isCancelled: json['is_cancelled'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
      venue: json['venue'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'series_id': seriesId,
        'subject_id': subjectId,
        'exam_date': examDate.toIso8601String().split('T').first,
        'start_time': startTime,
        'duration_minutes': durationMinutes,
        'is_cancelled': isCancelled,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        if (venue != null) 'venue': venue,
      };

  ExamEntryModel copyWith({
    String? id,
    String? seriesId,
    String? subjectId,
    DateTime? examDate,
    String? startTime,
    int? durationMinutes,
    bool? isCancelled,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? venue,
  }) {
    return ExamEntryModel(
      id: id ?? this.id,
      seriesId: seriesId ?? this.seriesId,
      subjectId: subjectId ?? this.subjectId,
      examDate: examDate ?? this.examDate,
      startTime: startTime ?? this.startTime,
      durationMinutes: durationMinutes ?? this.durationMinutes,
      isCancelled: isCancelled ?? this.isCancelled,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      venue: venue ?? this.venue,
    );
  }
}

/// Combined schedule response: series + entries
class ExamScheduleTable {
  const ExamScheduleTable({
    required this.series,
    required this.entries,
  });

  final ExamSeriesModel series;
  final List<ExamEntryModel> entries;

  factory ExamScheduleTable.fromJson(Map<String, dynamic> json) {
    return ExamScheduleTable(
      series: ExamSeriesModel.fromJson(json['series'] as Map<String, dynamic>),
      entries: (json['entries'] as List<dynamic>)
          .map((e) => ExamEntryModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
