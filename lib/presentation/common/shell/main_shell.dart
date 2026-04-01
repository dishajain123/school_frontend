import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_dimensions.dart';
import '../../../core/theme/app_typography.dart';
import '../../../providers/notification_provider.dart';
import 'role_shell_config.dart';

final shellTabIndexProvider = StateProvider<int>((ref) => 0);

class MainShell extends ConsumerStatefulWidget {
  const MainShell({
    super.key,
    required this.child,
    required this.role,
  });

  final Widget child;
  final String role;

  @override
  ConsumerState<MainShell> createState() => _MainShellState();
}

class _MainShellState extends ConsumerState<MainShell>
    with TickerProviderStateMixin {
  late final List<ShellTabItem> _tabs;
  late int _currentIndex;
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;
  late final List<bool> _tabInitialized;
  late AnimationController _indicatorController;

  @override
  void initState() {
    super.initState();
    _tabs = RoleShellConfig.tabsForRole(widget.role);
    _currentIndex = 0;
    _navigatorKeys =
        List.generate(_tabs.length, (_) => GlobalKey<NavigatorState>());
    _tabInitialized = List.filled(_tabs.length, false);
    _tabInitialized[0] = true;

    _indicatorController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 200),
    )..forward();

    // Load notification count on shell init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationNotifierProvider.notifier).loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _indicatorController.dispose();
    super.dispose();
  }

  void _onTabTapped(int index, BuildContext context) {
    if (index == _currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _tabInitialized[index] = true;
      _currentIndex = index;
    });

    ref.read(shellTabIndexProvider.notifier).state = index;
    _indicatorController
      ..reset()
      ..forward();

    context.go(_tabs[index].rootPath);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: widget.child,
      bottomNavigationBar: _BottomNav(
        tabs: _tabs,
        currentIndex: _currentIndex,
        indicatorController: _indicatorController,
        onTabTapped: (i) => _onTabTapped(i, context),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
    required this.tabs,
    required this.currentIndex,
    required this.indicatorController,
    required this.onTabTapped,
  });

  final List<ShellTabItem> tabs;
  final int currentIndex;
  final AnimationController indicatorController;
  final ValueChanged<int> onTabTapped;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Color(0x0D0B1F3A),
            blurRadius: 8,
            offset: Offset(0, -2),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: AppDimensions.bottomNavHeight,
          child: Row(
            children: List.generate(tabs.length, (i) {
              return Expanded(
                child: _NavItem(
                  tab: tabs[i],
                  isSelected: i == currentIndex,
                  indicatorController: indicatorController,
                  onTap: () => onTabTapped(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.tab,
    required this.isSelected,
    required this.indicatorController,
    required this.onTap,
  });

  final ShellTabItem tab;
  final bool isSelected;
  final AnimationController indicatorController;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(vertical: AppDimensions.space8),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              curve: Curves.easeOutCubic,
              width: isSelected ? 20 : 0,
              height: 3,
              margin: const EdgeInsets.only(bottom: AppDimensions.space4),
              decoration: BoxDecoration(
                color: AppColors.goldPrimary,
                borderRadius:
                    BorderRadius.circular(AppDimensions.radiusFull),
              ),
            ),
            AnimatedSwitcher(
              duration: const Duration(milliseconds: 200),
              child: Icon(
                isSelected ? tab.activeIcon : tab.icon,
                key: ValueKey(isSelected),
                size: AppDimensions.iconMD,
                color:
                    isSelected ? AppColors.navyDeep : AppColors.grey400,
              ),
            ),
            const SizedBox(height: AppDimensions.space4),
            Text(
              tab.label,
              style: AppTypography.labelSmall.copyWith(
                color:
                    isSelected ? AppColors.navyDeep : AppColors.grey400,
                fontWeight:
                    isSelected ? FontWeight.w600 : FontWeight.w400,
                fontSize: 10,
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
            ),
          ],
        ),
      ),
    );
  }
}