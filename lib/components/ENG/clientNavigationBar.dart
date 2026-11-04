import 'package:flutter/material.dart';
import '../sirvya_logo.dart';
import '../home_robot_wave.dart';
import '../../theme/fitlek_theme_extension.dart';

class ClientNavigationBar extends StatelessWidget {
  static const double _logoSize = 54;
  final int currentIndex;
  final ValueChanged<int> onSelected;
  final VoidCallback onScanMeal;
  const ClientNavigationBar(
      {super.key,
      required this.currentIndex,
      required this.onSelected,
      required this.onScanMeal});
  @override
  Widget build(BuildContext context) {
    const items = [
      (Icons.home_rounded, 'Home'),
      (Icons.search_rounded, 'Explore'),
      (Icons.calendar_today_rounded, 'Sessions'),
      (Icons.person_rounded, 'Profile'),
    ];

    const leftItems = [0, 1];
    const rightItems = [2, 3];

    return SafeArea(
        top: false,
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.bottomCenter,
          children: [
            Container(
              decoration: BoxDecoration(
                color: context.fitlek.card,
                border: Border(
                    top: BorderSide(color: context.fitlek.border, width: 1)),
                boxShadow: [
                  BoxShadow(
                    color: context.fitlek.shadow,
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ...leftItems.map((i) =>
                      Expanded(child: _buildNavItem(context, i, items[i]))),
                  const SizedBox(width: _logoSize),
                  ...rightItems.map((i) =>
                      Expanded(child: _buildNavItem(context, i, items[i]))),
                ],
              ),
            ),
            // The robot sits on the navbar surface; only the foreground logo
            // overlaps it, so its wave can remain visible inside the navbar.
            Positioned(
              top: -30,
              child: Transform.translate(
                offset: const Offset(20, 12),
                child: const HomeRobotWave(active: true),
              ),
            ),
            Positioned(
              top: -8,
              child: Semantics(
                label: 'Scan your meal',
                button: true,
                excludeSemantics: true,
                onTap: onScanMeal,
                child: GestureDetector(
                  onTap: onScanMeal,
                  child: Container(
                    width: _logoSize,
                    height: _logoSize,
                    decoration: BoxDecoration(
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .primary
                              .withValues(alpha: 0.15),
                          blurRadius: 20,
                          spreadRadius: 2,
                        ),
                      ],
                    ),
                    child: const Center(
                      child: SirvyaLogo(
                          variant: SirvyaLogoVariant.mark, height: _logoSize),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ));
  }

  Widget _buildNavItem(
      BuildContext context, int index, (IconData, String) item) {
    final active = index == currentIndex;
    return GestureDetector(
      onTap: () => onSelected(index),
      behavior: HitTestBehavior.opaque,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
        decoration: BoxDecoration(
          color: active
              ? Theme.of(context).colorScheme.primary.withValues(alpha: 0.12)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              item.$1,
              color: active
                  ? Theme.of(context).colorScheme.primary
                  : context.fitlek.navUnselected,
              size: 22,
            ),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                item.$2,
                style: TextStyle(
                  color: active
                      ? Theme.of(context).colorScheme.primary
                      : context.fitlek.navUnselected,
                  fontSize: 10,
                  fontWeight: active ? FontWeight.w700 : FontWeight.w400,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
