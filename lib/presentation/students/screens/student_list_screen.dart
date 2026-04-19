import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/masters/standard_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/student_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_dialog.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../widgets/student_tile.dart';

class StudentListScreen extends ConsumerStatefulWidget {
  const StudentListScreen({super.key});

  @override
  ConsumerState<StudentListScreen> createState() => _StudentListScreenState();
}

class _StudentListScreenState extends ConsumerState<StudentListScreen>
    with SingleTickerProviderStateMixin {
  final ScrollController _scrollController = ScrollController();
  StandardModel? _selectedStandard;
  String? _selectedSection;
  final Set<String> _selectedStudentIds = <String>{};
  final Set<String> _excludedStudentIds = <String>{};
  bool _selectAllInSectionMode = false;
  bool _isBulkUpdating = false;
  bool _filtersExpanded = false;

  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(studentNotifierProvider.notifier).load(refresh: true);
      ref.read(standardsNotifierProvider.notifier).refresh();
    });
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >=
        _scrollController.position.maxScrollExtent - 200) {
      ref.read(studentNotifierProvider.notifier).loadMore();
    }
  }

  bool get _canCreate {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('user:manage') ?? false;
  }

  bool get _canPromote {
    final user = ref.read(currentUserProvider);
    return user?.hasPermission('student:promote') ?? false;
  }

  bool get _showBulkSelection => _canPromote && _selectedSection != null;

  void _onStandardChanged(StandardModel? standard) {
    setState(() {
      _selectedStandard = standard;
      _selectedSection = null;
      _resetSelectionState();
    });
    ref.read(studentNotifierProvider.notifier).setFilters(
          StudentFilters(standardId: standard?.id, section: null),
        );
  }

  void _onSectionChanged(String? section) {
    setState(() {
      _selectedSection = section;
      _resetSelectionState();
    });
    ref.read(studentNotifierProvider.notifier).setFilters(
          StudentFilters(standardId: _selectedStandard?.id, section: section),
        );
  }

  void _toggleStudentSelection(String studentId, bool selected) {
    setState(() {
      if (_selectAllInSectionMode) {
        if (selected) {
          _excludedStudentIds.remove(studentId);
        } else {
          _excludedStudentIds.add(studentId);
        }
      } else {
        if (selected) {
          _selectedStudentIds.add(studentId);
        } else {
          _selectedStudentIds.remove(studentId);
        }
      }
    });
  }

  void _selectAllSectionStudents() {
    if (_selectedStandard == null || _selectedSection == null) {
      SnackbarUtils.showError(context, 'Please select class and section first.');
      return;
    }
    setState(() {
      _selectAllInSectionMode = true;
      _selectedStudentIds.clear();
      _excludedStudentIds.clear();
    });
    SnackbarUtils.showSuccess(
      context,
      'All students in selected section are selected. Uncheck any student to exclude.',
    );
  }

  void _resetSelectionState() {
    _selectedStudentIds.clear();
    _excludedStudentIds.clear();
    _selectAllInSectionMode = false;
  }

  void _clearSelections() => setState(_resetSelectionState);

  int _effectiveSelectedCount(int totalInSection) {
    if (_selectAllInSectionMode) {
      final count = totalInSection - _excludedStudentIds.length;
      return count < 0 ? 0 : count;
    }
    return _selectedStudentIds.length;
  }

  bool _isStudentSelected(String studentId) {
    if (_selectAllInSectionMode) {
      return !_excludedStudentIds.contains(studentId);
    }
    return _selectedStudentIds.contains(studentId);
  }

  Future<void> _bulkPromoteSelected(int totalInSection) async {
    final selectedCount = _effectiveSelectedCount(totalInSection);
    if (selectedCount == 0) {
      SnackbarUtils.showError(context, 'Select at least one student.');
      return;
    }
    final confirmed = await AppDialog.confirm(
      context,
      title: 'Promote Selected Students',
      message: _selectAllInSectionMode
          ? 'Promote all students in Section ${_selectedSection!}'
              '${_excludedStudentIds.isNotEmpty ? ' except ${_excludedStudentIds.length} deselected student${_excludedStudentIds.length == 1 ? '' : 's'}' : ''}?'
          : 'Promote $selectedCount selected students now?',
      confirmLabel: 'Promote',
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isBulkUpdating = true);
    try {
      if (_selectAllInSectionMode) {
        await ref
            .read(studentNotifierProvider.notifier)
            .bulkUpdatePromotionStatusBySection(
              standardId: _selectedStandard!.id,
              section: _selectedSection!,
              promotionStatus: 'PROMOTED',
              excludedStudentIds: _excludedStudentIds.toList(),
            );
      } else {
        await ref
            .read(studentNotifierProvider.notifier)
            .bulkUpdatePromotionStatus(
              studentIds: _selectedStudentIds.toList(),
              promotionStatus: 'PROMOTED',
            );
      }
      if (!mounted) return;
      _clearSelections();
      await ref.read(studentNotifierProvider.notifier).load(refresh: true);
      if (!mounted) return;
      SnackbarUtils.showSuccess(context, 'Students promoted successfully.');
    } catch (e) {
      if (!mounted) return;
      SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isBulkUpdating = false);
    }
  }

  String? _getStandardName(StudentModel student, List<StandardModel> standards) {
    if (student.standardId == null) return null;
    try {
      return standards.firstWhere((s) => s.id == student.standardId).name;
    } catch (_) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final asyncState = ref.watch(studentNotifierProvider);
    final studentStateSnapshot = asyncState.valueOrNull;
    final totalInSection = studentStateSnapshot?.total ?? 0;
    final selectedCount = _effectiveSelectedCount(totalInSection);
    final standardsAsync = ref.watch(standardsNotifierProvider);
    final standards = standardsAsync.valueOrNull ?? [];
    final sectionsAsync =
        ref.watch(studentSectionsProvider(_selectedStandard?.id));
    final sections = sectionsAsync.valueOrNull ?? const <String>[];

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Students',
        showBack: true,
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 4),
            child: IconButton(
              onPressed: () =>
                  setState(() => _filtersExpanded = !_filtersExpanded),
              icon: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (_selectedStandard != null || _selectedSection != null)
                      ? AppColors.goldPrimary.withValues(alpha: 0.25)
                      : AppColors.white.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  _filtersExpanded ? Icons.tune : Icons.tune_outlined,
                  color: (_selectedStandard != null || _selectedSection != null)
                      ? AppColors.goldPrimary
                      : AppColors.white,
                  size: 18,
                ),
              ),
            ),
          ),
          if (_canCreate)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () async {
                  final result = await context.push(RouteNames.createStudent);
                  if (result == true && mounted) {
                    ref
                        .read(studentNotifierProvider.notifier)
                        .load(refresh: true);
                  }
                },
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: AppColors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: _showBulkSelection
          ? _BulkActionBar(
              selectedCount: selectedCount,
              isBulkUpdating: _isBulkUpdating,
              sectionModeEnabled: _selectAllInSectionMode,
              onSelectAll: _selectAllSectionStudents,
              onClear: _clearSelections,
              onPromote: () => _bulkPromoteSelected(totalInSection),
            )
          : null,
      body: FadeTransition(
        opacity: _fade,
        child: Column(
          children: [
            AnimatedCrossFade(
              firstChild: const SizedBox(width: double.infinity),
              secondChild: _FilterPanel(
                standards: standards,
                sections: sections,
                selectedStandard: _selectedStandard,
                selectedSection: _selectedSection,
                sectionsLoading: sectionsAsync.isLoading,
                canPromote: _canPromote,
                onStandardChanged: _onStandardChanged,
                onSectionChanged: _onSectionChanged,
              ),
              crossFadeState: _filtersExpanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              duration: const Duration(milliseconds: 220),
            ),
            if (_filtersExpanded) Container(height: 1, color: AppColors.surface100),
            Expanded(
              child: asyncState.when(
                loading: () => _buildShimmer(),
                error: (e, _) => AppErrorState(
                  message: e.toString(),
                  onRetry: () => ref
                      .read(studentNotifierProvider.notifier)
                      .load(refresh: true),
                ),
                data: (studentState) {
                  if (studentState.isLoading) return _buildShimmer();

                  if (studentState.error != null && studentState.items.isEmpty) {
                    return AppErrorState(
                      message: studentState.error,
                      onRetry: () => ref
                          .read(studentNotifierProvider.notifier)
                          .load(refresh: true),
                    );
                  }

                  if (studentState.items.isEmpty) {
                    return AppEmptyState(
                      title: 'No students found',
                      subtitle: _selectedStandard != null
                          ? 'No students in ${_selectedStandard!.name}.'
                          : 'Add your first student to get started.',
                      icon: Icons.school_outlined,
                      actionLabel: _canCreate ? 'Add Student' : null,
                      onAction: _canCreate
                          ? () => context.push(RouteNames.createStudent)
                          : null,
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () => ref
                        .read(studentNotifierProvider.notifier)
                        .load(refresh: true),
                    color: AppColors.navyDeep,
                    child: ListView.builder(
                      controller: _scrollController,
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
                      itemCount: studentState.items.length +
                          (studentState.isLoadingMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == studentState.items.length) {
                          return AppLoading.paginating();
                        }
                        final student = studentState.items[index];
                        final isLast = index == studentState.items.length - 1;

                        return Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: [
                                BoxShadow(
                                  color:
                                      AppColors.navyDeep.withValues(alpha: 0.05),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: StudentTile(
                              student: student,
                              standardName:
                                  _getStandardName(student, standards),
                              isLast: isLast,
                              showSelection: _showBulkSelection,
                              isSelected: _isStudentSelected(student.id),
                              onSelectionChanged: _showBulkSelection
                                  ? (selected) => _toggleStudentSelection(
                                      student.id, selected)
                                  : null,
                              onTap: () {
                                if (_showBulkSelection) {
                                  _toggleStudentSelection(
                                    student.id,
                                    !_isStudentSelected(student.id),
                                  );
                                  return;
                                }
                                context.push(
                                  RouteNames.studentDetailPath(student.id),
                                  extra: student,
                                );
                              },
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
      itemCount: 7,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: AppLoading.card(height: 72),
      ),
    );
  }
}

class _FilterPanel extends StatelessWidget {
  const _FilterPanel({
    required this.standards,
    required this.sections,
    required this.selectedStandard,
    required this.selectedSection,
    required this.sectionsLoading,
    required this.canPromote,
    required this.onStandardChanged,
    required this.onSectionChanged,
  });

  final List<StandardModel> standards;
  final List<String> sections;
  final StandardModel? selectedStandard;
  final String? selectedSection;
  final bool sectionsLoading;
  final bool canPromote;
  final ValueChanged<StandardModel?> onStandardChanged;
  final ValueChanged<String?> onSectionChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      color: AppColors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _DropdownField<String?>(
            hint: 'All Classes',
            value: selectedStandard?.id,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Classes'),
              ),
              ...standards.map((s) => DropdownMenuItem<String?>(
                    value: s.id,
                    child: Text(s.name),
                  )),
            ],
            onChanged: (standardId) {
              final selected = standards.cast<StandardModel?>().firstWhere(
                    (s) => s?.id == standardId,
                    orElse: () => null,
                  );
              onStandardChanged(selected);
            },
            prefixIcon: Icons.school_outlined,
            label: 'Class',
          ),
          const SizedBox(height: 12),
          _DropdownField<String?>(
            hint: selectedStandard == null ? 'Select class first' : 'All Sections',
            value: selectedSection,
            items: [
              const DropdownMenuItem<String?>(
                value: null,
                child: Text('All Sections'),
              ),
              ...sections.map((section) => DropdownMenuItem<String?>(
                    value: section,
                    child: Text('Section $section'),
                  )),
            ],
            onChanged: selectedStandard == null ? null : onSectionChanged,
            prefixIcon: Icons.grid_view_outlined,
            label: 'Section',
            isLoading: sectionsLoading,
          ),
          if (canPromote && selectedSection != null) ...[
            const SizedBox(height: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.infoBlue.withValues(alpha: 0.07),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: AppColors.infoBlue.withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline_rounded,
                      size: 14, color: AppColors.infoBlue),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Use Select All, then uncheck specific students to exclude before promoting.',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.infoBlue,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
    required this.prefixIcon,
    required this.label,
    this.isLoading = false,
  });

  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;
  final IconData prefixIcon;
  final String label;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTypography.labelMedium.copyWith(
            color: AppColors.grey600,
            fontWeight: FontWeight.w600,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: onChanged == null ? AppColors.surface50 : AppColors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surface200, width: 1.5),
          ),
          child: Row(
            children: [
              Icon(prefixIcon, size: 16, color: AppColors.grey400),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonHideUnderline(
                  child: isLoading
                      ? Padding(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 14,
                                height: 14,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.navyMedium),
                              ),
                              const SizedBox(width: 8),
                              Text('Loading...',
                                  style: AppTypography.bodyMedium
                                      .copyWith(color: AppColors.grey400)),
                            ],
                          ),
                        )
                      : DropdownButton<T>(
                          value: value,
                          isExpanded: true,
                          hint: Text(hint,
                              style: AppTypography.bodyMedium
                                  .copyWith(color: AppColors.grey400)),
                          style: AppTypography.bodyMedium
                              .copyWith(color: AppColors.grey800),
                          icon: const Icon(Icons.keyboard_arrow_down_rounded,
                              color: AppColors.grey400),
                          onChanged: onChanged,
                          items: items,
                        ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _BulkActionBar extends StatelessWidget {
  const _BulkActionBar({
    required this.selectedCount,
    required this.isBulkUpdating,
    required this.sectionModeEnabled,
    required this.onSelectAll,
    required this.onClear,
    required this.onPromote,
  });

  final int selectedCount;
  final bool isBulkUpdating;
  final bool sectionModeEnabled;
  final VoidCallback onSelectAll;
  final VoidCallback onClear;
  final VoidCallback onPromote;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 10, 16, 10 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (selectedCount > 0) ...[
            Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.navyDeep.withValues(alpha: 0.06),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                '$selectedCount student${selectedCount == 1 ? '' : 's'} selected',
                style: AppTypography.labelSmall.copyWith(
                  color: AppColors.navyMedium,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
          ],
          Row(
            children: [
              Expanded(
                child: _ActionBtn(
                  label: sectionModeEnabled ? 'Section Selected' : 'Select All',
                  icon: Icons.select_all_rounded,
                  onTap: (isBulkUpdating || sectionModeEnabled) ? null : onSelectAll,
                  isSecondary: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _ActionBtn(
                  label: 'Clear',
                  icon: Icons.clear_all_rounded,
                  onTap: (isBulkUpdating || selectedCount == 0) ? null : onClear,
                  isSecondary: true,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                flex: 2,
                child: _ActionBtn(
                  label: isBulkUpdating
                      ? 'Promoting...'
                      : 'Promote ($selectedCount)',
                  icon: Icons.trending_up_rounded,
                  onTap: (isBulkUpdating || selectedCount == 0) ? null : onPromote,
                  isLoading: isBulkUpdating,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isSecondary = false,
    this.isLoading = false,
  });

  final String label;
  final IconData icon;
  final VoidCallback? onTap;
  final bool isSecondary;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final enabled = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 44,
        decoration: BoxDecoration(
          color: isSecondary
              ? (enabled ? AppColors.surface100 : AppColors.surface50)
              : (enabled ? AppColors.navyDeep : AppColors.surface200),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (isLoading)
              const SizedBox(
                width: 14,
                height: 14,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: AppColors.white),
              )
            else
              Icon(
                icon,
                size: 15,
                color: isSecondary
                    ? (enabled ? AppColors.grey700 : AppColors.grey400)
                    : (enabled ? AppColors.white : AppColors.grey400),
              ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: isSecondary
                      ? (enabled ? AppColors.grey700 : AppColors.grey400)
                      : (enabled ? AppColors.white : AppColors.grey400),
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
