import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/fee/fee_ledger_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/fee_provider.dart';
import '../../../providers/masters_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../../providers/student_provider.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_section_header.dart';
import '../widgets/fee_ledger_card.dart';
import '../widgets/fee_summary_bar.dart';

class FeeDashboardScreen extends ConsumerWidget {
  const FeeDashboardScreen({super.key, this.studentId});

  final String? studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    switch (user.role) {
      case UserRole.parent:
        return _ParentFeeDashboard(explicitStudentId: studentId);
      case UserRole.student:
        return _StudentFeeDashboard(explicitStudentId: studentId);
      default:
        final isLeadership = user.role == UserRole.principal ||
            user.role == UserRole.trustee ||
            user.role == UserRole.superadmin;

        if (isLeadership && (studentId == null || studentId!.isEmpty)) {
          return const _PrincipalFeeAnalyticsDashboard();
        }

        final id = studentId ??
            GoRouterState.of(context).uri.queryParameters['student_id'];
        if (id == null || id.isEmpty) {
          return _buildSelectStudentState(context);
        }
        return _FeeDashboardBody(studentId: id, user: user);
    }
  }

  Widget _buildSelectStudentState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: const AppAppBar(title: 'Fee Management', showBack: true),
      body: AppEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No Student Selected',
        subtitle: 'Access fee details from a student\'s profile page.',
        actionLabel: 'Go to Students',
        onAction: () => context.go(RouteNames.students),
      ),
    );
  }
}

// ── Parent wrapper ────────────────────────────────────────────────────────────

class _ParentFeeDashboard extends ConsumerWidget {
  const _ParentFeeDashboard({this.explicitStudentId});
  final String? explicitStudentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider)!;
    final childId = explicitStudentId ?? ref.watch(selectedChildIdProvider);

    if (childId == null || childId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: const AppAppBar(title: 'Fee Management', showBack: true),
        body: AppEmptyState(
          icon: Icons.family_restroom_outlined,
          title: 'No Child Selected',
          subtitle: 'Select your child from the dashboard to view fees.',
          actionLabel: 'Go to Dashboard',
          onAction: () => context.go(RouteNames.dashboard),
        ),
      );
    }

    return _FeeDashboardBody(studentId: childId, user: user);
  }
}

// ── Student wrapper ───────────────────────────────────────────────────────────

class _StudentFeeDashboard extends ConsumerWidget {
  const _StudentFeeDashboard({this.explicitStudentId});
  final String? explicitStudentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider)!;

    if (explicitStudentId != null) {
      return _FeeDashboardBody(studentId: explicitStudentId!, user: user);
    }

    final myIdAsync = ref.watch(myStudentIdProvider);

    return myIdAsync.when(
      loading: () => Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: const AppAppBar(title: 'Fee Management', showBack: true),
        body: AppLoading.fullPage(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: const AppAppBar(title: 'Fee Management', showBack: true),
        body: AppErrorState(
          message: 'Could not load your student profile.',
          onRetry: () => ref.invalidate(myStudentIdProvider),
        ),
      ),
      data: (id) {
        if (id == null) {
          return Scaffold(
            backgroundColor: AppColors.surface50,
            appBar: const AppAppBar(title: 'Fee Management', showBack: true),
            body: const AppEmptyState(
              icon: Icons.school_outlined,
              title: 'Profile Not Found',
              subtitle:
                  'Your student profile could not be located. Please contact your administrator.',
            ),
          );
        }
        return _FeeDashboardBody(studentId: id, user: user);
      },
    );
  }
}

// ── Principal analytics dashboard ────────────────────────────────────────────

class _PrincipalFeeAnalyticsDashboard extends ConsumerStatefulWidget {
  const _PrincipalFeeAnalyticsDashboard();

  @override
  ConsumerState<_PrincipalFeeAnalyticsDashboard> createState() =>
      _PrincipalFeeAnalyticsDashboardState();
}

class _PrincipalFeeAnalyticsDashboardState
    extends ConsumerState<_PrincipalFeeAnalyticsDashboard> {
  String? _standardId;
  String? _section;
  String? _studentId;

  String _currency(dynamic v) {
    final d = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
    return '₹${d.toStringAsFixed(2)}';
  }

  @override
  Widget build(BuildContext context) {
    final activeYearId = ref.watch(activeYearProvider)?.id;
    final standardsAsync = ref.watch(standardsProvider(activeYearId));
    final sectionsAsync = ref.watch(studentSectionsProvider(_standardId));
    final studentsAsync = ref.watch(feeReportStudentsProvider((
      academicYearId: activeYearId,
      standardId: _standardId,
      section: _section,
    )));
    final analyticsAsync = ref.watch(feeAnalyticsProvider((
      academicYearId: activeYearId,
      standardId: _standardId,
      section: _section,
      studentId: _studentId,
    )));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Fee Management',
        showBack: true,
        showNotificationBell: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(feeAnalyticsProvider),
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter bar
          Container(
            color: AppColors.white,
            padding: const EdgeInsets.fromLTRB(
              AppDimensions.space16,
              AppDimensions.space12,
              AppDimensions.space16,
              AppDimensions.space16,
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filter by',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.grey500,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                Row(
                  children: [
                    Expanded(
                      child: standardsAsync.when(
                        data: (standards) => _FilterDropdown<String?>(
                          hint: 'Class',
                          value: _standardId,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('All Classes')),
                            ...standards.map(
                              (s) => DropdownMenuItem(
                                  value: s.id, child: Text(s.name)),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _standardId = v;
                            _section = null;
                            _studentId = null;
                          }),
                        ),
                        loading: () => AppLoading.listTile(),
                        error: (e, _) => AppErrorState(message: e.toString()),
                      ),
                    ),
                    const SizedBox(width: AppDimensions.space8),
                    Expanded(
                      child: sectionsAsync.when(
                        data: (sections) => _FilterDropdown<String?>(
                          hint: 'Section',
                          value: _section,
                          items: [
                            const DropdownMenuItem(
                                value: null, child: Text('All')),
                            ...sections.map(
                              (s) => DropdownMenuItem(
                                  value: s, child: Text('Sec $s')),
                            ),
                          ],
                          onChanged: (v) => setState(() {
                            _section = v;
                            _studentId = null;
                          }),
                        ),
                        loading: () => AppLoading.listTile(),
                        error: (e, _) => AppErrorState(message: e.toString()),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppDimensions.space8),
                studentsAsync.when(
                  data: (students) => _FilterDropdown<String?>(
                    hint: 'Student',
                    value: _studentId,
                    items: [
                      const DropdownMenuItem(
                          value: null, child: Text('All Students')),
                      ...students.map(
                        (s) => DropdownMenuItem(
                          value: s.id,
                          child: Text(
                              '${s.admissionNumber} (${s.section ?? '-'})'),
                        ),
                      ),
                    ],
                    onChanged: (v) => setState(() => _studentId = v),
                  ),
                  loading: () => AppLoading.listTile(),
                  error: (e, _) => AppErrorState(message: e.toString()),
                ),
              ],
            ),
          ),
          // Content
          Expanded(
            child: analyticsAsync.when(
              loading: () => AppLoading.fullPage(),
              error: (e, _) => AppErrorState(message: e.toString()),
              data: (data) {
                final summary =
                    Map<String, dynamic>.from(data['summary'] as Map? ?? {});
                final byCategory = List<Map<String, dynamic>>.from(
                    data['by_category'] as List? ?? []);
                final byStatus = List<Map<String, dynamic>>.from(
                    data['by_status'] as List? ?? []);
                final byPaymentMode = List<Map<String, dynamic>>.from(
                    data['by_payment_mode'] as List? ?? []);
                final byStudent = List<Map<String, dynamic>>.from(
                    data['by_student'] as List? ?? []);

                return ListView(
                  padding: const EdgeInsets.all(AppDimensions.space16),
                  children: [
                    // KPI metric grid
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      crossAxisSpacing: AppDimensions.space12,
                      mainAxisSpacing: AppDimensions.space12,
                      childAspectRatio: 2.1,
                      children: [
                        _MetricCard(
                          title: 'Total Billed',
                          value: _currency(summary['total_billed_amount']),
                          icon: Icons.receipt_long_rounded,
                          accent: AppColors.navyMedium,
                        ),
                        _MetricCard(
                          title: 'Total Paid',
                          value: _currency(summary['total_paid_amount']),
                          icon: Icons.check_circle_outline_rounded,
                          accent: AppColors.successGreen,
                        ),
                        _MetricCard(
                          title: 'Outstanding',
                          value: _currency(summary['total_outstanding_amount']),
                          icon: Icons.pending_outlined,
                          accent: AppColors.warningAmber,
                        ),
                        _MetricCard(
                          title: 'Collection',
                          value:
                              '${(summary['collection_percentage'] ?? 0).toString()}%',
                          icon: Icons.pie_chart_outline_rounded,
                          accent: AppColors.infoBlue,
                        ),
                        _MetricCard(
                          title: 'Students',
                          value: '${summary['total_students'] ?? 0}',
                          icon: Icons.people_outline_rounded,
                          accent: AppColors.navyLight,
                        ),
                        _MetricCard(
                          title: 'Overdue',
                          value: '${summary['overdue_ledgers'] ?? 0}',
                          icon: Icons.warning_amber_rounded,
                          accent: AppColors.errorRed,
                        ),
                      ],
                    ),

                    const SizedBox(height: AppDimensions.space24),
                    const AppSectionHeader(title: 'Category Breakdown'),
                    const SizedBox(height: AppDimensions.space8),
                    _AnalyticsTable(
                      headers: const [
                        'Category',
                        'Billed',
                        'Paid',
                        'Outstanding',
                        'Ledgers'
                      ],
                      rows: byCategory
                          .map((r) => [
                                (r['fee_category'] ?? '-').toString(),
                                _currency(r['billed_amount']),
                                _currency(r['paid_amount']),
                                _currency(r['outstanding_amount']),
                                '${r['ledgers'] ?? 0}',
                              ])
                          .toList(),
                    ),

                    const SizedBox(height: AppDimensions.space16),
                    const AppSectionHeader(title: 'Status Breakdown'),
                    const SizedBox(height: AppDimensions.space8),
                    _AnalyticsTable(
                      headers: const [
                        'Status',
                        'Ledgers',
                        'Billed',
                        'Paid',
                        'Outstanding'
                      ],
                      rows: byStatus
                          .map((r) => [
                                (r['status'] ?? '-').toString(),
                                '${r['ledgers'] ?? 0}',
                                _currency(r['billed_amount']),
                                _currency(r['paid_amount']),
                                _currency(r['outstanding_amount']),
                              ])
                          .toList(),
                    ),

                    const SizedBox(height: AppDimensions.space16),
                    const AppSectionHeader(title: 'Payment Mode'),
                    const SizedBox(height: AppDimensions.space8),
                    _AnalyticsTable(
                      headers: const ['Mode', 'Amount', 'Transactions'],
                      rows: byPaymentMode
                          .map((r) => [
                                (r['payment_mode'] ?? '-').toString(),
                                _currency(r['amount']),
                                '${r['transactions'] ?? 0}',
                              ])
                          .toList(),
                    ),

                    const SizedBox(height: AppDimensions.space16),
                    AppSectionHeader(
                      title: 'Student Analysis (${byStudent.length})',
                    ),
                    const SizedBox(height: AppDimensions.space8),
                    _AnalyticsTable(
                      headers: const [
                        'Student',
                        'Class',
                        'Sec',
                        'Billed',
                        'Paid',
                        'Outstanding',
                        'Paid/Partial/Pending',
                        'Overdue',
                        'Latest Payment',
                      ],
                      rows: byStudent
                          .map((r) => [
                                (r['admission_number'] ?? '-').toString(),
                                (r['standard_id'] ?? '-').toString(),
                                (r['section'] ?? '-').toString(),
                                _currency(r['billed_amount']),
                                _currency(r['paid_amount']),
                                _currency(r['outstanding_amount']),
                                '${r['paid_ledgers'] ?? 0}/${r['partial_ledgers'] ?? 0}/${r['pending_ledgers'] ?? 0}',
                                '${r['overdue_ledgers'] ?? 0}',
                                (r['latest_payment_date'] ?? '-').toString(),
                              ])
                          .toList(),
                    ),
                    const SizedBox(height: AppDimensions.space40),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterDropdown<T> extends StatelessWidget {
  const _FilterDropdown({
    required this.hint,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String hint;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return DropdownButtonFormField<T>(
      initialValue: value,
      decoration: InputDecoration(
        hintText: hint,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space12,
          vertical: 10,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.surface200),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
          borderSide: const BorderSide(color: AppColors.surface200),
        ),
        filled: true,
        fillColor: AppColors.surface50,
        isDense: true,
      ),
      items: items,
      onChanged: onChanged,
      style: AppTypography.bodyMedium.copyWith(color: AppColors.grey800),
      icon: const Icon(Icons.keyboard_arrow_down_rounded,
          size: 18, color: AppColors.grey400),
    );
  }
}

class _AnalyticsTable extends StatelessWidget {
  const _AnalyticsTable({required this.headers, required this.rows});

  final List<String> headers;
  final List<List<String>> rows;

  @override
  Widget build(BuildContext context) {
    if (rows.isEmpty) {
      return const AppEmptyState(
        icon: Icons.table_chart_outlined,
        title: 'No data',
        subtitle: 'Try adjusting filters.',
      );
    }
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F3A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.surface50),
          dataRowMinHeight: 44,
          dataRowMaxHeight: 52,
          headingRowHeight: 40,
          dividerThickness: 1,
          columnSpacing: AppDimensions.space16,
          columns: headers
              .map((h) => DataColumn(
                    label: Text(
                      h,
                      style: AppTypography.labelMedium.copyWith(
                        color: AppColors.navyDeep,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ))
              .toList(),
          rows: rows
              .map(
                (row) => DataRow(
                  cells: row
                      .map((c) => DataCell(
                            Text(c, style: AppTypography.bodySmall),
                          ))
                      .toList(),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.accent,
  });

  final String title;
  final String value;
  final IconData icon;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space12),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
        border: Border.all(color: AppColors.surface200),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F3A).withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppDimensions.radiusSmall),
            ),
            child: Icon(icon, size: 18, color: accent),
          ),
          const SizedBox(width: AppDimensions.space8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  title,
                  style:
                      AppTypography.caption.copyWith(color: AppColors.grey500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: AppTypography.titleMedium.copyWith(
                      color: AppColors.navyDeep,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Main dashboard body ───────────────────────────────────────────────────────

class _FeeDashboardBody extends ConsumerWidget {
  const _FeeDashboardBody({
    required this.studentId,
    required this.user,
  });

  final String studentId;
  final CurrentUser user;

  bool get _canRecord =>
      user.hasPermission('fee:create') &&
      (user.role == UserRole.principal ||
          user.role == UserRole.trustee ||
          user.role == UserRole.superadmin);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashAsync = ref.watch(feeDashboardProvider(studentId));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Fee Management',
        showBack: true,
        showNotificationBell: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(feeDashboardProvider(studentId)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(feeDashboardProvider(studentId)),
        child: dashAsync.when(
          loading: () => _buildSkeleton(),
          error: (e, _) => AppErrorState(
            message: e.toString(),
            onRetry: () => ref.invalidate(feeDashboardProvider(studentId)),
          ),
          data: (result) => _buildContent(context, ref, result),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context,
    WidgetRef ref,
    FeeDashboardResult result,
  ) {
    if (result.items.isEmpty) {
      return const AppEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No Fee Records',
        subtitle: 'No fee ledger entries have been generated yet.',
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(
        AppDimensions.pageHorizontal,
        AppDimensions.space16,
        AppDimensions.pageHorizontal,
        AppDimensions.space40,
      ),
      children: [
        // Summary hero
        FeeSummaryBar(
          totalAmount: result.grandTotal,
          paidAmount: result.grandPaid,
          outstandingAmount: result.grandOutstanding,
        ),

        const SizedBox(height: AppDimensions.space24),

        // Section header
        Row(
          children: [
            Text(
              'Fee Entries',
              style: AppTypography.titleLarge.copyWith(
                color: AppColors.navyDeep,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(width: AppDimensions.space8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space8,
                vertical: AppDimensions.space2,
              ),
              decoration: BoxDecoration(
                color: AppColors.navyDeep.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                '${result.total}',
                style: AppTypography.labelMedium.copyWith(
                  color: AppColors.navyDeep,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: AppDimensions.space12),

        ...result.items.asMap().entries.map((entry) {
          return Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.space12),
            child: FeeLedgerCard(
              ledger: entry.value,
              sequenceNumber: entry.key + 1,
              onViewHistory: () => context.push(
                RouteNames.paymentHistory,
                extra: {
                  'ledgerId': entry.value.id,
                  'totalAmount': entry.value.totalAmount,
                  'paidAmount': entry.value.paidAmount,
                  'outstandingAmount': entry.value.outstandingAmount,
                  'status': entry.value.status.label,
                },
              ),
              onPayNow: _canRecord && entry.value.hasOutstanding
                  ? () => context.push(
                        RouteNames.recordPayment,
                        extra: {
                          'studentId': studentId,
                          'ledgerId': entry.value.id,
                          'outstandingAmount': entry.value.outstandingAmount,
                          'totalAmount': entry.value.totalAmount,
                        },
                      )
                  : null,
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
      children: [
        const SizedBox(height: AppDimensions.space16),
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: AppColors.surface100,
            borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          ),
        ),
        const SizedBox(height: AppDimensions.space24),
        ...List.generate(
          3,
          (_) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.space12),
            child: AppLoading.card(),
          ),
        ),
      ],
    );
  }
}
