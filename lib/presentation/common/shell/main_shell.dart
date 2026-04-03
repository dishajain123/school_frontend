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

class _MainShellState extends ConsumerState<MainShell> {
  late final List<ShellTabItem> _tabs;
  late int _currentIndex;
  late final List<GlobalKey<NavigatorState>> _navigatorKeys;

  @override
  void initState() {
    super.initState();
    _tabs = RoleShellConfig.tabsForRole(widget.role);
    _currentIndex = 0;
    _navigatorKeys =
        List.generate(_tabs.length, (_) => GlobalKey<NavigatorState>());

    // Load notification count on shell init
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(notificationNotifierProvider.notifier).loadUnreadCount();
    });
  }

  void _onTabTapped(int index, BuildContext context) {
    if (index == _currentIndex) {
      _navigatorKeys[index].currentState?.popUntil((r) => r.isFirst);
      return;
    }

    HapticFeedback.selectionClick();

    setState(() {
      _currentIndex = index;
    });

    ref.read(shellTabIndexProvider.notifier).state = index;

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
        onTabTapped: (i) => _onTabTapped(i, context),
      ),
    );
  }
}

class _BottomNav extends StatelessWidget {
  const _BottomNav({
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
          child: BottomNavigationBar(
            currentIndex: currentIndex,
            onTap: onTabTapped,
            type: BottomNavigationBarType.fixed,
            backgroundColor: AppColors.white,
            elevation: 0,
            selectedItemColor: AppColors.navyDeep,
            unselectedItemColor: AppColors.grey400,
            selectedFontSize: 10,
            unselectedFontSize: 10,
            selectedLabelStyle: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 10,
            ),
            unselectedLabelStyle: AppTypography.labelSmall.copyWith(
              fontWeight: FontWeight.w400,
              fontSize: 10,
            ),
            items: tabs
                .map(
                  (tab) => BottomNavigationBarItem(
                    icon: Icon(tab.icon, size: AppDimensions.iconSM),
                    activeIcon:
                        Icon(tab.activeIcon, size: AppDimensions.iconSM),
                    label: tab.label,
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
