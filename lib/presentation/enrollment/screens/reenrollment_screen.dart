// lib/presentation/enrollment/screens/reenrollment_screen.dart
// Phase 7 — Single Student Re-enrollment Screen.
// Re-enrolls a student in a target academic year without recreating user accounts.
// User identity, admission number, and parent links are permanently preserved.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/enrollment/enrollment_model.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';

class ReenrollmentScreen extends ConsumerStatefulWidget {
  const ReenrollmentScreen({
    super.key,
    required this.studentId,
    required this.studentName,
    required this.admissionNumber,
  });

  final String studentId;
  final String studentName;
  final String admissionNumber;

  @override
  ConsumerState<ReenrollmentScreen> createState() => _ReenrollmentScreenState();
}

class _ReenrollmentScreenState extends ConsumerState<ReenrollmentScreen> {
  String? _selectedYearId;
  String? _selectedStandardId;
  String? _selectedSectionId;
  final _rollCtrl = TextEditingController();
  DateTime? _joinedOn;
  AdmissionType _admissionType = AdmissionType.readmission;
  bool _isLoading = false;

  @override
  void dispose() {
    _rollCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_selectedYearId == null || _selectedStandardId == null) {
      SnackbarUtils.showError(
          context, 'Please select an academic year and class.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final result =
          await ref.read(enrollmentNotifierProvider.notifier).reenrollStudent(
                widget.studentId,
                targetYearId: _selectedYearId!,
                standardId: _selectedStandardId!,
                sectionId: _selectedSectionId,
                rollNumber: _rollCtrl.text.trim().isEmpty
                    ? null
                    : _rollCtrl.text.trim(),
                joinedOn: _joinedOn != null
                    ? DateFormatter.formatDateForApi(_joinedOn!)
                    : null,
                admissionType: _admissionType.backendValue,
              );

      if (mounted) {
        SnackbarUtils.showSuccess(
            context, '${widget.studentName} successfully re-enrolled.');
        context.pop(result);
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final yearsAsync = ref.watch(academicYearNotifierProvider);
    final allYears = yearsAsync.valueOrNull ?? [];
    final now = DateTime.now();
    final preferredYears = allYears
        .where((y) => !y.isActive && y.endDate.isAfter(now))
        .toList(growable: false)
      ..sort((a, b) => a.startDate.compareTo(b.startDate));
    final years = preferredYears.isNotEmpty
        ? preferredYears
        : allYears.where((y) => !y.isActive).toList(growable: false);
    final availableYears = years.isNotEmpty ? years : allYears;
    final selectedYearValue = availableYears.any((y) => y.id == _selectedYearId)
        ? _selectedYearId
        : null;
    final standardsAsync = ref.watch(standardsProvider(selectedYearValue));
    final standards = standardsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: const AppAppBar(title: 'Re-enroll Student', showBack: true),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Principle reminder
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.infoLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline,
                    color: AppColors.infoBlue, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Re-enrollment creates a new academic mapping for this student. '
                    'The student\'s user account, admission number '
                    '(${widget.admissionNumber}), and parent links are unchanged.',
                    style: const TextStyle(
                        color: AppColors.infoBlue, fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Student card
          Card(
            child: ListTile(
              leading: CircleAvatar(
                backgroundColor: AppColors.navyDeep.withValues(alpha: 0.1),
                child: Text(
                  widget.studentName.isNotEmpty
                      ? widget.studentName[0].toUpperCase()
                      : '?',
                  style: const TextStyle(
                      color: AppColors.navyDeep, fontWeight: FontWeight.bold),
                ),
              ),
              title: Text(widget.studentName,
                  style: const TextStyle(fontWeight: FontWeight.bold)),
              subtitle: Text('Admission No: ${widget.admissionNumber}'),
            ),
          ),
          const SizedBox(height: 16),

          // Admission Type
          DropdownButtonFormField<AdmissionType>(
            initialValue: _admissionType,
            decoration: const InputDecoration(
              labelText: 'Admission Type',
              border: OutlineInputBorder(),
            ),
            items: AdmissionType.values
                .map((t) => DropdownMenuItem(
                      value: t,
                      child: Text(t.label),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _admissionType = v!),
          ),
          const SizedBox(height: 12),

          // Academic Year
          DropdownButtonFormField<String>(
            initialValue: selectedYearValue,
            decoration: const InputDecoration(
              labelText: 'Target Academic Year *',
              border: OutlineInputBorder(),
            ),
            hint: const Text('Select year'),
            items: availableYears
                .map((y) => DropdownMenuItem<String>(
                      value: y.id,
                      child: Text(
                        '${y.name}${y.isActive ? ' (Active)' : ''}',
                      ),
                    ))
                .toList(),
            onChanged: (v) => setState(() {
              _selectedYearId = v;
              _selectedStandardId = null;
              _selectedSectionId = null;
            }),
          ),
          const SizedBox(height: 12),

          // Class
          DropdownButtonFormField<String>(
            initialValue: _selectedStandardId,
            decoration: const InputDecoration(
              labelText: 'Class *',
              border: OutlineInputBorder(),
            ),
            hint: const Text('Select class'),
            items: standards
                .map((s) => DropdownMenuItem<String>(
                      value: s.id,
                      child: Text(s.name),
                    ))
                .toList(),
            onChanged: (v) => setState(() => _selectedStandardId = v),
          ),
          const SizedBox(height: 12),

          // Roll Number (optional)
          TextFormField(
            controller: _rollCtrl,
            decoration: const InputDecoration(
              labelText: 'Roll Number (optional)',
              border: OutlineInputBorder(),
              hintText: 'Will be assigned automatically if left blank',
            ),
          ),
          const SizedBox(height: 12),

          // Joining Date
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _joinedOn ?? DateTime.now(),
                firstDate: DateTime(2020),
                lastDate: DateTime(2100),
              );
              if (picked != null) setState(() => _joinedOn = picked);
            },
            child: InputDecorator(
              decoration: const InputDecoration(
                labelText: 'Joining Date (optional)',
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today_outlined),
              ),
              child: Text(
                _joinedOn != null
                    ? DateFormatter.formatDate(_joinedOn!)
                    : 'Today (default)',
                style: _joinedOn == null
                    ? const TextStyle(color: Colors.grey)
                    : null,
              ),
            ),
          ),
          const SizedBox(height: 24),

          AppButton.primary(
            label: 'Re-enroll Student',
            onTap: _isLoading ? null : _submit,
            isLoading: _isLoading,
            icon: Icons.how_to_reg_outlined,
          ),
        ],
      ),
    );
  }
}
