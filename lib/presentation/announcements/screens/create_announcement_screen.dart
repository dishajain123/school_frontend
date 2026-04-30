import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/announcement/announcement_model.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/attendance_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class CreateAnnouncementScreen extends ConsumerStatefulWidget {
  const CreateAnnouncementScreen({super.key, this.existing});

  final AnnouncementModel? existing;

  @override
  ConsumerState<CreateAnnouncementScreen> createState() =>
      _CreateAnnouncementScreenState();
}

class _CreateAnnouncementScreenState
    extends ConsumerState<CreateAnnouncementScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _bodyController = TextEditingController();
  AnnouncementType _selectedType = AnnouncementType.general;
  String? _targetRole;
  String? _selectedClassSectionKey;
  bool _isLoading = false;

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();

    if (isEditing) {
      _titleController.text = widget.existing!.title;
      _bodyController.text = widget.existing!.body;
      _selectedType = widget.existing!.type;
      _targetRole = widget.existing!.targetRole;
      final standardId = widget.existing!.targetStandardId;
      final section = widget.existing!.targetSection;
      if (standardId != null && standardId.isNotEmpty) {
        _selectedClassSectionKey = '$standardId::${section ?? ''}';
      }
    }
  }

  List<(String, TeacherClassSubjectModel)> _teacherClassSectionOptions(
    List<TeacherClassSubjectModel> assignments,
  ) {
    final unique = <String, TeacherClassSubjectModel>{};
    for (final assignment in assignments) {
      final key = '${assignment.standardId}::${assignment.section.trim()}';
      unique.putIfAbsent(key, () => assignment);
    }
    return unique.entries.map((entry) => (entry.key, entry.value)).toList();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _bodyController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);

    try {
      final currentUser = ref.read(currentUserProvider);
      final isTeacher = currentUser?.role == UserRole.teacher;
      String? targetStandardId;
      String? targetSection;
      if (_selectedClassSectionKey != null &&
          _selectedClassSectionKey!.contains('::')) {
        final parts = _selectedClassSectionKey!.split('::');
        targetStandardId = parts.first;
        final resolvedSection = parts.length > 1 ? parts[1].trim() : '';
        targetSection = resolvedSection.isEmpty ? null : resolvedSection;
      }
      if (isTeacher && (targetStandardId == null || targetStandardId.isEmpty)) {
        SnackbarUtils.showError(
          context,
          'Please select assigned class and section.',
        );
        return;
      }
      final payload = {
        'title': _titleController.text.trim(),
        'body': _bodyController.text.trim(),
        'type': _selectedType.backendValue,
        if (_targetRole != null && _targetRole!.trim().isNotEmpty)
          'target_role': _targetRole,
        if (targetStandardId != null && targetStandardId.isNotEmpty)
          'target_standard_id': targetStandardId,
        if (targetSection != null && targetSection.isNotEmpty)
          'target_section': targetSection,
      };

      if (isEditing) {
        await ref
            .read(announcementNotifierProvider.notifier)
            .updateAnnouncement(widget.existing!.id, payload);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Announcement updated.');
          context.pop();
        }
      } else {
        await ref.read(announcementNotifierProvider.notifier).create(payload);
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Announcement posted.');
          context.pop();
        }
      }
    } catch (e) {
      if (mounted) {
        SnackbarUtils.showError(context, 'Failed: ${e.toString()}');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider);
    final activeYearId = ref.watch(activeYearProvider)?.id;
    final isTeacher = currentUser?.role == UserRole.teacher;
    final assignmentsAsync = isTeacher
        ? ref.watch(myTeacherAssignmentsProvider(activeYearId))
        : const AsyncValue<List<TeacherClassSubjectModel>>.data(
            <TeacherClassSubjectModel>[],
          );
    final classSectionOptions =
        _teacherClassSectionOptions(assignmentsAsync.valueOrNull ?? const []);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: isEditing ? 'Edit Announcement' : 'New Announcement',
        showBack: true,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _FormCard(
                          title: 'Announcement Details',
                          icon: Icons.campaign_outlined,
                          children: [
                            AppTextField(
                              controller: _titleController,
                              label: 'Title',
                              hint: 'Announcement title',
                              textInputAction: TextInputAction.next,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Title is required';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _bodyController,
                              label: 'Content',
                              hint: 'Write the announcement content...',
                              maxLines: 6,
                              validator: (v) {
                                if (v == null || v.trim().isEmpty) {
                                  return 'Body is required';
                                }
                                return null;
                              },
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _FormCard(
                          title: 'Type',
                          icon: Icons.label_outline_rounded,
                          children: [
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: AnnouncementType.values.map((type) {
                                final isSelected = _selectedType == type;
                                final color = type.color;
                                return GestureDetector(
                                  onTap: () =>
                                      setState(() => _selectedType = type),
                                  child: AnimatedContainer(
                                    duration: const Duration(milliseconds: 180),
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 14, vertical: 9),
                                    decoration: BoxDecoration(
                                      color: isSelected
                                          ? color.withValues(alpha: 0.12)
                                          : AppColors.surface50,
                                      borderRadius: BorderRadius.circular(12),
                                      border: Border.all(
                                        color: isSelected
                                            ? color.withValues(alpha: 0.5)
                                            : AppColors.surface200,
                                        width: isSelected ? 1.5 : 1,
                                      ),
                                      boxShadow: isSelected
                                          ? [
                                              BoxShadow(
                                                color: color.withValues(
                                                    alpha: 0.15),
                                                blurRadius: 6,
                                                offset: const Offset(0, 2),
                                              )
                                            ]
                                          : null,
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(type.icon,
                                            size: 15,
                                            color: isSelected
                                                ? color
                                                : AppColors.grey400),
                                        const SizedBox(width: 6),
                                        Text(
                                          type.label,
                                          style: AppTypography.labelMedium
                                              .copyWith(
                                            color: isSelected
                                                ? color
                                                : AppColors.grey400,
                                            fontWeight: isSelected
                                                ? FontWeight.w700
                                                : FontWeight.w500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        _FormCard(
                          title: 'Audience',
                          icon: Icons.groups_outlined,
                          children: [
                            DropdownButtonFormField<String?>(
                              value: _targetRole,
                              decoration: const InputDecoration(
                                labelText: 'Send To',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text('All'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'STUDENT',
                                  child: Text('Students'),
                                ),
                                DropdownMenuItem<String?>(
                                  value: 'PARENT',
                                  child: Text('Parents'),
                                ),
                              ],
                              onChanged: (value) =>
                                  setState(() => _targetRole = value),
                            ),
                            if (isTeacher) ...[
                              const SizedBox(height: 16),
                              DropdownButtonFormField<String>(
                                value: classSectionOptions.any(
                                  (entry) =>
                                      entry.$1 == _selectedClassSectionKey,
                                )
                                    ? _selectedClassSectionKey
                                    : null,
                                decoration: const InputDecoration(
                                  labelText: 'Assigned Class & Section',
                                  border: OutlineInputBorder(),
                                ),
                                items: classSectionOptions
                                    .map(
                                      (entry) => DropdownMenuItem<String>(
                                        value: entry.$1,
                                        child: Text(entry.$2.classLabel),
                                      ),
                                    )
                                    .toList(),
                                onChanged: (value) => setState(
                                  () => _selectedClassSectionKey = value,
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 16),
                        _SelectedTypePreview(type: _selectedType),
                        const SizedBox(height: 8),
                      ],
                    ),
                  ),
                ),
                _SubmitBar(
                  isLoading: _isLoading,
                  isEditing: isEditing,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FormCard extends StatelessWidget {
  const _FormCard({
    required this.title,
    required this.icon,
    required this.children,
  });

  final String title;
  final IconData icon;
  final List<Widget> children;

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
        crossAxisAlignment: CrossAxisAlignment.start,
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
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: children,
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectedTypePreview extends StatelessWidget {
  const _SelectedTypePreview({required this.type});
  final AnnouncementType type;

  @override
  Widget build(BuildContext context) {
    final color = type.color;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline_rounded, size: 14, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'This announcement will be tagged as "${type.label}"',
              style: AppTypography.bodySmall.copyWith(
                color: color,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.isLoading,
    required this.isEditing,
    required this.onSubmit,
  });

  final bool isLoading;
  final bool isEditing;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: AppButton.primary(
        label: isEditing ? 'Update Announcement' : 'Post Announcement',
        onTap: isLoading ? null : onSubmit,
        isLoading: isLoading,
        icon: isEditing ? Icons.save_outlined : Icons.send_rounded,
      ),
    );
  }
}
