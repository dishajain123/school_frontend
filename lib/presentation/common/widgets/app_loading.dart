import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';

class AppLoading extends StatelessWidget {
  const AppLoading._({super.key, required this.child});

  static Widget _shimmer({required Widget child}) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFEEF0F3),
      highlightColor: AppColors.white,
      period: const Duration(milliseconds: 1400),
      child: child,
    );
  }

  static Widget listTile({bool withAvatar = true}) {
    return _shimmer(child: _ShimmerListTile(withAvatar: withAvatar));
  }

  static Widget listView({
    int count = 6,
    bool withAvatar = true,
    double? width,
  }) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontal,
        vertical: AppDimensions.pageVertical,
      ),
      itemCount: count,
      separatorBuilder: (_, __) =>
          const SizedBox(height: AppDimensions.space12),
      itemBuilder: (_, __) => Align(
        alignment: Alignment.topCenter,
        child: SizedBox(
          width: width,
          child: _shimmer(child: _ShimmerListTile(withAvatar: withAvatar)),
        ),
      ),
    );
  }

  static Widget card({double? height}) {
    return _shimmer(child: _ShimmerCard(height: height));
  }

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
              borderRadius: BorderRadius.circular(14),
            ),
          ),
        ),
      ),
    );
  }

  static Widget fullPage() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 32,
            height: 32,
            child: CircularProgressIndicator.adaptive(
              strokeWidth: 2.5,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.navyMedium),
            ),
          ),
        ],
      ),
    );
  }

  static Widget paginating() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppDimensions.space16),
      child: Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator.adaptive(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(
              AppColors.navyMedium.withValues(alpha: 0.6),
            ),
          ),
        ),
      ),
    );
  }

  static Widget statCard() {
    return _shimmer(child: const _ShimmerCard(height: 96));
  }

  static Widget dashboard() {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppDimensions.pageHorizontal,
        vertical: AppDimensions.pageVertical,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _shimmer(child: const _ShimmerCard(height: 110)),
          const SizedBox(height: AppDimensions.space16),
          Row(
            children: [
              Expanded(child: _shimmer(child: const _ShimmerCard(height: 90))),
              const SizedBox(width: AppDimensions.gridGap2col),
              Expanded(child: _shimmer(child: const _ShimmerCard(height: 90))),
              const SizedBox(width: AppDimensions.gridGap2col),
              Expanded(child: _shimmer(child: const _ShimmerCard(height: 90))),
            ],
          ),
          const SizedBox(height: AppDimensions.space16),
          _shimmer(child: const _ShimmerCard(height: 56)),
          const SizedBox(height: AppDimensions.space16),
          ...List.generate(
            3,
            (i) => Padding(
              padding: const EdgeInsets.only(bottom: AppDimensions.space12),
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

class _ShimmerListTile extends StatelessWidget {
  const _ShimmerListTile({this.withAvatar = true});
  final bool withAvatar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: AppColors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          if (withAvatar) ...[
            Container(
              width: 44,
              height: 44,
              decoration: const BoxDecoration(
                color: Color(0xFFEEF0F3),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  height: 13,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0F3),
                    borderRadius: BorderRadius.circular(6),
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  height: 11,
                  width: 140,
                  decoration: BoxDecoration(
                    color: const Color(0xFFEEF0F3),
                    borderRadius: BorderRadius.circular(6),
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
        borderRadius: BorderRadius.circular(14),
      ),
    );
  }
}
