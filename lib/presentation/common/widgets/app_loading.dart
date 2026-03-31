import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

/// Shimmer skeleton loaders for various content shapes.
///
/// Always use these instead of full-screen spinners to show loading state.
///
/// Usage:
/// ```dart
/// AsyncValue<List<Item>> items = ref.watch(itemsProvider);
/// items.when(
///   loading: () => AppLoading.listView(),
///   error: (e, _) => AppErrorState(message: e.toString(), onRetry: ...),
///   data: (list) => ListView(children: [...]),
/// );
/// ```
class AppLoading extends StatelessWidget {
  const AppLoading._({
    super.key,
    required this.child,
  });

  /// Shimmer wrapper — use named constructors instead.
  static Widget _shimmer({required Widget child}) {
    return Shimmer.fromColors(
      baseColor: AppColors.surface100,
      highlightColor: AppColors.white,
      period: const Duration(milliseconds: 1500),
      child: child,
    );
  }

  // ── Named constructors ─────────────────────────────────────────────────────

  /// A single shimmer tile matching the shape of [AppListTile].
  static Widget listTile({bool withAvatar = true}) {
    return _shimmer(
      child: _ShimmerListTile(withAvatar: withAvatar),
    );
  }

  /// Multiple stacked shimmer tiles — pass [count] to control how many.
  static Widget listView({int count = 6, bool withAvatar = true}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontal,
        vertical: AppDimensions.pageVertical,
      ),
      child: Column(
        children: List.generate(
          count,
          (i) => Padding(
            padding: const EdgeInsets.only(bottom: AppDimensions.space8),
            child: _shimmer(
              child: _ShimmerListTile(withAvatar: withAvatar),
            ),
          ),
        ),
      ),
    );
  }

  /// A shimmer block matching the shape of a card.
  static Widget card({double? height}) {
    return _shimmer(child: _ShimmerCard(height: height));
  }

  /// Two-column grid of shimmer cards.
  static Widget grid({int count = 4}) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontal,
        vertical: AppDimensions.pageVertical,
      ),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: AppDimensions.gridGap2col,
          mainAxisSpacing: AppDimensions.gridGap2col,
          childAspectRatio: 1.4,
        ),
        itemCount: count,
        itemBuilder: (_, __) => _shimmer(
          child: Container(
            decoration: BoxDecoration(
              color: AppColors.white,
              borderRadius:
                  BorderRadius.circular(AppDimensions.radiusMedium),
            ),
          ),
        ),
      ),
    );
  }

  /// Centered adaptive spinner for full-page initial loads.
  static Widget fullPage() {
    return const Center(
      child: CircularProgressIndicator.adaptive(
        valueColor: AlwaysStoppedAnimation<Color>(AppColors.navyMedium),
      ),
    );
  }

  /// Slim shimmer bar — for bottom-of-list "loading more" indicators.
  static Widget paginating() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
      child: Center(
        child: SizedBox(
          width: 24,
          height: 24,
          child: CircularProgressIndicator.adaptive(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.navyMedium.withValues(alpha: 0.7),
            ),
          ),
        ),
      ),
    );
  }

  /// Shimmer for a stat card (small rectangular block).
  static Widget statCard() {
    return _shimmer(child: const _ShimmerCard(height: 90));
  }

  /// Dashboard shimmer (greeting + quick actions + cards).
  static Widget dashboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontal,
        vertical: AppDimensions.pageVertical,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmer(child: const _ShimmerCard(height: 100)),
          const SizedBox(height: AppDimensions.space16),
          _shimmer(child: const _ShimmerCard(height: 56)),
          const SizedBox(height: AppDimensions.space16),
          Row(
            children: [
              Expanded(child: _shimmer(child: const _ShimmerCard(height: 80))),
              const SizedBox(width: AppDimensions.gridGap2col),
              Expanded(child: _shimmer(child: const _ShimmerCard(height: 80))),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.space8),
              child: _shimmer(child: const _ShimmerListTile()),
            ),
          ),
        ],
      ),
    );
  }

  final Widget child;

  @override
  Widget build(BuildContext context) => child;
}

// ── Internal shimmer shape widgets ─────────────────────────────────────────

class _ShimmerListTile extends StatelessWidget {
  const _ShimmerListTile({this.withAvatar = true});

  final bool withAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.space16,
        vertical: AppDimensions.space12,
      ),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
      child: Row(
        children: [
          if (withAvatar) ...[
            Container(
              width: AppDimensions.avatarMd,
              height: AppDimensions.avatarMd,
              decoration: const BoxDecoration(
                color: AppColors.surface200,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: AppDimensions.space12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 14,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: AppColors.surface200,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
                  ),
                ),
                const SizedBox(height: AppDimensions.space8),
                Container(
                  height: 12,
                  width: 160,
                  decoration: BoxDecoration(
                    color: AppColors.surface200,
                    borderRadius:
                        BorderRadius.circular(AppDimensions.radiusSmall),
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

class _ShimmerCard extends StatelessWidget {
  const _ShimmerCard({this.height = 120});

  final double? height;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: height,
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusMedium),
      ),
    );
  }
}