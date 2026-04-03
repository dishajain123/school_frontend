import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_dimensions.dart';
import '../../../../core/theme/app_typography.dart';
import '../../../../providers/academic_year_provider.dart';
import '../../../../providers/leave_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../../common/widgets/app_scaffold.dart'; 
import '../widgets/balance_tile.dart';

class LeaveBalanceScreen extends ConsumerWidget {
  const LeaveBalanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeYear = ref.watch(activeYearProvider);
    final balanceAsync = ref.watch(leaveBalanceProvider(activeYear?.id));

    return AppScaffold(
      appBar: const AppAppBar(
        title: 'Leave Balance',
        showBack: true,
        showNotificationBell: false,
      ),
      body: balanceAsync.when(
        loading: () => AppLoading.listView(count: 4, withAvatar: false),
        error: (e, _) => AppErrorState(
          message: e.toString(),
          onRetry: () => ref.invalidate(leaveBalanceProvider(activeYear?.id)),
        ),
        data: (balances) {
          if (balances.isEmpty) {
            return const AppEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              title: 'No leave balance',
              subtitle:
                  'Leave balances have not been configured yet. Contact your principal.',
            );
          }

          // Summary stats
          final totalAllocated = balances.fold<double>(
            0,
            (sum, b) => sum + b.totalDays,
          );
          final totalUsed = balances.fold<double>(
            0,
            (sum, b) => sum + b.usedDays,
          );
          final totalRemaining = balances.fold<double>(
            0,
            (sum, b) => sum + b.remainingDays,
          );

          return RefreshIndicator(
            color: AppColors.navyDeep,
            onRefresh: () async =>
                ref.invalidate(leaveBalanceProvider(activeYear?.id)),
            child: CustomScrollView(
              slivers: [
                // ── Summary card ───────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.space16,
                      AppDimensions.space20,
                      AppDimensions.space16,
                      AppDimensions.space4,
                    ),
                    child: _SummaryCard(
                      totalAllocated: totalAllocated,
                      totalUsed: totalUsed,
                      totalRemaining: totalRemaining,
                      academicYearName: activeYear?.name,
                    ),
                  ),
                ),

                // ── Section header ─────────────────────────────────────────
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppDimensions.space16,
                      AppDimensions.space20,
                      AppDimensions.space16,
                      AppDimensions.space12,
                    ),
                    child: Text(
                      'By Leave Type',
                      style: AppTypography.headlineSmall,
                    ),
                  ),
                ),

                // ── Balance tiles ──────────────────────────────────────────
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(
                    AppDimensions.space16,
                    0,
                    AppDimensions.space16,
                    AppDimensions.pageBottomScroll,
                  ),
                  sliver: SliverList.separated(
                    itemCount: balances.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.space12),
                    itemBuilder: (_, index) {
                        final b = balances[index];
                        return BalanceTile(
                          leaveType: b.leaveType.toString().split('.').last,
                          balance: b.remainingDays,
                          total: b.totalDays,
                          used: b.usedDays,
                        );
                      },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

// ── Summary Card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.totalAllocated,
    required this.totalUsed,
    required this.totalRemaining,
    this.academicYearName,
  });

  final double totalAllocated;
  final double totalUsed;
  final double totalRemaining;
  final String? academicYearName;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppDimensions.space20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppColors.navyDeep, AppColors.navyMedium],
        ),
        borderRadius: BorderRadius.circular(AppDimensions.radiusLarge),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.beach_access_outlined,
                color: AppColors.goldPrimary,
                size: AppDimensions.iconSM,
              ),
              const SizedBox(width: AppDimensions.space8),
              Expanded(
                child: Text(
                  academicYearName != null
                      ? 'Leave Summary · $academicYearName'
                      : 'Leave Summary',
                  style: AppTypography.labelMedium.copyWith(
                    color: AppColors.white.withValues(alpha: 0.8),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          Row(
            children: [
              Expanded(
                child: _SummaryMetric(
                  label: 'Allocated',
                  value: totalAllocated.toStringAsFixed(0),
                  color: AppColors.white,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'Used',
                  value: totalUsed.toStringAsFixed(0),
                  color: AppColors.warningAmber,
                ),
              ),
              Expanded(
                child: _SummaryMetric(
                  label: 'Remaining',
                  value: totalRemaining.toStringAsFixed(0),
                  color: AppColors.successGreen,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SummaryMetric extends StatelessWidget {
  const _SummaryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          value,
          style: AppTypography.headlineMedium.copyWith(
            color: color,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: AppColors.white.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}