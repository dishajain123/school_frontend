import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../../providers/notification_provider.dart';
import '../bottom_nav/nav_item.dart';
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
    with SingleTickerProviderStateMixin {
  late final List<ShellTabItem> _tabs;
  late AnimationController _navRevealCtrl;
  late Animation<Offset> _navSlide;
  int _lastSyncedIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabs = RoleShellConfig.tabsForRole(widget.role);
    _lastSyncedIndex = 0;

    _navRevealCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _navSlide = Tween<Offset>(
      begin: const Offset(0, 1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _navRevealCtrl, curve: Curves.easeOutCubic),
    );
    _navRevealCtrl.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationNotifierProvider.notifier).loadUnreadCount();
    });
  }

  @override
  void dispose() {
    _navRevealCtrl.dispose();
    super.dispose();
  }

  int _currentIndexForLocation(BuildContext context) {
    final location = GoRouterState.of(context).uri.path;
    return RoleShellConfig.indexForPath(_tabs, location);
  }

  void _onTabTapped(int index, BuildContext context) {
    final currentIndex = _currentIndexForLocation(context);
    if (index == currentIndex) {
      context.go(_tabs[index].rootPath);
      return;
    }

    HapticFeedback.selectionClick();

    ref.read(shellTabIndexProvider.notifier).state = index;
    context.go(_tabs[index].rootPath);
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = _currentIndexForLocation(context);
    if (_lastSyncedIndex != currentIndex) {
      _lastSyncedIndex = currentIndex;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(shellTabIndexProvider.notifier).state = currentIndex;
      });
    }

    return Scaffold(
      backgroundColor: AppColors.surface50,
      body: SafeArea(
        bottom: true,
        top: false,
        child: widget.child,
      ),
      extendBody: true,
      bottomNavigationBar: SlideTransition(
        position: _navSlide,
        child: _PremiumBottomNav(
          tabs: _tabs,
          currentIndex: currentIndex,
          onTabTapped: (i) => _onTabTapped(i, context),
        ),
      ),
    );
  }
}

class _PremiumBottomNav extends StatelessWidget {
  const _PremiumBottomNav({
    required this.tabs,
    required this.currentIndex,
    required this.onTabTapped,
  });

  final List<ShellTabItem> tabs;
  final int currentIndex;
  final ValueChanged<int> onTabTapped;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.white,
        border: const Border(
          top: BorderSide(
            color: AppColors.surface100,
            width: 1,
          ),
        ),
        boxShadow: [
          BoxShadow(
            color: AppColors.navyDeep.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
            spreadRadius: -2,
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: SizedBox(
            height: 60,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(tabs.length, (i) {
                return Expanded(
                  child: NavItem(
                    icon: tabs[i].icon,
                    activeIcon: tabs[i].activeIcon,
                    label: tabs[i].label,
                    isSelected: i == currentIndex,
                    onTap: () => onTabTapped(i),
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}
