import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/fee/fee_ledger_model.dart';
import '../../../data/models/fee/fee_structure_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/academic_year_provider.dart';
import '../../../providers/dashboard_provider.dart';
import '../../../providers/fee_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_loading.dart';

// ── Color constants ───────────────────────────────────────────────────────────
const _kGreen = Color(0xFF2E7D32);
const _kGreenBg = Color(0xFFE8F5E9);
const _kOrange = Color(0xFFE65100);
const _kOrangeBg = Color(0xFFFFF3E0);
const _kRed = Color(0xFFC62828);
const _kRedBg = Color(0xFFFFEBEE);

final myStudentIdProvider = FutureProvider<String?>((ref) async {
  final profile = await ref.watch(myStudentProfileProvider.future);
  return profile.id;
});

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
            user.role == UserRole.staffAdmin;

        if (isLeadership && (studentId == null || studentId!.isEmpty)) {
          return const _PrincipalFeeAnalyticsDashboard();
        }

        final id = studentId ??
            GoRouterState.of(context).uri.queryParameters['student_id'];
        if (id == null || id.isEmpty) {
          return _buildSelectStudentState(context);
        }
        final activeYearId = ref.watch(activeYearProvider)?.id;
        return _FeeDashboardBody(
          studentId: id,
          user: user,
          academicYearId: activeYearId,
        );
    }
  }

  Widget _buildSelectStudentState(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: const AppAppBar(title: 'Fee Management', showBack: true),
      body: AppEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No Student Selected',
        subtitle: "Access fee details from a student's profile page.",
        actionLabel: 'Go to Students',
        onAction: () => context.go(RouteNames.students),
      ),
    );
  }
}

// ── Parent Wrapper ────────────────────────────────────────────────────────────

class _ParentFeeDashboard extends ConsumerWidget {
  const _ParentFeeDashboard({this.explicitStudentId});
  final String? explicitStudentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider)!;
    final selectedChild = ref.watch(selectedChildProvider);
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

    final activeYearId = ref.watch(activeYearProvider)?.id;
    return _FeeDashboardBody(
      studentId: childId,
      user: user,
      academicYearId: activeYearId,
      standardId: selectedChild?.standardId,
    );
  }
}

// ── Student Wrapper ───────────────────────────────────────────────────────────

class _StudentFeeDashboard extends ConsumerWidget {
  const _StudentFeeDashboard({this.explicitStudentId});
  final String? explicitStudentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider)!;

    if (explicitStudentId != null) {
      final activeYearId = ref.watch(activeYearProvider)?.id;
      return _FeeDashboardBody(
        studentId: explicitStudentId!,
        user: user,
        academicYearId: activeYearId,
      );
    }

    final myProfileAsync = ref.watch(myStudentProfileProvider);
    return myProfileAsync.when(
      loading: () => const Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppAppBar(title: 'Fee Management', showBack: true),
        body: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: const AppAppBar(title: 'Fee Management', showBack: true),
        body: AppErrorState(
          message: 'Could not load your student profile.',
          onRetry: () => ref.invalidate(myStudentIdProvider),
        ),
      ),
      data: (profile) {
        final id = profile.id;
        if (id.isEmpty) {
          return const Scaffold(
            backgroundColor: AppColors.surface50,
            appBar: AppAppBar(title: 'Fee Management', showBack: true),
            body: AppEmptyState(
              icon: Icons.school_outlined,
              title: 'Profile Not Found',
              subtitle:
                  'Your student profile could not be located. Please contact your administrator.',
            ),
          );
        }
        final activeYearId = ref.watch(activeYearProvider)?.id;
        return _FeeDashboardBody(
          studentId: id,
          user: user,
          academicYearId: activeYearId,
          standardId: profile.standardId,
        );
      },
    );
  }
}

// ── Fee Dashboard Body (Student/Parent) ───────────────────────────────────────

class _FeeDashboardBody extends ConsumerWidget {
  const _FeeDashboardBody({
    required this.studentId,
    required this.user,
    this.academicYearId,
    this.standardId,
  });

  final String studentId;
  final CurrentUser user;
  final String? academicYearId;
  final String? standardId;

  bool get _canRecord =>
      user.hasPermission('fee:create') || user.role.isSchoolScopedAdmin;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = (studentId: studentId, academicYearId: academicYearId);
    final dashAsync = ref.watch(feeDashboardProvider(params));
    final structureParams =
        (academicYearId: academicYearId, standardId: standardId);
    final structuresAsync = ref.watch(feeStructuresProvider(structureParams));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Fee Management',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(feeDashboardProvider(params)),
          ),
        ],
      ),
      body: dashAsync.when(
        data: (result) => _buildBody(context, ref, result, structuresAsync),
        loading: () => AppLoading.fullPage(),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(feeDashboardProvider(params)),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    WidgetRef ref,
    FeeDashboardResult result,
    AsyncValue<List<FeeStructureModel>> structuresAsync,
  ) {
    if (result.items.isEmpty) {
      return structuresAsync.when(
        loading: () => AppLoading.fullPage(),
        error: (_, __) => const AppEmptyState(
          icon: Icons.account_balance_wallet_outlined,
          title: 'No Fee Records',
          subtitle: 'No fee ledger entries have been generated yet.',
        ),
        data: (structures) {
          if (structures.isEmpty) {
            return const AppEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No Fee Records',
              subtitle: 'No fee structures found for your allotted class yet.',
            );
          }
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Class Fee Structures',
                style: AppTypography.titleLarge.copyWith(
                  fontWeight: FontWeight.w700,
                  color: AppColors.grey800,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Ledger is not generated yet. Showing configured class fee heads.',
                style:
                    AppTypography.bodySmall.copyWith(color: AppColors.grey500),
              ),
              const SizedBox(height: 14),
              ...structures.map(
                (s) => Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.surface100),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          // ✅ FIX: was s.displayFeeHead — correct getter is displayLabel
                          s.displayLabel,
                          style: AppTypography.labelLarge.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Text(
                        '₹${s.amount.toStringAsFixed(2)}',
                        style: AppTypography.labelLarge.copyWith(
                          color: AppColors.navyDeep,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      );
    }

    return RefreshIndicator(
      color: AppColors.navyDeep,
      onRefresh: () async => ref.invalidate(feeDashboardProvider(
        (studentId: studentId, academicYearId: academicYearId),
      )),
      child: CustomScrollView(
        slivers: [
          // ── Sticky summary header ─────────────────────────────────────
          SliverToBoxAdapter(
            child: _StickyHeader(result: result),
          ),

          // ── Overdue alert ─────────────────────────────────────────────
          if (result.hasOverdue)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 0),
                child: _OverdueAlert(),
              ),
            ),

          // ── Section title ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
              child: Row(
                children: [
                  Text(
                    'Installments',
                    style: AppTypography.titleLarge.copyWith(
                      fontWeight: FontWeight.w700,
                      color: AppColors.grey800,
                    ),
                  ),
                  const SizedBox(width: 8),
                  _CountBadge(count: result.total),
                ],
              ),
            ),
          ),

          // ── Installment cards ─────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 40),
            sliver: SliverList.separated(
              itemCount: result.items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) {
                final ledger = result.items[i];
                return _InstallmentCard(
                  ledger: ledger,
                  index: i + 1,
                  canRecord: _canRecord,
                  studentId: studentId,
                  onViewHistory: () => context.push(
                    RouteNames.paymentHistory,
                    extra: {
                      'ledgerId': ledger.id,
                      'totalAmount': ledger.totalAmount,
                      'paidAmount': ledger.paidAmount,
                      'outstandingAmount': ledger.outstandingAmount,
                      'status': ledger.status.label,
                      'installmentName': ledger.displayLabel,
                      'dueDate': ledger.dueDate?.toIso8601String(),
                    },
                  ),
                  onPayNow: _canRecord && ledger.hasOutstanding
                      ? () async {
                          final result = await context.push<dynamic>(
                            RouteNames.recordPayment,
                            extra: {
                              'studentId': studentId,
                              'ledgerId': ledger.id,
                              'totalAmount': ledger.totalAmount,
                              'outstandingAmount': ledger.outstandingAmount,
                              'installmentName': ledger.displayLabel,
                              'dueDate': ledger.dueDate?.toIso8601String(),
                            },
                          );
                          if (result != null) {
                            ref.invalidate(feeDashboardProvider(
                              (
                                studentId: studentId,
                                academicYearId: academicYearId
                              ),
                            ));
                            if (context.mounted) {
                              context.push(
                                RouteNames.feeReceipt,
                                extra: {
                                  'paymentId': result.id.toString(),
                                  'amount': result.amount,
                                  'paymentDate': result.paymentDate,
                                  'paymentMode': result.paymentMode.label,
                                  'installmentName': ledger.displayLabel,
                                },
                              );
                            }
                          }
                        }
                      : null,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sticky Header ─────────────────────────────────────────────────────────────

class _StickyHeader extends StatelessWidget {
  const _StickyHeader({required this.result});
  final FeeDashboardResult result;

  @override
  Widget build(BuildContext context) {
    final pct = result.grandTotal > 0
        ? (result.grandPaid / result.grandTotal).clamp(0.0, 1.0)
        : 0.0;
    final pctColor = pct >= 1.0
        ? _kGreen
        : pct >= 0.5
            ? _kOrange
            : _kRed;

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF0B1F3A), Color(0xFF1A3558)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0B1F3A).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Total Fees',
                      style: AppTypography.bodySmall
                          .copyWith(color: AppColors.white54),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _fmt(result.grandTotal),
                      style: AppTypography.headlineMedium.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
              // Progress ring
              SizedBox(
                width: 72,
                height: 72,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    CircularProgressIndicator(
                      value: pct,
                      strokeWidth: 6,
                      backgroundColor: AppColors.white.withValues(alpha: 0.15),
                      valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                      strokeCap: StrokeCap.round,
                    ),
                    Text(
                      '${(pct * 100).toStringAsFixed(0)}%',
                      style: AppTypography.titleSmall.copyWith(
                        color: AppColors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HeaderStat(
                  label: 'Paid',
                  value: _fmt(result.grandPaid),
                  color: _kGreen,
                ),
              ),
              Expanded(
                child: _HeaderStat(
                  label: 'Outstanding',
                  value: _fmt(result.grandOutstanding),
                  color: result.grandOutstanding > 0 ? _kRed : _kGreen,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Progress bar
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: pct,
              minHeight: 7,
              backgroundColor: AppColors.white.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(pctColor),
            ),
          ),
        ],
      ),
    );
  }

  String _fmt(double v) {
    return '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }
}

class _HeaderStat extends StatelessWidget {
  const _HeaderStat(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.caption.copyWith(color: AppColors.white54)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.titleMedium
                .copyWith(color: color, fontWeight: FontWeight.w700)),
      ],
    );
  }
}

// ── Overdue Alert ─────────────────────────────────────────────────────────────

class _OverdueAlert extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: _kRedBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _kRed.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: _kRed, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'You have overdue installments. Please pay as soon as possible to avoid penalties.',
              style: AppTypography.bodySmall.copyWith(color: _kRed),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Installment Card ──────────────────────────────────────────────────────────

class _InstallmentCard extends StatelessWidget {
  const _InstallmentCard({
    required this.ledger,
    required this.index,
    required this.canRecord,
    required this.studentId,
    required this.onViewHistory,
    this.onPayNow,
  });

  final FeeLedgerModel ledger;
  final int index;
  final bool canRecord;
  final String studentId;
  final VoidCallback onViewHistory;
  final VoidCallback? onPayNow;

  Color get _statusColor => ledger.status.color;
  Color get _statusBg => ledger.status.bgColor;

  String _fmt(double v) =>
      '₹${v.toStringAsFixed(2).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: ledger.isOverdue
              ? _kRed.withValues(alpha: 0.3)
              : AppColors.surface200,
          width: ledger.isOverdue ? 1.5 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: _statusColor.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          // ── Header ──────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 0),
            child: Row(
              children: [
                // Status icon circle
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child:
                      Icon(ledger.status.icon, size: 18, color: _statusColor),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        ledger.displayLabel,
                        style: AppTypography.titleSmall.copyWith(
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey800,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (ledger.feeDescription != null &&
                          ledger.feeDescription!.isNotEmpty)
                        Text(
                          ledger.feeDescription!,
                          style: AppTypography.caption
                              .copyWith(color: AppColors.grey500),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Status badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _statusBg,
                    borderRadius: BorderRadius.circular(20),
                    border:
                        Border.all(color: _statusColor.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    ledger.status.label,
                    style: AppTypography.labelSmall.copyWith(
                      color: _statusColor,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Due date ─────────────────────────────────────────────────────
          if (ledger.dueDate != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
              child: Row(
                children: [
                  Icon(Icons.event_rounded, size: 13, color: AppColors.grey400),
                  const SizedBox(width: 4),
                  Text(
                    'Due: ${_fmtDate(ledger.dueDate!)}',
                    style: AppTypography.caption.copyWith(
                      color: ledger.isOverdue ? _kRed : AppColors.grey500,
                      fontWeight:
                          ledger.isOverdue ? FontWeight.w600 : FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),

          // ── Amount row ────────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: Row(
              children: [
                Expanded(
                  child: _AmountStat(
                    label: 'Total',
                    value: _fmt(ledger.totalAmount),
                    color: AppColors.grey700,
                  ),
                ),
                Expanded(
                  child: _AmountStat(
                    label: 'Paid',
                    value: _fmt(ledger.paidAmount),
                    color: _kGreen,
                  ),
                ),
                Expanded(
                  child: _AmountStat(
                    label: 'Due',
                    value: _fmt(ledger.outstandingAmount),
                    color: ledger.hasOutstanding ? _kRed : _kGreen,
                  ),
                ),
              ],
            ),
          ),

          // ── Progress bar ──────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: ledger.progressFraction,
                minHeight: 7,
                backgroundColor: AppColors.surface100,
                valueColor: AlwaysStoppedAnimation<Color>(
                  ledger.isFullyPaid ? _kGreen : AppColors.navyMedium,
                ),
              ),
            ),
          ),

          // ── Action buttons ────────────────────────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
            child: Row(
              children: [
                Expanded(
                  child: _ActionBtn(
                    icon: Icons.history_rounded,
                    label: 'History',
                    onTap: onViewHistory,
                    outlined: true,
                  ),
                ),
                if (onPayNow != null && ledger.hasOutstanding) ...[
                  const SizedBox(width: 10),
                  Expanded(
                    child: _ActionBtn(
                      icon: Icons.payments_rounded,
                      label: 'Pay Now',
                      onTap: onPayNow!,
                      outlined: false,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _fmtDate(DateTime d) {
    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec'
    ];
    return '${d.day} ${months[d.month - 1]} ${d.year}';
  }
}

class _AmountStat extends StatelessWidget {
  const _AmountStat(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.caption.copyWith(color: AppColors.grey400)),
        const SizedBox(height: 2),
        Text(value,
            style: AppTypography.labelMedium.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              fontSize: 13,
            )),
      ],
    );
  }
}

class _ActionBtn extends StatelessWidget {
  const _ActionBtn({
    required this.icon,
    required this.label,
    required this.onTap,
    required this.outlined,
  });
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool outlined;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 40,
        decoration: BoxDecoration(
          color: outlined ? AppColors.surface50 : AppColors.navyDeep,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: outlined ? AppColors.surface200 : AppColors.navyDeep,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon,
                size: 15,
                color: outlined ? AppColors.grey700 : AppColors.white),
            const SizedBox(width: 5),
            Text(
              label,
              style: AppTypography.labelMedium.copyWith(
                color: outlined ? AppColors.grey700 : AppColors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CountBadge extends StatelessWidget {
  const _CountBadge({required this.count});
  final int count;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: AppColors.navyDeep.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$count',
        style: AppTypography.labelMedium.copyWith(
          color: AppColors.navyDeep,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

// ── Principal Analytics Dashboard ────────────────────────────────────────────

class _PrincipalFeeAnalyticsDashboard extends ConsumerStatefulWidget {
  const _PrincipalFeeAnalyticsDashboard();

  @override
  ConsumerState<_PrincipalFeeAnalyticsDashboard> createState() =>
      _PrincipalFeeAnalyticsDashboardState();
}

class _PrincipalFeeAnalyticsDashboardState
    extends ConsumerState<_PrincipalFeeAnalyticsDashboard>
    with SingleTickerProviderStateMixin {
  late TabController _tabCtrl;
  String? _standardId;
  String? _section;
  String? _studentId;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  String _currency(dynamic v) {
    final d = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
    return '₹${d.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final activeYear = ref.watch(activeYearProvider);
    final activeYearId = activeYear?.id;

    final analyticsAsync = ref.watch(feeAnalyticsProvider((
      academicYearId: activeYearId,
      standardId: _standardId,
      section: _section,
      studentId: _studentId,
    )));

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(
        title: 'Fee Analytics',
        showBack: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => ref.invalidate(feeAnalyticsProvider),
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Tab bar ────────────────────────────────────────────────────
          Container(
            color: AppColors.white,
            child: TabBar(
              controller: _tabCtrl,
              labelStyle: AppTypography.labelLarge
                  .copyWith(fontWeight: FontWeight.w700),
              unselectedLabelStyle: AppTypography.labelLarge,
              labelColor: AppColors.navyDeep,
              unselectedLabelColor: AppColors.grey500,
              indicatorColor: AppColors.navyDeep,
              indicatorSize: TabBarIndicatorSize.label,
              tabs: const [
                Tab(text: 'Overview'),
                Tab(text: 'Classes'),
                Tab(text: 'Defaulters'),
              ],
            ),
          ),
          Expanded(
            child: analyticsAsync.when(
              data: (data) => TabBarView(
                controller: _tabCtrl,
                children: [
                  _OverviewTab(data: data, currency: _currency),
                  _ClassesTab(data: data, currency: _currency),
                  _DefaultersTab(data: data),
                ],
              ),
              loading: () => AppLoading.fullPage(),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref.invalidate(feeAnalyticsProvider),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Overview Tab ──────────────────────────────────────────────────────────────

class _OverviewTab extends StatelessWidget {
  const _OverviewTab({required this.data, required this.currency});
  final Map<String, dynamic> data;
  final String Function(dynamic) currency;

  @override
  Widget build(BuildContext context) {
    final summary = data['summary'] as Map<String, dynamic>? ?? {};
    final byStatus = data['by_status'] as List<dynamic>? ?? [];
    final byMode = data['by_payment_mode'] as List<dynamic>? ?? [];

    final collected = summary['total_paid_amount'];
    final pending = summary['total_outstanding_amount'];
    final defaulters =
        summary['defaulters_count'] ?? summary['overdue_ledgers'] ?? 0;
    final pct = (summary['collection_percentage'] as num?)?.toDouble() ?? 0.0;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── KPI cards row ─────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _KpiCard(
                label: 'Collected',
                value: currency(collected),
                icon: Icons.check_circle_rounded,
                color: _kGreen,
                bg: _kGreenBg,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                label: 'Pending',
                value: currency(pending),
                icon: Icons.pending_rounded,
                color: _kOrange,
                bg: _kOrangeBg,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _KpiCard(
                label: 'Defaulters',
                value: '$defaulters',
                icon: Icons.warning_amber_rounded,
                color: _kRed,
                bg: _kRedBg,
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),

        // ── Collection % card ─────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: AppColors.navyDeep.withValues(alpha: 0.05),
                blurRadius: 10,
              )
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Collection Rate',
                      style: AppTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.w700)),
                  Text(
                    '${pct.toStringAsFixed(1)}%',
                    style: AppTypography.titleMedium.copyWith(
                      color: pct >= 80
                          ? _kGreen
                          : pct >= 50
                              ? _kOrange
                              : _kRed,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: (pct / 100).clamp(0.0, 1.0),
                  minHeight: 10,
                  backgroundColor: AppColors.surface100,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    pct >= 80
                        ? _kGreen
                        : pct >= 50
                            ? _kOrange
                            : _kRed,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  _InlineStat(
                      label: 'Billed',
                      value: currency(summary['total_billed_amount'])),
                  const SizedBox(width: 20),
                  _InlineStat(
                      label: 'Paid',
                      value: currency(summary['total_paid_amount'])),
                  const SizedBox(width: 20),
                  _InlineStat(
                      label: 'Students',
                      value: '${summary['total_students'] ?? 0}'),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),

        // ── Status breakdown ──────────────────────────────────────────
        if (byStatus.isNotEmpty) ...[
          Text('By Status',
              style: AppTypography.titleSmall
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...byStatus.map((s) {
            final m = s as Map<String, dynamic>;
            final st = (m['status'] as String? ?? '').toUpperCase();
            final color = st == 'PAID'
                ? _kGreen
                : st == 'PARTIAL'
                    ? _kOrange
                    : st == 'OVERDUE'
                        ? _kRed
                        : AppColors.grey500;
            return _StatusRow(
              label: _titleCase(st),
              count: m['ledgers'] as int? ?? 0,
              amount: currency(m['paid_amount']),
              color: color,
            );
          }),
          const SizedBox(height: 20),
        ],

        // ── Payment mode breakdown ────────────────────────────────────
        if (byMode.isNotEmpty) ...[
          Text('By Payment Mode',
              style: AppTypography.titleSmall
                  .copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 10),
          ...byMode.map((m) {
            final mp = m as Map<String, dynamic>;
            return _ModeRow(
              mode: _titleCase(mp['payment_mode'] as String? ?? ''),
              amount: currency(mp['amount']),
              txns: mp['transactions'] as int? ?? 0,
            );
          }),
        ],
      ],
    );
  }

  String _titleCase(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1).toLowerCase();
}

// ── Classes Tab ───────────────────────────────────────────────────────────────

class _ClassesTab extends StatelessWidget {
  const _ClassesTab({required this.data, required this.currency});
  final Map<String, dynamic> data;
  final String Function(dynamic) currency;

  @override
  Widget build(BuildContext context) {
    final byClass = data['by_class'] as List<dynamic>? ?? [];

    if (byClass.isEmpty) {
      return const AppEmptyState(
        icon: Icons.class_outlined,
        title: 'No class data',
        subtitle: 'Class-wise analytics will appear once fees are generated.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: byClass.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) {
        final c = byClass[i] as Map<String, dynamic>;
        final billed = (c['total_billed'] as num?)?.toDouble() ?? 0.0;
        final paid = (c['total_paid'] as num?)?.toDouble() ?? 0.0;
        final pct = billed > 0 ? (paid / billed).clamp(0.0, 1.0) : 0.0;
        final pctColor = pct >= 0.8
            ? _kGreen
            : pct >= 0.5
                ? _kOrange
                : _kRed;
        final section = c['section'] as String?;
        final classLabel = section != null && section.isNotEmpty
            ? '${c['standard_name']} – $section'
            : c['standard_name'] as String? ?? '—';

        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: AppColors.navyDeep.withValues(alpha: 0.04),
                  blurRadius: 8)
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(classLabel,
                        style: AppTypography.titleSmall
                            .copyWith(fontWeight: FontWeight.w700)),
                  ),
                  Text(
                    '${(pct * 100).toStringAsFixed(0)}%',
                    style: AppTypography.titleSmall
                        .copyWith(color: pctColor, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(5),
                child: LinearProgressIndicator(
                  value: pct,
                  minHeight: 7,
                  backgroundColor: AppColors.surface100,
                  valueColor: AlwaysStoppedAnimation<Color>(pctColor),
                ),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text('${c['total_students'] ?? 0} students',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.grey500)),
                  const Spacer(),
                  if ((c['defaulters_count'] as int? ?? 0) > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: _kRedBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        '${c['defaulters_count']} overdue',
                        style: AppTypography.caption.copyWith(
                            color: _kRed, fontWeight: FontWeight.w600),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${currency(paid)} / ${currency(billed)}',
                    style: AppTypography.caption.copyWith(
                        color: AppColors.grey600, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Defaulters Tab ────────────────────────────────────────────────────────────

class _DefaultersTab extends StatelessWidget {
  const _DefaultersTab({required this.data});
  final Map<String, dynamic> data;

  String _currency(dynamic v) {
    final d = (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0;
    return '₹${d.toStringAsFixed(0).replaceAllMapped(RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'), (m) => '${m[1]},')}';
  }

  @override
  Widget build(BuildContext context) {
    final byStudent = data['by_student'] as List<dynamic>? ?? [];
    final defaulters =
        byStudent.where((s) => (s as Map)['is_defaulter'] == true).toList();

    if (defaulters.isEmpty) {
      return const AppEmptyState(
        icon: Icons.check_circle_outline,
        title: 'No Defaulters',
        subtitle: 'All students are up to date with their fee payments.',
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: defaulters.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final s = defaulters[i] as Map<String, dynamic>;
        return Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: _kRed.withValues(alpha: 0.2)),
            boxShadow: [
              BoxShadow(color: _kRed.withValues(alpha: 0.04), blurRadius: 8)
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _kRedBg,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.warning_amber_rounded,
                    size: 18, color: _kRed),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s['admission_number'] as String? ?? '—',
                      style: AppTypography.titleSmall
                          .copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      'Overdue: ${s['overdue_ledgers']} installment(s)',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.grey500),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _currency(s['outstanding_amount']),
                    style: AppTypography.titleSmall
                        .copyWith(color: _kRed, fontWeight: FontWeight.w700),
                  ),
                  Text('outstanding',
                      style: AppTypography.caption
                          .copyWith(color: AppColors.grey400, fontSize: 10)),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ── Shared helper widgets ─────────────────────────────────────────────────────

class _KpiCard extends StatelessWidget {
  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.08), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(height: 10),
          Text(value,
              style: AppTypography.titleMedium.copyWith(
                  color: color, fontWeight: FontWeight.w800, fontSize: 16)),
          const SizedBox(height: 2),
          Text(label,
              style: AppTypography.caption.copyWith(color: AppColors.grey500)),
        ],
      ),
    );
  }
}

class _InlineStat extends StatelessWidget {
  const _InlineStat({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: AppTypography.caption.copyWith(color: AppColors.grey400)),
        Text(value,
            style: AppTypography.labelMedium
                .copyWith(fontWeight: FontWeight.w700)),
      ],
    );
  }
}

class _StatusRow extends StatelessWidget {
  const _StatusRow({
    required this.label,
    required this.count,
    required this.amount,
    required this.color,
  });
  final String label;
  final int count;
  final String amount;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: AppColors.navyDeep.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(label,
                style: AppTypography.bodySmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Text('$count entries',
              style: AppTypography.caption.copyWith(color: AppColors.grey500)),
          const SizedBox(width: 10),
          Text(amount,
              style: AppTypography.labelMedium
                  .copyWith(color: color, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _ModeRow extends StatelessWidget {
  const _ModeRow(
      {required this.mode, required this.amount, required this.txns});
  final String mode;
  final String amount;
  final int txns;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
              color: AppColors.navyDeep.withValues(alpha: 0.04), blurRadius: 6)
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(mode,
                style: AppTypography.bodySmall
                    .copyWith(fontWeight: FontWeight.w600)),
          ),
          Text('$txns txns',
              style: AppTypography.caption.copyWith(color: AppColors.grey500)),
          const SizedBox(width: 12),
          Text(amount,
              style: AppTypography.labelMedium
                  .copyWith(fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}
