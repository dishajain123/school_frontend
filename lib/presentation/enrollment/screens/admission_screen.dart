// lib/presentation/enrollment/screens/admission_screen.dart
// Phase 6 — New Student Admission Screen.
// Handles complete flow: create user → create student profile → create enrollment mapping.
// Responsibility: Admissions Staff creates record; Admin/Principal finalises.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/utils/snackbar_utils.dart';
import '../../../core/utils/validators.dart';
import '../../../data/models/enrollment/enrollment_model.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/enrollment_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_button.dart';
import '../../common/widgets/app_text_field.dart';

class AdmissionScreen extends ConsumerStatefulWidget {
  const AdmissionScreen({super.key});

  @override
  ConsumerState<AdmissionScreen> createState() => _AdmissionScreenState();
}

class _AdmissionScreenState extends ConsumerState<AdmissionScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TabController _tabController;

  // ── Step 1: Student Account ───────────────────────────────────────────────
  final _fullNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  // ── Step 2: Student Details ───────────────────────────────────────────────
  final _admissionNumberCtrl = TextEditingController();
  DateTime? _dateOfBirth;
  DateTime? _admissionDate;
  AdmissionType _admissionType = AdmissionType.newAdmission;

  // ── Step 3: Parent Linking ────────────────────────────────────────────────
  bool _createParentInline = false;
  final _parentIdCtrl = TextEditingController();
  final _parentEmailCtrl = TextEditingController();
  final _parentPhoneCtrl = TextEditingController();
  final _parentPasswordCtrl = TextEditingController();
  final _parentOccupationCtrl = TextEditingController();
  String _parentRelation = 'GUARDIAN';

  // ── Step 4: Class Assignment ──────────────────────────────────────────────
  String? _selectedStandardId;
  String? _selectedSectionId;
  String? _selectedYearId;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _admissionDate = DateTime.now();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _fullNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _admissionNumberCtrl.dispose();
    _parentIdCtrl.dispose();
    _parentEmailCtrl.dispose();
    _parentPhoneCtrl.dispose();
    _parentPasswordCtrl.dispose();
    _parentOccupationCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedStandardId == null || _selectedYearId == null) {
      SnackbarUtils.showError(context, 'Please select a class and academic year.');
      return;
    }

    setState(() => _isLoading = true);
    try {
      final dio = ref.read(dioClientProvider).dio;

      // Step A: Create parent (if inline)
      String? resolvedParentId = _parentIdCtrl.text.trim().isEmpty
          ? null
          : _parentIdCtrl.text.trim();

      if (_createParentInline && resolvedParentId == null) {
        final parentResp = await dio.post<Map<String, dynamic>>(
          ApiConstants.parents,
          data: {
            'user': {
              'email': _parentEmailCtrl.text.trim().toLowerCase(),
              'phone': _parentPhoneCtrl.text.trim(),
              'password': _parentPasswordCtrl.text,
            },
            'relation': _parentRelation,
            if (_parentOccupationCtrl.text.trim().isNotEmpty)
              'occupation': _parentOccupationCtrl.text.trim(),
          },
        );
        resolvedParentId = parentResp.data?['id'] as String?;
      }

      if (resolvedParentId == null) {
        throw Exception('Parent ID is required');
      }

      // Step B: Create student (creates user + student profile + admission number)
      final studentResp = await dio.post<Map<String, dynamic>>(
        ApiConstants.students,
        data: {
          'user': {
            'full_name': _fullNameCtrl.text.trim(),
            'email': _emailCtrl.text.trim().toLowerCase(),
            'phone': _phoneCtrl.text.trim(),
            'password': _passwordCtrl.text,
          },
          'parent_id': resolvedParentId,
          if (_admissionNumberCtrl.text.trim().isNotEmpty)
            'admission_number': _admissionNumberCtrl.text.trim(),
          if (_dateOfBirth != null)
            'date_of_birth': DateFormatter.formatDateForApi(_dateOfBirth!),
          if (_admissionDate != null)
            'admission_date': DateFormatter.formatDateForApi(_admissionDate!),
        },
      );

      final studentId = studentResp.data?['id'] as String?;
      if (studentId == null) throw Exception('Student creation failed');

      // Step C: Create enrollment mapping
      await ref.read(enrollmentNotifierProvider.notifier).createMapping(
            studentId: studentId,
            academicYearId: _selectedYearId!,
            standardId: _selectedStandardId!,
            sectionId: _selectedSectionId,
            joinedOn: _admissionDate != null
                ? DateFormatter.formatDateForApi(_admissionDate!)
                : null,
            admissionType: _admissionType,
          );

      if (mounted) {
        SnackbarUtils.showSuccess(
            context, 'Student admitted and enrolled successfully.');
        context.pop(true);
      }
    } catch (e) {
      if (mounted) SnackbarUtils.showError(context, e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final standardsAsync = ref.watch(standardsNotifierProvider);
    final standards = standardsAsync.valueOrNull ?? [];
    final yearsAsync = ref.watch(academicYearNotifierProvider);
    final years = yearsAsync.valueOrNull ?? [];

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: const AppAppBar(title: 'New Student Admission', showBack: true),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            TabBar(
              controller: _tabController,
              isScrollable: true,
              tabs: const [
                Tab(text: '1. Account'),
                Tab(text: '2. Details'),
                Tab(text: '3. Parent'),
                Tab(text: '4. Class'),
              ],
            ),
            Expanded(
              child: TabBarView(
                controller: _tabController,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  // ── Tab 1: Student Account ─────────────────────────────
                  _buildStep(
                    children: [
                      AppTextField(
                        controller: _fullNameCtrl,
                        label: 'Full Name',
                        hint: 'Student full name',
                        prefixIconData: Icons.person_outline,
                        validator: (v) =>
                            (v?.trim().isEmpty ?? true) ? 'Required' : null,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _emailCtrl,
                        label: 'Email',
                        hint: 'student@example.com',
                        keyboardType: TextInputType.emailAddress,
                        prefixIconData: Icons.email_outlined,
                        validator: Validators.validateEmail,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _phoneCtrl,
                        label: 'Phone',
                        hint: '+91 9876543210',
                        keyboardType: TextInputType.phone,
                        prefixIconData: Icons.phone_outlined,
                        validator: Validators.validatePhone,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        controller: _passwordCtrl,
                        label: 'Initial Password',
                        hint: 'Min 8 characters',
                        obscureText: true,
                        prefixIconData: Icons.lock_outlined,
                        validator: Validators.validatePassword,
                      ),
                    ],
                  ),

                  // ── Tab 2: Student Details ─────────────────────────────
                  _buildStep(
                    children: [
                      AppTextField(
                        controller: _admissionNumberCtrl,
                        label: 'Custom Admission Number (optional)',
                        hint: 'Leave blank for auto-generation',
                        prefixIconData: Icons.badge_outlined,
                      ),
                      const SizedBox(height: 12),
                      // Admission Type picker
                      DropdownButtonFormField<AdmissionType>(
                        value: _admissionType,
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
                        onChanged: (v) =>
                            setState(() => _admissionType = v!),
                      ),
                      const SizedBox(height: 12),
                      _buildDatePicker(
                        label: 'Date of Birth',
                        value: _dateOfBirth,
                        onPicked: (d) =>
                            setState(() => _dateOfBirth = d),
                      ),
                      const SizedBox(height: 12),
                      _buildDatePicker(
                        label: 'Admission Date',
                        value: _admissionDate,
                        onPicked: (d) =>
                            setState(() => _admissionDate = d),
                      ),
                    ],
                  ),

                  // ── Tab 3: Parent ──────────────────────────────────────
                  _buildStep(
                    children: [
                      SwitchListTile(
                        title: const Text('Create new parent account'),
                        subtitle: const Text(
                          'Or enter an existing parent ID below',
                        ),
                        value: _createParentInline,
                        onChanged: (v) =>
                            setState(() => _createParentInline = v),
                      ),
                      const SizedBox(height: 8),
                      if (!_createParentInline)
                        AppTextField(
                          controller: _parentIdCtrl,
                          label: 'Existing Parent ID (UUID)',
                          prefixIconData: Icons.family_restroom_outlined,
                        )
                      else ...[
                        AppTextField(
                          controller: _parentEmailCtrl,
                          label: 'Parent Email',
                          keyboardType: TextInputType.emailAddress,
                          prefixIconData: Icons.email_outlined,
                          validator: _createParentInline
                              ? Validators.validateEmail
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _parentPhoneCtrl,
                          label: 'Parent Phone',
                          keyboardType: TextInputType.phone,
                          prefixIconData: Icons.phone_outlined,
                          validator: _createParentInline
                              ? Validators.validatePhone
                              : null,
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _parentPasswordCtrl,
                          label: 'Parent Initial Password',
                          obscureText: true,
                          prefixIconData: Icons.lock_outlined,
                          validator: _createParentInline
                              ? Validators.validatePassword
                              : null,
                        ),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _parentRelation,
                          decoration: const InputDecoration(
                            labelText: 'Relation',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'FATHER',
                                child: Text('Father')),
                            DropdownMenuItem(
                                value: 'MOTHER',
                                child: Text('Mother')),
                            DropdownMenuItem(
                                value: 'GUARDIAN',
                                child: Text('Guardian')),
                          ],
                          onChanged: (v) =>
                              setState(() => _parentRelation = v!),
                        ),
                        const SizedBox(height: 12),
                        AppTextField(
                          controller: _parentOccupationCtrl,
                          label: 'Occupation (optional)',
                          prefixIconData: Icons.work_outline,
                        ),
                      ],
                    ],
                  ),

                  // ── Tab 4: Class Assignment ────────────────────────────
                  _buildStep(
                    children: [
                      // Academic Year
                      DropdownButtonFormField<String>(
                        value: _selectedYearId,
                        decoration: const InputDecoration(
                          labelText: 'Academic Year',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Select year'),
                        items: years
                            .map((y) => DropdownMenuItem<String>(
                                  value: y.id,
                                  child: Text(
                                    '${y.name}${y.isActive ? ' (Active)' : ''}',
                                  ),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedYearId = v),
                        validator: (v) =>
                            v == null ? 'Select an academic year' : null,
                      ),
                      const SizedBox(height: 12),
                      // Standard (Class)
                      DropdownButtonFormField<String>(
                        value: _selectedStandardId,
                        decoration: const InputDecoration(
                          labelText: 'Class',
                          border: OutlineInputBorder(),
                        ),
                        hint: const Text('Select class'),
                        items: standards
                            .map((s) => DropdownMenuItem<String>(
                                  value: s.id,
                                  child: Text(s.name),
                                ))
                            .toList(),
                        onChanged: (v) =>
                            setState(() => _selectedStandardId = v),
                        validator: (v) =>
                            v == null ? 'Select a class' : null,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Section and roll number can be assigned after admission via the Enrollment module.',
                        style: TextStyle(color: Colors.grey, fontSize: 12),
                      ),
                    ],
                    submitButton: AppButton.primary(
                      label: 'Complete Admission',
                      onTap: _isLoading ? null : _submit,
                      isLoading: _isLoading,
                      icon: Icons.how_to_reg_outlined,
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

  Widget _buildStep({
    required List<Widget> children,
    Widget? submitButton,
  }) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
      children: [
        ...children,
        if (submitButton != null) ...[
          const SizedBox(height: 24),
          submitButton,
        ],
        if (submitButton == null) ...[
          const SizedBox(height: 24),
          AppButton.secondary(
            label: 'Next',
            onTap: () {
              if (_tabController.index < 3) {
                _tabController.animateTo(_tabController.index + 1);
              }
            },
            icon: Icons.arrow_forward,
          ),
        ],
      ],
    );
  }

  Widget _buildDatePicker({
    required String label,
    required DateTime? value,
    required void Function(DateTime) onPicked,
  }) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(1950),
          lastDate: DateTime(2100),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          suffixIcon: const Icon(Icons.calendar_today_outlined),
        ),
        child: Text(
          value != null ? DateFormatter.formatDate(value) : 'Tap to select',
          style: value != null
              ? null
              : const TextStyle(color: Colors.grey),
        ),
      ),
    );
  }
}