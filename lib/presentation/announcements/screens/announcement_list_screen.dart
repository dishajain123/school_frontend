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
    extends ConsumerState<AnnouncementListScreen>
    with SingleTickerProviderStateMixin {
  AnnouncementType? _selectedType;
  late AnimationController _fabCtrl;
  late Animation<double> _fabScale;

  @override
  void initState() {
    super.initState();
    _fabCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 350),
    );
    _fabScale = CurvedAnimation(parent: _fabCtrl, curve: Curves.elasticOut);
    _fabCtrl.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(announcementNotifierProvider.notifier).refresh();
    });
  }

  @override
  void dispose() {
    _fabCtrl.dispose();
    super.dispose();
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
      appBar: AppAppBar(
        title: 'Announcements',
        actions: [
          if (_canCreate(user))
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: IconButton(
                onPressed: () => context.push(RouteNames.createAnnouncement),
                tooltip: 'New Announcement',
                icon: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: AppColors.white.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.add_rounded,
                      color: AppColors.white, size: 20),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          _TypeFilterBar(
            selectedType: _selectedType,
            onSelected: (type) => setState(() => _selectedType = type),
          ),
          Container(height: 1, color: AppColors.surface100),
          Expanded(
            child: announcements.when(
              loading: () => _buildShimmer(),
              error: (e, _) => AppErrorState(
                message: e.toString(),
                onRetry: () =>
                    ref.read(announcementNotifierProvider.notifier).refresh(),
              ),
              data: (items) {
                final filtered = _selectedType == null
                    ? items
                    : items.where((a) => a.type == _selectedType).toList();

                if (filtered.isEmpty) {
                  return AppEmptyState(
                    title: _selectedType == null
                        ? 'No announcements'
                        : 'No ${_selectedType!.label} announcements',
                    subtitle: 'Announcements will appear here.',
                    icon: Icons.campaign_outlined,
                  );
                }

                return RefreshIndicator(
                  onRefresh: () =>
                      ref.read(announcementNotifierProvider.notifier).refresh(),
                  color: AppColors.navyDeep,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 80),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final announcement = filtered[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: AnnouncementCard(
                          announcement: announcement,
                          onTap: () => context.push(
                            RouteNames.announcementDetailPath(announcement.id),
                            extra: announcement,
                          ),
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

  Widget _buildShimmer() {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      itemCount: 5,
      itemBuilder: (_, __) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: AppLoading.card(height: 110),
      ),
    );
  }
}

class _TypeFilterBar extends StatelessWidget {
  const _TypeFilterBar({required this.selectedType, required this.onSelected});
  final AnnouncementType? selectedType;
  final ValueChanged<AnnouncementType?> onSelected;

  @override
  Widget build(BuildContext context) {
    final types = [null, ...AnnouncementType.values];

    return Container(
      height: 50,
      color: AppColors.white,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        itemCount: types.length,
        itemBuilder: (context, index) {
          final type = types[index];
          final isSelected = selectedType == type;
          final label = type?.label ?? 'All';
          final color = type?.color ?? AppColors.navyDeep;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(type),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: isSelected
                      ? (type != null
                          ? color.withValues(alpha: 0.12)
                          : AppColors.navyDeep)
                      : AppColors.surface100,
                  borderRadius: BorderRadius.circular(20),
                  border: isSelected && type != null
                      ? Border.all(color: color.withValues(alpha: 0.4))
                      : null,
                  boxShadow: isSelected && type == null
                      ? [
                          BoxShadow(
                            color: AppColors.navyDeep.withValues(alpha: 0.2),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          )
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (type != null) ...[
                      Icon(type.icon,
                          size: 12,
                          color: isSelected ? color : AppColors.grey500),
                      const SizedBox(width: 5),
                    ],
                    Text(
                      label,
                      style: AppTypography.labelMedium.copyWith(
                        color: isSelected
                            ? (type != null ? color : AppColors.white)
                            : AppColors.grey600,
                        fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}