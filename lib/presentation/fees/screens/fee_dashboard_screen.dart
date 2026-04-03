import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_decorations.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../data/models/fee/fee_ledger_model.dart';
import '../../../providers/auth_provider.dart';
import '../../../providers/fee_provider.dart';
import '../../../providers/parent_provider.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_section_header.dart';
import '../widgets/fee_ledger_card.dart';
import '../widgets/fee_summary_bar.dart';

class FeeDashboardScreen extends ConsumerWidget {
  const FeeDashboardScreen({super.key, this.studentId});

  /// Explicit studentId for admin roles navigating from a student profile.
  final String? studentId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const SizedBox.shrink();

    // ── Resolve studentId based on role ──────────────────────────────────────
    switch (user.role) {
      case UserRole.parent:
        return _ParentFeeDashboard(explicitStudentId: studentId);
      case UserRole.student:
        return _StudentFeeDashboard(explicitStudentId: studentId);
      default:
        // Admin/Principal/Trustee/Teacher must supply studentId via route param.
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
      appBar: AppBar(title: const Text('Fee Management')),
      body: AppEmptyState(
        icon: Icons.account_balance_wallet_outlined,
        title: 'No Student Selected',
        subtitle:
            'Please access fee details from a student\'s profile page.',
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
    final childId =
        explicitStudentId ?? ref.watch(selectedChildIdProvider);

    if (childId == null || childId.isEmpty) {
      return Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppBar(title: const Text('Fee Management')),
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
        appBar: AppBar(title: const Text('Fee Management')),
        body: AppLoading.fullPage(),
      ),
      error: (e, _) => Scaffold(
        backgroundColor: AppColors.surface50,
        appBar: AppBar(title: const Text('Fee Management')),
        body: AppErrorState(
          message: 'Could not load your student profile.',
          onRetry: () => ref.invalidate(myStudentIdProvider),
        ),
      ),
      data: (id) {
        if (id == null) {
          return Scaffold(
            backgroundColor: AppColors.surface50,
            appBar: AppBar(title: const Text('Fee Management')),
            body: const AppEmptyState(
              icon: Icons.school_outlined,
              title: 'Profile Not Found',
              subtitle: 'Your student profile could not be located. '
                  'Please contact your school administrator.',
            ),
          );
        }
        return _FeeDashboardBody(studentId: id, user: user);
      },
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
      appBar: AppBar(
        title: const Text('Fee Management'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () =>
                ref.invalidate(feeDashboardProvider(studentId)),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async =>
            ref.invalidate(feeDashboardProvider(studentId)),
        child: dashAsync.when(
          loading: () => _buildSkeleton(),
          error: (e, _) => AppErrorState(
            message: e.toString(),
            onRetry: () =>
                ref.invalidate(feeDashboardProvider(studentId)),
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
      padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
      children: [
        const SizedBox(height: AppDimensions.space8),

        // ── Summary bar ────────────────────────────────────────────────────
        FeeSummaryBar(
          totalAmount: result.grandTotal,
          paidAmount: result.grandPaid,
          outstandingAmount: result.grandOutstanding,
        ),

        const SizedBox(height: AppDimensions.space24),

        // ── Ledger list header ─────────────────────────────────────────────
        AppSectionHeader(
          title: 'Fee Entries (${result.total})',
        ),

        const SizedBox(height: AppDimensions.space12),

        // ── Ledger cards ───────────────────────────────────────────────────
        ...result.items.asMap().entries.map((entry) {
          final index = entry.key;
          final ledger = entry.value;
          return Padding(
            padding:
                const EdgeInsets.only(bottom: AppDimensions.space12),
            child: FeeLedgerCard(
              ledger: ledger,
              sequenceNumber: index + 1,
              onViewHistory: () => context.push(
                RouteNames.paymentHistory,
                extra: {
                  'ledgerId': ledger.id,
                  'totalAmount': ledger.totalAmount,
                  'paidAmount': ledger.paidAmount,
                  'outstandingAmount': ledger.outstandingAmount,
                  'status': ledger.status.label,
                },
              ),
              onPayNow: _canRecord && ledger.hasOutstanding
                  ? () => context.push(
                        RouteNames.recordPayment,
                        extra: {
                          'studentId': studentId,
                          'ledgerId': ledger.id,
                          'outstandingAmount': ledger.outstandingAmount,
                          'totalAmount': ledger.totalAmount,
                        },
                      )
                  : null,
            ),
          );
        }),

        const SizedBox(height: AppDimensions.space40),
      ],
    );
  }

  Widget _buildSkeleton() {
    return ListView(
      padding: const EdgeInsets.all(AppDimensions.pageHorizontal),
      children: [
        const SizedBox(height: AppDimensions.space8),
        Container(
          height: 140,
          decoration: BoxDecoration(
            color: AppColors.surface100,
            borderRadius:
                BorderRadius.circular(AppDimensions.radiusLarge),
          ),
        ),
        const SizedBox(height: AppDimensions.space24),
        ...List.generate(
          3,
          (_) => Padding(
            padding:
                const EdgeInsets.only(bottom: AppDimensions.space12),
            child: AppLoading.card(),
          ),
        ),
      ],
    );
  }
} 
