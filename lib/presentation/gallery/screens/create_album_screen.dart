import "package:flutter/material.dart";
import "package:flutter_riverpod/flutter_riverpod.dart";
import "package:go_router/go_router.dart";

import "../../../core/theme/app_colors.dart";
import "../../../core/theme/app_dimensions.dart";
import "../../../core/theme/app_typography.dart";
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

class _CreateAlbumScreenState extends ConsumerState<CreateAlbumScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _eventNameController = TextEditingController();
  final _descriptionController = TextEditingController();

  DateTime? _eventDate;

  late AnimationController _animCtrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

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
  }

  @override
  void dispose() {
    _eventNameController.dispose();
    _descriptionController.dispose();
    _animCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _eventDate ?? DateTime.now(),
      firstDate: DateTime(DateTime.now().year - 10),
      lastDate: DateTime(DateTime.now().year + 2),
      builder: (ctx, child) => Theme(
        data: Theme.of(ctx).copyWith(
          colorScheme: const ColorScheme.light(
            primary: AppColors.navyDeep,
            onPrimary: AppColors.white,
          ),
        ),
        child: child!,
      ),
    );
    if (picked != null) setState(() => _eventDate = picked);
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
      appBar: const AppAppBar(title: "Create Album", showBack: true),
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
                      _FormCard(
                        title: "Album Details",
                        icon: Icons.photo_library_outlined,
                        children: [
                          AppTextField(
                            controller: _eventNameController,
                            label: "Event Name",
                            hint: "Annual Day 2026",
                            prefixIconData: Icons.event_note_outlined,
                            textInputAction: TextInputAction.next,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return "Event name is required";
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                          _FieldLabel("Event Date"),
                          const SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickDate,
                            child: AnimatedContainer(
                              duration: const Duration(milliseconds: 200),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 14),
                              decoration: BoxDecoration(
                                color: AppColors.surface50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _eventDate != null
                                      ? AppColors.navyMedium
                                          .withValues(alpha: 0.5)
                                      : AppColors.surface200,
                                  width: _eventDate != null ? 1.5 : 1,
                                ),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.calendar_today_outlined,
                                    size: 16,
                                    color: _eventDate != null
                                        ? AppColors.navyMedium
                                        : AppColors.grey400,
                                  ),
                                  const SizedBox(width: 10),
                                  Text(
                                    _eventDate != null
                                        ? DateFormatter.formatDate(_eventDate!)
                                        : "Select event date",
                                    style: AppTypography.bodyMedium.copyWith(
                                      color: _eventDate != null
                                          ? AppColors.grey800
                                          : AppColors.grey400,
                                    ),
                                  ),
                                  const Spacer(),
                                  const Icon(
                                      Icons.keyboard_arrow_down_rounded,
                                      color: AppColors.grey400,
                                      size: 18),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      _FormCard(
                        title: "Description",
                        icon: Icons.description_outlined,
                        children: [
                          AppTextField(
                            controller: _descriptionController,
                            label: "",
                            hint:
                                "Highlights and summary of the event (optional)",
                            maxLines: 4,
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.infoBlue.withValues(alpha: 0.07),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                              color: AppColors.infoBlue.withValues(alpha: 0.2)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded,
                                size: 15, color: AppColors.infoBlue),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                "After creating the album, you can upload photos to it.",
                                style: AppTypography.bodySmall.copyWith(
                                  color: AppColors.infoBlue,
                                  height: 1.4,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                    ],
                  ),
                ),
                _SubmitBar(isSubmitting: isSubmitting, onSubmit: _submit),
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

class _SubmitBar extends StatelessWidget {
  const _SubmitBar({required this.isSubmitting, required this.onSubmit});
  final bool isSubmitting;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.of(context).padding.bottom;
    return Container(
      color: AppColors.white,
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + bottom),
      child: AppButton.primary(
        label: "Create Album",
        onTap: isSubmitting ? null : onSubmit,
        isLoading: isSubmitting,
        icon: Icons.photo_library_outlined,
      ),
    );
  }
}