import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class BottomNavBar extends StatelessWidget {
  const BottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    required this.onAddPressed,
    this.notificationCount = 0,
  });

  final int currentIndex;
  final ValueChanged<int> onTabSelected;
  final VoidCallback onAddPressed;
  final int notificationCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      decoration: BoxDecoration(
        color: colors.surfaceContainerLowest.withValues(alpha: 0.92),
        boxShadow: [
          BoxShadow(
            color: colors.primary.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 80,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _NavItem(
                icon: Icons.photo_library_outlined,
                selectedIcon: Icons.photo_library,
                label: 'Albümler',
                selected: currentIndex == 0,
                onTap: () => onTabSelected(0),
              ),
              _NavItem(
                icon: Icons.explore_outlined,
                selectedIcon: Icons.explore,
                label: 'Keşfet',
                selected: currentIndex == 1,
                onTap: () => onTabSelected(1),
              ),
              _AddButton(onPressed: onAddPressed),
              _NavItem(
                icon: Icons.notifications_outlined,
                selectedIcon: Icons.notifications,
                label: 'Bildirimler',
                selected: currentIndex == 2,
                onTap: () => onTabSelected(2),
                badgeCount: notificationCount,
              ),
              _NavItem(
                icon: Icons.person_outline,
                selectedIcon: Icons.person,
                label: 'Profil',
                selected: currentIndex == 3,
                onTap: () => onTabSelected(3),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.selectedIcon,
    required this.label,
    required this.selected,
    required this.onTap,
    this.badgeCount = 0,
  });

  final IconData icon;
  final IconData selectedIcon;
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final int badgeCount;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final color = selected ? colors.primary : colors.onSurfaceVariant;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: SizedBox(
        width: 68,
        height: 72,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(selected ? selectedIcon : icon, color: color, size: 24),
                if (badgeCount > 0)
                  Positioned(
                    right: -6,
                    top: -3,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                      constraints: const BoxConstraints(minWidth: 14),
                      decoration: BoxDecoration(color: colors.secondary, borderRadius: BorderRadius.circular(AppRadius.pill)),
                      child: Text(
                        badgeCount > 99 ? '99+' : '$badgeCount',
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSm.copyWith(color: colors.onSecondary, fontSize: 9, height: 1.3),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSm.copyWith(
                color: color,
                fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Transform.translate(
      offset: const Offset(0, -20),
      child: InkWell(
        onTap: onPressed,
        customBorder: const CircleBorder(),
        child: Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: colors.brandGradient,
            boxShadow: [
              BoxShadow(
                color: colors.secondary.withValues(alpha: 0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Icon(Icons.add, color: colors.onSecondary, size: 28),
        ),
      ),
    );
  }
}
