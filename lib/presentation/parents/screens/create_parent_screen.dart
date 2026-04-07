import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/parent/parent_model.dart';
import '../../../data/models/student/student_model.dart';
import '../../../providers/parent_provider.dart';
import '../../../data/repositories/parent_repository.dart';
import '../../../data/repositories/student_repository.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class CreateParentScreen extends ConsumerStatefulWidget {
  const CreateParentScreen({super.key, this.existing});

  final ParentModel? existing;

  @override
  ConsumerState<CreateParentScreen> createState() => _CreateParentScreenState();
}

class _CreateParentScreenState extends ConsumerState<CreateParentScreen> {
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

  bool get isEditing => widget.existing != null;

  @override
  void initState() {
    super.initState();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: isEditing ? 'Edit Parent' : 'Add Parent',
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
          children: [
            const SizedBox(height: AppDimensions.space16),

            if (!isEditing) ...[
              _SectionLabel(label: 'Account Information'),
              const SizedBox(height: AppDimensions.space12),
              AppTextField(
                controller: _emailController,
                label: 'Email Address',
                hint: 'parent@example.com',
                keyboardType: TextInputType.emailAddress,
                prefixIconData: Icons.email_outlined,
                textInputAction: TextInputAction.next,
                validator: Validators.validateEmail,
              ),
              const SizedBox(height: AppDimensions.space16),
              AppTextField(
                controller: _phoneController,
                label: 'Phone Number',
                hint: '+91 9876543210',
                keyboardType: TextInputType.phone,
                prefixIconData: Icons.phone_outlined,
                textInputAction: TextInputAction.next,
                validator: Validators.validatePhone,
              ),
              const SizedBox(height: AppDimensions.space16),
              AppTextField(
                controller: _passwordController,
                label: 'Initial Password',
                hint: 'Min 8 characters',
                obscureText: true,
                prefixIconData: Icons.lock_outlined,
                textInputAction: TextInputAction.next,
                validator: Validators.validatePassword,
              ),
              const SizedBox(height: AppDimensions.space24),
            ],

            _SectionLabel(label: 'Parent Details'),
            const SizedBox(height: AppDimensions.space12),

            // Relation Selector
            Text(
              'Relation',
              style:
                  AppTypography.labelMedium.copyWith(color: AppColors.grey600),
            ),
            const SizedBox(height: AppDimensions.space8),
            Row(
              children: RelationType.values.map((relation) {
                final isSelected = _selectedRelation == relation;
                return Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(
                      right: relation != RelationType.values.last
                          ? AppDimensions.space8
                          : 0,
                    ),
                    child: GestureDetector(
                      onTap: () => setState(() => _selectedRelation = relation),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 150),
                        padding: const EdgeInsets.symmetric(
                          vertical: AppDimensions.space12,
                        ),
                        decoration: BoxDecoration(
                          color: isSelected
                              ? AppColors.navyDeep
                              : AppColors.surface100,
                          borderRadius:
                              BorderRadius.circular(AppDimensions.radiusSmall),
                          border: Border.all(
                            color: isSelected
                                ? AppColors.navyDeep
                                : AppColors.surface200,
                          ),
                        ),
                        child: Column(
                          children: [
                            Icon(
                              _getRelationIcon(relation),
                              size: AppDimensions.iconSM,
                              color: isSelected
                                  ? AppColors.white
                                  : AppColors.grey600,
                            ),
                            const SizedBox(height: AppDimensions.space4),
                            Text(
                              relation.label,
                              style: AppTypography.labelSmall.copyWith(
                                color: isSelected
                                    ? AppColors.white
                                    : AppColors.grey800,
                                fontWeight: FontWeight.w600,
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

            const SizedBox(height: AppDimensions.space16),

            AppTextField(
              controller: _occupationController,
              label: 'Occupation (optional)',
              hint: 'e.g. Engineer, Teacher',
              prefixIconData: Icons.work_outline_rounded,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
            ),

            const SizedBox(height: AppDimensions.space24),

            _SectionLabel(label: 'Children Assignment'),
            const SizedBox(height: AppDimensions.space12),
            _buildStudentsSection(),

            const SizedBox(height: AppDimensions.space32),

            AppButton.primary(
              label: isEditing ? 'Update Parent' : 'Create Parent',
              onTap: _isLoading ? null : _submit,
              isLoading: _isLoading,
              icon: isEditing ? Icons.check_rounded : Icons.person_add_outlined,
            ),

            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }

  IconData _getRelationIcon(RelationType relation) {
    switch (relation) {
      case RelationType.mother:
        return Icons.female_rounded;
      case RelationType.father:
        return Icons.male_rounded;
      case RelationType.guardian:
        return Icons.supervisor_account_outlined;
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

  Widget _buildStudentsSection() {
    if (_isStudentsLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: AppDimensions.space16),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (_studentsError != null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.space12),
        decoration: BoxDecoration(
          color: AppColors.errorRed.withValues(alpha: 0.06),
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.25)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Could not load students.',
              style: AppTypography.bodyMedium.copyWith(
                color: AppColors.errorRed,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppDimensions.space8),
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
        width: double.infinity,
        padding: const EdgeInsets.all(AppDimensions.space12),
        decoration: BoxDecoration(
          color: AppColors.surface100,
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(color: AppColors.surface200),
        ),
        child: Text(
          'No students available to assign.',
          style: AppTypography.bodyMedium.copyWith(color: AppColors.grey600),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                '${_selectedStudentIds.length} of ${_students.length} selected',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.grey600,
                ),
              ),
            ),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedStudentIds = _students.map((s) => s.id).toSet();
                });
              },
              child: const Text('Select all'),
            ),
            TextButton(
              onPressed: () {
                setState(() => _selectedStudentIds = <String>{});
              },
              child: const Text('Clear'),
            ),
          ],
        ),
        Text(
          'Selected students will be linked to this parent.',
          style: AppTypography.caption.copyWith(color: AppColors.grey600),
        ),
        const SizedBox(height: AppDimensions.space8),
        Container(
          constraints: const BoxConstraints(maxHeight: 300),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            border: Border.all(color: AppColors.surface200),
          ),
          child: ListView.separated(
            shrinkWrap: true,
            itemCount: _students.length,
            separatorBuilder: (_, __) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final student = _students[index];
              final selected = _selectedStudentIds.contains(student.id);
              return CheckboxListTile(
                value: selected,
                onChanged: (value) {
                  setState(() {
                    if (value == true) {
                      _selectedStudentIds.add(student.id);
                    } else {
                      _selectedStudentIds.remove(student.id);
                    }
                  });
                },
                controlAffinity: ListTileControlAffinity.leading,
                title: Text(
                  student.admissionNumber,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                subtitle: Text(
                  _studentSubtitle(student),
                  style: AppTypography.bodySmall.copyWith(
                    color: AppColors.grey600,
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _studentSubtitle(StudentModel student) {
    final parts = <String>[];
    if (student.standardId != null && student.standardId!.isNotEmpty) {
      parts.add('Class mapped');
    }
    if (student.section != null && student.section!.trim().isNotEmpty) {
      parts.add('Section ${student.section!.trim()}');
    }
    if (student.rollNumber != null && student.rollNumber!.trim().isNotEmpty) {
      parts.add('Roll ${student.rollNumber!.trim()}');
    }
    if (parts.isEmpty) return 'No class/section details';
    return parts.join(' • ');
  }
}

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label.toUpperCase(),
      style: AppTypography.labelSmall.copyWith(
        color: AppColors.grey400,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
    );
  }
}
