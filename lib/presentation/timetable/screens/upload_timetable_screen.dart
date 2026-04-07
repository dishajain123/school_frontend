import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/router/route_names.dart';
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

class _UploadTimetableScreenState extends ConsumerState<UploadTimetableScreen> {
  String? _selectedStandardId;
  final _sectionController = TextEditingController();
  PlatformFile? _pickedFile;
  Uint8List? _pickedBytes;

  @override
  void initState() {
    super.initState();
    _selectedStandardId = widget.initialStandardId;
    final initialSection = widget.initialSection?.trim();
    if (initialSection != null && initialSection.isNotEmpty) {
      _sectionController.text = initialSection;
    }
  }

  @override
  void dispose() {
    _sectionController.dispose();
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
      if (section != null && section.isNotEmpty) {
        qp['section'] = section;
      }
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
      appBar: AppAppBar(
        title: 'Upload Timetable',
        showBack: true,
        actions: [
          TextButton(
            onPressed: uploadState.isUploading ? null : () => context.pop(),
            child: Text(
              'Cancel',
              style: AppTypography.titleSmall.copyWith(color: AppColors.white),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Scrollable form ────────────────────────────────────────
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppDimensions.space20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Class ─────────────────────────────────────────
                  _FieldLabel('Class'),
                  const SizedBox(height: AppDimensions.space8),
                  standardsAsync.when(
                    loading: () => AppLoading.card(),
                    error: (_, __) => _InlineError('Could not load classes'),
                    data: (standards) => _DropdownField<String>(
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

                  const SizedBox(height: AppDimensions.space20),

                  // ── Section (optional) ─────────────────────────────
                  _FieldLabel('Section (optional)'),
                  const SizedBox(height: AppDimensions.space8),
                  _TextInputField(
                    controller: _sectionController,
                    hint: 'e.g. A, B, C  —  leave blank for all sections',
                    maxLength: 10,
                    textCapitalization: TextCapitalization.characters,
                  ),

                  const SizedBox(height: AppDimensions.space20),

                  // ── Academic Year (read-only) ──────────────────────
                  _FieldLabel('Academic Year'),
                  const SizedBox(height: AppDimensions.space8),
                  _ReadOnlyField(
                    value: activeYear?.name ?? '—',
                    icon: Icons.date_range_outlined,
                  ),

                  const SizedBox(height: AppDimensions.space20),

                  // ── File picker ────────────────────────────────────
                  _FieldLabel('Timetable File'),
                  const SizedBox(height: AppDimensions.space8),
                  _pickedFile == null
                      ? _FileTapTarget(onTap: _pickFile)
                      : _FileAttached(
                          fileName: _pickedFile!.name,
                          fileSizeBytes: _pickedFile!.size,
                          bytesForPreview: _pickedBytes,
                          onRemove: _clearFile,
                        ),
                  const SizedBox(height: AppDimensions.space4),
                  Text(
                    'PDF, JPG or PNG · Max 10 MB',
                    style: AppTypography.caption
                        .copyWith(color: AppColors.grey400),
                  ),
                ],
              ),
            ),
          ),

          // ── Sticky submit ──────────────────────────────────────────
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space20,
              AppDimensions.space12,
              AppDimensions.space20,
              AppDimensions.space24,
            ),
            child: AppButton.primary(
              label: 'Upload Timetable',
              onTap: uploadState.isUploading ? null : _submit,
              isLoading: uploadState.isUploading,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Private sub-widgets ───────────────────────────────────────────────────────

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Text(
        text,
        style: AppTypography.labelLarge.copyWith(color: AppColors.grey600),
      );
}

class _DropdownField<T> extends StatelessWidget {
  const _DropdownField({
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
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<T>(
          value: value,
          isExpanded: true,
          hint: Text(hint,
              style:
                  AppTypography.bodyMedium.copyWith(color: AppColors.grey400)),
          style: AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
          icon: const Icon(Icons.keyboard_arrow_down, color: AppColors.grey400),
          onChanged: onChanged,
          items: items,
        ),
      ),
    );
  }
}

class _TextInputField extends StatelessWidget {
  const _TextInputField({
    required this.controller,
    required this.hint,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
  });

  final TextEditingController controller;
  final String hint;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surface50,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: TextField(
        controller: controller,
        textCapitalization: textCapitalization,
        maxLength: maxLength,
        decoration: InputDecoration(
          border: InputBorder.none,
          hintText: hint,
          hintStyle:
              AppTypography.bodyMedium.copyWith(color: AppColors.grey400),
          counterText: '',
        ),
        style: AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
      ),
    );
  }
}

class _ReadOnlyField extends StatelessWidget {
  const _ReadOnlyField({required this.value, required this.icon});
  final String value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.surface100,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.grey400),
          const SizedBox(width: AppDimensions.space12),
          Text(value,
              style:
                  AppTypography.bodyMedium.copyWith(color: AppColors.grey600)),
        ],
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
        height: 80,
        decoration: BoxDecoration(
          color: AppColors.surface50,
          borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
          border: Border.all(color: AppColors.navyDeep.withOpacity(0.20)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.attach_file_rounded,
                size: 20, color: AppColors.navyMedium),
            const SizedBox(width: AppDimensions.space8),
            Text(
              'Tap to attach file',
              style: AppTypography.titleSmall
                  .copyWith(color: AppColors.navyMedium),
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
      constraints: const BoxConstraints(minHeight: 56),
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.infoLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.infoBlue.withOpacity(0.30)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.insert_drive_file_outlined,
                  size: 18, color: AppColors.infoBlue),
              const SizedBox(width: AppDimensions.space12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      fileName,
                      style: AppTypography.bodyMedium
                          .copyWith(color: AppColors.infoBlue),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatBytes(fileSizeBytes),
                      style: AppTypography.caption
                          .copyWith(color: AppColors.grey600),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded,
                    size: 18, color: AppColors.grey400),
                onPressed: onRemove,
                tooltip: 'Remove file',
              ),
            ],
          ),
          if (_isImagePreviewable && bytesForPreview != null) ...[
            const SizedBox(height: AppDimensions.space8),
            ClipRRect(
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
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
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.space16),
      decoration: BoxDecoration(
        color: AppColors.errorLight,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.errorRed.withOpacity(0.30)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, size: 16, color: AppColors.errorRed),
          const SizedBox(width: AppDimensions.space8),
          Text(message,
              style:
                  AppTypography.bodySmall.copyWith(color: AppColors.errorRed)),
        ],
      ),
    );
  }
}
