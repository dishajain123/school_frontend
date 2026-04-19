import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/parent/child_summary.dart';
import '../../../data/models/parent/parent_model.dart';
import '../../../data/repositories/parent_repository.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_loading.dart';
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

class _ParentDetailScreenState extends ConsumerState<ParentDetailScreen>
    with SingleTickerProviderStateMixin {
  ParentModel? _parent;
  List<ChildSummaryModel> _children = [];
  bool _isLoading = true;
  bool _isChildrenLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);

    if (widget.initialParent != null) {
      _parent = widget.initialParent;
      _isLoading = false;
      _animCtrl.forward();
      _loadChildren();
    } else {
      _loadAll();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() => _isLoading = true);
    final p = await ref
        .read(parentNotifierProvider.notifier)
        .getById(widget.parentId);
    if (mounted) {
      setState(() {
        _parent = p;
        _isLoading = false;
      });
      _animCtrl.forward();
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
        appBar: const AppAppBar(title: 'Parent', showBack: true),
        body: _buildShimmer(),
      );
    }

    if (_parent == null) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: const AppAppBar(title: 'Parent', showBack: true),
        body: const Center(child: Text('Parent not found.')),
      );
    }

    final parent = _parent!;

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: FadeTransition(
        opacity: _fade,
        child: CustomScrollView(
          slivers: [
            _ParentSliverAppBar(
              parent: parent,
              canEdit: _canEdit,
              onBack: () => context.pop(),
              onEdit: () async {
                final result = await context.push(
                  '${RouteNames.parentDetailPath(parent.id)}/edit',
                  extra: parent,
                );
                if (result == true && mounted) _loadAll();
              },
            ),
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (parent.email != null || parent.phone != null) ...[
                      _InfoCard(
                        title: 'Contact Information',
                        icon: Icons.contact_phone_outlined,
                        rows: [
                          if (parent.email != null)
                            _InfoRowData(
                              icon: Icons.email_outlined,
                              label: 'Email',
                              value: parent.email!,
                            ),
                          if (parent.phone != null)
                            _InfoRowData(
                              icon: Icons.phone_outlined,
                              label: 'Phone',
                              value: parent.phone!,
                            ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                    _InfoCard(
                      title: 'Personal Details',
                      icon: Icons.person_outline_rounded,
                      rows: [
                        _InfoRowData(
                          icon: Icons.supervisor_account_outlined,
                          label: 'Relation',
                          value: parent.relation.label,
                        ),
                        if (parent.occupation != null)
                          _InfoRowData(
                            icon: Icons.work_outline_rounded,
                            label: 'Occupation',
                            value: parent.occupation!,
                          ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    _SectionHeader(
                      title: 'Children',
                      count: _children.length,
                    ),
                    const SizedBox(height: 12),
                    if (_isChildrenLoading)
                      ..._buildChildShimmers()
                    else if (_children.isEmpty)
                      _EmptyChildren()
                    else
                      ...(_children.map((child) => Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: ChildCard(
                              child: child,
                              standardName: _getStandardName(child),
                              onTap: () => context.push(
                                RouteNames.studentDetailPath(child.id),
                              ),
                            ),
                          ))),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: AppLoading.card(height: 64),
      ),
    );
  }

  List<Widget> _buildChildShimmers() {
    return List.generate(
      2,
      (_) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppLoading.card(height: 76),
      ),
    );
  }
}

class _ParentSliverAppBar extends StatelessWidget {
  const _ParentSliverAppBar({
    required this.parent,
    required this.canEdit,
    required this.onBack,
    required this.onEdit,
  });

  final ParentModel parent;
  final bool canEdit;
  final VoidCallback onBack;
  final VoidCallback onEdit;

  Color get _relationColor {
    switch (parent.relation) {
      case RelationType.mother:
        return AppColors.subjectHindi;
      case RelationType.father:
        return AppColors.infoBlue;
      case RelationType.guardian:
        return AppColors.subjectMath;
    }
  }

  String get _initials {
    final parts = parent.displayName.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parent.displayName.isNotEmpty
        ? parent.displayName[0].toUpperCase()
        : '?';
  }

  @override
  Widget build(BuildContext context) {
    final color = _relationColor;

    return SliverAppBar(
      expandedHeight: 210,
      pinned: true,
      backgroundColor: AppColors.navyDeep,
      foregroundColor: AppColors.white,
      automaticallyImplyLeading: false,
      leading: Padding(
        padding: const EdgeInsets.only(left: 8),
        child: IconButton(
          onPressed: onBack,
          icon: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.white.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              color: AppColors.white,
              size: 16,
            ),
          ),
        ),
      ),
      actions: [
        if (canEdit)
          Padding(
            padding: const EdgeInsets.only(right: 8),
            child: IconButton(
              onPressed: onEdit,
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(
                  Icons.edit_outlined,
                  color: AppColors.white,
                  size: 16,
                ),
              ),
            ),
          ),
      ],
      flexibleSpace: FlexibleSpaceBar(
        background: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF0B1F3A), Color(0xFF1A3A5C)],
            ),
          ),
          child: SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 32),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color,
                        Color.lerp(color, Colors.black, 0.2) ?? color,
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppColors.white.withValues(alpha: 0.25),
                      width: 2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: color.withValues(alpha: 0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Text(
                      _initials,
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 26,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  parent.displayName,
                  style: AppTypography.headlineSmall.copyWith(
                    color: AppColors.white,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: AppColors.goldPrimary.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: AppColors.goldPrimary.withValues(alpha: 0.35),
                    ),
                  ),
                  child: Text(
                    parent.relation.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: AppColors.goldPrimary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.title, required this.count});
  final String title;
  final int count;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: AppColors.navyDeep.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(9),
          ),
          child: const Icon(
            Icons.people_outline_rounded,
            size: 15,
            color: AppColors.navyDeep,
          ),
        ),
        const SizedBox(width: 10),
        Text(
          title,
          style: AppTypography.titleSmall.copyWith(
            fontWeight: FontWeight.w700,
            color: AppColors.navyDeep,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: AppColors.navyDeep.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            '$count',
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.navyDeep,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
        ),
      ],
    );
  }
}

class _EmptyChildren extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.child_care_rounded,
            size: 32,
            color: AppColors.grey400,
          ),
          const SizedBox(height: 8),
          Text(
            'No children linked',
            style: AppTypography.bodyMedium.copyWith(
              color: AppColors.grey500,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRowData {
  const _InfoRowData({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;
}

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.title,
    required this.icon,
    required this.rows,
  });

  final String title;
  final IconData icon;
  final List<_InfoRowData> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) return const SizedBox.shrink();

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
                  child: Icon(icon, size: 15, color: AppColors.navyDeep),
                ),
                const SizedBox(width: 10),
                Text(
                  title,
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
          ...rows.asMap().entries.map((entry) {
            final row = entry.value;
            final isLast = entry.key == rows.length - 1;
            return Column(
              children: [
                Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      Icon(row.icon, size: 18, color: AppColors.grey400),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              row.label,
                              style: AppTypography.caption.copyWith(
                                color: AppColors.grey400,
                                fontSize: 11,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              row.value,
                              style: AppTypography.bodyMedium.copyWith(
                                color: row.valueColor ?? AppColors.grey800,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                if (!isLast)
                  Container(
                    height: 1,
                    color: AppColors.surface100,
                    margin: const EdgeInsets.only(left: 46),
                  ),
              ],
            );
          }),
        ],
      ),
    );
  }
}