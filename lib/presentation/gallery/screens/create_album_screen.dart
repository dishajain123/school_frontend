import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_dimensions.dart";
import "../../../core/utils/date_formatter.dart";
import "../../../core/utils/snackbar_utils.dart";
import "../../../providers/academic_year_provider.dart";
import "../../../providers/gallery_provider.dart";
import "../../common/widgets/app_app_bar.dart";
import "../../common/widgets/app_button.dart";
import "../../common/widgets/app_scaffold.dart";
import "../../common/widgets/app_text_field.dart";

class CreateAlbumScreen extends ConsumerStatefulWidget {
  const CreateAlbumScreen({super.key});

  @override
  ConsumerState<CreateAlbumScreen> createState() => _CreateAlbumScreenState();
}

class _CreateAlbumScreenState extends ConsumerState<CreateAlbumScreen> {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _eventDate;

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 2),
    );
    if (picked != null) {
      setState(() => _eventDate = picked);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_eventDate == null) {
      SnackbarUtils.showError(context, "Please select an event date");
      return;
    }

    final activeYear = ref.read(activeYearProvider);
    final payload = <String, dynamic>{
      "event_name": _eventNameController.text.trim(),
      "event_date": DateFormatter.formatDateForApi(_eventDate!),
      if (_descriptionController.text.trim().isNotEmpty)
        "description": _descriptionController.text.trim(),
      if (activeYear != null) "academic_year_id": activeYear.id,
    };

    final created = await ref
        .read(galleryAlbumListNotifierProvider.notifier)
        .createAlbum(payload);

    if (!mounted) return;

    if (created != null) {
      SnackbarUtils.showSuccess(context, "Album created successfully");
      context.pop(true);
    } else {
      final error =
          ref.read(galleryAlbumListNotifierProvider).valueOrNull?.error;
      SnackbarUtils.showError(
        context,
        error ?? "Failed to create album. Please try again.",
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final albumListState =
        ref.watch(galleryAlbumListNotifierProvider).valueOrNull;
    final isSubmitting = albumListState?.isSubmitting ?? false;

    return AppScaffold(
      appBar: const AppAppBar(
        title: "Create Album",
        showBack: true,
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
          children: [
            const SizedBox(height: AppDimensions.space16),
            AppTextField(
              controller: _eventNameController,
              label: "Event Name",
              hint: "Annual Day 2026",
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) {
                  return "Event name is required";
                }
                return null;
              },
            ),
            const SizedBox(height: AppDimensions.space16),
            TextFormField(
              readOnly: true,
              onTap: _pickDate,
              decoration: InputDecoration(
                labelText: "Event Date",
                hintText: _eventDate == null
                    ? "Select event date"
                    : DateFormatter.formatDate(_eventDate!),
                prefixIcon: const Icon(Icons.event_outlined),
                filled: true,
                fillColor: AppColors.surface50,
                enabledBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: const BorderSide(
                    color: AppColors.surface200,
                    width: AppDimensions.borderMedium,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius:
                      BorderRadius.circular(AppDimensions.radiusSmall),
                  borderSide: const BorderSide(
                    color: AppColors.navyMedium,
                    width: AppDimensions.borderMedium,
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppDimensions.space16),
            AppTextField(
              controller: _descriptionController,
              label: "Description (optional)",
              hint: "Highlights and summary of the event",
              maxLines: 4,
            ),
            const SizedBox(height: AppDimensions.space32),
            AppButton.primary(
              label: "Create Album",
              onTap: isSubmitting ? null : _submit,
              isLoading: isSubmitting,
              icon: Icons.check_circle_outline_rounded,
            ),
            const SizedBox(height: AppDimensions.space40),
          ],
        ),
      ),
    );
  }
}
