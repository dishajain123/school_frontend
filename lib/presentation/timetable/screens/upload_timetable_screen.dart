import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/result/result_model.dart';
import '../../../data/models/teacher/teacher_class_subject_model.dart';
import '../../../data/models/timetable/timetable_model.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/result_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../../providers/teacher_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';
import '../widgets/timetable_compact_preview.dart';

class UploadTimetableScreen extends ConsumerStatefulWidget {
  const UploadTimetableScreen({
    super.key,
    this.initialStandardId,
    this.initialSection,
    this.initialExamId,
    this.examMode = false,
  });

  final String? initialStandardId;
  final String? initialSection;
  /// Class examination schedule PDF — distinct from daily class timetable.
  final String? initialExamId;
  final bool examMode;

  @override
  ConsumerState<UploadTimetableScreen> createState() =>
      _UploadTimetableScreenState();
}

class _UploadTimetableScreenState extends ConsumerState<UploadTimetableScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedStandardId;
  String? _selectedExamId;
  String? _selectedExamName;
  String? _selectedSection;
  PlatformFile? _pickedFile;
  Uint8List? _pickedBytes;

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _selectedStandardId = widget.initialStandardId;
    final initialSection = widget.initialSection?.trim();
    if (initialSection != null && initialSection.isNotEmpty) {
      _selectedSection = initialSection.toUpperCase();
    }
    final initialExam = widget.initialExamId?.trim();
    if (initialExam != null && initialExam.isNotEmpty) {
      _selectedExamId = initialExam;
    }

    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );
    _fade = CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.04), end: Offset.zero)
        .animate(CurvedAnimation(parent: _animCtrl, curve: Curves.easeOut));
    _animCtrl.forward();
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'doc', 'docx', 'jpg', 'jpeg', 'png'],
        withData: true,
      );
      if (result == null || result.files.isEmpty) return;
      final picked = result.files.single;
      setState(() {
        _pickedFile = picked;
        _pickedBytes = picked.bytes;
      });
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, 'Failed to pick file: $e');
    }
  }

  void _clearFile() => setState(() {
        _pickedFile = null;
        _pickedBytes = null;
      });

  Future<void> _submit() async {
    if (_selectedStandardId == null) {
      SnackbarUtils.showError(context, 'Please select a class');
      return;
    }
    if (_pickedFile == null) {
      SnackbarUtils.showError(context, 'Please attach a timetable file');
      return;
    }
    if (widget.examMode &&
        (_selectedExamId == null || _selectedExamId!.trim().isEmpty)) {
      SnackbarUtils.showError(context, 'Please select exam');
      return;
    }

    final activeYear = ref.read(activeYearProvider);
    final section =
        (_selectedSection == null || _selectedSection!.trim().isEmpty)
            ? null
            : _selectedSection!.trim().toUpperCase();
    final existingForSelection = (_selectedStandardId == null)
        ? null
        : await ref
            .read(
              timetableProvider((
                standardId: _selectedStandardId!,
                academicYearId: activeYear?.id,
                section: section,
                examId: widget.examMode ? _selectedExamId : null,
              )).future,
            )
            .then<TimetableModel?>((value) => value)
            .catchError((_) => null);

    if (existingForSelection != null && mounted) {
      final shouldReplace = await showDialog<bool>(
            context: context,
            builder: (dialogContext) => AlertDialog(
              title: const Text('Replace Existing Schedule?'),
              content: const Text(
                'A schedule file already exists for this class/section. '
                'Uploading now will replace it.',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(dialogContext).pop(false),
                  child: const Text('Cancel'),
                ),
                FilledButton(
                  onPressed: () => Navigator.of(dialogContext).pop(true),
                  child: const Text('Replace'),
                ),
              ],
            ),
          ) ??
          false;
      if (!shouldReplace) return;
    }

    String? overrideFileName;
    if (widget.examMode && _selectedExamName != null) {
      final cleanType = _selectedExamName!
          .toLowerCase()
          .replaceAll(RegExp(r'[^a-z0-9]+'), '_')
          .replaceAll(RegExp(r'_+'), '_')
          .replaceAll(RegExp(r'^_|_$'), '');
      overrideFileName = '${cleanType}_${_pickedFile!.name}';
    }

    final success = await ref.read(timetableUploadProvider.notifier).upload(
          standardId: _selectedStandardId!,
          file: _pickedFile!,
          academicYearId: activeYear?.id,
          section: section,
          examId: widget.examMode ? _selectedExamId : null,
          overrideFileName: overrideFileName,
        );

    if (!mounted) return;

    if (success) {
      ref.invalidate(sectionsByStandardProvider((
        standardId: _selectedStandardId!,
        academicYearId: activeYear?.id,
      )));
      ref.invalidate(timetableSectionsProvider((
        standardId: _selectedStandardId!,
        academicYearId: activeYear?.id,
      )));
      SnackbarUtils.showSuccess(context, 'Timetable uploaded successfully!');
      final qp = <String, String>{'standard_id': _selectedStandardId!};
      if (section != null && section.isNotEmpty) qp['section'] = section;
      final uri = Uri(path: RouteNames.timetable, queryParameters: qp);
      context.go(uri.toString());
    } else {
      final error = ref.read(timetableUploadProvider).error;
      SnackbarUtils.showError(
          context, error ?? 'Upload failed. Please try again.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final uploadState = ref.watch(timetableUploadProvider);
    final currentUser = ref.watch(currentUserProvider);
    final activeYear = ref.watch(activeYearProvider);
    final standardsAsync = ref.watch(standardsProvider(activeYear?.id));
    final teacherAssignmentsAsync = (currentUser?.role == UserRole.teacher)
        ? ref.watch(teacherAssignmentsByTeacherProvider(currentUser!.id))
        : const AsyncData<List<TeacherClassSubjectModel>>(
            <TeacherClassSubjectModel>[],
          );
    final studentSectionsAsync = _selectedStandardId == null
        ? const AsyncData<List<String>>(<String>[])
        : ref.watch(sectionsByStandardProvider((
            standardId: _selectedStandardId,
            academicYearId: activeYear?.id,
          )));
    final timetableSectionsAsync = _selectedStandardId == null
        ? const AsyncData<List<String>>(<String>[])
        : ref.watch(timetableSectionsProvider((
            standardId: _selectedStandardId!,
            academicYearId: activeYear?.id,
          )));
    final examsAsync = _selectedStandardId == null
        ? const AsyncData<List<ExamModel>>(<ExamModel>[])
        : ref.watch(
            examListProvider((
              studentId: null,
              academicYearId: activeYear?.id,
              standardId: _selectedStandardId,
            )),
          );

    final mergedSections = <String>{
      ...studentSectionsAsync.valueOrNull?.map((s) => s.trim().toUpperCase()) ??
          const <String>{},
      ...timetableSectionsAsync.valueOrNull
              ?.map((s) => s.trim().toUpperCase()) ??
          const <String>{},
    }.where((s) => s.isNotEmpty).toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    final safeSelectedSection =
        mergedSections.contains(_selectedSection) ? _selectedSection : null;
    final AsyncValue<TimetableModel?> existingTimetableAsync =
        _selectedStandardId == null
            ? const AsyncData<TimetableModel?>(null)
            : ref
                .watch(timetableProvider((
                  standardId: _selectedStandardId!,
                  academicYearId: activeYear?.id,
                  section: safeSelectedSection,
                  examId: widget.examMode ? _selectedExamId : null,
                )))
                .whenData((value) => value);

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Upload Timetable',
        showBack: true,
      ),
      body: FadeTransition(
        opacity: _fade,
        child: SlideTransition(
          position: _slide,
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    _FormCard(
                      title: widget.examMode
                          ? 'Exam Timetable Details'
                          : 'Class Selection',
                      icon: Icons.school_outlined,
                      children: [
                        _FieldLabel('Class'),
                        const SizedBox(height: 8),
                        standardsAsync.when(
                          loading: () => AppLoading.card(height: 46),
                          error: (_, __) =>
                              _InlineError('Could not load classes'),
                          data: (standards) {
                            if (currentUser?.role == UserRole.teacher) {
                              return teacherAssignmentsAsync.when(
                                loading: () => AppLoading.card(height: 46),
                                error: (_, __) =>
                                    _InlineError('Could not load classes'),
                                data: (assignments) {
                                  final allowedStandardIds = assignments
                                      .map((a) => a.standardId)
                                      .toSet();
                                  final allowedStandards = standards
                                      .where((s) =>
                                          allowedStandardIds.contains(s.id))
                                      .toList();
                                  final safeValue = allowedStandardIds
                                          .contains(_selectedStandardId)
                                      ? _selectedStandardId
                                      : null;
                                  return _StyledDropdown<String>(
                                    hint: 'Select class',
                                    value: safeValue,
                                    items: allowedStandards
                                        .map((s) => DropdownMenuItem(
                                              value: s.id,
                                              child: Text(
                                                s.name,
                                                style: AppTypography.bodyMedium
                                                    .copyWith(
                                                        color:
                                                            AppColors.grey800),
                                              ),
                                            ))
                                        .toList(),
                                    onChanged: (id) => setState(() {
                                      _selectedStandardId = id;
                                      _selectedExamId = null;
                                      _selectedExamName = null;
                                      _selectedSection = null;
                                    }),
                                  );
                                },
                              );
                            }
                            return _StyledDropdown<String>(
                              hint: 'Select class',
                              value: _selectedStandardId,
                              items: standards
                                  .map((s) => DropdownMenuItem(
                                        value: s.id,
                                        child: Text(s.name,
                                            style: AppTypography.bodyMedium
                                                .copyWith(
                                                    color: AppColors.grey800)),
                                      ))
                                  .toList(),
                              onChanged: (id) => setState(() {
                                _selectedStandardId = id;
                                _selectedExamId = null;
                                _selectedExamName = null;
                                _selectedSection = null;
                              }),
                            );
                          },
                        ),
                        const SizedBox(height: 16),
                        if (widget.examMode) ...[
                          _FieldLabel('Exam'),
                          const SizedBox(height: 8),
                          examsAsync.when(
                            loading: () => AppLoading.card(height: 46),
                            error: (_, __) =>
                                _InlineError('Could not load exams'),
                            data: (exams) => _StyledDropdown<String>(
                              hint: 'Select exam',
                              value: _selectedExamId,
                              items: exams
                                  .map(
                                    (exam) => DropdownMenuItem(
                                      value: exam.id,
                                      child: Text(
                                        exam.name,
                                        style:
                                            AppTypography.bodyMedium.copyWith(
                                          color: AppColors.grey800,
                                        ),
                                      ),
                                    ),
                                  )
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _selectedExamId = value;
                                  final selected = exams.where(
                                    (e) => e.id == value,
                                  );
                                  _selectedExamName = selected.isEmpty
                                      ? null
                                      : selected.first.name;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 16),
                        ],
                        _FieldLabel('Section (optional)'),
                        const SizedBox(height: 8),
                        _StyledDropdown<String?>(
                          hint: _selectedStandardId == null
                              ? 'Select class first'
                              : 'All sections',
                          value: safeSelectedSection,
                          items: [
                            DropdownMenuItem<String?>(
                              value: null,
                              child: Text(
                                'All sections',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.grey800,
                                ),
                              ),
                            ),
                            ...mergedSections.map(
                              (section) => DropdownMenuItem<String?>(
                                value: section,
                                child: Text(
                                  section,
                                  style: AppTypography.bodyMedium.copyWith(
                                    color: AppColors.grey800,
                                  ),
                                ),
                              ),
                            ),
                          ],
                          onChanged: _selectedStandardId == null
                              ? (_) {}
                              : (value) =>
                                  setState(() => _selectedSection = value),
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('Academic Year'),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 13),
                          decoration: BoxDecoration(
                            color: AppColors.surface50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: AppColors.surface100),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.date_range_outlined,
                                  size: 16, color: AppColors.grey400),
                              const SizedBox(width: 10),
                              Text(
                                activeYear?.name ?? '—',
                                style: AppTypography.bodyMedium.copyWith(
                                  color: AppColors.grey600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _FormCard(
                      title: 'File Attachment',
                      icon: Icons.attach_file_rounded,
                      children: [
                        existingTimetableAsync.when(
                          loading: () => const SizedBox.shrink(),
                          error: (_, __) => const SizedBox.shrink(),
                          data: (existing) {
                            if (existing == null) {
                              return const SizedBox.shrink();
                            }
                            return TimetableCompactPreview(timetable: existing);
                          },
                        ),
                        _pickedFile == null
                            ? _FileTapTarget(onTap: _pickFile)
                            : _FileAttached(
                                fileName: _pickedFile!.name,
                                fileSizeBytes: _pickedFile!.size,
                                bytesForPreview: _pickedBytes,
                                onRemove: _clearFile,
                              ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 13, color: AppColors.grey400),
                            const SizedBox(width: 5),
                            Text(
                              'PDF, DOC, DOCX, JPG or PNG · Max 10 MB',
                              style: AppTypography.caption.copyWith(
                                color: AppColors.grey400,
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                  ],
                ),
              ),
              _SubmitBar(
                isUploading: uploadState.isUploading,
                onSubmit: _submit,
              ),
            ],
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

class _StyledDropdown<T> extends StatelessWidget {
  const _StyledDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: value != null
              ? AppColors.navyMedium.withValues(alpha: 0.5)
              : AppColors.surface200,
          width: value != null ? 1.5 : 1,
        ),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style:
                  AppTypography.bodyMedium.copyWith(color: AppColors.grey400)),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
          icon: const Icon(Icons.keyboard_arrow_down_rounded,
              color: AppColors.grey400),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}

class _FileTapTarget extends StatelessWidget {
  const _FileTapTarget({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 90,
        decoration: BoxDecoration(
          color: AppColors.navyDeep.withValues(alpha: 0.04),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.navyDeep.withValues(alpha: 0.18),
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.navyDeep.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.attach_file_rounded,
                  size: 18, color: AppColors.navyMedium),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap to attach file',
              style: AppTypography.labelMedium.copyWith(
                color: AppColors.navyMedium,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FileAttached extends StatelessWidget {
  const _FileAttached({
    required this.fileName,
    required this.fileSizeBytes,
    required this.bytesForPreview,
    required this.onRemove,
  });

  final String fileName;
  final int fileSizeBytes;
  final Uint8List? bytesForPreview;
  final VoidCallback onRemove;

  bool get _isImagePreviewable {
    final lower = fileName.toLowerCase();
    return lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.png');
  }

  String _formatBytes(int bytes) {
    if (bytes < 1024) return '$bytes B';
    final kb = bytes / 1024;
    if (kb < 1024) return '${kb.toStringAsFixed(1)} KB';
    final mb = kb / 1024;
    return '${mb.toStringAsFixed(2)} MB';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.infoBlue.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.infoBlue.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.infoBlue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.insert_drive_file_outlined,
                    size: 18, color: AppColors.infoBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatBytes(fileSizeBytes),
                      style: AppTypography.caption.copyWith(
                        color: AppColors.grey500,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
              GestureDetector(
                onTap: onRemove,
                child: Container(
                  width: 30,
                  height: 30,
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
          if (_isImagePreviewable && bytesForPreview != null) ...[
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(10),
              child: Image.memory(
                bytesForPreview!,
                height: 140,
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _InlineError extends StatelessWidget {
  const _InlineError(this.message);
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.errorRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 15, color: AppColors.errorRed),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.errorRed,
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.isUploading, required this.onSubmit});
  final bool isUploading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: AppButton.primary(
        label: 'Upload Timetable',
        onTap: isUploading ? null : onSubmit,
        isLoading: isUploading,
        icon: Icons.upload_file_outlined,
      ),
    );
  }
}
