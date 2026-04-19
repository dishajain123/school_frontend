import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/timetable_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart';

class UploadTimetableScreen extends ConsumerStatefulWidget {
  const UploadTimetableScreen({
    super.key,
    this.initialStandardId,
    this.initialSection,
  });

  final String? initialStandardId;
  final String? initialSection;

  @override
  ConsumerState<UploadTimetableScreen> createState() =>
      _UploadTimetableScreenState();
}

class _UploadTimetableScreenState extends ConsumerState<UploadTimetableScreen>
    with SingleTickerProviderStateMixin {
  String? _selectedStandardId;
  final _sectionController = TextEditingController();
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
      _sectionController.text = initialSection;
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
    _sectionController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
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

    final activeYear = ref.read(activeYearProvider);
    final section = _sectionController.text.trim().isEmpty
        ? null
        : _sectionController.text.trim().toUpperCase();

    final success = await ref.read(timetableUploadProvider.notifier).upload(
          standardId: _selectedStandardId!,
          file: _pickedFile!,
          academicYearId: activeYear?.id,
          section: section,
        );

    if (!mounted) return;

    if (success) {
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
    final activeYear = ref.watch(activeYearProvider);
    final standardsAsync = ref.watch(standardsProvider(activeYear?.id));

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
                      title: 'Class Selection',
                      icon: Icons.school_outlined,
                      children: [
                        _FieldLabel('Class'),
                        const SizedBox(height: 8),
                        standardsAsync.when(
                          loading: () => AppLoading.card(height: 46),
                          error: (_, __) => _InlineError('Could not load classes'),
                          data: (standards) => _StyledDropdown<String>(
                            hint: 'Select class',
                            value: _selectedStandardId,
                            items: standards
                                .map((s) => DropdownMenuItem(
                                      value: s.id,
                                      child: Text(s.name,
                                          style: AppTypography.bodyMedium
                                              .copyWith(color: AppColors.grey800)),
                                    ))
                                .toList(),
                            onChanged: (id) =>
                                setState(() => _selectedStandardId = id),
                          ),
                        ),
                        const SizedBox(height: 16),
                        _FieldLabel('Section (optional)'),
                        const SizedBox(height: 8),
                        _SectionInput(
                          controller: _sectionController,
                          hint: 'e.g. A, B, C — leave blank for all sections',
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
                              'PDF, JPG or PNG · Max 10 MB',
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
              style: AppTypography.bodyMedium.copyWith(color: AppColors.grey400)),
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

class _SectionInput extends StatelessWidget {
  const _SectionInput({required this.controller, required this.hint});
  final TextEditingController controller;
  final String hint;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.surface200),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: TextCapitalization.characters,
        maxLength: 10,
        style: AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle:
              AppTypography.bodyMedium.copyWith(color: AppColors.grey400, fontSize: 13),
          counterText: '',
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