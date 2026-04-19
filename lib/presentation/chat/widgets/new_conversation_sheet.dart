import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/errors/app_exception.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/chat/conversation_model.dart';
import '../../../data/models/masters/standard_model.dart';
import '../../../data/models/masters/subject_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../data/repositories/chat_repository.dart';
import '../../../presentation/common/widgets/app_button.dart';
import '../../../presentation/common/widgets/app_text_field.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/chat_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/teacher_provider.dart';

class NewConversationSheet extends ConsumerStatefulWidget {
  const NewConversationSheet({super.key});

  @override
  ConsumerState<NewConversationSheet> createState() =>
      _NewConversationSheetState();
}

class _NewConversationSheetState extends ConsumerState<NewConversationSheet>
    with SingleTickerProviderStateMixin {
  ConversationType _type = ConversationType.oneToOne;
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _groupNameController = TextEditingController();
  _GroupTargetRole _targetRole = _GroupTargetRole.teacher;
  final Set<_TeacherRecipientType> _teacherRecipientTypes = {
    _TeacherRecipientType.student,
    _TeacherRecipientType.parent,
  };
  String? _filterStandardId;
  String? _filterSection;
  String? _filterSubjectId;
  List<_UserResult> _searchResults = [];
  final List<_UserResult> _selectedUsers = [];
  bool _isSearching = false;
  bool _isAutoAdding = false;
  bool _isCreating = false;
  String? _error;

  late AnimationController _animCtrl;
  late Animation<double> _fade;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 350));
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _groupNameController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  bool get _canCreate {
    if (_isCreating) return false;
    if (_type == ConversationType.oneToOne) return _selectedUsers.length == 1;
    return _groupNameController.text.trim().isNotEmpty &&
        _selectedUsers.isNotEmpty;
  }

  Future<void> _search(String query) async {
    if (query.trim().isEmpty) {
      setState(() => _searchResults = []);
      return;
    }
    setState(() {
      _isSearching = true;
      _error = null;
    });
    try {
      final activeYearId = ref.read(activeYearProvider)?.id;
      final currentUser = ref.read(currentUserProvider);
      final isTeacherGroupMode = _type == ConversationType.group &&
          currentUser?.role == UserRole.teacher;
      final repo = ref.read(chatRepositoryProvider);
      final results = isTeacherGroupMode
          ? await repo.searchUsersAcrossRoles(
              query: query,
              roles: _teacherRecipientTypes
                  .map((e) => e.backendRole)
                  .toList(growable: false),
              standardId: _filterStandardId,
              section: _filterSection,
              subjectId: _filterSubjectId,
              academicYearId: activeYearId,
            )
          : await repo.searchUsersWithFilters(
              query: query,
              role: _type == ConversationType.group
                  ? _targetRole.backendRole
                  : null,
              standardId: _filterStandardId,
              section: _filterSection,
              subjectId: _targetRole == _GroupTargetRole.teacher
                  ? _filterSubjectId
                  : null,
              academicYearId: activeYearId,
            );
      final currentId = ref.read(currentUserProvider)?.id;
      final selectedIds = _selectedUsers.map((u) => u.id).toSet();
      setState(() {
        _searchResults = results
            .where((u) => u.id != currentId && !selectedIds.contains(u.id))
            .map((u) =>
                _UserResult(id: u.id, display: u.displayName, role: u.role))
            .toList();
        _isSearching = false;
      });
    } catch (_) {
      setState(() {
        _isSearching = false;
        _searchResults = [];
      });
    }
  }

  Future<void> _autoAddByFilters() async {
    if (_type != ConversationType.group) return;
    setState(() {
      _isAutoAdding = true;
      _error = null;
    });
    try {
      final activeYearId = ref.read(activeYearProvider)?.id;
      final currentUser = ref.read(currentUserProvider);
      final isTeacherGroupMode = currentUser?.role == UserRole.teacher;
      final repo = ref.read(chatRepositoryProvider);
      final users = isTeacherGroupMode
          ? await repo.searchUsersAcrossRoles(
              roles: _teacherRecipientTypes
                  .map((e) => e.backendRole)
                  .toList(growable: false),
              standardId: _filterStandardId,
              section: _filterSection,
              subjectId: _filterSubjectId,
              academicYearId: activeYearId,
            )
          : await repo.searchUsersWithFilters(
              role: _targetRole.backendRole,
              standardId: _filterStandardId,
              section: _filterSection,
              subjectId: _targetRole == _GroupTargetRole.teacher
                  ? _filterSubjectId
                  : null,
              academicYearId: activeYearId,
            );
      final currentId = ref.read(currentUserProvider)?.id;
      final existing = _selectedUsers.map((e) => e.id).toSet();
      final fetched = users
          .where((u) => u.id != currentId && !existing.contains(u.id))
          .map((u) =>
              _UserResult(id: u.id, display: u.displayName, role: u.role))
          .toList();
      setState(() {
        _selectedUsers.addAll(fetched);
        _isAutoAdding = false;
        if (fetched.isEmpty) {
          _error = 'No users matched these filters.';
        }
      });
    } catch (_) {
      setState(() {
        _isAutoAdding = false;
        _error = 'Could not fetch users for selected filters.';
      });
    }
  }

  Future<void> _create() async {
    if (!_canCreate) return;
    setState(() {
      _isCreating = true;
      _error = null;
    });
    try {
      ConversationModel? conversation;
      final notifier = ref.read(conversationNotifierProvider.notifier);

      if (_type == ConversationType.oneToOne) {
        conversation = await notifier.startOneToOne(_selectedUsers.first.id);
        if (conversation != null && mounted) {
          conversation = conversation.copyWith(
            displayNameOverride: _selectedUsers.first.display,
          );
        }
      } else {
        conversation = await notifier.createGroup(
          name: _groupNameController.text.trim(),
          participantIds: _selectedUsers.map((e) => e.id).toList(),
        );
      }

      if (mounted) Navigator.of(context).pop(conversation);
    } on AppException catch (e) {
      setState(() {
        _isCreating = false;
        _error = e.message;
      });
    } catch (e) {
      setState(() {
        _isCreating = false;
        _error = 'Something went wrong. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider);
    final canGroup = (user?.hasPermission('chat:group_manage') ?? false) ||
        user?.role == UserRole.teacher;
    final isTeacherUser = user?.role == UserRole.teacher;
    final activeYearId = ref.watch(activeYearProvider)?.id;
    final standards = ref.watch(standardsProvider(activeYearId)).valueOrNull ??
        const <StandardModel>[];
    final sections = ref
            .watch(sectionsByStandardProvider((
              standardId: _filterStandardId,
              academicYearId: activeYearId,
            )))
            .valueOrNull ??
        const <String>[];
    final subjects =
        ref.watch(subjectsProvider(_filterStandardId)).valueOrNull ??
            const <SubjectModel>[];
    final teacherAssignments =
        ref.watch(myTeacherAssignmentsProvider(activeYearId)).valueOrNull ??
            const <TeacherClassSubjectModel>[];

    final standardOptions = <String, String>{};
    final sectionOptions = <String>[];
    final subjectOptions = <String, String>{};

    if (isTeacherUser && _type == ConversationType.group) {
      for (final assignment in teacherAssignments) {
        standardOptions.putIfAbsent(
          assignment.standardId,
          () => assignment.standardName ?? assignment.standardId,
        );
      }
      final filteredForSection = teacherAssignments.where((a) {
        if (_filterStandardId != null && a.standardId != _filterStandardId) {
          return false;
        }
        return true;
      });
      final sectionSet = <String>{};
      for (final assignment in filteredForSection) {
        final sec = assignment.section.trim();
        if (sec.isNotEmpty) sectionSet.add(sec);
      }
      sectionOptions.addAll(sectionSet.toList()..sort());

      final filteredForSubject = teacherAssignments.where((a) {
        if (_filterStandardId != null && a.standardId != _filterStandardId) {
          return false;
        }
        if (_filterSection != null && a.section.trim() != _filterSection) {
          return false;
        }
        return true;
      });
      for (final assignment in filteredForSubject) {
        subjectOptions.putIfAbsent(
          assignment.subjectId,
          () => assignment.subjectLabel,
        );
      }
    } else {
      for (final standard in standards) {
        standardOptions[standard.id] = standard.name;
      }
      sectionOptions.addAll(sections);
      for (final subject in subjects) {
        subjectOptions[subject.id] = '${subject.name} (${subject.code})';
      }
    }

    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;
    final safeBottom = MediaQuery.paddingOf(context).bottom;

    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      padding: EdgeInsets.only(bottom: bottomInset),
      child: FractionallySizedBox(
        heightFactor: 0.92,
        child: Container(
          decoration: const BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: FadeTransition(
            opacity: _fade,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, bottom: 4),
                    child: Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                        color: AppColors.surface200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.navyDeep.withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.chat_bubble_outline_rounded,
                            color: AppColors.navyDeep, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Text('New Conversation',
                          style: AppTypography.headlineSmall.copyWith(
                            fontWeight: FontWeight.w700,
                            fontSize: 17,
                          )),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: SingleChildScrollView(
                    padding: EdgeInsets.fromLTRB(20, 0, 20, 20 + safeBottom),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (canGroup) ...[
                          _TypeSelector(
                            selected: _type,
                            onChanged: (t) => setState(() {
                              _type = t;
                              _selectedUsers.clear();
                              _searchResults = [];
                              _searchController.clear();
                            }),
                          ),
                          const SizedBox(height: 16),
                        ],
                        if (_type == ConversationType.group) ...[
                          AppTextField(
                            label: 'Group Name',
                            hint: 'e.g. Class 10-A Teachers',
                            controller: _groupNameController,
                            prefixIconData: Icons.group_outlined,
                            onChanged: (_) => setState(() {}),
                          ),
                          const SizedBox(height: 16),
                          _GroupFiltersCard(
                            isTeacherMode: isTeacherUser,
                            targetRole: _targetRole,
                            teacherRecipientTypes: _teacherRecipientTypes,
                            standards: standardOptions,
                            sections: sectionOptions,
                            subjects: subjectOptions,
                            standardId: _filterStandardId,
                            section: _filterSection,
                            subjectId: _filterSubjectId,
                            onRoleChanged: (role) => setState(() {
                              _targetRole = role;
                              _filterSubjectId = null;
                              _searchResults = [];
                            }),
                            onTeacherRecipientToggle: (type) => setState(() {
                              if (_teacherRecipientTypes.contains(type)) {
                                if (_teacherRecipientTypes.length > 1) {
                                  _teacherRecipientTypes.remove(type);
                                }
                              } else {
                                _teacherRecipientTypes.add(type);
                              }
                              _searchResults = [];
                            }),
                            onStandardChanged: (value) => setState(() {
                              _filterStandardId = value;
                              _filterSection = null;
                              _filterSubjectId = null;
                              _searchResults = [];
                            }),
                            onSectionChanged: (value) => setState(() {
                              _filterSection = value;
                              _searchResults = [];
                            }),
                            onSubjectChanged: (value) => setState(() {
                              _filterSubjectId = value;
                              _searchResults = [];
                            }),
                            onAutoAdd: _isAutoAdding ? null : _autoAddByFilters,
                            isLoading: _isAutoAdding,
                          ),
                          const SizedBox(height: 16),
                        ],
                        AppTextField(
                          label: _type == ConversationType.oneToOne
                              ? 'Find User'
                              : 'Add Participant Manually',
                          hint: 'Search by email or phone…',
                          controller: _searchController,
                          prefixIconData: Icons.search_rounded,
                          onChanged: _search,
                        ),
                        const SizedBox(height: 10),
                        if (_selectedUsers.isNotEmpty) ...[
                          ..._selectedUsers.map(
                            (u) => Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: _SelectedChip(
                                user: u,
                                onRemove: () =>
                                    setState(() => _selectedUsers.removeWhere(
                                          (x) => x.id == u.id,
                                        )),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (_isSearching)
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Center(
                                child: CircularProgressIndicator.adaptive()),
                          )
                        else if (_searchResults.isNotEmpty) ...[
                          Container(
                            decoration: BoxDecoration(
                              color: AppColors.white,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.surface200),
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.navyDeep
                                      .withValues(alpha: 0.06),
                                  blurRadius: 10,
                                  offset: const Offset(0, 2),
                                ),
                              ],
                            ),
                            child: ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: _searchResults.length.clamp(0, 5),
                              itemBuilder: (_, i) => _ResultTile(
                                user: _searchResults[i],
                                isLast:
                                    i == _searchResults.length.clamp(0, 5) - 1,
                                onTap: () => setState(() {
                                  if (_type == ConversationType.oneToOne) {
                                    _selectedUsers
                                      ..clear()
                                      ..add(_searchResults[i]);
                                  } else if (!_selectedUsers.any(
                                      (u) => u.id == _searchResults[i].id)) {
                                    _selectedUsers.add(_searchResults[i]);
                                  }
                                  _searchResults = [];
                                  _searchController.clear();
                                }),
                              ),
                            ),
                          ),
                          const SizedBox(height: 6),
                        ],
                        if (_error != null) ...[
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: AppColors.errorLight,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              _error!,
                              style: AppTypography.labelSmall.copyWith(
                                color: AppColors.errorRed,
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                        ],
                        const SizedBox(height: 16),
                        AppButton.primary(
                          label: 'Start Conversation',
                          onTap: _canCreate ? _create : null,
                          isLoading: _isCreating,
                          icon: Icons.chat_bubble_outline_rounded,
                        ),
                        const SizedBox(height: 20),
                      ],
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

enum _GroupTargetRole { teacher, student, parent }

extension _GroupTargetRoleX on _GroupTargetRole {
  String get label {
    switch (this) {
      case _GroupTargetRole.teacher:
        return 'Teachers';
      case _GroupTargetRole.student:
        return 'Students';
      case _GroupTargetRole.parent:
        return 'Parents';
    }
  }

  String get backendRole {
    switch (this) {
      case _GroupTargetRole.teacher:
        return 'TEACHER';
      case _GroupTargetRole.student:
        return 'STUDENT';
      case _GroupTargetRole.parent:
        return 'PARENT';
    }
  }
}

enum _TeacherRecipientType { student, parent }

extension _TeacherRecipientTypeX on _TeacherRecipientType {
  String get label {
    switch (this) {
      case _TeacherRecipientType.student:
        return 'Students';
      case _TeacherRecipientType.parent:
        return 'Parents';
    }
  }

  String get backendRole {
    switch (this) {
      case _TeacherRecipientType.student:
        return 'STUDENT';
      case _TeacherRecipientType.parent:
        return 'PARENT';
    }
  }
}

class _GroupFiltersCard extends StatelessWidget {
  const _GroupFiltersCard({
    required this.isTeacherMode,
    required this.targetRole,
    required this.teacherRecipientTypes,
    required this.standards,
    required this.sections,
    required this.subjects,
    required this.standardId,
    required this.section,
    required this.subjectId,
    required this.onRoleChanged,
    required this.onTeacherRecipientToggle,
    required this.onStandardChanged,
    required this.onSectionChanged,
    required this.onSubjectChanged,
    required this.onAutoAdd,
    required this.isLoading,
  });

  final bool isTeacherMode;
  final _GroupTargetRole targetRole;
  final Set<_TeacherRecipientType> teacherRecipientTypes;
  final Map<String, String> standards;
  final List<String> sections;
  final Map<String, String> subjects;
  final String? standardId;
  final String? section;
  final String? subjectId;
  final ValueChanged<_GroupTargetRole> onRoleChanged;
  final ValueChanged<_TeacherRecipientType> onTeacherRecipientToggle;
  final ValueChanged<String?> onStandardChanged;
  final ValueChanged<String?> onSectionChanged;
  final ValueChanged<String?> onSubjectChanged;
  final VoidCallback? onAutoAdd;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final selectedStandardValid =
        standardId == null || standards.containsKey(standardId);
    final selectedSectionValid = sections.contains(section);
    final selectedSubjectValid =
        subjectId == null || subjects.containsKey(subjectId);

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Quick Add By Filters',
            style: AppTypography.labelMedium.copyWith(
              color: AppColors.navyDeep,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          if (!isTeacherMode)
            DropdownButtonFormField<_GroupTargetRole>(
              initialValue: targetRole,
              decoration: const InputDecoration(labelText: 'Add Role'),
              items: _GroupTargetRole.values
                  .map(
                    (r) => DropdownMenuItem<_GroupTargetRole>(
                      value: r,
                      child: Text(r.label),
                    ),
                  )
                  .toList(),
              onChanged: (v) {
                if (v != null) onRoleChanged(v);
              },
            ),
          if (isTeacherMode)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Add Recipients',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.navyDeep,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: _TeacherRecipientType.values.map((type) {
                    final selected = teacherRecipientTypes.contains(type);
                    return Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: InkWell(
                          onTap: () => onTeacherRecipientToggle(type),
                          borderRadius: BorderRadius.circular(10),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: selected
                                  ? AppColors.navyDeep.withValues(alpha: 0.12)
                                  : AppColors.white,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppColors.navyDeep
                                    : AppColors.surface200,
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  selected
                                      ? Icons.check_box
                                      : Icons.check_box_outline_blank,
                                  size: 16,
                                  color: selected
                                      ? AppColors.navyDeep
                                      : AppColors.grey500,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  type.label,
                                  style: AppTypography.labelSmall.copyWith(
                                    color: selected
                                        ? AppColors.navyDeep
                                        : AppColors.grey600,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ],
            ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: selectedStandardValid ? standardId : null,
                  decoration: const InputDecoration(labelText: 'Class'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Classes'),
                    ),
                    ...standards.entries.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s.key,
                        child: Text(s.value),
                      ),
                    ),
                  ],
                  onChanged: onStandardChanged,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DropdownButtonFormField<String?>(
                  initialValue: selectedSectionValid ? section : null,
                  decoration: const InputDecoration(labelText: 'Section'),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('All Sections'),
                    ),
                    ...sections.map(
                      (s) => DropdownMenuItem<String?>(
                        value: s,
                        child: Text(s),
                      ),
                    ),
                  ],
                  onChanged: onSectionChanged,
                ),
              ),
            ],
          ),
          if ((isTeacherMode) ||
              (!isTeacherMode && targetRole == _GroupTargetRole.teacher)) ...[
            const SizedBox(height: 8),
            DropdownButtonFormField<String?>(
              initialValue: selectedSubjectValid ? subjectId : null,
              decoration: const InputDecoration(labelText: 'Subject'),
              items: [
                const DropdownMenuItem<String?>(
                  value: null,
                  child: Text('All Subjects'),
                ),
                ...subjects.entries.map(
                  (s) => DropdownMenuItem<String?>(
                    value: s.key,
                    child: Text(s.value),
                  ),
                ),
              ],
              onChanged: onSubjectChanged,
            ),
          ],
          const SizedBox(height: 10),
          AppButton.secondary(
            label: 'Fetch & Add Matching Users',
            onTap: onAutoAdd,
            isLoading: isLoading,
            icon: Icons.filter_alt_outlined,
          ),
        ],
      ),
    );
  }
}

class _TypeSelector extends StatelessWidget {
  const _TypeSelector({required this.selected, required this.onChanged});
  final ConversationType selected;
  final ValueChanged<ConversationType> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.surface100,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(3),
      child: Row(
        children: ConversationType.values.map((type) {
          final isSelected = type == selected;
          return Expanded(
            child: GestureDetector(
              onTap: () => onChanged(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: isSelected
                      ? [
                          BoxShadow(
                            color: AppColors.navyDeep.withValues(alpha: 0.08),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      type.icon,
                      size: 16,
                      color:
                          isSelected ? AppColors.navyDeep : AppColors.grey500,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      type.label,
                      style: AppTypography.labelMedium.copyWith(
                        color:
                            isSelected ? AppColors.navyDeep : AppColors.grey500,
                        fontWeight:
                            isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _SelectedChip extends StatelessWidget {
  const _SelectedChip({required this.user, required this.onRemove});
  final _UserResult user;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.navyDeep.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.navyMedium.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: AppColors.navyDeep.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.person_rounded,
                size: 16, color: AppColors.navyMedium),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(user.display,
                    style: AppTypography.titleSmall.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis),
                Text(user.role,
                    style: AppTypography.caption
                        .copyWith(color: AppColors.grey500)),
              ],
            ),
          ),
          GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.surface100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.close_rounded,
                  size: 14, color: AppColors.grey500),
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultTile extends StatelessWidget {
  const _ResultTile({
    required this.user,
    required this.onTap,
    this.isLast = false,
  });

  final _UserResult user;
  final VoidCallback onTap;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: isLast
          ? const BorderRadius.only(
              bottomLeft: Radius.circular(14),
              bottomRight: Radius.circular(14),
            )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.navyDeep.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.person_outline_rounded,
                  size: 18, color: AppColors.navyMedium),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(user.display,
                      style: AppTypography.titleSmall.copyWith(
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      overflow: TextOverflow.ellipsis),
                  Text(user.role,
                      style: AppTypography.caption.copyWith(
                        color: AppColors.grey500,
                        fontSize: 11,
                      )),
                ],
              ),
            ),
            Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: AppColors.navyDeep.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.add_rounded,
                  size: 16, color: AppColors.navyMedium),
            ),
          ],
        ),
      ),
    );
  }
}

class _UserResult {
  const _UserResult({
    required this.id,
    required this.display,
    required this.role,
  });
  final String id;
  final String display;
  final String role;
}
