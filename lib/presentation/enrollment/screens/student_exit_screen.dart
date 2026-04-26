// lib/presentation/enrollment/screens/student_exit_screen.dart
// Phase 6 — Student Exit / Lifecycle Transition Screen.
// Handles LEFT, TRANSFERRED, and COMPLETED status transitions.
// Data is NEVER deleted — records are preserved for full history.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../data/models/enrollment/enrollment_model.dart';
import '../../../providers/enrollment_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class StudentExitScreen extends ConsumerStatefulWidget {
  const StudentExitScreen({
    super.key,
    required this.mappingId,
    required this.studentName,
    required this.admissionNumber,
    required this.standardName,
    required this.currentStatus,
  });

  final String mappingId;
  final String studentName;
  final String admissionNumber;
  final String standardName;
  final EnrollmentStatus currentStatus;

  @override
  ConsumerState<StudentExitScreen> createState() =>
      _StudentExitScreenState();
}

class _StudentExitScreenState extends ConsumerState<StudentExitScreen> {
  final _reasonCtrl = TextEditingController();
  _ExitAction _selectedAction = _ExitAction.left;
  DateTime _exitDate = DateTime.now();
  bool _isLoading = false;

  @override
  void dispose() {
    _reasonCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_reasonCtrl.text.trim().length < 3) {
      SnackbarUtils.showError(context, 'Please provide a reason (min 3 characters).');
      return;
    }

    // Confirm
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm ${_selectedAction.label}'),
        content: Text(
          'Mark ${widget.studentName} as ${_selectedAction.label}?\n\n'
          'This action records the exit but preserves all historical data.',
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: _selectedAction == _ExitAction.complete
                  ? Colors.blue
                  : Colors.red,
            ),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _isLoading = true);
    try {
      final notifier = ref.read(enrollmentNotifierProvider.notifier);

      if (_selectedAction == _ExitAction.complete) {
        await notifier.completeMapping(
          widget.mappingId,
          completedOn: DateFormatter.formatDateForApi(_exitDate),
        );
        if (mounted) {
          SnackbarUtils.showSuccess(
              context, 'Mapping marked as COMPLETED. Student is eligible for promotion.');
          context.pop(true);
        }
      } else {
        await notifier.exitStudent(
          widget.mappingId,
          status: _selectedAction == _ExitAction.left ? 'LEFT' : 'TRANSFERRED',
          leftOn: DateFormatter.formatDateForApi(_exitDate),
          exitReason: _reasonCtrl.text.trim(),
        );
        if (mounted) {
          SnackbarUtils.showSuccess(
              context, 'Student marked as ${_selectedAction.label}.');
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
      appBar: const AppAppBar(
        title: 'Student Exit / Lifecycle',
        showBack: true,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Student summary card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.studentName,
                      style: AppTypography.titleLarge
                          .copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Text('Admission No: ${widget.admissionNumber}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.grey500)),
                  Text('Class: ${widget.standardName}',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.grey500)),
                  const SizedBox(height: 8),
                  Chip(
                    label: Text(widget.currentStatus.label),
                    backgroundColor:
                        widget.currentStatus.color.withValues(alpha: 0.1),
                    labelStyle: TextStyle(
                      color: widget.currentStatus.color,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Action selector
          Text('Select Action',
              style: AppTypography.titleMedium
                  .copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          ..._ExitAction.values.map((action) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(
                  color: _selectedAction == action
                      ? action.color
                      : Colors.transparent,
                  width: 2,
                ),
              ),
              child: ListTile(
                leading: Icon(action.icon, color: action.color),
                title: Text(action.label,
                    style: const TextStyle(fontWeight: FontWeight.w600)),
                subtitle: Text(action.description,
                    style: const TextStyle(fontSize: 12)),
                selected: _selectedAction == action,
                onTap: () => setState(() => _selectedAction = action),
                trailing: _selectedAction == action
                    ? Icon(Icons.check_circle, color: action.color)
                    : null,
              ),
            );
          }),
          const SizedBox(height: 16),

          // Date picker
          InkWell(
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _exitDate,
                firstDate: DateTime(2020),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _exitDate = picked);
            },
            child: InputDecorator(
              decoration: InputDecoration(
                labelText: _selectedAction == _ExitAction.complete
                    ? 'Completion Date'
                    : 'Exit Date',
                border: const OutlineInputBorder(),
                suffixIcon: const Icon(Icons.calendar_today_outlined),
              ),
              child: Text(DateFormatter.formatDate(_exitDate)),
            ),
          ),
          const SizedBox(height: 12),

          // Reason field (not needed for COMPLETE)
          if (_selectedAction != _ExitAction.complete)
            AppTextField(
              controller: _reasonCtrl,
              label: 'Reason',
              hint: _selectedAction == _ExitAction.left
                  ? 'e.g. Family relocated to another city'
                  : 'e.g. Transferred to XYZ School',
              maxLines: 3,
              validator: (v) =>
                  (v?.trim().length ?? 0) < 3 ? 'Minimum 3 characters' : null,
            ),

          // Note for COMPLETE action
          if (_selectedAction == _ExitAction.complete)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
              ),
              child: const Row(
                children: [
                  Icon(Icons.info_outline, color: Colors.blue, size: 18),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Marking as COMPLETED means the student has finished this academic year '
                      'and is eligible for the promotion workflow.',
                      style: TextStyle(color: Colors.blue, fontSize: 12),
                    ),
                  ),
                ],
              ),
            ),

          const SizedBox(height: 24),
          AppButton.primary(
            label: _selectedAction.label,
            onTap: _isLoading ? null : _submit,
            isLoading: _isLoading,
            icon: _selectedAction.icon,
          ),
        ],
      ),
    );
  }
}

enum _ExitAction {
  left,
  transferred,
  complete,
}

extension _ExitActionX on _ExitAction {
  String get label {
    switch (this) {
      case _ExitAction.left:
        return 'Mark as Left';
      case _ExitAction.transferred:
        return 'Mark as Transferred';
      case _ExitAction.complete:
        return 'Complete Academic Year';
    }
  }

  String get description {
    switch (this) {
      case _ExitAction.left:
        return 'Student left school mid-year (voluntary withdrawal)';
      case _ExitAction.transferred:
        return 'Student transferred to another school';
      case _ExitAction.complete:
        return 'Year finished — student becomes eligible for promotion';
    }
  }

  IconData get icon {
    switch (this) {
      case _ExitAction.left:
        return Icons.logout_rounded;
      case _ExitAction.transferred:
        return Icons.swap_horiz_rounded;
      case _ExitAction.complete:
        return Icons.check_circle_outline;
    }
  }

  Color get color {
    switch (this) {
      case _ExitAction.left:
        return Colors.red;
      case _ExitAction.transferred:
        return Colors.purple;
      case _ExitAction.complete:
        return Colors.blue;
    }
  }
}