import 'package:flutter/material.dart';
import '../../theme/fitlek_theme_extension.dart';

class CoachNavbar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  const CoachNavbar(
      {super.key, required this.currentIndex, required this.onTap});
  static const _items = [
    (Icons.dashboard_outlined, Icons.dashboard_rounded, 'Dashboard'),
    (Icons.calendar_month_outlined, Icons.calendar_month_rounded, 'Calendar'),
    (Icons.chat_bubble_outline_rounded, Icons.chat_bubble_rounded, 'Chats'),
    (Icons.people_outline_rounded, Icons.people_rounded, 'Clients'),
    (Icons.person_outline_rounded, Icons.person_rounded, 'Profile'),
  ];
  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final colors = context.fitlek;
    return SafeArea(
      top: false,
      minimum: const EdgeInsets.fromLTRB(12, 6, 12, 8),
      child: Center(
        heightFactor: 1,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: DecoratedBox(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: colors.border.withValues(alpha: .65)),
              boxShadow: [
                BoxShadow(
                    color: colors.shadow,
                    blurRadius: 16,
                    offset: const Offset(0, 4))
              ],
            ),
            child: Padding(
              padding: const EdgeInsets.all(6),
              child: Row(
                  children: List.generate(_items.length, (index) {
                final item = _items[index];
                final selected = index == currentIndex;
                final foreground =
                    selected ? cs.onPrimary : colors.navUnselected;
                return Expanded(
                    child: Semantics(
                  selected: selected,
                  button: true,
                  label: item.$3,
                  child: Tooltip(
                      message: item.$3,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 180),
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                            color: selected ? cs.primary : Colors.transparent,
                            borderRadius: BorderRadius.circular(18)),
                        child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              borderRadius: BorderRadius.circular(18),
                              onTap: () => onTap(index),
                              child: Padding(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 2, vertical: 9),
                                  child: Column(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(selected ? item.$2 : item.$1,
                                            size: 21, color: foreground),
                                        const SizedBox(height: 5),
                                        Text(item.$3,
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: TextStyle(
                                                color: foreground,
                                                fontSize: 10,
                                                fontWeight: selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w500)),
                                      ])),
                            )),
                      )),
                ));
              })),
            ),
          ),
        ),
      ),
    );
  }
}
