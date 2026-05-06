import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';

/// A premium inline date range picker widget.
///
/// Usage:
/// ```dart
/// AppDateRangePicker(
///   startDate: _start,
///   endDate: _end,
///   onRangeSelected: (start, end) {
///     setState(() { _start = start; _end = end; });
///   },
/// )
/// ```
class AppDateRangePicker extends StatefulWidget {
  const AppDateRangePicker({
    super.key,
    this.startDate,
    this.endDate,
    required this.onRangeSelected,
    this.firstDate,
    this.lastDate,
    this.label,
    this.hint = 'Select date range',
  });

  final DateTime? startDate;
  final DateTime? endDate;
  final void Function(DateTime? start, DateTime? end) onRangeSelected;
  final DateTime? firstDate;
  final DateTime? lastDate;
  final String? label;
  final String hint;

  @override
  State<AppDateRangePicker> createState() => _AppDateRangePickerState();
}

class _AppDateRangePickerState extends State<AppDateRangePicker> {
  DateTime? _startDate;
  DateTime? _endDate;

  @override
  void initState() {
    super.initState();
    _startDate = widget.startDate;
    _endDate = widget.endDate;
  }

  String get _displayText {
    if (_startDate == null && _endDate == null) return widget.hint;
    final start = _startDate != null ? _formatDate(_startDate!) : '—';
    final end = _endDate != null ? _formatDate(_endDate!) : '—';
    if (_startDate != null && _endDate == null) return start;
    return '$start  →  $end';
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
    ];
    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  bool get _hasValue => _startDate != null || _endDate != null;

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final first = widget.firstDate ?? DateTime(now.year - 5);
    final last = widget.lastDate ?? DateTime(now.year + 2);

    final picked = await showDateRangePicker(
      context: context,
      firstDate: first,
      lastDate: last,
      initialDateRange: (_startDate != null && _endDate != null)
          ? DateTimeRange(start: _startDate!, end: _endDate!)
          : null,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.navyDeep,
              onPrimary: AppColors.white,
              surface: AppColors.white,
              onSurface: AppColors.grey800,
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: AppColors.navyMedium,
              ),
            ),
            dialogTheme: const DialogThemeData(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.all(Radius.circular(20)),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _startDate = picked.start;
        _endDate = picked.end;
      });
      widget.onRangeSelected(_startDate, _endDate);
    }
  }

  void _clear() {
    setState(() {
      _startDate = null;
      _endDate = null;
    });
    widget.onRangeSelected(null, null);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (widget.label != null) ...[
          Text(
            widget.label!,
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.grey600,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
        ],
        GestureDetector(
          onTap: _pickRange,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(
                horizontal: 14, vertical: 13),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: _hasValue
                    ? AppColors.navyMedium.withValues(alpha: 0.5)
                    : AppColors.surface200,
                width: 1.5,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.date_range_rounded,
                  size: 18,
                  color: _hasValue
                      ? AppColors.navyMedium
                      : AppColors.grey400,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    _displayText,
                    style: AppTypography.bodyMedium.copyWith(
                      color: _hasValue
                          ? AppColors.grey800
                          : AppColors.grey400,
                      fontSize: 14,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (_hasValue)
                  GestureDetector(
                    onTap: _clear,
                    child: const Icon(
                      Icons.close_rounded,
                      size: 16,
                      color: AppColors.grey400,
                    ),
                  )
                else
                  const Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 18,
                    color: AppColors.grey400,
                  ),
              ],
            ),
          ),
        ),
        if (_startDate != null && _endDate != null) ...[
          const SizedBox(height: 6),
          Row(
            children: [
              const Icon(
                Icons.info_outline_rounded,
                size: 12,
                color: AppColors.grey400,
              ),
              const SizedBox(width: 4),
              Text(
                '${_endDate!.difference(_startDate!).inDays + 1} days selected',
                style: AppTypography.caption.copyWith(
                  color: AppColors.grey500,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}

/// Quick preset chips for common date ranges.
class AppDateRangePresets extends StatelessWidget {
  const AppDateRangePresets({
    super.key,
    required this.onSelected,
    this.selectedPreset,
  });

  final void Function(DateTime start, DateTime end, String label) onSelected;
  final String? selectedPreset;

  static List<_Preset> get _presets {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return [
      _Preset(
        label: 'Today',
        start: today,
        end: today,
      ),
      _Preset(
        label: 'This Week',
        start: today.subtract(Duration(days: today.weekday - 1)),
        end: today,
      ),
      _Preset(
        label: 'This Month',
        start: DateTime(today.year, today.month, 1),
        end: today,
      ),
      _Preset(
        label: 'Last Month',
        start: DateTime(today.year, today.month - 1, 1),
        end: DateTime(today.year, today.month, 0),
      ),
      _Preset(
        label: 'This Year',
        start: DateTime(today.year, 1, 1),
        end: today,
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: _presets.map((p) {
          final isSelected = selectedPreset == p.label;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(p.start, p.end, p.label),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.navyDeep
                      : AppColors.surface100,
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusFull),
                  border: isSelected
                      ? null
                      : Border.all(
                          color: AppColors.surface200,
                          width: 1,
                        ),
                ),
                child: Text(
                  p.label,
                  style: AppTypography.labelMedium.copyWith(
                    color:
                        isSelected ? AppColors.white : AppColors.grey700,
                    fontWeight: isSelected
                        ? FontWeight.w600
                        : FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _Preset {
  const _Preset(
      {required this.label, required this.start, required this.end});
  final String label;
  final DateTime start;
  final DateTime end;
}