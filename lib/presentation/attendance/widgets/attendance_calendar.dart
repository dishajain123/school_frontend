import 'package:flutter/material.dart';
import '../../../data/models/attendance/attendance_model.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class AttendanceCalendar extends StatelessWidget {
  const AttendanceCalendar({
    super.key,
    required this.records,
    required this.month,
    required this.year,
    required this.onMonthChanged,
  });

  final List<AttendanceModel> records;
  final int month;
  final int year;
  final void Function(int month, int year) onMonthChanged;

  Map<String, AttendanceStatus> get _statusByDate {
    final map = <String, AttendanceStatus>{};
    for (final r in records) {
      final key =
          '${r.date.year}-${r.date.month.toString().padLeft(2, '0')}-${r.date.day.toString().padLeft(2, '0')}';
      if (!map.containsKey(key) || map[key] == AttendanceStatus.absent) {
        map[key] = r.status;
      }
    }
    return map;
  }

  void _previousMonth() {
    if (month == 1) {
      onMonthChanged(12, year - 1);
    } else {
      onMonthChanged(month - 1, year);
    }
  }

  void _nextMonth() {
    final now = DateTime.now();
    final targetYear = month == 12 ? year + 1 : year;
    final targetMonth = month == 12 ? 1 : month + 1;
    if (DateTime(targetYear, targetMonth).isAfter(DateTime(now.year, now.month))) return;
    onMonthChanged(targetMonth, targetYear);
  }

  static const List<String> _weekdays = ['Mo', 'Tu', 'We', 'Th', 'Fr', 'Sa', 'Su'];
  static const List<String> _months = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(year, month, 1);
    final daysInMonth = DateTime(year, month + 1, 0).day;
    final startOffset = firstDay.weekday - 1;
    final statusMap = _statusByDate;
    final now = DateTime.now();
    final isCurrentMonth = year == now.year && month == now.month;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            GestureDetector(
              onTap: _previousMonth,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.surface100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.chevron_left_rounded,
                    color: AppColors.navyDeep, size: 20),
              ),
            ),
            Expanded(
              child: Text(
                '${_months[month]} $year',
                textAlign: TextAlign.center,
                style: AppTypography.titleMedium.copyWith(
                  color: AppColors.navyDeep,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            GestureDetector(
              onTap: isCurrentMonth ? null : _nextMonth,
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCurrentMonth ? AppColors.surface50 : AppColors.surface100,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.chevron_right_rounded,
                    color: isCurrentMonth ? AppColors.grey400 : AppColors.navyDeep,
                    size: 20),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Row(
          children: _weekdays.map((d) => Expanded(
                child: Center(
                  child: Text(d,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.grey400,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      )),
                ),
              )).toList(),
        ),
        const SizedBox(height: 8),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            childAspectRatio: 1.0,
            crossAxisSpacing: 4,
            mainAxisSpacing: 4,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox.shrink();
            final day = index - startOffset + 1;
            final dateKey =
                '$year-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';
            final status = statusMap[dateKey];
            final isToday = now.year == year && now.month == month && now.day == day;
            final isFuture = DateTime(year, month, day).isAfter(now);

            return _CalendarCell(
              day: day,
              status: status,
              isToday: isToday,
              isFuture: isFuture,
            );
          },
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _LegendItem(color: AppColors.successLight, borderColor: AppColors.successGreen, label: 'Present'),
            const SizedBox(width: 16),
            _LegendItem(color: AppColors.errorLight, borderColor: AppColors.errorRed, label: 'Absent'),
            const SizedBox(width: 16),
            _LegendItem(color: AppColors.warningLight, borderColor: AppColors.warningAmber, label: 'Late'),
          ],
        ),
      ],
    );
  }
}

class _CalendarCell extends StatelessWidget {
  const _CalendarCell({
    required this.day,
    this.status,
    required this.isToday,
    required this.isFuture,
  });

  final int day;
  final AttendanceStatus? status;
  final bool isToday;
  final bool isFuture;

  Color get _bgColor {
    if (isToday) return AppColors.navyDeep;
    if (isFuture) return Colors.transparent;
    if (status == null) return AppColors.surface50;
    switch (status!) {
      case AttendanceStatus.present: return AppColors.successLight;
      case AttendanceStatus.absent: return AppColors.errorLight;
      case AttendanceStatus.late: return AppColors.warningLight;
    }
  }

  Color get _textColor {
    if (isToday) return AppColors.white;
    if (isFuture) return AppColors.grey400;
    if (status == null) return AppColors.grey600;
    switch (status!) {
      case AttendanceStatus.present: return AppColors.successGreen;
      case AttendanceStatus.absent: return AppColors.errorRed;
      case AttendanceStatus.late: return AppColors.warningAmber;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bgColor,
        borderRadius: BorderRadius.circular(8),
        boxShadow: isToday
            ? [BoxShadow(
                color: AppColors.navyDeep.withValues(alpha: 0.25),
                blurRadius: 6,
                offset: const Offset(0, 2),
              )]
            : null,
      ),
      child: Center(
        child: Text(
          '$day',
          style: AppTypography.labelSmall.copyWith(
            color: _textColor,
            fontWeight: isToday ? FontWeight.w800 : FontWeight.w500,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _LegendItem extends StatelessWidget {
  const _LegendItem({
    required this.color,
    required this.borderColor,
    required this.label,
  });

  final Color color, borderColor;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1),
          ),
        ),
        const SizedBox(width: 5),
        Text(label,
            style: AppTypography.caption.copyWith(color: AppColors.grey500, fontSize: 11)),
      ],
    );
  }
}
