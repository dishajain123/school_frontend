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
import '../../common/widgets/app_loading.dart';
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

class _SchoolDetailScreenState extends ConsumerState<SchoolDetailScreen>
    with SingleTickerProviderStateMixin {
  SchoolModel? _school;
  bool _isLoading = true;
  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _school = widget.initialSchool;
    _isLoading = widget.initialSchool == null;
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadSchool());
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
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
    final school = await ref
        .read(schoolNotifierProvider.notifier)
        .getById(widget.schoolId);
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
    final updated = await ref
        .read(schoolNotifierProvider.notifier)
        .deactivateSchool(school.id);
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
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: const AppAppBar(title: 'School Detail', showBack: true),
        body: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            AppLoading.card(height: 200),
            const SizedBox(height: 16),
            AppLoading.card(height: 80),
            const SizedBox(height: 16),
            AppLoading.card(height: 60),
          ],
        ),
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

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'School Detail',
        showBack: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: () async {
                final updated =
                    await context.push(RouteNames.createSchool, extra: school);
                if (updated == true) _loadSchool();
              },
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.edit_outlined,
                    color: AppColors.white, size: 16),
              ),
            ),
          ),
        ],
      ),
      body: FadeTransition(
        opacity: _fade,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _SchoolHeroCard(school: school),
            const SizedBox(height: 16),
            _DetailCard(school: school),
            const SizedBox(height: 16),
            _StatusCard(
              school: school,
              isSubmitting: isSubmitting,
              onToggle: _toggleActive,
            ),
            const SizedBox(height: 24),
            AppButton.destructive(
              label: 'Deactivate School',
              onTap: (!school.isActive || isSubmitting)
                  ? null
                  : _deactivateSchool,
              isLoading: isSubmitting,
              icon: Icons.block_outlined,
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _SchoolHeroCard extends StatelessWidget {
  const _SchoolHeroCard({required this.school});
  final SchoolModel school;

  Color get _planColor {
    switch (school.subscriptionPlan) {
      case SubscriptionPlan.basic:
        return AppColors.infoBlue;
      case SubscriptionPlan.standard:
        return AppColors.warningAmber;
      case SubscriptionPlan.premium:
        return AppColors.successGreen;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0B1F3A), Color(0xFF1A3A5C)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.2),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.business_outlined,
                    color: AppColors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      school.name,
                      style: AppTypography.headlineSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      school.contactEmail,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.white.withValues(alpha: 0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: school.isActive
                      ? AppColors.successGreen.withValues(alpha: 0.2)
                      : AppColors.errorRed.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: school.isActive
                        ? AppColors.successGreen.withValues(alpha: 0.4)
                        : AppColors.errorRed.withValues(alpha: 0.4),
                  ),
                ),
                child: Text(
                  school.isActive ? 'Active' : 'Inactive',
                  style: AppTypography.labelSmall.copyWith(
                    color: school.isActive
                        ? AppColors.successGreen
                        : AppColors.errorRed,
                    fontWeight: FontWeight.w700,
                    fontSize: 10,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(height: 1, color: AppColors.white.withValues(alpha: 0.1)),
          const SizedBox(height: 14),
          Row(
            children: [
              _HeroStat(
                  label: 'Plan', value: school.subscriptionPlan.label),
              Container(
                width: 1,
                height: 30,
                color: AppColors.white.withValues(alpha: 0.15),
                margin: const EdgeInsets.symmetric(horizontal: 20),
              ),
              _HeroStat(
                label: 'Created',
                value: DateFormatter.formatDate(school.createdAt),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroStat extends StatelessWidget {
  const _HeroStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.white.withValues(alpha: 0.5),
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: AppTypography.titleSmall.copyWith(
            color: AppColors.white,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.school});
  final SchoolModel school;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 10,
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
                  child: const Icon(Icons.info_outline_rounded,
                      size: 15, color: AppColors.navyDeep),
                ),
                const SizedBox(width: 10),
                Text(
                  'Contact Details',
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
          _InfoRow(
              icon: Icons.email_outlined,
              label: 'Email',
              value: school.contactEmail),
          if (school.contactPhone != null &&
              school.contactPhone!.trim().isNotEmpty) ...[
            Container(
                height: 1,
                color: AppColors.surface100,
                margin: const EdgeInsets.only(left: 56)),
            _InfoRow(
                icon: Icons.phone_outlined,
                label: 'Phone',
                value: school.contactPhone!),
          ],
          if (school.address != null &&
              school.address!.trim().isNotEmpty) ...[
            Container(
                height: 1,
                color: AppColors.surface100,
                margin: const EdgeInsets.only(left: 56)),
            _InfoRow(
                icon: Icons.location_on_outlined,
                label: 'Address',
                value: school.address!),
          ],
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.navyDeep.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 17, color: AppColors.navyMedium),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: AppColors.grey400,
                    fontWeight: FontWeight.w600,
                    fontSize: 10,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.grey800,
                    fontWeight: FontWeight.w500,
                    fontSize: 13,
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

class _StatusCard extends StatelessWidget {
  const _StatusCard({
    required this.school,
    required this.isSubmitting,
    required this.onToggle,
  });

  final SchoolModel school;
  final bool isSubmitting;
  final ValueChanged<bool> onToggle;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: school.isActive
                  ? AppColors.successGreen.withValues(alpha: 0.1)
                  : AppColors.errorRed.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              school.isActive
                  ? Icons.check_circle_outline_rounded
                  : Icons.block_outlined,
              size: 18,
              color: school.isActive
                  ? AppColors.successGreen
                  : AppColors.errorRed,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'School Status',
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
                Text(
                  school.isActive ? 'Currently active' : 'Currently inactive',
                  style: AppTypography.caption.copyWith(
                    color: school.isActive
                        ? AppColors.successGreen
                        : AppColors.grey400,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
          Switch.adaptive(
            value: school.isActive,
            onChanged: isSubmitting ? null : onToggle,
            activeColor: AppColors.successGreen,
          ),
        ],
      ),
    );
  }
}