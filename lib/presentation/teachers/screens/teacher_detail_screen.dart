import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/teacher/teacher_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_avatar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_loading.dart';

class TeacherDetailScreen extends ConsumerStatefulWidget {
  const TeacherDetailScreen({
    super.key,
    required this.teacherId,
    this.initialTeacher,
  });

  final String teacherId;
  final TeacherModel? initialTeacher;

  @override
  ConsumerState<TeacherDetailScreen> createState() =>
      _TeacherDetailScreenState();
}

class _TeacherDetailScreenState extends ConsumerState<TeacherDetailScreen> {
  TeacherModel? _teacher;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    if (widget.initialTeacher != null) {
      _teacher = widget.initialTeacher;
      _isLoading = false;
    } else {
      _loadTeacher();
    }
  }

  Future<void> _loadTeacher() async {
    setState(() => _isLoading = true);
    final t =
        await ref.read(teacherNotifierProvider.notifier).getById(widget.teacherId);
    if (mounted) {
      setState(() {
        _teacher = t;
        _isLoading = false;
      });
    }
  }

  bool get _canEdit {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('user:manage') ?? false;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(title: 'Teacher', showBack: true),
        body: AppLoading.listView(count: 5),
      );
    }

    if (_teacher == null) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(title: 'Teacher', showBack: true),
        body: const Center(
          child: Text('Teacher not found.'),
        ),
      );
    }

    final teacher = _teacher!;

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.navyDeep,
            foregroundColor: AppColors.white,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: () => context.pop(),
            ),
            actions: [
              if (_canEdit)
                IconButton(
                  icon: const Icon(Icons.edit_outlined),
                  onPressed: () async {
                    final result = await context.push(
                      RouteNames.teacherDetailPath(teacher.id) + '/edit',
                      extra: teacher,
                    );
                    if (result == true && mounted) {
                      _loadTeacher();
                    }
                  },
                ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [AppColors.navyDeep, AppColors.navyMedium],
                  ),
                ),
                child: SafeArea(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: AppDimensions.space48),
                      AppAvatar.xl(
                        imageUrl: teacher.profilePhotoUrl,
                        name: teacher.displayName,
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Text(
                        teacher.displayName,
                        style: AppTypography.headlineSmall.copyWith(
                          color: AppColors.white,
                        ),
                      ),
                      const SizedBox(height: AppDimensions.space4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: AppDimensions.space12,
                          vertical: AppDimensions.space4,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary.withValues(alpha: 0.2),
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusFull),
                        ),
                        child: Text(
                          teacher.employeeCode,
                          style: AppTypography.labelSmall.copyWith(
                            color: AppColors.goldPrimary,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: AppDimensions.space16),
                  _InfoSection(
                    title: 'Contact Information',
                    children: [
                      _InfoRow(
                        icon: Icons.email_outlined,
                        label: 'Email',
                        value: teacher.email ?? '—',
                      ),
                      _InfoRow(
                        icon: Icons.phone_outlined,
                        label: 'Phone',
                        value: teacher.phone ?? '—',
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  _InfoSection(
                    title: 'Professional Details',
                    children: [
                      _InfoRow(
                        icon: Icons.badge_outlined,
                        label: 'Employee Code',
                        value: teacher.employeeCode,
                      ),
                      if (teacher.specialization != null)
                        _InfoRow(
                          icon: Icons.school_outlined,
                          label: 'Specialization',
                          value: teacher.specialization!,
                        ),
                      if (teacher.joinDate != null)
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Join Date',
                          value: DateFormatter.formatDate(teacher.joinDate!),
                        ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  _InfoSection(
                    title: 'Status',
                    children: [
                      _InfoRow(
                        icon: Icons.circle,
                        label: 'Account Status',
                        value: teacher.isActive ? 'Active' : 'Inactive',
                        valueColor: teacher.isActive
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                        iconColor: teacher.isActive
                            ? AppColors.successGreen
                            : AppColors.errorRed,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppDimensions.space16),
                  Text(
                    'Joined ${DateFormatter.formatDate(teacher.createdAt)}',
                    style: AppTypography.caption,
                  ),
                  const SizedBox(height: AppDimensions.space40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoSection extends StatelessWidget {
  const _InfoSection({
    required this.title,
    required this.children,
  });

  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.grey600,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: AppDimensions.space8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(
              color: AppColors.surface200,
              width: AppDimensions.borderThin,
            ),
          ),
          child: Column(
            children: children
                .asMap()
                .entries
                .map((entry) => Column(
                      children: [
                        entry.value,
                        if (entry.key < children.length - 1)
                          const Divider(
                            height: 1,
                            color: AppColors.surface100,
                            indent: AppDimensions.space16,
                          ),
                      ],
                    ))
                .toList(),
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: AppDimensions.iconSM,
            color: iconColor ?? AppColors.grey400,
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption,
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: AppTypography.bodyMedium.copyWith(
                    color: valueColor ?? AppColors.grey800,
                    fontWeight: FontWeight.w500,
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