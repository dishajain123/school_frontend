import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/complaint/complaint_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/complaint_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_bottom_sheet.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_scaffold.dart';
import '../../common/widgets/app_status_chip.dart';
import '../../common/widgets/app_text_field.dart';
import '../widgets/status_stepper.dart';

class ComplaintDetailScreen extends ConsumerStatefulWidget {
  const ComplaintDetailScreen({
    super.key,
    required this.complaintId,
    this.initialComplaint,
  });

  final String complaintId;
  final ComplaintModel? initialComplaint;

  @override
  ConsumerState<ComplaintDetailScreen> createState() =>
      _ComplaintDetailScreenState();
}

class _ComplaintDetailScreenState extends ConsumerState<ComplaintDetailScreen> {
  ComplaintModel? _complaint;

  @override
  void initState() {
    super.initState();
    _complaint = widget.initialComplaint;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(complaintNotifierProvider.notifier).load();
    });
  }

  Future<void> _showStatusUpdateSheet(ComplaintModel complaint) async {
    final nextStatus = complaint.status.next;
    if (nextStatus == null) return;

    final noteController = TextEditingController();

    await AppBottomSheet.show<void>(
      context,
      title: 'Update Complaint Status',
      subtitle: 'Move complaint to next stage',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(AppDimensions.space12),
            decoration: BoxDecoration(
              color: AppColors.surface50,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.surface200),
            ),
            child: Row(
              children: [
                AppStatusChip(status: complaint.status.backendValue),
                const Padding(
                  padding:
                      EdgeInsets.symmetric(horizontal: AppDimensions.space8),
                  child: Icon(Icons.arrow_right_alt_rounded),
                ),
                AppStatusChip(status: nextStatus.backendValue),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          AppTextField(
            controller: noteController,
            label: 'Resolution Note (optional)',
            hint: 'Add a short note for this transition',
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: AppDimensions.space20),
          AppButton.primary(
            label: 'Update to ${nextStatus.label}',
            onTap: () async {
              final updated = await ref
                  .read(complaintNotifierProvider.notifier)
                  .updateStatus(
                    complaintId: complaint.id,
                    nextStatus: nextStatus,
                    resolutionNote: noteController.text,
                  );

              if (!mounted) return;

              if (updated != null) {
                Navigator.of(context).pop();
                SnackbarUtils.showSuccess(
                  context,
                  'Status updated to ${updated.status.label}',
                );
              } else {
                final message =
                    ref.read(complaintNotifierProvider).valueOrNull?.error ??
                        'Failed to update status';
                SnackbarUtils.showError(context, message);
              }
            },
            icon: Icons.check_circle_outline_rounded,
          ),
        ],
      ),
    );

    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(complaintNotifierProvider);
    final complaint =
        ref.watch(complaintByIdProvider(widget.complaintId)) ?? _complaint;
    final user = ref.watch(currentUserProvider);

    final canManage =
        user?.role == UserRole.principal || user?.role == UserRole.trustee;

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Complaint Detail',
        showBack: true,
      ),
      body: state.when(
        loading: () {
          if (complaint != null) {
            return _DetailBody(
              complaint: complaint,
              canManage: canManage,
              onUpdateStatus: () => _showStatusUpdateSheet(complaint),
            );
          }
          return const Center(child: CircularProgressIndicator.adaptive());
        },
        error: (e, _) {
          if (complaint != null) {
            return _DetailBody(
              complaint: complaint,
              canManage: canManage,
              onUpdateStatus: () => _showStatusUpdateSheet(complaint),
            );
          }
          return Center(
            child: Text(
              e.toString(),
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
          );
        },
        data: (_) {
          if (complaint == null) {
            return Center(
              child: Text(
                'Complaint not found',
                style: AppTypography.bodyMedium,
              ),
            );
          }

          return _DetailBody(
            complaint: complaint,
            canManage: canManage,
            onUpdateStatus: () => _showStatusUpdateSheet(complaint),
          );
        },
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({
    required this.complaint,
    required this.canManage,
    required this.onUpdateStatus,
  });

  final ComplaintModel complaint;
  final bool canManage;
  final VoidCallback onUpdateStatus;

  @override
  Widget build(BuildContext context) {
    final nextStatus = complaint.status.next;

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.space16,
        AppDimensions.space16,
        AppDimensions.space16,
        AppDimensions.pageBottomScroll,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.surface200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    complaint.category.icon,
                    color: complaint.category.color,
                    size: AppDimensions.iconMD,
                  ),
                  const SizedBox(width: AppDimensions.space8),
                  Expanded(
                    child: Text(
                      complaint.category.label,
                      style: AppTypography.titleLarge,
                    ),
                  ),
                  AppStatusChip(status: complaint.status.backendValue),
                ],
              ),
              const SizedBox(height: AppDimensions.space12),
              Text(
                complaint.description,
                style: AppTypography.bodyMedium.copyWith(
                  color: AppColors.grey800,
                ),
              ),
              const SizedBox(height: AppDimensions.space12),
              Row(
                children: [
                  const Icon(
                    Icons.schedule_outlined,
                    size: AppDimensions.iconXS,
                    color: AppColors.grey400,
                  ),
                  const SizedBox(width: AppDimensions.space4),
                  Text(
                    DateFormatter.formatDateTime(complaint.createdAt),
                    style: AppTypography.caption,
                  ),
                  const Spacer(),
                  if (complaint.isAnonymous)
                    Text(
                      'Anonymous',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.grey600,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                ],
              ),
              if (complaint.attachmentKey != null) ...[
                const SizedBox(height: AppDimensions.space12),
                Row(
                  children: [
                    const Icon(
                      Icons.attachment_rounded,
                      size: AppDimensions.iconSM,
                      color: AppColors.grey600,
                    ),
                    const SizedBox(width: AppDimensions.space6),
                    Expanded(
                      child: Text(
                        complaint.attachmentKey!,
                        style: AppTypography.bodySmall,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
              if (complaint.resolutionNote != null &&
                  complaint.resolutionNote!.trim().isNotEmpty) ...[
                const SizedBox(height: AppDimensions.space12),
                Text(
                  'Resolution Note',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
                const SizedBox(height: AppDimensions.space4),
                Text(
                  complaint.resolutionNote!,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.grey800,
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: AppDimensions.space20),
        Container(
          padding: const EdgeInsets.all(AppDimensions.space16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.surface200),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Status Progress',
                style: AppTypography.titleMedium,
              ),
              const SizedBox(height: AppDimensions.space16),
              StatusStepper(currentStatus: complaint.status),
            ],
          ),
        ),
        if (canManage && nextStatus != null) ...[
          const SizedBox(height: AppDimensions.space20),
          AppButton.primary(
            label: 'Move to ${nextStatus.label}',
            onTap: onUpdateStatus,
            icon: Icons.sync_alt_rounded,
          ),
        ],
      ],
    );
  }
}
