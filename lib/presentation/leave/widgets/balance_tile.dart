import 'package:flutter/material.dart';
import 'package:sms_app/core/theme/app_dimensions.dart';

/// A compact tile that shows leave balance information.
///
/// This widget intentionally does not depend on custom getters like
/// `LeaveType.color`, `LeaveType.icon`, or `LeaveType.label`.
/// It derives display values from [leaveType] text to avoid enum-extension
/// coupling errors.
class BalanceTile extends StatelessWidget {
  const BalanceTile({
    super.key,
    required this.leaveType,
    required this.balance,
    this.total,
    this.used,
  });

  /// Leave type name (for example: "Casual", "Sick", "Earned").
  final String leaveType;

  /// Remaining leave balance.
  final num balance;

  /// Optional total allocation for this leave type.
  final num? total;

  /// Optional used leaves for this leave type.
  final num? used;

  Color get _typeColor {
    final normalized = leaveType.trim().toLowerCase();
    if (normalized.contains('sick') || normalized.contains('medical')) {
      return Colors.red;
    }
    if (normalized.contains('casual')) {
      return Colors.blue;
    }
    if (normalized.contains('earned') || normalized.contains('annual')) {
      return Colors.green;
    }
    if (normalized.contains('maternity') || normalized.contains('paternity')) {
      return Colors.purple;
    }
    return Colors.teal;
  }

  IconData get _typeIcon {
    final normalized = leaveType.trim().toLowerCase();
    if (normalized.contains('sick') || normalized.contains('medical')) {
      return Icons.local_hospital_rounded;
    }
    if (normalized.contains('casual')) {
      return Icons.event_available_rounded;
    }
    if (normalized.contains('earned') || normalized.contains('annual')) {
      return Icons.workspace_premium_rounded;
    }
    if (normalized.contains('maternity') || normalized.contains('paternity')) {
      return Icons.child_friendly_rounded;
    }
    return Icons.calendar_today_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final color = _typeColor;
    final label = leaveType.trim().isEmpty ? 'Leave' : leaveType.trim();

    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.16),
            child: Icon(_typeIcon, color: color, size: AppDimensions.iconSM),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: color,
                  ),
                ),
                if (total != null || used != null) ...[
                  const SizedBox(height: AppDimensions.space8),
                  Text(
                    _subLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Text(
            balance.toString(),
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String get _subLabel {
    if (total != null && used != null) {
      return 'Used ${used.toString()} / ${total.toString()}';
    }
    if (total != null) {
      return 'Total ${total.toString()}';
    }
    if (used != null) {
      return 'Used ${used.toString()}';
    }
    return '';
  }
}
