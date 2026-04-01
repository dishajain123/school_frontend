import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/parent/child_summary.dart';
import '../../../data/models/parent/parent_model.dart';
import '../../../data/repositories/parent_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_avatar.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_section_header.dart';
import '../widgets/child_card.dart';

class ParentDetailScreen extends ConsumerStatefulWidget {
  const ParentDetailScreen({
    super.key,
    required this.parentId,
    this.initialParent,
  });

  final String parentId;
  final ParentModel? initialParent;

  @override
  ConsumerState<ParentDetailScreen> createState() => _ParentDetailScreenState();
}

class _ParentDetailScreenState extends ConsumerState<ParentDetailScreen> {
  ParentModel? _parent;
  List<ChildSummaryModel> _children = [];
  bool _isLoading = true;
  bool _isChildrenLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.initialParent != null) {
      _parent = widget.initialParent;
      _isLoading = false;
      _loadChildren();
    } else {
      _loadAll();
    }
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final p = await ref.read(parentNotifierProvider.notifier).getById(widget.parentId);
    if (mounted) {
      setState(() {
        _parent = p;
        _isLoading = false;
      });
      if (p != null) _loadChildren();
    }
  }

  Future<void> _loadChildren() async {
    setState(() => _isChildrenLoading = true);
    try {
      final repo = ref.read(parentRepositoryProvider);
      final children = await repo.getChildren(widget.parentId);
      if (mounted) {
        setState(() {
          _children = children;
          _isChildrenLoading = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _isChildrenLoading = false);
    }
  }

  bool get _canEdit {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('user:manage') ?? false;
  }

  String? _getStandardName(ChildSummaryModel child) {
    if (child.standardId == null) return null;
    final standards = ref.read(standardsNotifierProvider).valueOrNull ?? [];
    try {
      return standards.firstWhere((s) => s.id == child.standardId).name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(title: 'Parent', showBack: true),
        body: AppLoading.listView(count: 5),
      );
    }

    if (_parent == null) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(title: 'Parent', showBack: true),
        body: const Center(child: Text('Parent not found.')),
      );
    }

    final parent = _parent!;

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
                      RouteNames.parentDetailPath(parent.id) + '/edit',
                      extra: parent,
                    );
                    if (result == true && mounted) _loadAll();
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
                        imageUrl: parent.profilePhotoUrl,
                        name: parent.displayName,
                      ),
                      const SizedBox(height: AppDimensions.space12),
                      Text(
                        parent.displayName,
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
                          parent.relation.label,
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

                  // Contact Info
                  _InfoSection(
                    title: 'Contact Information',
                    children: [
                      if (parent.email != null)
                        _InfoRow(
                          icon: Icons.email_outlined,
                          label: 'Email',
                          value: parent.email!,
                        ),
                      if (parent.phone != null)
                        _InfoRow(
                          icon: Icons.phone_outlined,
                          label: 'Phone',
                          value: parent.phone!,
                        ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.space16),

                  // Personal Info
                  _InfoSection(
                    title: 'Personal Details',
                    children: [
                      _InfoRow(
                        icon: Icons.supervisor_account_outlined,
                        label: 'Relation',
                        value: parent.relation.label,
                      ),
                      if (parent.occupation != null)
                        _InfoRow(
                          icon: Icons.work_outline_rounded,
                          label: 'Occupation',
                          value: parent.occupation!,
                        ),
                    ],
                  ),

                  const SizedBox(height: AppDimensions.space24),

                  // Children
                  AppSectionHeader(title: 'Children (${_children.length})'),
                  const SizedBox(height: AppDimensions.space12),

                  if (_isChildrenLoading)
                    AppLoading.listView(count: 2, withAvatar: false)
                  else if (_children.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(AppDimensions.space16),
                      decoration: BoxDecoration(
                        color: AppColors.white,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusMedium),
                        border: Border.all(color: AppColors.surface200),
                      ),
                      child: Text(
                        'No children linked to this parent.',
                        style: AppTypography.bodyMedium.copyWith(
                          color: AppColors.grey600,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    )
                  else
                    Column(
                      children: _children
                          .map((child) => Padding(
                                padding: const EdgeInsets.only(
                                    bottom: AppDimensions.space8),
                                child: ChildCard(
                                  child: child,
                                  standardName: _getStandardName(child),
                                  onTap: () => context.push(
                                    RouteNames.studentDetailPath(child.id),
                                  ),
                                ),
                              ))
                          .toList(),
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
  const _InfoSection({required this.title, required this.children});
  final String title;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.grey600,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppDimensions.space8),
        Container(
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
            border: Border.all(color: AppColors.surface200, width: AppDimensions.borderThin),
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
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      child: Row(
        children: [
          Icon(icon, size: AppDimensions.iconSM, color: AppColors.grey400),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: AppTypography.caption),
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