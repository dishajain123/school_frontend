import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

class NavItem extends StatefulWidget {
  const NavItem({
    super.key,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final IconData icon;
  final IconData activeIcon;
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  State<NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<NavItem>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _scaleAnim;
  late Animation<double> _pillWidthAnim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 280),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.12).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutBack),
    );
    _pillWidthAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _ctrl, curve: Curves.easeOutCubic),
    );

    if (widget.isSelected) _ctrl.forward();
  }

  @override
  void didUpdateWidget(NavItem oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _ctrl.forward();
      } else {
        _ctrl.reverse();
      }
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      behavior: HitTestBehavior.opaque,
      child: SizedBox(
        height: 60,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ScaleTransition(
              scale: _scaleAnim,
              child: AnimatedBuilder(
                animation: _pillWidthAnim,
                builder: (_, child) {
                  return Container(
                    width: 40,
                    height: 32,
                    decoration: BoxDecoration(
                      color: widget.isSelected
                          ? AppColors.navyDeep.withValues(
                              alpha: 0.1 * _pillWidthAnim.value)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: child,
                  );
                },
                child: Icon(
                  widget.isSelected ? widget.activeIcon : widget.icon,
                  size: 22,
                  color: widget.isSelected
                      ? AppColors.navyDeep
                      : AppColors.grey400,
                ),
              ),
            ),
            const SizedBox(height: 3),
            AnimatedDefaultTextStyle(
              duration: const Duration(milliseconds: 200),
              style: AppTypography.labelSmall.copyWith(
                fontSize: 10,
                fontWeight: widget.isSelected
                    ? FontWeight.w700
                    : FontWeight.w400,
                color: widget.isSelected
                    ? AppColors.navyDeep
                    : AppColors.grey400,
              ),
              child: Text(widget.label),
            ),
          ],
        ),
      ),
    );
  }
}