import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/parent/parent_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../data/repositories/parent_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class CreateParentScreen extends ConsumerStatefulWidget {
  const CreateParentScreen({super.key, this.existing});

  final ParentModel? existing;

  @override
  ConsumerState<CreateParentScreen> createState() => _CreateParentScreenState();
}

class _CreateParentScreenState extends ConsumerState<CreateParentScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _occupationController = TextEditingController();
  RelationType _selectedRelation = RelationType.guardian;
  bool _isLoading = false;
  bool _isStudentsLoading = false;
  String? _studentsError;
  List<StudentModel> _students = const [];
  Set<String> _selectedStudentIds = <String>{};

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
      final p = widget.existing!;
      _emailController.text = p.email ?? '';
      _phoneController.text = p.phone ?? '';
      _occupationController.text = p.occupation ?? '';
      _selectedRelation = p.relation;
    }
    _loadStudentsAndSelection();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _occupationController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStudentIds.isEmpty) {
      SnackbarUtils.showError(
        context,
        'Please select at least one student for this parent.',
      );
      return;
    }
    setState(() => _isLoading = true);

    try {
      if (isEditing) {
        final payload = <String, dynamic>{
          'relation': _selectedRelation.backendValue,
        };
        if (_occupationController.text.trim().isNotEmpty) {
          payload['occupation'] = _occupationController.text.trim();
        }
        await ref
            .read(parentNotifierProvider.notifier)
            .updateParent(widget.existing!.id, payload);
        await ref.read(parentNotifierProvider.notifier).assignChildren(
              widget.existing!.id,
              _selectedStudentIds.toList(),
            );
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Parent updated successfully.');
          context.pop(true);
        }
      } else {
        final payload = <String, dynamic>{
          'user': {
            'email': _emailController.text.trim().toLowerCase(),
            'phone': _phoneController.text.trim(),
            'password': _passwordController.text,
          },
          'relation': _selectedRelation.backendValue,
        };
        if (_occupationController.text.trim().isNotEmpty) {
          payload['occupation'] = _occupationController.text.trim();
        }
        final created = await ref.read(parentNotifierProvider.notifier).create(
              payload,
            );
        await ref.read(parentNotifierProvider.notifier).assignChildren(
              created.id,
              _selectedStudentIds.toList(),
            );
        if (mounted) {
          SnackbarUtils.showSuccess(context, 'Parent created successfully.');
          context.pop(true);
        }
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStudentsAndSelection() async {
    setState(() {
      _isStudentsLoading = true;
      _studentsError = null;
    });

    try {
      final studentRepo = ref.read(studentRepositoryProvider);
      final parentRepo = ref.read(parentRepositoryProvider);

      final loadedStudents = <StudentModel>[];
      var page = 1;
      var totalPages = 1;

      while (page <= totalPages) {
        final result = await studentRepo.list(page: page, pageSize: 100);
        loadedStudents.addAll(result.items);
        totalPages = result.totalPages;
        if (result.items.isEmpty) break;
        page += 1;
      }

      final existingSelected = <String>{};
      if (isEditing) {
        final children = await parentRepo.getChildren(widget.existing!.id);
        existingSelected.addAll(children.map((c) => c.id));
      }

      final validIds = loadedStudents.map((s) => s.id).toSet();
      if (!mounted) return;

      setState(() {
        _students = loadedStudents;
        _selectedStudentIds = existingSelected.where(validIds.contains).toSet();
        _isStudentsLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isStudentsLoading = false;
        _studentsError = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: isEditing ? 'Edit Parent' : 'Add Parent',
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
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      if (!isEditing) ...[
                        _FormCard(
                          title: 'Account Information',
                          icon: Icons.manage_accounts_outlined,
                          children: [
                            AppTextField(
                              controller: _emailController,
                              label: 'Email Address',
                              hint: 'parent@example.com',
                              keyboardType: TextInputType.emailAddress,
                              prefixIconData: Icons.email_outlined,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validateEmail,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _phoneController,
                              label: 'Phone Number',
                              hint: '+91 9876543210',
                              keyboardType: TextInputType.phone,
                              prefixIconData: Icons.phone_outlined,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validatePhone,
                            ),
                            const SizedBox(height: 16),
                            AppTextField(
                              controller: _passwordController,
                              label: 'Initial Password',
                              hint: 'Min 8 characters',
                              obscureText: true,
                              prefixIconData: Icons.lock_outline_rounded,
                              textInputAction: TextInputAction.next,
                              validator: Validators.validatePassword,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                      ],
                      _FormCard(
                        title: 'Parent Details',
                        icon: Icons.person_outline_rounded,
                        children: [
                          const _FieldLabel('Relation'),
                          const SizedBox(height: 10),
                          _RelationSelector(
                            selected: _selectedRelation,
                            onChanged: (r) =>
                                setState(() => _selectedRelation = r),
                          ),
                          const SizedBox(height: 16),
                          AppTextField(
                            controller: _occupationController,
                            label: 'Occupation (optional)',
                            hint: 'e.g. Engineer, Teacher',
                            prefixIconData: Icons.work_outline_rounded,
                            textInputAction: TextInputAction.done,
                            onSubmitted: (_) => _submit(),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormCard(
                        title: 'Children Assignment',
                        icon: Icons.people_outline_rounded,
                        children: [
                          _buildStudentsSection(),
                        ],
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _SubmitBar(
                  isEditing: isEditing,
                  isLoading: _isLoading,
                  onSubmit: _submit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStudentsSection() {
    if (_isStudentsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 20),
        child: Center(
          child: CircularProgressIndicator(
            color: AppColors.navyDeep,
            strokeWidth: 2.5,
          ),
        ),
      );
    }

    if (_studentsError != null) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: AppColors.errorRed.withValues(alpha: 0.25),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.error_outline_rounded,
                  size: 16,
                  color: AppColors.errorRed,
                ),
                const SizedBox(width: 8),
                Text(
                  'Could not load students.',
                  style: AppTypography.bodyMedium.copyWith(
                    color: AppColors.errorRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            AppButton.text(
              label: 'Retry',
              onTap: _loadStudentsAndSelection,
            ),
          ],
        ),
      );
    }

    if (_students.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface50,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.surface200),
        ),
        child: Row(
          children: [
            const Icon(
              Icons.info_outline_rounded,
              size: 16,
              color: AppColors.grey400,
            ),
            const SizedBox(width: 10),
            Text(
              'No students available to assign.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.grey500,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '${_selectedStudentIds.length}',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                    TextSpan(
                      text: ' of ${_students.length} selected',
                      style: AppTypography.caption.copyWith(
                        color: AppColors.grey500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            _QuickTextBtn(
              label: 'All',
              onTap: () => setState(() {
                _selectedStudentIds = _students.map((s) => s.id).toSet();
              }),
            ),
            const SizedBox(width: 4),
            _QuickTextBtn(
              label: 'Clear',
              onTap: () => setState(() => _selectedStudentIds = <String>{}),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Container(
          constraints: const BoxConstraints(maxHeight: 280),
          decoration: BoxDecoration(
            color: AppColors.surface50,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.surface200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _students.length,
            separatorBuilder: (_, __) =>
                Container(height: 1, color: AppColors.surface100),
            itemBuilder: (context, index) {
              final student = _students[index];
              final selected = _selectedStudentIds.contains(student.id);
              return _StudentCheckItem(
                student: student,
                selected: selected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedStudentIds.add(student.id);
                    } else {
                      _selectedStudentIds.remove(student.id);
                    }
                  });
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

class _RelationSelector extends StatelessWidget {
  const _RelationSelector({
    required this.selected,
    required this.onChanged,
  });

  final RelationType selected;
  final ValueChanged<RelationType> onChanged;

  IconData _icon(RelationType r) {
    switch (r) {
      case RelationType.mother:
        return Icons.female_rounded;
      case RelationType.father:
        return Icons.male_rounded;
      case RelationType.guardian:
        return Icons.supervisor_account_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: RelationType.values.map((relation) {
        final isSelected = selected == relation;
        final isLast = relation == RelationType.values.last;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: isLast ? 0 : 8),
            child: GestureDetector(
              onTap: () => onChanged(relation),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.navyDeep
                      : AppColors.surface50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isSelected
                        ? AppColors.navyDeep
                        : AppColors.surface200,
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  children: [
                    Icon(
                      _icon(relation),
                      size: 20,
                      color:
                          isSelected ? AppColors.white : AppColors.grey500,
                    ),
                    const SizedBox(height: 5),
                    Text(
                      relation.label,
                      style: AppTypography.labelSmall.copyWith(
                        color: isSelected
                            ? AppColors.white
                            : AppColors.grey700,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _StudentCheckItem extends StatelessWidget {
  const _StudentCheckItem({
    required this.student,
    required this.selected,
    required this.onChanged,
  });

  final StudentModel student;
  final bool selected;
  final ValueChanged<bool?> onChanged;

  String _subtitle() {
    final parts = <String>[];
    if (student.standardId != null && student.standardId!.isNotEmpty) {
      parts.add('Class mapped');
    }
    if (student.section != null && student.section!.trim().isNotEmpty) {
      parts.add('Sec ${student.section!.trim()}');
    }
    if (student.rollNumber != null && student.rollNumber!.trim().isNotEmpty) {
      parts.add('Roll ${student.rollNumber!.trim()}');
    }
    if (parts.isEmpty) return 'No class details';
    return parts.join(' · ');
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () => onChanged(!selected),
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                color: selected ? AppColors.navyDeep : AppColors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(
                  color: selected
                      ? AppColors.navyDeep
                      : AppColors.surface200,
                  width: 1.5,
                ),
              ),
              child: selected
                  ? const Icon(
                      Icons.check_rounded,
                      size: 13,
                      color: AppColors.white,
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    student.admissionNumber,
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.grey800,
                    ),
                  ),
                  Text(
                    _subtitle(),
                    style: AppTypography.caption.copyWith(
                      color: AppColors.grey400,
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ],
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

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: AppTypography.labelMedium.copyWith(
        color: AppColors.grey600,
        fontWeight: FontWeight.w600,
        fontSize: 12,
      ),
    );
  }
}

class _QuickTextBtn extends StatelessWidget {
  const _QuickTextBtn({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppColors.navyDeep.withValues(alpha: 0.07),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTypography.labelSmall.copyWith(
            color: AppColors.navyDeep,
            fontWeight: FontWeight.w700,
            fontSize: 11,
          ),
        ),
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({
    required this.isEditing,
    required this.isLoading,
    required this.onSubmit,
  });

  final bool isEditing;
  final bool isLoading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 16 + bottom),
      child: AppButton.primary(
        label: isEditing ? 'Update Parent' : 'Create Parent',
        onTap: isLoading ? null : onSubmit,
        isLoading: isLoading,
        icon: isEditing ? Icons.check_rounded : Icons.person_add_outlined,
      ),
    );
  }
}