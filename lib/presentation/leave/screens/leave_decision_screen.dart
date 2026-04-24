import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_decorations.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../core/utils/snackbar_utils.dart';
import '../../../../data/models/leave/leave_model.dart';
import '../../../../providers/leave_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_dialog.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_text_field.dart';

class LeaveDecisionScreen extends ConsumerStatefulWidget {
  const LeaveDecisionScreen({
    super.key,
    required this.leaveId,
    this.leave,
  });

  final String leaveId;

  /// Optionally passed via GoRouter extras for immediate display.
  final LeaveModel? leave;

  @override
  ConsumerState<LeaveDecisionScreen> createState() =>
      _LeaveDecisionScreenState();
}

class _LeaveDecisionScreenState extends ConsumerState<LeaveDecisionScreen> {
  final _remarksController = TextEditingController();
  LeaveModel? _leave;

  @override
  void initState() {
    super.initState();
    _leave = widget.leave;
    if (_leave == null) _loadLeave();
  }

  void _loadLeave() {
    // Fall back to finding in provider list
    final state = ref.read(leaveNotifierProvider).valueOrNull;
    if (state != null) {
      try {
        _leave =
            state.items.firstWhere((l) => l.id == widget.leaveId);
        setState(() {});
      } catch (_) {
        // Not found yet; trigger a load
        ref.read(leaveNotifierProvider.notifier).load();
      }
    }
  }

  @override
  void dispose() {
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _decide(LeaveStatus decision) async {
    final label = decision == LeaveStatus.approved ? 'Approve' : 'Reject';
    final icon = decision == LeaveStatus.approved
        ? Icons.check_circle_outline_rounded
        : Icons.cancel_outlined;

    final confirmed = await AppDialog.confirm(
      context,
      title: '$label Leave Request',
      message: decision == LeaveStatus.approved
          ? 'Are you sure you want to approve this leave request?'
          : 'Are you sure you want to reject this leave request?',
      confirmLabel: label,
      icon: icon,
    );

    if (confirmed != true || !mounted) return;

    final result = await ref.read(leaveNotifierProvider.notifier).decide(
          leaveId: widget.leaveId,
          status: decision,
          remarks: _remarksController.text.trim().isEmpty
              ? null
              : _remarksController.text.trim(),
        );

    if (!mounted) return;

    if (result != null) {
      await ref.read(leaveNotifierProvider.notifier).load(
            statusFilter: null,
            refresh: true,
          );
      if (!mounted) return;
      SnackbarUtils.showSuccess(
        context,
        decision == LeaveStatus.approved
            ? 'Leave request approved.'
            : 'Leave request rejected.',
      );
      context.pop();
    } else {
      final error = ref.read(leaveNotifierProvider).valueOrNull?.error ??
          'Failed to process decision.';
      SnackbarUtils.showError(context, error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final leaveState = ref.watch(leaveNotifierProvider);
    final isSubmitting = leaveState.valueOrNull?.isSubmitting ?? false;

    // Try to get leave from provider state if not passed
    final leave = _leave ??
        leaveState.valueOrNull?.items
            .where((l) => l.id == widget.leaveId)
            .firstOrNull;

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Leave Decision',
        showBack: true,
        showNotificationBell: false,
      ),
      body: leave == null
          ? const Center(child: CircularProgressIndicator.adaptive())
          : CustomScrollView(
              slivers: [
                SliverPadding(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate([
                      // ── Leave Detail Card ──────────────────────────────────
                      _LeaveDetailCard(leave: leave),

                      const SizedBox(height: AppDimensions.space24),

                      // ── Remarks ────────────────────────────────────────────
                      AppTextField(
                        label: 'Remarks (Optional)',
                        hint: 'Add a note for the teacher...',
                        controller: _remarksController,
                        maxLines: 3,
                        minLines: 2,
                        textCapitalization: TextCapitalization.sentences,
                      ),

                      const SizedBox(height: AppDimensions.space32),

                      // ── Action Buttons ─────────────────────────────────────
                      if (leave.isPending) ...[
                        AppButton.primary(
                          label: 'Approve Leave',
                          onTap: isSubmitting
                              ? null
                              : () => _decide(LeaveStatus.approved),
                          isLoading: isSubmitting,
                          icon: Icons.check_circle_outline_rounded,
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        AppButton.destructive(
                          label: 'Reject Leave',
                          onTap: isSubmitting
                              ? null
                              : () => _decide(LeaveStatus.rejected),
                        ),
                        const SizedBox(height: AppDimensions.space12),
                        AppButton.secondary(
                          label: 'Back',
                          onTap: isSubmitting ? null : () => context.pop(),
                        ),
                      ] else ...[
                        // Already decided — show read-only state
                        _DecisionResultBanner(status: leave.status),
                        const SizedBox(height: AppDimensions.space16),
                        AppButton.secondary(
                          label: 'Back',
                          onTap: () => context.pop(),
                        ),
                      ],

                      const SizedBox(height: AppDimensions.space40),
                    ]),
                  ),
                ),
              ],
            ),
    );
  }
}

// ── Leave Detail Card ─────────────────────────────────────────────────────────

class _LeaveDetailCard extends StatelessWidget {
  const _LeaveDetailCard({required this.leave});

  final LeaveModel leave;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: AppDecorations.card,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: const BoxDecoration(
              color: AppColors.surface50,
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(AppDimensions.radiusMedium),
                topRight: Radius.circular(AppDimensions.radiusMedium),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: BoxDecoration(
                    color:
                        leave.leaveType.color.withValues(alpha: 0.12),
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                  child: Icon(
                    leave.leaveType.icon,
                    color: leave.leaveType.color,
                    size: AppDimensions.iconMD,
                  ),
                ),
                const SizedBox(width: AppDimensions.space12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        leave.leaveType.label,
                        style: AppTypography.titleMedium,
                      ),
                      Text(
                        'Teacher ID: ${leave.teacherId.substring(0, 8)}…',
                        style: AppTypography.caption,
                      ),
                    ],
                  ),
                ),
                _StatusPill(status: leave.status),
              ],
            ),
          ),

          // Details
          Padding(
            padding: const EdgeInsets.all(AppDimensions.space16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _DetailRow(
                  icon: Icons.calendar_today_outlined,
                  label: 'From',
                  value: DateFormat('dd MMM yyyy').format(leave.fromDate),
                ),
                const SizedBox(height: AppDimensions.space12),
                _DetailRow(
                  icon: Icons.event_outlined,
                  label: 'To',
                  value: DateFormat('dd MMM yyyy').format(leave.toDate),
                ),
                const SizedBox(height: AppDimensions.space12),
                _DetailRow(
                  icon: Icons.schedule_outlined,
                  label: 'Duration',
                  value:
                      '${leave.daysCount} ${leave.daysCount == 1 ? 'day' : 'days'}',
                ),
                if (leave.reason != null && leave.reason!.isNotEmpty) ...[
                  const SizedBox(height: AppDimensions.space12),
                  _DetailRow(
                    icon: Icons.comment_outlined,
                    label: 'Reason',
                    value: leave.reason!,
                    multiLine: true,
                  ),
                ],
                const SizedBox(height: AppDimensions.space12),
                _DetailRow(
                  icon: Icons.access_time_rounded,
                  label: 'Applied',
                  value: DateFormat('dd MMM yyyy, h:mm a')
                      .format(leave.createdAt),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.icon,
    required this.label,
    required this.value,
    this.multiLine = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool multiLine;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment:
          multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
      children: [
        Icon(icon, size: AppDimensions.iconXS, color: AppColors.grey400),
        const SizedBox(width: AppDimensions.space8),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: AppTypography.caption.copyWith(
              color: AppColors.grey400,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.grey800,
            ),
            maxLines: multiLine ? null : 1,
            overflow:
                multiLine ? TextOverflow.visible : TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}

// ── Status Pill ───────────────────────────────────────────────────────────────

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});

  final LeaveStatus status;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space12,
        vertical: 6.0,
      ),
      decoration: BoxDecoration(
        color: status.backgroundColor,
        borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
      ),
      child: Text(
        status.label,
        style: AppTypography.labelSmall.copyWith(
          color: status.color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

// ── Decision Result Banner ────────────────────────────────────────────────────

class _DecisionResultBanner extends StatelessWidget {
  const _DecisionResultBanner({required this.status});

  final LeaveStatus status;

  @override
  Widget build(BuildContext context) {
    final isApproved = status == LeaveStatus.approved;
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space16),
      decoration: BoxDecoration(
        color: isApproved ? AppColors.successLight : AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(
          color: isApproved
              ? AppColors.successGreen.withValues(alpha: 0.3)
              : AppColors.errorRed.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(
            isApproved
                ? Icons.check_circle_outline_rounded
                : Icons.cancel_outlined,
            color: isApproved ? AppColors.successDark : AppColors.errorDark,
            size: AppDimensions.iconMD,
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Text(
              isApproved
                  ? 'This leave request has already been approved.'
                  : 'This leave request has already been rejected.',
              style: AppTypography.bodySmall.copyWith(
                color: isApproved ? AppColors.successDark : AppColors.errorDark,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
