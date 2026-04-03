import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/school/school_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/school_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_dialog.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_scaffold.dart';

class SchoolDetailScreen extends ConsumerStatefulWidget {
  const SchoolDetailScreen({
    super.key,
    required this.schoolId,
    this.initialSchool,
  });

  final String schoolId;
  final SchoolModel? initialSchool;

  @override
  ConsumerState<SchoolDetailScreen> createState() => _SchoolDetailScreenState();
}

class _SchoolDetailScreenState extends ConsumerState<SchoolDetailScreen> {
  SchoolModel? _school;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _school = widget.initialSchool;
    _isLoading = widget.initialSchool == null;
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSchool());
  }

  Future<void> _loadSchool() async {
    final fromState = ref.read(schoolByIdProvider(widget.schoolId));
    if (fromState != null) {
      setState(() {
        _school = fromState;
        _isLoading = false;
      });
      return;
    }

    final school = await ref.read(schoolNotifierProvider.notifier).getById(
          widget.schoolId,
        );
    if (!mounted) return;
    setState(() {
      _school = school;
      _isLoading = false;
    });
  }

  Future<void> _deactivateSchool() async {
    final school = _school;
    if (school == null || !school.isActive) return;
    final confirmed = await AppDialog.destructive(
      context,
      title: 'Deactivate School',
      message:
          'This school will be marked inactive and unavailable for operations.',
      confirmLabel: 'Deactivate',
    );
    if (confirmed != true || !mounted) return;

    final updated =
        await ref.read(schoolNotifierProvider.notifier).deactivateSchool(
              school.id,
            );
    if (!mounted) return;
    if (updated != null) {
      setState(() => _school = updated);
      SnackbarUtils.showSuccess(context, 'School deactivated successfully');
    } else {
      final error = ref.read(schoolNotifierProvider).valueOrNull?.error ??
          'Failed to deactivate school';
      SnackbarUtils.showError(context, error);
    }
  }

  Future<void> _toggleActive(bool value) async {
    final school = _school;
    if (school == null) return;
    if (!value && school.isActive) {
      await _deactivateSchool();
      return;
    }
    if (value && !school.isActive) {
      SnackbarUtils.showInfo(
        context,
        'Activation is not available from this API. Edit through backend admin.',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canManage = user?.role == UserRole.superadmin;
    final isSubmitting =
        ref.watch(schoolNotifierProvider).valueOrNull?.isSubmitting ?? false;

    if (!canManage) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'School', showBack: true),
        body: AppEmptyState(
          icon: Icons.lock_outline_rounded,
          title: 'Access denied',
          subtitle: 'Only superadmin can manage schools.',
        ),
      );
    }

    if (_isLoading) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'School Detail', showBack: true),
        body: Center(child: CircularProgressIndicator.adaptive()),
      );
    }

    final school = _school;
    if (school == null) {
      return const AppScaffold(
        appBar: AppAppBar(title: 'School Detail', showBack: true),
        body: AppEmptyState(
          icon: Icons.business_outlined,
          title: 'School not found',
          subtitle: 'This school may have been removed.',
        ),
      );
    }

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'School Detail',
        showBack: true,
      ),
      body: ListView(
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
                    Expanded(
                      child: Text(
                        school.name,
                        style: AppTypography.headlineSmall,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppDimensions.space8,
                        vertical: AppDimensions.space4,
                      ),
                      decoration: BoxDecoration(
                        color: school.isActive
                            ? AppColors.successLight
                            : AppColors.errorLight,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusFull),
                      ),
                      child: Text(
                        school.isActive ? 'Active' : 'Inactive',
                        style: AppTypography.labelSmall.copyWith(
                          color: school.isActive
                              ? AppColors.successGreen
                              : AppColors.errorRed,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space12),
                _DetailRow(label: 'Email', value: school.contactEmail),
                if (school.contactPhone != null &&
                    school.contactPhone!.trim().isNotEmpty)
                  _DetailRow(label: 'Phone', value: school.contactPhone!),
                if (school.address != null && school.address!.trim().isNotEmpty)
                  _DetailRow(label: 'Address', value: school.address!),
                _DetailRow(
                  label: 'Subscription',
                  value: school.subscriptionPlan.label,
                ),
                _DetailRow(
                  label: 'Created',
                  value: DateFormatter.formatDateTime(school.createdAt),
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          Container(
            padding: const EdgeInsets.all(AppDimensions.space16),
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
              border: Border.all(color: AppColors.surface200),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'School Active',
                    style: AppTypography.titleMedium,
                  ),
                ),
                Switch.adaptive(
                  value: school.isActive,
                  onChanged: isSubmitting ? null : _toggleActive,
                ),
              ],
            ),
          ),
          const SizedBox(height: AppDimensions.space16),
          AppButton.secondary(
            label: 'Edit School',
            onTap: () async {
              final updated = await context.push(
                RouteNames.createSchool,
                extra: school,
              );
              if (updated == true) {
                await _loadSchool();
              }
            },
            icon: Icons.edit_outlined,
          ),
          const SizedBox(height: AppDimensions.space12),
          AppButton.destructive(
            label: 'Deactivate School',
            onTap:
                (!school.isActive || isSubmitting) ? null : _deactivateSchool,
            isLoading: isSubmitting,
            icon: Icons.block_outlined,
          ),
        ],
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.space8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.grey600,
              ),
            ),
          ),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.grey800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
