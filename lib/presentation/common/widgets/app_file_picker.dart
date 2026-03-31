import 'dart:io';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/file_utils.dart';

/// File / image picker widget with preview and validation.
///
/// Shows a tap target when no file is selected, and a file preview with
/// a remove button once a file has been picked.
///
/// Usage:
/// ```dart
/// AppFilePicker(
///   label: 'Attach Assignment',
///   allowedTypes: FilePickerType.any,
///   maxSizeMb: 10,
///   onFilePicked: (file) => setState(() => _attachment = file),
/// )
/// ```
class AppFilePicker extends StatefulWidget {
  const AppFilePicker({
    super.key,
    this.label = 'Tap to attach file',
    this.hint,
    required this.onFilePicked,
    this.onFileRemoved,
    this.allowedTypes = FilePickerType.any,
    this.maxSizeMb = 10,
    this.initialFile,
    this.initialFileName,
    this.icon,
    this.isRequired = false,
    this.errorText,
    this.allowMultiple = false,
  });

  final String label;
  final String? hint;
  final ValueChanged<File?> onFilePicked;
  final VoidCallback? onFileRemoved;
  final FilePickerType allowedTypes;
  final int maxSizeMb;
  final File? initialFile;
  final String? initialFileName;
  final IconData? icon;
  final bool isRequired;
  final String? errorText;
  final bool allowMultiple;

  @override
  State<AppFilePicker> createState() => _AppFilePickerState();
}

enum FilePickerType { image, pdf, document, any }

class _AppFilePickerState extends State<AppFilePicker> {
  File? _pickedFile;
  String? _fileName;
  String? _errorText;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _pickedFile = widget.initialFile;
    _fileName = widget.initialFileName;
    _errorText = widget.errorText;
  }

  @override
  void didUpdateWidget(AppFilePicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.errorText != oldWidget.errorText) {
      setState(() => _errorText = widget.errorText);
    }
  }

  List<String>? get _allowedExtensions {
    switch (widget.allowedTypes) {
      case FilePickerType.image:
        return ['jpg', 'jpeg', 'png', 'webp', 'gif'];
      case FilePickerType.pdf:
        return ['pdf'];
      case FilePickerType.document:
        return ['pdf', 'doc', 'docx'];
      case FilePickerType.any:
        return null;
    }
  }

  FileType get _fileType {
    switch (widget.allowedTypes) {
      case FilePickerType.image:
        return FileType.image;
      case FilePickerType.pdf:
      case FilePickerType.document:
      case FilePickerType.any:
        return FileType.custom;
    }
  }

  Future<void> _pickFile() async {
    setState(() {
      _isLoading = true;
      _errorText = null;
    });

    try {
      final result = await FilePicker.platform.pickFiles(
        type: _fileType,
        allowedExtensions: _fileType == FileType.custom
            ? _allowedExtensions
            : null,
        allowMultiple: widget.allowMultiple,
      );

      if (result == null || result.files.isEmpty) {
        setState(() => _isLoading = false);
        return;
      }

      final pickedFile = result.files.first;
      final path = pickedFile.path;

      if (path == null) {
        setState(() {
          _isLoading = false;
          _errorText = 'Could not access the selected file.';
        });
        return;
      }

      final file = File(path);
      final maxBytes = widget.maxSizeMb * 1024 * 1024;

      if (!FileUtils.isWithinSizeLimit(file, maxBytes)) {
        setState(() {
          _isLoading = false;
          _errorText =
              'File size exceeds ${widget.maxSizeMb}MB limit.';
        });
        return;
      }

      setState(() {
        _pickedFile = file;
        _fileName = pickedFile.name;
        _isLoading = false;
        _errorText = null;
      });

      widget.onFilePicked(file);
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorText = 'Failed to pick file. Please try again.';
      });
    }
  }

  void _removeFile() {
    setState(() {
      _pickedFile = null;
      _fileName = null;
      _errorText = null;
    });
    widget.onFilePicked(null);
    widget.onFileRemoved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        _pickedFile != null || _fileName != null
            ? _FilePreview(
                fileName: _fileName ?? 'Attached file',
                file: _pickedFile,
                onRemove: _removeFile,
              )
            : _PickerTarget(
                label: widget.label,
                hint: widget.hint,
                icon: widget.icon,
                allowedTypes: widget.allowedTypes,
                isLoading: _isLoading,
                hasError: _errorText != null,
                onTap: _pickFile,
              ),
        if (_errorText != null) ...[
          const SizedBox(height: AppDimensions.space4),
          Text(
            _errorText!,
            style: AppTypography.labelSmall.copyWith(
              color: AppColors.errorRed,
            ),
          ),
        ],
      ],
    );
  }
}

class _PickerTarget extends StatelessWidget {
  const _PickerTarget({
    required this.label,
    this.hint,
    this.icon,
    required this.allowedTypes,
    required this.isLoading,
    required this.hasError,
    required this.onTap,
  });

  final String label;
  final String? hint;
  final IconData? icon;
  final FilePickerType allowedTypes;
  final bool isLoading;
  final bool hasError;
  final VoidCallback onTap;

  IconData get _defaultIcon {
    switch (allowedTypes) {
      case FilePickerType.image:
        return Icons.image_outlined;
      case FilePickerType.pdf:
        return Icons.picture_as_pdf_outlined;
      case FilePickerType.document:
        return Icons.description_outlined;
      case FilePickerType.any:
        return Icons.attach_file_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          vertical: AppDimensions.space20,
          horizontal: AppDimensions.space16,
        ),
        decoration: BoxDecoration(
          color: hasError
              ? AppColors.errorLight
              : AppColors.surface50,
          borderRadius:
              BorderRadius.circular(AppDimensions.radiusSmall),
          border: Border.all(
            color: hasError
                ? AppColors.errorRed
                : AppColors.surface200,
            width: AppDimensions.borderMedium,
            style: BorderStyle.solid,
          ),
        ),
        child: Column(
          children: [
            if (isLoading)
              const SizedBox(
                width: 24,
                height: 24,
                child: CircularProgressIndicator.adaptive(
                  strokeWidth: 2,
                ),
              )
            else ...[
              Icon(
                icon ?? _defaultIcon,
                size: AppDimensions.iconMD,
                color: hasError
                    ? AppColors.errorRed
                    : AppColors.grey400,
              ),
              const SizedBox(height: AppDimensions.space8),
              Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: hasError
                      ? AppColors.errorRed
                      : AppColors.navyMedium,
                ),
                textAlign: TextAlign.center,
              ),
              if (hint != null) ...[
                const SizedBox(height: AppDimensions.space4),
                Text(
                  hint!,
                  style: AppTypography.caption,
                  textAlign: TextAlign.center,
                ),
              ],
            ],
          ],
        ),
      ),
    );
  }
}

class _FilePreview extends StatelessWidget {
  const _FilePreview({
    required this.fileName,
    required this.file,
    required this.onRemove,
  });

  final String fileName;
  final File? file;
  final VoidCallback onRemove;

  String get _extension => FileUtils.extension(fileName);

  bool get _isImage => FileUtils.isImage(fileName);

  Color get _iconColor {
    if (_isImage) return AppColors.infoBlue;
    if (_extension == 'pdf') return AppColors.errorRed;
    return AppColors.navyMedium;
  }

  IconData get _icon {
    if (_isImage) return Icons.image_outlined;
    if (_extension == 'pdf') return Icons.picture_as_pdf_outlined;
    return Icons.description_outlined;
  }

  String get _fileSize {
    if (file == null) return '';
    try {
      return FileUtils.formatSize(file!.lengthSync());
    } catch (_) {
      return '';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius:
            BorderRadius.circular(AppDimensions.radiusSmall),
        border: Border.all(
          color: AppColors.surface200,
          width: AppDimensions.borderThin,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: _iconColor.withValues(alpha: 0.1),
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(
              _icon,
              color: _iconColor,
              size: AppDimensions.iconSM,
            ),
          ),
          const SizedBox(width: AppDimensions.space12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  fileName,
                  style: AppTypography.titleSmall,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                if (_fileSize.isNotEmpty)
                  Text(
                    _fileSize,
                    style: AppTypography.caption,
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: onRemove,
            icon: const Icon(
              Icons.close_rounded,
              size: AppDimensions.iconSM,
              color: AppColors.grey400,
            ),
            tooltip: 'Remove file',
            splashRadius: 18,
          ),
        ],
      ),
    );
  }
}