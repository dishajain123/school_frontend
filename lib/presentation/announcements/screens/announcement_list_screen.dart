import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/router/route_names.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../data/models/announcement/announcement_model.dart';
import '../../../data/models/auth/current_user.dart';
import '../../../providers/announcement_provider.dart';
import '../../../providers/auth_provider.dart';
import '../../common/widgets/app_app_bar.dart';
import '../../common/widgets/app_empty_state.dart';
import '../../common/widgets/app_error_state.dart';
import '../../common/widgets/app_loading.dart';
import '../widgets/announcement_card.dart';

class AnnouncementListScreen extends ConsumerStatefulWidget {
  const AnnouncementListScreen({super.key});

  @override
  ConsumerState<AnnouncementListScreen> createState() =>
      _AnnouncementListScreenState();
}

class _AnnouncementListScreenState
    extends ConsumerState<AnnouncementListScreen> {
  AnnouncementType? _selectedType;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(announcementNotifierProvider.notifier).refresh();
    });
  }

  bool _canCreate(CurrentUser? user) {
    if (user == null) return false;
    return user.hasPermission('announcement:create');
  }

  @override
  Widget build(BuildContext context) {
    final announcements = ref.watch(announcementNotifierProvider);
    final user = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: AppColors.surface50,
      appBar: AppAppBar(title: 'Announcements'),
      floatingActionButton: _canCreate(user)
          ? FloatingActionButton(
              onPressed: () => context.push(RouteNames.createAnnouncement),
              child: const Icon(Icons.add),
            )
          : null,
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(
            child: announcements.when(
              loading: () => AppLoading.listView(),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () => ref
                    .read(announcementNotifierProvider.notifier)
                    .refresh(),
              ),
              data: (items) {
                final filtered = _selectedType == null
                    ? items
                    : items
                        .where((a) => a.type == _selectedType)
                        .toList();

                if (filtered.isEmpty) {
                  return const AppEmptyState(
                    title: 'No announcements',
                    subtitle: 'Announcements will appear here.',
                    icon: Icons.campaign_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => ref
                      .read(announcementNotifierProvider.notifier)
                      .refresh(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(AppDimensions.space16),
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) =>
                        const SizedBox(height: AppDimensions.space12),
                    itemBuilder: (context, index) {
                      final announcement = filtered[index];
                      return AnnouncementCard(
                        announcement: announcement,
                        onTap: () => context.push(
                          RouteNames.announcementDetailPath(announcement.id),
                          extra: announcement,
                        ),
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterBar() {
    final types = [null, ...AnnouncementType.values];
    return Container(
      height: 48,
      color: AppColors.white,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppDimensions.space16,
          vertical: AppDimensions.space8,
        ),
        itemCount: types.length,
        separatorBuilder: (_, __) =>
            const SizedBox(width: AppDimensions.space8),
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = _selectedType == type;
          final label = type?.label ?? 'All';
          return GestureDetector(
            onTap: () => setState(() => _selectedType = type),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(
                horizontal: AppDimensions.space12,
                vertical: AppDimensions.space4,
              ),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.navyDeep
                    : AppColors.surface100,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
              child: Text(
                label,
                style: AppTypography.labelMedium.copyWith(
                  color: isSelected
                      ? AppColors.white
                      : AppColors.grey800,
                  fontWeight:
                      isSelected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}