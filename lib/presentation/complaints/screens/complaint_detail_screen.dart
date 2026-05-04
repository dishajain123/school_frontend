import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_colors.dart';
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
import '../widgets/status_stepper.dart' as complaint_widgets;

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

class _ComplaintDetailScreenState extends ConsumerState<ComplaintDetailScreen>
    with SingleTickerProviderStateMixin {
  ComplaintModel? _complaint;
  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _complaint = widget.initialComplaint;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    // Keep list/detail state stable while navigating back and forth.
    // Only reload when this screen is opened without complaint data.
    if (_complaint == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(complaintNotifierProvider.notifier).load();
      });
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _showStatusUpdateSheet(ComplaintModel complaint) async {
    final nextStatus = complaint.status.next;
    if (nextStatus == null) return;

    final noteController = TextEditingController();

    await AppBottomSheet.show<void>(
      context,
      title: 'Update Status',
      subtitle: 'Move complaint to next stage',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
              color: AppColors.surface50,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppColors.surface200),
            ),
            child: Row(
              children: [
                AppStatusChip(status: complaint.status.backendValue),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: AppColors.navyDeep.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.arrow_forward_rounded,
                        size: 14, color: AppColors.navyDeep),
                  ),
                ),
                AppStatusChip(status: nextStatus.backendValue),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            controller: noteController,
            label: 'Resolution Note (optional)',
            hint: 'Add a short note for this transition...',
            maxLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const SizedBox(height: 20),
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
    final canManage = user?.role.isSchoolScopedAdminOrTrustee ?? false;

    return AppScaffold(
      appBar: const AppAppBar(title: 'Complaint Detail', showBack: true),
      body: state.when(
        loading: () {
          if (complaint != null) {
            return _buildBody(complaint, canManage);
          }
          return const Center(child: CircularProgressIndicator.adaptive());
        },
        error: (e, _) {
          if (complaint != null) return _buildBody(complaint, canManage);
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(e.toString(),
                  style: AppTypography.bodyMedium, textAlign: TextAlign.center),
            ),
          );
        },
        data: (_) {
          if (complaint == null) {
            return Center(
              child:
                  Text('Complaint not found', style: AppTypography.bodyMedium),
            );
          }
          return _buildBody(complaint, canManage);
        },
      ),
    );
  }

  Widget _buildBody(ComplaintModel complaint, bool canManage) {
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: _DetailBody(
          complaint: complaint,
          canManage: canManage,
          onUpdateStatus: () => _showStatusUpdateSheet(complaint),
        ),
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
    final catColor = complaint.category.color;

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _HeroCard(complaint: complaint, catColor: catColor),
              const SizedBox(height: 16),
              _ProgressCard(complaint: complaint),
              if (complaint.resolutionNote != null &&
                  complaint.resolutionNote!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                _ResolutionCard(note: complaint.resolutionNote!),
              ],
              const SizedBox(height: 16),
            ],
          ),
        ),
        if (canManage && nextStatus != null)
          _ActionBar(
            nextLabel: nextStatus.label,
            onTap: onUpdateStatus,
          ),
      ],
    );
  }
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.complaint, required this.catColor});
  final ComplaintModel complaint;
  final Color catColor;

  @override
  Widget build(BuildContext context) {
    final hasSubmitterName = complaint.submittedByName != null &&
        complaint.submittedByName!.trim().isNotEmpty;
    final submitterRole = complaint.submittedByRole?.trim();
    final formattedRole = (submitterRole != null && submitterRole.isNotEmpty)
        ? _formatRole(submitterRole)
        : null;
    final raisedByText = complaint.isAnonymous
        ? 'Anonymous'
        : hasSubmitterName
            ? (formattedRole != null
                ? '${complaint.submittedByName!} ($formattedRole)'
                : complaint.submittedByName!)
            : (formattedRole ?? 'Unknown');

    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.07),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: catColor.withValues(alpha: 0.06),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: catColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child:
                      Icon(complaint.category.icon, size: 20, color: catColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        complaint.category.label,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey800,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          const Icon(Icons.schedule_rounded,
                              size: 11, color: AppColors.grey400),
                          const SizedBox(width: 3),
                          Text(
                            DateFormatter.formatDateTime(complaint.createdAt),
                            style: AppTypography.caption.copyWith(
                              color: AppColors.grey400,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Row(
                        children: [
                          Icon(
                            complaint.isAnonymous
                                ? Icons.visibility_off_outlined
                                : Icons.person_outline_rounded,
                            size: 11,
                            color: AppColors.grey500,
                          ),
                          const SizedBox(width: 3),
                          Expanded(
                            child: Text(
                              'Raised by: $raisedByText',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.grey500,
                                fontSize: 11,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (!complaint.isAnonymous && formattedRole != null) ...[
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            const Icon(
                              Icons.badge_outlined,
                              size: 11,
                              color: AppColors.grey500,
                            ),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                'Complainant Type: $formattedRole',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.caption.copyWith(
                                  color: AppColors.grey500,
                                  fontSize: 11,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                AppStatusChip(status: complaint.status.backendValue),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.surface100),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  complaint.description,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.grey700,
                    height: 1.65,
                    fontSize: 14,
                  ),
                ),
                if (complaint.isAnonymous || complaint.attachmentKey != null)
                  const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  children: [
                    if (complaint.isAnonymous)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.surface100,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.visibility_off_outlined,
                                size: 12, color: AppColors.grey500),
                            const SizedBox(width: 4),
                            Text(
                              'Anonymous',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.grey500,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    if (complaint.attachmentKey != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.infoBlue.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.attach_file_rounded,
                                size: 12, color: AppColors.infoBlue),
                            const SizedBox(width: 4),
                            Text(
                              'Has attachment',
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.infoBlue,
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatRole(String role) {
    final lower = role.toLowerCase();
    if (lower.isEmpty) return role;
    return lower[0].toUpperCase() + lower.substring(1);
  }
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({required this.complaint});
  final ComplaintModel complaint;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 10),
            child: Row(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppColors.navyDeep.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.timeline_rounded,
                      size: 15, color: AppColors.navyDeep),
                ),
                const SizedBox(width: 10),
                Text(
                  'Status Progress',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: AppColors.navyDeep,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
          Container(height: 1, color: AppColors.surface100),
          Padding(
            padding: const EdgeInsets.all(20),
            child: complaint_widgets.StatusStepper(
              currentStatus: complaint.status,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResolutionCard extends StatelessWidget {
  const _ResolutionCard({required this.note});
  final String note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.successLight,
        borderRadius: BorderRadius.circular(14),
        border:
            Border.all(color: AppColors.successGreen.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.check_circle_outline_rounded,
              size: 18, color: AppColors.successGreen),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Resolution Note',
                  style: AppTypography.labelSmall.copyWith(
                    color: AppColors.successGreen,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  note,
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.grey700,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionBar extends StatelessWidget {
  const _ActionBar({required this.nextLabel, required this.onTap});
  final String nextLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: AppButton.primary(
        label: 'Move to $nextLabel',
        onTap: onTap,
        icon: Icons.sync_alt_rounded,
      ),
    );
  }
}
