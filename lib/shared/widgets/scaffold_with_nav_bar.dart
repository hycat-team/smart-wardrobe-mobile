import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import '../../core/theme/app_theme.dart';

/// Bottom navigation bar designed according to Closy Quiet Luxury aesthetic,
/// featuring a prominent floating circular center button for the Wardrobe tab,
/// top indicator bars for standard tabs, and refined micro-interactions.
class ScaffoldWithNavBar extends StatelessWidget {
  const ScaffoldWithNavBar({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    final currentIndex = navigationShell.currentIndex;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: Container(
        color: Colors.transparent,
        child: SafeArea(
          top: false,
          child: SizedBox(
            height: 76,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                // Layer 1: White background bar with subtle border & upward luxury shadow
                Positioned(
                  left: 0,
                  right: 0,
                  top: 16,
                  bottom: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      border: const Border(
                        top: BorderSide(
                          color: AppColors.divider,
                          width: 1.0,
                        ),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.04),
                          blurRadius: 14,
                          offset: const Offset(0, -3),
                        ),
                      ],
                    ),
                  ),
                ),

                // Layer 2: 5 navigation items horizontally spaced
                Positioned(
                  left: 0,
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Row(
                    children: [
                      // Tab 0: Home
                      Expanded(
                        child: _StandardNavItem(
                          index: 0,
                          currentIndex: currentIndex,
                          icon: Icons.home_outlined,
                          activeIcon: Icons.home_rounded,
                          label: 'Home',
                          onTap: () => _onTabTapped(0),
                        ),
                      ),

                      // Tab 1: Stylist
                      Expanded(
                        child: _StandardNavItem(
                          index: 1,
                          currentIndex: currentIndex,
                          icon: Icons.auto_awesome_outlined,
                          activeIcon: Icons.auto_awesome,
                          label: 'Stylist',
                          onTap: () => _onTabTapped(1),
                        ),
                      ),

                      // Tab 2: Wardrobe (Center Hero Elevated Button)
                      Expanded(
                        child: _CenterHeroNavItem(
                          index: 2,
                          currentIndex: currentIndex,
                          label: 'Wardrobe',
                          onTap: () => _onTabTapped(2),
                        ),
                      ),

                      // Tab 3: Outfits
                      Expanded(
                        child: _StandardNavItem(
                          index: 3,
                          currentIndex: currentIndex,
                          icon: Icons.style_outlined,
                          activeIcon: Icons.style_rounded,
                          label: 'Outfits',
                          onTap: () => _onTabTapped(3),
                        ),
                      ),

                      // Tab 4: Profile
                      Expanded(
                        child: _StandardNavItem(
                          index: 4,
                          currentIndex: currentIndex,
                          icon: Icons.person_outline_rounded,
                          activeIcon: Icons.person_rounded,
                          label: 'Profile',
                          onTap: () => _onTabTapped(4),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _onTabTapped(int index) {
    HapticFeedback.lightImpact();
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }
}

/// Standard navigation item (Home, Stylist, Outfits, Profile) with top pill indicator
class _StandardNavItem extends StatelessWidget {
  const _StandardNavItem({
    required this.index,
    required this.currentIndex,
    required this.icon,
    required this.activeIcon,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final IconData icon;
  final IconData activeIcon;
  final String label;
  final VoidCallback onTap;

  static const Color _accentCaramel = Color(0xFFBE9B7B);

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        children: [
          // Spacer from top of 74px Stack to bar content
          const SizedBox(height: 18),

          // Top pill indicator bar (active) or placeholder spacer (inactive)
          if (isSelected)
            Container(
              width: 28,
              height: 3,
              margin: const EdgeInsets.only(bottom: 6),
              decoration: BoxDecoration(
                color: _accentCaramel,
                borderRadius: BorderRadius.circular(2),
              ),
            )
          else
            const SizedBox(height: 9),

          // Icon with outline/rounded transition
          Icon(
            isSelected ? activeIcon : icon,
            size: 22,
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(height: 3),

          // Label
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              letterSpacing: -0.1,
            ),
          ),
        ],
      ),
    );
  }
}

/// Center Hero Elevated Button for Wardrobe (elevated circular container + label + dot)
class _CenterHeroNavItem extends StatelessWidget {
  const _CenterHeroNavItem({
    required this.index,
    required this.currentIndex,
    required this.label,
    required this.onTap,
  });

  final int index;
  final int currentIndex;
  final String label;
  final VoidCallback onTap;

  static const Color _accentCaramel = Color(0xFFBE9B7B);
  static const Color _inactiveRing = Color(0xFFD8C4B6);

  @override
  Widget build(BuildContext context) {
    final isSelected = currentIndex == index;

    return InkWell(
      onTap: onTap,
      splashColor: Colors.transparent,
      highlightColor: Colors.transparent,
      child: Column(
        children: [
          const SizedBox(height: 1),

          // Circular elevated hero container
          AnimatedContainer(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeInOutCubic,
            width: 49,
            height: 49,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: isSelected ? _accentCaramel : Colors.white,
              border: isSelected
                  ? null
                  : Border.all(
                      color: _inactiveRing,
                      width: 1.5,
                    ),
              boxShadow: isSelected
                  ? [
                      BoxShadow(
                        color: _accentCaramel.withOpacity(0.38),
                        blurRadius: 14,
                        offset: const Offset(0, 4),
                      ),
                    ]
                  : [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.06),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
            ),
            child: Center(
              child: AnimatedSwitcher(
                duration: const Duration(milliseconds: 180),
                child: Icon(
                  isSelected ? Icons.checkroom_rounded : Icons.checkroom_outlined,
                  key: ValueKey<bool>(isSelected),
                  size: 25,
                  color: isSelected ? Colors.white : const Color(0xFF2D2D2D),
                ),
              ),
            ),
          ),

          const SizedBox(height: 3),

          // Label
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
              color: isSelected ? AppColors.primary : AppColors.textSecondary,
              letterSpacing: -0.1,
            ),
          ),

          const SizedBox(height: 2),

          // Tiny accent dot indicator under label when active (as in Image 2)
          AnimatedOpacity(
            duration: const Duration(milliseconds: 180),
            opacity: isSelected ? 1.0 : 0.0,
            child: Container(
              width: 3.5,
              height: 3.5,
              decoration: const BoxDecoration(
                color: _accentCaramel,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
